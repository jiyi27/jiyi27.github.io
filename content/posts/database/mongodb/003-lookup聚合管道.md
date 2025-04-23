---
title: MongoDB $lookup 聚合管道
date: 2025-04-23 21:39:18
categories:
 - 数据库
tags:
 - 数据库
 - mongodb
---

MongoDB 查询中, 一般一个聚合阶段比如 `$lookup` 会用到多个子管道, 比如下面的一些:

1. **from**: 指定要连接的集合（这里是 "Orders"）
2. **let**: 定义变量，将主集合中的字段传递到子管道中使用
3. **pipeline**: 定义子聚合管道，处理从 Orders 集合中查找的数据
4. **as**: 指定输出字段的名称，存储查找结果

我们可以通过具体的例子来解释他们的作用, 下面是用户和订单两个 collections 的结构, 

```json
{
  "_id": ObjectId("..."),
  "name": "Alice",
  "userId": "u123"
}
```

```json
{
  "_id": ObjectId("..."),
  "orderId": "o456",
  "userId": "u123",
  "amount": 100,
  "status": "completed"
}
```

我们想查询每个用户的资料，并附上该用户**近30天内已完成的订单列表**

```js
db.users.aggregate([
  {
    $lookup: {
      from: "orders",
      let: { uid: "$userId" },  // 定义变量，将主表的 userId 传入
      pipeline: [
        {
          $match: {
            $expr: {
              $and: [
                { $eq: ["$userId", "$$uid"] }, // 使用 let 定义的变量进行匹配
                { $eq: ["$status", "completed"] },
                { $gte: ["$createdAt", { $dateSubtract: { startDate: "$$NOW", unit: "day", amount: 30 } }] }
              ]
            }
          }
        },
        { $project: { orderId: 1, amount: 1, createdAt: 1 } }
      ],
      as: "recentOrders" // 把查出来的订单放在 recentOrders 字段里
    }
  }
])
```

| 参数         | 作用                                                         |
| ------------ | ------------------------------------------------------------ |
| **from**     | 指定要关联的集合名，这里是 `"orders"`                        |
| **let**      | 用于在 `pipeline` 中定义变量，变量名可以在后续 `$match` 或 `$expr` 里使用，例如 `$$uid` |
| **pipeline** | 子管道，对关联集合进行更复杂的过滤，比如 `match`、`sort`、`project` 等操作 |
| **as**       | 指定查找结果的字段名，这里会把查到的订单放进 `recentOrders` 数组字段中 |

**输出结果示例：**

```json
{
  "name": "Alice",
  "userId": "u123",
  "recentOrders": [
    {
      "orderId": "o456",
      "amount": 100,
      "createdAt": "2025-04-01T..."
    },
    ...
  ]
}
```

### 1. `let` 的作用

在 MongoDB 的聚合管道中，特别是在 `$lookup` 阶段，`let` 用于**定义变量**，这些变量可以将**父文档（外层文档）**的字段值传递到子管道（`pipeline`）中供其使用, 可以类比为**函数调用中的参数传递**，但更具体地说：

- `let` 定义了一组变量，这些变量的值来自外层文档的字段
- 这些变量可以在子管道（`pipeline`）中使用，通过 `$$variableName` 的语法引用

在上面的代码中：

```csharp
let: { uid: "$userId" }
```

- `uid` 是变量名（相当于函数的参数名），用于在子管道中引用
- `"$userId"` 是外层文档（`orders` 集合中的文档）的字段名，表示将外层文档的 `userId` 字段的值绑定到 `uid` 变量上

### 2. `uid` 和 `$userId` 的区别

- `uid`：这是你在 `let` 中定义的**变量名**, 仅在子管道（`pipeline`）中有效, 你可以随意命名, 比如叫 `myVar`, 只要在子管道中一致引用即可
- `$userId`：这是外层文档（`orders` 集合）的字段名, 前面加 `$` 表示引用文档的字段值, MongoDB 聚合管道中使用 `$fieldName` 语法来表示字段的值

**例子**：
假设 `Orders` 集合中的一个文档如下：

```json
{
  "_id": 1,
  "userId": "P123",
}
```

通过 `let`：

- `uid` 变量的值被绑定为 `"P123"`（来自 `$userId`）

在子管道中，你可以通过 `$$uid` 访问这个值（注意 `$$` 前缀，表示引用 `let` 定义的变量）

### 3. `pipeline` 中的 `$eq` 和 `$$uid`

现在来看子管道中的代码：

```csharp
{ $eq: ["$userId", "$$uid"] }
```

这部分代码出现在 `$match` 阶段的 `$expr` 中, 用于比较两个值是否相等, `$eq` 是一个比较操作符, 接受一个包含两个元素的数组 `[value1, value2]`，检查 `value1` 是否等于 `value2`