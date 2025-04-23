---
title: MongoDB 聚合管道中的 (Stages 和 Operators)
date: 2025-04-19 22:20:18
categories:
 - 数据库
tags:
 - 数据库
 - mongodb
---

## 1. 为何聚合管道效率更高

### 1.1. 普通查询

```c#
var posts = await _postModel.Find(_ => true).ToListAsync();
List<CommentModel> allComments = new List<CommentModel>();

foreach (var post in posts)
{
    if (post.CommentList != null && post.CommentList.Any())
    {
        allComments.AddRange(post.CommentList);
    }
}

return allComments;
```

❗1. **传输的数据体积大**

- `ToListAsync()` 会把**整条文档加载进内存**，包括帖子内容、标题、标签、图片等一堆无关字段
- 比如每个帖子 1MB，1000 个帖子就是 1GB 网络传输量，哪怕你只要其中的评论

❗2. **内存占用高**

- 所有数据都拉进内存，哪怕你只关心里面一小块数据（比如 `CommentList`）
- 对于大集合、高并发服务，这会造成严重的资源消耗

❗3. **处理逻辑写在代码层，效率低**

- 你要在 C# 层手动拆解、遍历、组合这些数据，相当于自己在模拟数据库的工作，性能远不如数据库原生操作

### 1.2. 聚合查询

```c#
var pipeline = new BsonDocument[]
{
    // 第一步：展开 CommentList 数组
    // 对每个 Post 文档，将 CommentList 中的每条评论都“拆开”，每条评论单独形成一条文档
    new BsonDocument("$unwind",
        new BsonDocument("path", "$CommentList")
            .Add("preserveNullAndEmptyArrays", false)), // 如果 CommentList 是 null 或空数组，则跳过该文档

    // 第二步：投影出我们感兴趣的字段
    // 我们只要评论内容，把它包装成 "comment" 字段，同时去掉 _id
    new BsonDocument("$project",
        new BsonDocument("_id", 0) // 不要 MongoDB 的 ObjectId 字段
            .Add("comment", "$CommentList")), // 把 CommentList 的当前项命名为 comment

    // 第三步：把 comment 作为根节点
    // 把整条文档替换为 comment 字段的内容，相当于去掉了外层包裹
    new BsonDocument("$replaceRoot",
        new BsonDocument("newRoot", "$comment"))
};

// 执行聚合管道，最终返回的是一组 CommentModel 类型的列表
var comments = await _postModel.Aggregate<CommentModel>(pipeline).ToListAsync();
return comments;
```

✅1. **只取需要的数据**

- 聚合管道中用 `$project` 和 `$replaceRoot` 精确过滤出「你想要的字段」，减少网络负担

✅2. **由数据库高效处理数据结构**

- MongoDB 内部做展开、映射、过滤，使用原生的 C++ 引擎，速度远远快于 C# 遍历

✅3. **节省内存与计算资源**

- 不需要把整条大文档拉进来，只需要从 MongoDB 拿你想要的部分，C# 层代码也变得非常轻量

✅4. **可以在聚合中做更复杂操作**

- 想做排序、过滤、分页等操作？聚合支持 `$match`、`$sort`、`$limit`，让数据库帮你完成这些逻辑

## 2. `unwind`, `project`, `replaceRoot`

在上面的聚合管道中, 我们用了:

```js
$unwind: "$CommentList"
$project: { comment: "$CommentList" }
$replaceRoot: { newRoot: "$comment" }
```

MongoDB 会把每个评论都**单独展开成一条结果文档**，像这样：

```js
[
  { "Author": "小明", "Content": "写得不错", "CreatedAt": "..." },
  { "Author": "小红", "Content": "顶一个", "CreatedAt": "..." },
  ...
]
```

每条结果就是一个纯粹的 `CommentModel`，所以：聚合后返回的每一条记录是一个 `CommentModel` 实例，组成的整体就是一个 `List<CommentModel>`

假设有一个帖子集合 `posts`，每条文档结构如下：

```json
{
  "_id": "post1",
  "title": "MongoDB 聚合示例",
  "CommentList": [
    { "Author": "Alice", "Content": "Nice post!" },
    { "Author": "Bob", "Content": "I agree!" }
  ]
}
```

我们目标是：从整个 posts 集合中，**提取出每一条独立的评论（CommentModel）**，不带其他字段

### 2.1. 第一步 `$unwind` —— **展开数组字段**

**✅ 语法：**

```json
{ "$unwind": { "path": "$CommentList", "preserveNullAndEmptyArrays": false } }
```

**✅ 参数解释：**

- `path`: 要展开的数组字段，**必须是数组**（这里是 `CommentList`）
- `preserveNullAndEmptyArrays`: 是否保留空数组或不存在该字段的文档
  - `false` 表示不保留（只处理有评论的文档）

**✅ 效果：**

这一步的作用是：

> 如果一个文档中的 `CommentList` 是一个数组, 它会**把数组里的每个元素拆分为一条新的文档**

