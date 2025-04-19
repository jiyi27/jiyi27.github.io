---
title: MongoDB 聚合管道
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

