---
title: Basic MySQL
date: 2024-01-10 11:51:35
categories:
 - database
tags:
 - database
 - mysql
---

## Denormalization

### Normalization

首先，了解什么是 Normalization 很重要。在关系型数据库设计中，Normalization 是一个组织数据的过程，目的是减少数据冗余和提高数据完整性。它涉及将数据分解成多个相互关联的表。这种设计减少了数据的重复，但**通常会导致更复杂的查询，因为需要多个JOIN操作来重建原始信息**。

### Denormalization

Denormalization 是 Normalization 的对立面。它涉及将数据从多个表合并到一个表中，有时通过添加冗余数据来实现。在非关系型数据库，如MongoDB中，Denormalization 通常表现为：

1. **嵌入子文档**：将相关的数据直接嵌入到一个文档中，而不是将它们分散到多个集合（表）中。例如，而不是在单独的集合中维护用户地址，可以将地址作为子文档直接嵌入到用户文档中。

2. **使用数组**：在文档中使用数组来存储相关项的列表。例如，一个产品文档可能包含一个评论的数组，而不是将评论存储在一个单独的集合中。

### Denormalization 的优点和缺点

**优点**：
- **提高查询性能**：由于相关数据更紧密地存储在一起，因此减少了查询所需的JOIN操作或跨文档查找。
- **简化查询逻辑**：数据模型更直观，容易理解和操作，特别是对于文档数据库。

**缺点**：
- **数据冗余(Data Redundancy)**：相同的数据在多个地方重复，可能导致**数据同步问题**。
- **更新操作复杂化(Complexity in Updates)**：当需要更新冗余数据时，**可能需要在多个地方进行更新**，增加了复杂性。

### 结论

在MongoDB这样的非关系型数据库中，反规范化是一种常见的数据建模技术，特别**适用于读取操作远多于写入操作的场景**。它通过牺牲一定程度的数据冗余来换取读取性能的提升和查询逻辑的简化。然而，设计时需要平衡冗余带来的管理复杂性和性能优势。

## Join & Foreign Key

- Join: [MySQL: JOINS are easy (INNER, LEFT, RIGHT)](https://www.youtube.com/watch?v=G3lJAxg1cy8)
- Foreign Key is used to ensure the consistency and integrity of data. 
  - 既然有了 join, 为什么还需要 foreign key: https://chat.openai.com/share/419afe95-279b-477f-8afa-8f75ab76edad

> MongoDB 没有 join 和 foreign key 的的概念, 但是可以通过嵌套文档来实现类似 Join 的功能, 以及使用 Reference 来实现类似 Foreign Key 的功能.

JOIN操作经常利用外键来连接两个表, 虽然JOIN操作不一定要求存在外键约束, 但外键为JOIN提供了自然的连接点, 如下例子:
- **Users表** 存储用户信息：UserID (用户ID，主键), UserName (用户名)
- **Orders表** 存储订单信息：OrderID (订单ID，主键) OrderDate (订单日期) UserID (用户ID，外键)

在这个情况下，`Orders.UserID` 是一个外键，它指向`Users.UserID`。这意味着每个订单都与一个特定的用户相关联，外键保证了每个订单中的UserID都对应于一个有效的用户。假设我们想获取订单信息以及下单的用户的名称。我们可以使用以下SQL查询：

```sql
SELECT Users.UserName, Orders.OrderID, Orders.OrderDate
FROM Orders
JOIN Users ON Orders.UserID = Users.UserID;
```

这个查询中：

1. `JOIN Users ON Orders.UserID = Users.UserID`这一句是JOIN的核心，它说明了如何连接这两个表。我们通过`Orders`表中的`UserID`（外键）与`Users`表中的`UserID`（主键）进行匹配。
2. 由于使用了JOIN，我们可以同时从`Orders`表和`Users`表中选择数据。因此，我们能够在同一个查询结果中同时看到用户的名字和他们的订单信息。

## One to Many & Many to Many

- **一对多关系**：通过在“多”的一方表中设置外键指向“一”的一方的主键来实现。
- **多对多关系**：通过创建一个额外的关联表，其中包含指向两个相关表主键的外键来实现。

在**一对多**关系中，一个记录在一个表中对应着多个记录在另一个表中。这种关系通常通过在“多”的一方使用外键（Foreign Key）来实现。如 `Posts` 表和 `Comments` 表, 此时 `Comments` 表中的 `PostID` 就是一个外键, 它指向 `Posts` 表中的 `PostID`. 通过这个外键, 我们可以追踪哪个评论属于哪个帖子, 从而实现一对多关系。

**多对多**关系是指两个表中的记录可以相互关联, 在关系型数据库中, 这种关系通常通过第三个表（称为关联表或连接表）来实现，这个表包含了两个表的外键. 假设有两个表：`Students` 和 `Courses`: 
- **Students表** 存储学生的信息，如：
  - StudentID (主键)
  - StudentName

- **Courses表** 存储课程的信息，如：
  - CourseID (主键)
  - CourseName

- **Enrollments表** 作为关联表，存储学生和课程之间的关系，如：
  - EnrollmentID (主键)
  - StudentID (外键，指向Students表)
  - CourseID (外键，指向Courses表)

在这个例子中，每个学生可以选修多个课程，同时每个课程也可以被多个学生选修。通过Enrollments表，我们可以追踪哪个学生选修了哪个课程，从而实现多对多关系。

## One-to-Many and Many-to-Many in NoSQL MongoDB

### One-to-Many

一对多关系在MongoDB中通常有两种表示方式：

1. **嵌入文档（Embedded Documents）**:
   - 在这种方法中，'多'的部分作为子文档嵌入到'一'的部分中。
   - 例如，如果一个用户有多个地址，那么地址可以直接嵌入到用户文档中。

   **示例**:
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

2. **引用（References）**:
   - 在这种方法中，'多'的一方会包含指向'一'方的引用（通常是ID）。
   - 这类似于关系型数据库中的外键

   **示例**:
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

> Looking at how you model `users` and `orders` illustrates another common relationship: one-to-many. That is, every user has many orders. In an RDBMS, you’d use a **foreign key** in your `orders` table; here, the convention is similar. Learn more: Action in MongoDB: 4.2.2  Users and orders (one-to-many)

### Many-to-Many

多对多关系在MongoDB中通常通过引用来表示, 每个文档存储与之相关联的其他文档的ID, **an array of object IDs**.

了解更多: MongoDB in Action: 4.2.1 Many-to-many relationships

#### 示例
假设有学生和课程，每个学生可以选修多门课程，每门课程也可以由多个学生选修。

1. **学生文档**可能包含它们所选课程的ID列表。

   ```json
   {
     "_id": "studentId1",
     "name": "Alice",
     "courses": ["courseId1", "courseId2"]
   }
   ```

2. **课程文档**可能包含选修该课程的学生ID列表。

   ```json
   {
     "_id": "courseId1",
     "courseName": "Mathematics",
     "students": ["studentId1", "studentId3"]
   }
   ```

嵌入文档可以提高读取性能，因为所有相关数据都在一个文档内；而引用更灵活，可以更容易地维护大量动态关联数据。