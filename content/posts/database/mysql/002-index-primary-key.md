---
title: 索引和主键 - MySQL
date: 2023-02-02 18:22:30
categories:
 - 数据库
tags:
 - 数据库
 - mysql
---

## 1. When will index be created

**Primary Key:** By default, when you define a primary key constraint on a column or set of columns using the PRIMARY KEY keyword, MySQL automatically creates an index on that column(s). 

```sql
# index will created on user_id column
create table `user` (
  `user_id` smallint not null auto_increment,
  `username` varchar(20) not null,
  `password` varchar(20) not null,
  primary key (`user_id`)
);
```

**Unique Constraints:** When you define a unique constraint on a column or set of columns using the UNIQUE keyword, MySQL automatically creates an index to enforce uniqueness. 

```sql
# index will be created on username column
create table `user` (
  `user_id` smallint not null,
  `username` varchar(20) not null,
  `password` varchar(20) not null,
   unique (`username`)
);
# there will be two indexes
# index will be created on both user_id and username column
create table `user` (
  `user_id` smallint not null auto_increment,
  `username` varchar(20) not null,
  `password` varchar(20) not null,
  primary key (`user_id`),
  unique (`username`)
);
```

> When you define a `PRIMARY KEY` on a table, `InnoDB` uses it as the **clustered index**. 
>
> A primary key should be defined for each table. If you do not define a `PRIMARY KEY` for a table, `InnoDB` uses the first `UNIQUE` index with all key columns defined as `NOT NULL` as the **clustered index.**
>
> If a table has no `PRIMARY KEY` or suitable `UNIQUE` index, `InnoDB` generates a hidden clustered index named `GEN_CLUST_INDEX` on a synthetic column that contains row ID values.

## 2. Indexe Types

| **索引类型**             | **存储结构**                                         |
| ------------------------ | ---------------------------------------------------- |
| **主键索引（聚簇索引）** | 数据本身存储在 B+ 树的叶子节点，数据按照主键顺序存储 |
| **二级索引（普通索引）** | 额外的 B+ 树，只存储索引列和主键 ID，查询时需要回表  |

数据实际按照主键顺序物理存储在硬盘上, **主键索引**的叶子节点存储的就是实际的数据行（完整数据）

示例:

```mysql
CREATE TABLE users (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    age INT
);
```

存储结构:

```mysql
B+ 树（主键索引）
---------------------------------
| ID=1  | Alice   | 25  |
| ID=5  | Bob     | 30  |
| ID=10 | Charlie | 28  |
---------------------------------
```

数据行是按照 `id` 这个主键顺序排列的, 主键索引的叶子节点直接存储了数据。

上面我们知道 InnoDB 的数据是按照主键索引顺序存储在硬盘上的, 那建立其它索引是什么意思, 索引不会改变数据的存储顺序吗? 还是数据库会单独不同索引单独建立一个数据表按照索引排序? 

**二级索引**是为了加快查询速度，但不会改变数据的存储顺序！ 二级索引（普通索引）是 独立于主键索引 的，它只存储 索引字段值 + 主键值。当你查询时，数据库会先通过 二级索引找到主键值，然后再去 主键索引中找到数据。

示例 如果我们对 `name` 建立索引：

```mysql
CREATE INDEX idx_name ON users(name);
```

数据库会额外建立一个 B+ 树 索引：

```mysql
B+ 树（name 索引）
---------------------------------
| Alice   | ID=1  |
| Bob     | ID=5  |
| Charlie | ID=10 |
---------------------------------
```

这个 B+ 树按照 `name` 排序，但它的叶子节点不存储数据，只存储 主键 ID！查询 `name='Bob'` 时，MySQL 先在 name 索引里找到 ID=5，然后再到主键索引里查找完整数据。

> 现在回答上面的问题: 建立索引会不会改变数据的存储顺序？数据库会不会单独为索引建立一个新表？

答案是： ✅ 不会改变数据存储顺序！ ✅ 但数据库会额外维护索引结构，每个索引是独立的 B+ 树！