🔁 原始数据：

```json
{
  "_id": "post1",
  "CommentList": [
    { "Author": "Alice", "Content": "Nice post!" },
    { "Author": "Bob", "Content": "I agree!" }
  ]
}
```

📤 经过 `$unwind` 后变成两条记录：

```json
{
  "_id": "post1",
  "CommentList": { "Author": "Alice", "Content": "Nice post!" }
},
{
  "_id": "post1",
  "CommentList": { "Author": "Bob", "Content": "I agree!" }
}
```

 每条结果都只包含**一个评论对象**在 `CommentList` 字段中（已经不是数组了）

### 2.2. 第二步 `$project` —— **保留我们关心的字段，并重新命名**

**✅ 语法：**

```json
{ "$project": { "_id": 0, "comment": "$CommentList" } }
```

**✅ 参数解释：**

- `_id: 0`：不显示 MongoDB 默认的 `_id` 字段

- `"comment": "$CommentList"`：把 `CommentList` 字段的内容赋值给一个新字段 `comment`

**🔁 上一步输出：**

```json
{
  "_id": "post1",
  "CommentList": { "Author": "Alice", "Content": "Nice post!" }
}
```

**📤 变成：**

```json
{
  "comment": { "Author": "Alice", "Content": "Nice post!" }
}
```

💡 我们只保留了评论这部分数据，字段名变成了 `comment`，**更好处理下一步的结构变换**

### 2.3. 第三步 `$replaceRoot` —— **让 comment 成为新文档的根部**

✅ 语法：

```json
{ "$replaceRoot": { "newRoot": "$comment" } }
```

**✅ 参数解释**

- `newRoot`: 用哪个字段的值**替换掉当前文档的根**

**🔁 上一步输出：**

```json
{
  "comment": { "Author": "Alice", "Content": "Nice post!" }
}
```

**📤 变成：**

```json
{
  "Author": "Alice",
  "Content": "Nice post!"
}
```

💡 `comment` 字段里的内容被**提取成了顶层字段**，正是你最终想要的结构：一个干净的 `CommentModel`

## 3. `$group`, `$sum`

假设我们有一个集合 `orders`，它存储了客户订单，结构大概如下：

```json
[
  { "_id": 1, "orderStatus": "pending", "amount": 100, "customer": "Alice" },
  { "_id": 2, "orderStatus": "processing", "amount": 200, "customer": "Bob" },
  { "_id": 3, "orderStatus": "completed", "amount": 150, "customer": "Charlie" },
  { "_id": 4, "orderStatus": "pending", "amount": 300, "customer": "Dave" },
  { "_id": 5, "orderStatus": "completed", "amount": 250, "customer": "Eve" },
  { "_id": 6, "orderStatus": "processing", "amount": 400, "customer": "Frank" }
]
```

目标是通过聚合管道统计每个订单状态（`orderStatus`）的订单数量，例如有多少订单是 `pending`、`processing` 和 `completed`, 使用一个 `$group` 聚合阶段配合一个聚合运算符 `$sum` 就可以实现:

```c#
{
  "$group": {
    "_id": "$orderStatus",
    "count": { "$sum": 1 }
  }
}
```

- `"_id": "$orderStatus"` 告诉 MongoDB 根据 `orderStatus` 字段的值将文档分组
- MongoDB 会**扫描集合中的每个文档**，读取 `orderStatus` 的值，并将具有相同 `orderStatus` 值的文档归为一组
- `$sum: 1` 的计数过程
  - 对于每个分组，MongoDB **创建一个新的文档**，包含 `_id`（分组键的值，例如 "pending"）和 `count` 字段（由 $sum: 1 定义） `count` 初始值为 0
  - 也就是说, MongoDB 会创建三个文档(因为一共有三个状态), 每个文档的分组键 `_id` 的值都是对应的状态值  
  - MongoDB 按顺序（或优化后的顺序）遍历集合中的每个文档，检查其 `orderStatus`，并将其分配到对应的分组
  - 对于每个文档，`$sum: 1` 表示将该文档的  `count` 字段的值增加 1, 换句话说，每个文档为它所在分组的 `count` 贡献 1

经过 `$group` 阶段，数据被转换为以下形式：

```json
[
  { "_id": "pending", "count": 2 },
  { "_id": "processing", "count": 2 },
  { "_id": "completed", "count": 2 }
]
```

## 4. Operators vs Stages

### 4.1. 聚合阶段（Aggregation Stages）

构成聚合管道的“每一步”

| 聚合阶段           | 功能                                           |
| ------------------ | ---------------------------------------------- |
| `$match`           | 过滤文档（类似 SQL 的 `WHERE`）                |
| `$group`           | 分组并进行聚合计算（类似 SQL 的 `GROUP BY`）   |
| `$project`         | 投影字段（类似 SQL 的 `SELECT column AS ...`） |
| `$sort`            | 排序                                           |
| `$limit` / `$skip` | 分页                                           |
| `$lookup`          | 类似 SQL 的 `JOIN`                             |

