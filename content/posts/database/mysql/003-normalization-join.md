---
title: 一对多, 多对多建表 MySQL MongoDB
date: 2024-01-10 11:51:35
categories:
 - 数据库
tags:
 - 数据库
 - mysql
 - mongodb
---

## 1. 规范化 

### 1.1. Normalization

规范化是一种将数据库表结构分解为更小的、更符合范式的表，以减少数据冗余，提高数据一致性的方法。它涉及将数据分解成多个相互关联的表。这种设计减少了数据的重复，但**通常会导致更复杂的查询，因为需要多个JOIN操作来重建原始信息**。

### 1.2. Denormalization

Denormalization 是 Normalization 的对立面。它涉及将数据从多个表合并到一个表中，有时通过添加冗余数据来实现。在非关系型数据库，如MongoDB中，Denormalization 通常表现为：

1. **嵌入子文档**：将相关的数据直接嵌入到一个文档中，而不是将它们分散到多个集合（表）中。例如，而不是在单独的集合中维护用户地址，可以将地址作为子文档直接嵌入到用户文档中

2. **使用数组**：在文档中使用数组来存储相关项的列表。例如，一个产品文档可能包含一个评论的数组，而不是将评论存储在一个单独的集合中

### 1.3. 结论

在MongoDB这样的非关系型数据库中，反规范化是一种常见的数据建模技术，特别**适用于读取操作远多于写入操作的场景**。它通过牺牲一定程度的数据冗余来换取读取性能的提升和查询逻辑的简化。然而，设计时需要平衡冗余带来的管理复杂性和性能优势。

## 2. Join & Foreign Key

- Join: [MySQL: JOINS are easy (INNER, LEFT, RIGHT)](https://www.youtube.com/watch?v=G3lJAxg1cy8)
- Foreign Key is used to ensure the consistency and integrity of data. 

> MongoDB 没有 join 和 foreign key 的的概念, 但是可以通过嵌套文档来实现类似 Join 的功能, 以及使用 Reference 来实现类似 Foreign Key 的功能.

JOIN操作经常利用外键来连接两个表, 虽然 JOIN 操作不一定要求存在外键约束, 但外键为 JOIN 提供了自然的连接点, 如下例子:
- **Users表** 存储用户信息：UserID (用户ID，主键), UserName (用户名)
- **Orders表** 存储订单信息：OrderID (订单ID，主键) OrderDate (订单日期) UserID (用户ID，外键)

在这个情况下，`Orders.UserID` 是一个外键, 它指向`Users.UserID`, 这意味着每个订单都与一个特定的用户相关联，外键保证了每个订单中的UserID都对应于一个有效的用户, 假设我们想获取订单信息以及下单的用户的名称。我们可以使用以下SQL查询：

```sql
SELECT Users.UserName, Orders.OrderID, Orders.OrderDate
FROM Orders
JOIN Users ON Orders.UserID = Users.UserID;
```

这个查询中：

1. `JOIN Users ON Orders.UserID = Users.UserID`这一句是JOIN的核心，它说明了如何连接这两个表。我们通过`Orders`表中的`UserID`（外键）与`Users`表中的`UserID`（主键）进行匹配。
2. 由于使用了JOIN，我们可以同时从`Orders`表和`Users`表中选择数据。因此，我们能够在同一个查询结果中同时看到用户的名字和他们的订单信息。

## 3. One to Many & Many to Many

- **一对多关系**：如订单和用户表, 通过在订单表中设置外键用户ID指向用户表的主键ID来实现
- **多对多关系**：通过创建一个额外的关联表，其中包含指向两个相关表主键的外键来实现, 如术语和分类表, 每个术语可以有多个分类, 每个分类下可以有多个术语, 这时候需要一个单独的术语分类关系表, 来表示术语和分类的关系

> 多对多关系中, 可以在单独的那个关系表中建立一个复合索引, 比如术语和分类, 我们建立 (分类, 术语) 索引, 这样呢, 我们就可以很快的找到某个分类下的所有术语, 因为但我们建立了这个索引, 表中的存储结构就会变为: 同一分类下的术语都会在一块, 且 分类也是排序过的,

## 4. One-to-Many and Many-to-Many in NoSQL MongoDB

一对多关系在MongoDB中通常有两种表示方式：

1. **嵌入文档**: 如果一个用户有多个地址，那么地址可以直接嵌入到用户文档中
   
   ```json
   {
     "_id": "userId123",
     "name": "John Doe",
     "addresses": [
       {"street": "123 Apple St", "city": "New York"},
       {"street": "456 Orange Ave", "city": "Boston"}
     ]
   }
   ```
   
2. **引用**: 类似关系型数据库中的外键
   
   ```json
   // User document
   {
     "_id": "userId123",
     "name": "John Doe"
   }
   
   // Address documents
   [
     {"_id": "addressId1", "userId": ObjectID("userId123"), "street": "123 Apple St", "city": "New York"},
     {"_id": "addressId2", "userId": ObjectID("userId123"), "street": "456 Orange Ave", "city": "Boston"}
   ]
   ```

多对多关系在MongoDB中通常通过引用来表示, 每个文档存储与之相关联的其他文档的ID, **an array of object IDs**. 假设有学生和课程，每个学生可以选修多门课程，每门课程也可以由多个学生选修

**学生文档**可能包含它们所选课程的ID列表:

```json
{
  "_id": "studentId1",
  "name": "Alice",
  "courses": ["courseId1", "courseId2"]
}
```

**课程文档**可能包含选修该课程的学生ID列表:

```json
{
  "_id": "courseId1",
  "courseName": "Mathematics",
  "students": ["studentId1", "studentId3"]
}
```

嵌入文档可以提高读取性能，因为所有相关数据都在一个文档内；而引用更灵活，可以更容易地维护大量动态关联数据, 了解更多: MongoDB in Action: 4.2.1 Many-to-many relationships
