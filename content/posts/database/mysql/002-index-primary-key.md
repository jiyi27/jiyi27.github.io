---
title: Index and Primary Key
date: 2023-10-03 12:06:36
categories:
 - database
tags:
 - database
 - mysql
---

## 1. Index concepts

Learn more: https://www.oreilly.com/library/view/high-performance-mysql/0596003064/ch04.html

## 2. When will index be created

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

## 3. Why use index

Indexes are used to find rows with specific column values quickly. Without an index, MySQL must begin with the first row and then read through the entire table to find the relevant rows. The larger the table, the more this costs. If the table has an index for the columns in question, MySQL can quickly determine the position to seek to in the middle of the data file without having to look at all the data. This is much faster than reading every row sequentially.

Most MySQL indexes (`PRIMARY KEY`, `UNIQUE`, `INDEX`, and `FULLTEXT`) are stored in [B-trees](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_b_tree). Exceptions: Indexes on spatial data types use R-trees; `MEMORY` tables also support [hash indexes](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_hash_index); `InnoDB` uses inverted lists for `FULLTEXT` indexes.

The best way to improve the performance of [`SELECT`](https://dev.mysql.com/doc/refman/8.0/en/select.html) operations is to create indexes on one or more of the columns that are tested in the query. **The index entries act like pointers to the table rows**, allowing the query to quickly determine which rows match a condition in the `WHERE` clause, and retrieve the other column values for those rows. All MySQL data types can be indexed.

> Although it can be tempting to create an indexes for every possible column used in a query, unnecessary indexes waste space and waste time for MySQL to determine which indexes to use. Indexes also add to the cost of inserts, updates, and deletes because each index must be updated. You must find the right balance to achieve fast queries using the optimal set of indexes.

Source: [MySQL :: MySQL 8.0 Reference Manual :: 8.3 Optimization and Indexes](https://dev.mysql.com/doc/refman/8.0/en/optimization-indexes.html)

Learn when index will be used in MySQL operations: https://dev.mysql.com/doc/refman/8.0/en/mysql-indexes.html

## 4. Table types

`MyISAM` and `InnoDB` are two different storage engines in MySQL, each with its own characteristics and features. 

### 4.1. InnoDB tables

InnoDB tables provide B-tree indexes. The indexes provide no packing or prefix compression. In addition, InnoDB also requires a primary key for each table. As with BDB, though, if you don’t provide a primary key, MySQL will supply a 64-bit value for you.

The indexes are stored in the InnoDB tablespace, just like the data and data dictionary (table definitions, etc.). Furthermore, `InnoDB` uses clustered indexes. That is, the **primary key’s value directly affects the physical location of the row** as well as its corresponding index node. Because of this, lookups based on primary key in InnoDB are very fast. Once the index node is found, the relevant records are likely to already be cached in InnoDB’s buffer pool. 

> With *clustered indexes*, the primary key and the record itself are “clustered” together, and the records are all stored in primary-key order. InnoDB table uses clustered indexes.

### 4.2. MyISAM tables

MySQL’s default table type provides B-tree indexes, and as of Version 4.1.0, it provides R-tree indexes for spatial data. 

With MyISAM tables, the indexes are kept in a completely separate file that contains a list of primary (and possibly secondary) keys and a value that represents the byte offset for the record. These ensure MySQL can find and then quickly skip to that point within the database to locate the record. MySQL has to store the indexes this way because **the records are stored in essentially random order**. 

> Note that the difference between MyISAM table and InnoDB table is that the records are stored in random order, another tables's record stored according to clustered indexe (primary key). 
>
> With a standard MyISAM table index, there are two lookups, one to the index, and a second to the table itself via the location specified in the index. With clustered indexes in InnoDB table, there’s a single lookup that points directly to the record in question. Therefore, when your data is almost always searched on via its primary key, clustered indexes can make lookups incredibly fast. 

## 5. Clustered vs secondary indexes

Each `InnoDB` table has a special index called the **clustered index** that stores row data. Typically, the clustered index is synonymous with the primary key. To get the best performance from queries, inserts, and other database operations, it is important to understand how `InnoDB` uses the clustered index to optimize the common lookup and DML operations.

- When you define a `PRIMARY KEY` on a table, `InnoDB` uses it as the clustered index. A primary key should be defined for each table. If there is no logical unique and non-null column or set of columns to use a the primary key, add an auto-increment column. Auto-increment column values are unique and are added automatically as new rows are inserted.
- If you do not define a `PRIMARY KEY` for a table, `InnoDB` uses the first `UNIQUE` index with all key columns defined as `NOT NULL` as the clustered index.
- If a table has no `PRIMARY KEY` or suitable `UNIQUE` index, `InnoDB` generates a hidden clustered index named `GEN_CLUST_INDEX` on a synthetic column that contains row ID values. The rows are ordered by the row ID that `InnoDB` assigns. The row ID is a 6-byte field that increases monotonically as new rows are inserted. Thus, the rows ordered by the row ID are physically in order of insertion.

Source: https://dev.mysql.com/doc/refman/8.0/en/innodb-index-types.html

**Secondary indexes** point to the primary key rather than the row. Therefore, if you index on a very large value and have several secondary indexes, you will end up with many duplicate copies of that primary index, first as the clustered index stored alongside the records themselves, but then again for as many times as you have secondary indexes pointing to those clustered indexes. With a small value as the primary key, this may not be so bad, but if you are using something potentially long, such as a URL, this repeated storage of the primary key on disk may cause storage issues.

Some operations render clustered indexes less effective. For instance, consider when a secondary index is in use. Going back to our phone book example, suppose you have `last_name` set as the primary index and `phone_number` set as a secondary index, and you perform the following query:

```
SELECT * FROM phone_book WHERE phone_number = '555-7271'
```

MySQL scans the `phone_number` index to find the entry for `555-7271`, which contains the primary key entry `Zawodny` because `phone_book`’s primary index is the last name. MySQL then skips to the relevant entry in the database itself.

In other words, lookups based on your primary key happen exceedingly fast, and lookups based on secondary indexes happen at essentially the same speed as MyISAM index lookups would.

Another less common but equally problematic condition happens when the data is altered such that the **primary key is changed on a record**. This is the most costly function of clustered indexes. A number of things can happen to make this operation a more severe performance hit:

- Alter the record in question according to the query that was issued.
- Determine the new primary key for that record, based on the altered data record.
- Relocate the stored records so that the record in question is moved to the proper location in the tablespace.
- Update any secondary indexes that point to that primary key.

As you might imagine, if you’re altering the primary key for a number of records, that `UPDATE` command might take quite some time to do its job, especially on larger tables. Choose your primary keys wisely. Use values that are unlikely to change, such as a Social Security account number instead of a last name, serial number instead of a product name, and so on.

Source: https://www.oreilly.com/library/view/high-performance-mysql/0596003064/ch04.html

## 6. Should each table have a primary key

Short answer: yes, each table should have a PRIMARY KEY so that you could distinguish two records. 

In MySQL, the **InnoDB storage engine** always creates a primary key if you didn't specify it explicitly, thus making an extra column you don't have access to.

Learn more: https://stackoverflow.com/a/840182/16317008

## 7. Unique indexes versus primary keys

If you’re coming from other relational databases, you might wonder what the difference between a primary key and a unique index is in MySQL. As usual, it depends. In **MyISAM tables**, there’s almost no difference. The only thing special about a primary key is that it can’t contain NULL values. The primary key is simply a `NOT` `NULL` `UNIQUE` `INDEX` named `PRIMARY`. MyISAM tables don’t require that you declare a primary key.

**InnoDB and BDB tables** require primary keys for every table. There’s no requirement that you specify one, however. If you don’t, the storage engine automatically adds a hidden primary key for you. In both cases, the primary keys are simply incrementing numeric values, similar to an `AUTO-INCREMENT` column. If you decide to add your own primary key at a later time, simply use `ALTER` `TABLE` to add one. Both storage engines will discard their internally generated keys in favor of yours. Heap tables don’t require a primary key but will create one for you. In fact, you can create Heap tables with no indexes at all.

## 8. Index adds places and time overhead

**Time overhead** is easy to understand, indexes add to the cost of inserts, updates, and deletes because each index must be updated. 

**For taking up place,** there is an example: try to think our book or dictionary which have index (table of contents) which helps us to find the content quickly, the table of contents usually has multiple pages, just like this, index in a table also will take up some place which makes a table bigger. 

Given that creating an index requires additional disk space (277,778 blocks extra from the above example, a ~28% increase), and that too many indices can cause issues arising from the file systems size limits, careful thought must be used to select the correct fields to index. Learn more: https://stackoverflow.com/a/1130/16317008

Since indices are only used to speed up the searching for a matching field within the records, it stands to reason that **indexing fields used only for output** would be simply a waste of disk space and processing time when doing an insert or delete operation, and thus should be avoided.

What does "*indexing fields used only for output*" mean?

For example, imagine a table of products. Some fields like "name" or "price" are used for searching and filtering, while other fields like "description" or "image_url" are used only to provide additional information in the output. Creating an index on fields used only for output is not helpful and can waste resources.

> Indexes trade space for performance. Because MySQL needs to maintain a separate list of indexes’ values and keep them updated as your data changes, you really don’t want to index every column in a table. Indexes are a trade-off between space and time. You’re sacrificing some extra disk space and a bit of CPU overhead on each `INSERT`, `UPDATE`, and `DELETE` query to make most (if not all) your queries much faster. Source: https://www.oreilly.com/library/view/high-performance-mysql/0596003064/ch04.html





