---
title: Practice of MySQL
date: 2024-01-10 23:06:36
categories:
 - database
tags:
 - database
 - mysql
---

## Store string

The most commonly used string data types in the context of databases are CHAR and VARCHAR. TEXT and LONGTEXT are also commonly used string data types. 

**`char(10)` vs `varchar(10) `**

When you define a column as CHAR(10), it will always occupy 10 characters of storage, regardless of the actual data length. If you store a string shorter than 10 characters, it will be padded with spaces to fill up the remaining space.

When you define a column as VARCHAR(10), you store a string shorter than 10 characters, it will use only the necessary amount of storage, without any padding. 

In general, the performance difference between CHAR and VARCHAR is usually negligible unless you're dealing with extremely large datasets or have specific performance requirements. 

> When the length of strings to be written to the field is explicitly specified choose CHAR as the data type. When the number of strings that users will input is not fixed, but there is a limit based on the number of characters, use VARCHAR as the data type. For example, for a username that can vary in length, VARCHAR is used as the data type.

## 存储时间

### 不要用字符串存储日期

- 字符串占用的空间更大
- 字符串存储的日期比较效率比较低（逐个字符进行比对），无法用日期相关的 API 进行计算和比较

### Datetime and Timestamp

`Datetime` 和 `Timestamp` 是 MySQL 提供的两种比较相似的保存时间的数据类型, 通常我们都会首选 `Timestamp`. 因为DateTime类型没有时区信息的, 而Timestamp可以存储time zone信息, 并且做转换. 

Timestamp 只需要使用 4 个字节的存储空间，但是 DateTime 需要耗费 8 个字节的存储空间。但是，这样同样造成了一个问题，Timestamp 表示的时间范围更小。

- DateTime ：1000-01-01 00:00:00 ~ 9999-12-31 23:59:59
- Timestamp： 1970-01-01 00:00:01 ~ 2037-12-31 23:59:59

```sql
CREATE TABLE `time_zone_test` (
  `id` int NOT NULL AUTO_INCREMENT,
  `date_time` datetime DEFAULT NULL,
  `time_stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);


INSERT INTO time_zone_test(date_time) VALUES(NOW());

select * from time_zone_test;

+----+---------------------+---------------------+
| id | date_time           | time_stamp          |
+----+---------------------+---------------------+
|  1 | 2023-04-01 10:45:04 | 2023-04-01 10:45:04 |
+----+---------------------+---------------------+
```

这也说明了一个问题, 就是我们插入数据的时候, 没必要在逻辑上获取时间再加入, 我们只需要在创建表的时候设置一个time column并为其设置default值, 即可, 每次只用在Java代码中插入其他column, 然后时间会被mysql自动加上去. 

对于上面的数据, 我们修改会话的时区, 可以看到时间就变了:

```sql
set time_zone='+8:00';

+----+---------------------+---------------------+
| id | date_time           | time_stamp          |
+----+---------------------+---------------------+
|  1 | 2023-04-01 10:45:04 | 2023-04-01 21:45:04 |
+----+---------------------+---------------------+
```

## 查看 MySQL Warning

有时候我们创建表的时候或者执行SQL语句, 虽然执行成功了但是会显示有警告,但是还不告诉你警告内容, 这时候你需要立刻执行`SHOW WARNINGS;`语句, 否则你执行了其他语句再执行这个show, 那现实的就不是上一个语句的warnings了, 如下图:

![a](/001-mysql-basics/a.png)

## Default vs NOT NULL 

有没有想过, 建表的时候default 和 not null一起使用, 是不是有点redundant? 因为比如你不插入值的时候mysql会帮你插入默认值, 

其实这么想你就错了, 你想的是我不插入, mysql就会帮我插入个默认值, 所以似乎not null没起作用, 但是你有没有想过如果你只设置了default而没有设置not null限制, 那这时候我插入null个呢, 显然可以插入成功, 但有时候为null, 比如一个日期, 当我们在写Java或者其他代码的时候查询数据然后把date转为string, 如果数据为null可能就会发生异常~

## Naming conventions

**General**

1. **Using lowercase** will help speed typing, avoid mistakes as MYSQL is case sensitive. 

2. **Space replaced with Underscore** — Using space between words is not advised.

3. Numbers are not for names — While naming, it is essential that it contains only Alpha English alphabets.

**Table**

1. Table names are lower case, uses underscores to separate words, and are **singular** (e.g. `foo`, `foo_bar`, etc.

**Columns**

1. Always use the singular name.
2. Always use lowercase except where it may make sense not to such as proper nouns.
3. Where possible **avoid simply using `id`** as the primary identifier for the table.
4. Do not add a column with the same name as its table and vice versa.
5. I generally (not always) have a auto increment PK. I use the following convention: `tablename_id` (e.g. `foo_id`, `foo_bar_id`, etc.).

参考:

- [MYSQL Naming Conventions. What is MYSQL? | by Centizen Nationwide | Medium](https://medium.com/@centizennationwide/mysql-naming-conventions-e3a6f6219efe)
- [Is there a naming convention for MySQL? - Stack Overflow](https://stackoverflow.com/questions/7899200/is-there-a-naming-convention-for-mysql)
- [SQL style guide by Simon Holywell](https://www.sqlstyle.guide/#columns)
- [MySQL数据库中常见的几种表字段数据类型 - 掘金](https://juejin.cn/post/7165675545965887525)
- [老生常谈！数据库如何存储时间？你真的知道吗？ - 掘金](https://juejin.cn/post/6844904047489581063)