### 4.2.  聚合运算符（Aggregation Operators）

在某些阶段内部使用的“函数”，比如 `$group` 阶段里面常用的：

| 聚合运算符      | 用法        | 类似 SQL 函数       |
| --------------- | ----------- | ------------------- |
| `$sum`          | 求和或计数  | `SUM()` / `COUNT()` |
| `$avg`          | 求平均      | `AVG()`             |
| `$min` / `$max` | 最小/最大值 | `MIN()` / `MAX()`   |

## 5. `$sum` vs  `$group`

`$sum` 是聚合运算符, 与 `$group` 聚合阶段不同, **一个查询聚合管道由多个聚合阶段组成**, 每个聚合阶段都定义了一个新的文档, 可以理解为每个聚合阶段 stage 都会对输入的文档流进行处理，并生成一个新的文档流（可以是转换后的文档、过滤后的文档、分组后的文档等）

### 5.1. 业务逻辑

```json
[
  { "_id": 1, "product": "Laptop", "category": "Electronics", "price": 1000, "quantity": 2, "orderDate": "2023-01-10", "region": "North" },
  { "_id": 2, "product": "Phone", "category": "Electronics", "price": 500, "quantity": 5, "orderDate": "2023-01-15", "region": "South" },
  { "_id": 3, "product": "Desk", "category": "Furniture", "price": 200, "quantity": 1, "orderDate": "2023-02-01", "region": "North" },
  { "_id": 4, "product": "Chair", "category": "Furniture", "price": 100, "quantity": 4, "orderDate": "2023-02-10", "region": "South" },
  { "_id": 5, "product": "Tablet", "category": "Electronics", "price": 300, "quantity": 3, "orderDate": "2023-03-01", "region": "North" }
]
```

我们想分析 2023 年 1 月和 2 月的销售数据，筛选出 `Electronics` 类别，按 `region` 分组，计算每个地区的总销售额（`price * quantity`），并按总销售额降序排序，输出特定字段, 以下是对应的聚合管道（用 MongoDB 的 `BSON` 格式表示）

```json
[
  {
    "$match": {
      "category": "Electronics",
      "orderDate": { "$gte": "2023-01-01", "$lte": "2023-02-28" }
    }
  },
  {
    "$project": {
      "region": 1,
      "totalSale": { "$multiply": ["$price", "$quantity"] }
    }
  },
  {
    "$group": {
      "_id": "$region",
      "totalRegionSale": { "$sum": "$totalSale" }
    }
  },
  {
    "$sort": {
      "totalRegionSale": -1
    }
  }
]
```

### 5.2. 初始数据 输入文档结构 

```json
{
  "_id": ObjectId,
  "product": String,
  "category": String,
  "price": Number,
  "quantity": Number,
  "orderDate": String,
  "region": String
}
```

### 5.3. 阶段 1: `$match`

过滤文档，只保留 `category` 为 `"Electronics"` 且 `orderDate` 在 2023 年 1 月至 2 月之间的文档

```json
{
  "$match": {
    "category": "Electronics",
    "orderDate": { "$gte": "2023-01-01", "$lte": "2023-02-28" }
  }
}
```

**输出文档结构**：与输入相同，因为 $match 只过滤文档，不改变结构

### 5.4. 阶段 2: `$project`

**操作**：选择并转换字段，只保留 `region` 字段，并计算每个订单的总销售额（`totalSale = price * quantity`）

```json
{
  "$project": {
    "region": 1,
    "totalSale": { "$multiply": ["$price", "$quantity"] }
  }
}
```

**输入文档结构**：阶段 1 的输出（包含 `_id`、 `product`、 `category` 等）

**输出文档结构**：

- `region`: 保留原始 region 字段
- `totalSale`: 新字段，计算 `price * quantity`
- **注意**：默认情况下，`_id` 字段会保留，除非明确设置为 `"_id": 0`

```json
{
  "_id": ObjectId,
  "region": String,
  "totalSale": Number
}
```

**输出数据**：

```json
[
  { "_id": 1, "region": "North", "totalSale": 2000 },
  { "_id": 2, "region": "South", "totalSale": 2500 }
]
```

### 5.5. 阶段 3: `$group`

- **操作**：按 `region` 分组，计算每个地区的 `totalSale` 总和（`totalRegionSale`）

```json
{
  "$group": {
    "_id": "$region",
    "totalRegionSale": { "$sum": "$totalSale" }
  }
}
```

**输入文档结构**：阶段 2 的输出（包含 `_id`、 `region`、 `totalSale`）

**输出文档结构**：

- `_id`: 分组键，即 `region` 的值

- `totalRegionSale`: 每个组的 `totalSale` 字段总和（由 `$sum` 计算）

```json
{
  "_id": String,
  "totalRegionSale": Number
}
```

**输出数据**：

```json
[
  { "_id": "North", "totalRegionSale": 2000 },
  { "_id": "South", "totalRegionSale": 2500 }
]
```

...
