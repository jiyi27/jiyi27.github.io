---
title: MongoDB in Action Reading Note
date: 2024-04-24 18:29:30
categories:
 - database
tags:
 - database
 - mongodb
---

## Basic Theory

MongoDB stores its information in **documents** rather than **rows**. Where relational databases have **tables**, MongoDB has ***collections***. 

Every MongoDB document requires an `_id`, and if one isn’t present when the document is created, a special MongoDB ObjectID will be generated and added to the document at that time. You can set your own `_id` by setting it in the document you insert, the ObjectID is just MongoDB’s default.

Indexes don’t come for free; they take up some space and can make your inserts slightly more expensive, but they are an essential tool for query optimization.

MongoDB store documents in a collection in no particular order. To get documents in a particular order, you must can use the `sort()` method or the `$sort` aggregation pipeline stage. Learn more: [natural order — MongoDB Manual](https://www.mongodb.com/docs/manual/reference/glossary/#std-term-natural-order)

关于 foreign key 的概念常出现在 one to many 关系中, 比如评论表和用户, 一个用户可以有多个评论, 但一个评论只能有一个用户. 在传统数据库中, 评论表中会有一个 `user_id` 字段, 我们叫它外键, 每次查询时可以通过 join 操作将用户信息和评论信息关联起来 (即获取写了这个评论的用户具体信息和评论的具体内容). 

MongoDB 没有传统数据库中 join 操作和 foreign key, 但可以通过 [embedded documents](https://www.mongodb.com/docs/manual/data-modeling/concepts/embedding-vs-references/#embedded-data-models) 或者 [reference](https://www.mongodb.com/docs/manual/data-modeling/concepts/embedding-vs-references/#std-label-data-modeling-referencing) 来表示一对多关系, 也可使用聚合来实现类似 Join 的功能. 具体官方文档有解释: [Model One-to-Many Relationships with Embedded Documents](https://www.mongodb.com/docs/manual/tutorial/model-embedded-one-to-many-relationships-between-documents/), [Model One-to-Many Relationships with Document References](https://www.mongodb.com/docs/manual/tutorial/model-referenced-one-to-many-relationships-between-documents/)

关于一对多, 多对多关系参考: [SQL Server Tutorial - One-to-many and many-to-many table relationships](https://www.youtube.com/watch?v=4q-keGvUnag)

关于外键请参考: [Learning MySQL - FOREIGN KEY CONSTRAINTS](https://www.youtube.com/watch?v=UQK9_gKQHZg) 

关于 join 操作请参考: [SQL Joins Explained](https://www.youtube.com/watch?v=9yeOJ0ZMUYw)

## Examples in the Book

### Reviews - One to Many Relationship

Each *product* can have many *reviews*, and you create this relationship by storing a `product_id` in each *review*, as shown in the sample document:

```json
{   
    _id: ObjectId("4c4b1476238d3b4dd5000041"),   
    product_id: ObjectId("4c4b1476238d3b4dd5003981"),   
    date: new Date(2010, 5, 7),   
    title: "Amazing",   
    text: "Has a squeaky wheel, but still a darn good wheelbarrow.",   
    rating: 4,   
    user_id: ObjectId("4c4b1476238d3b4dd5000042"),   
    username: "dgreenthumb",   
    helpful_votes: 3,   
    voter_ids: [
            ObjectId("4c4b1476238d3b4dd5000033"),     
            ObjectId("7a4f0376238d3b4dd5000003"),     
            ObjectId("92c21476238d3b4dd5000032")   
        ]
}
```

But it may come as a surprise that you store the username as well. If this were an RDBMS, you’d be able to pull in the username with a join on the users table. Because you don’t have the join option with MongoDB, you can proceed in one of two ways: either query against the user collection for each review or accept some **denormalization**. Issuing a query for every review might be unnecessarily costly when username is extremely unlikely to change, so here we’ve chosen to optimize for query speed rather than **normalization**. 

Also noteworthy is the decision to store votes in the review document itself. It’s common for users to be able to vote on reviews. Here, you store the object ID of each voting user in an array of voter IDs. This allows you to prevent users from voting on a review more than once, and it also gives you the ability to query for all the reviews a user has voted on. You **cache** the total number of helpful votes, which among other things allows you to sort reviews based on helpfulness. Caching is useful, a query to sort reviews by helpful votes, for example, is much easier if the size of the voting array is cached in the helpful_votes field.

> 用户名信息原本可以通过用户ID (`user_id`) 在用户集合(users collection)中查到, 但这样每次刷新评论都要重新查一次用户名. 
>
> 这段提到了一个关键概念：缓存（Caching）, 这里的 “缓存” 是指在文档中直接存储一个额外的数据项（在这个例子中是“有帮助的投票数”），而不是每次查询时计算这个数值。

### Student & Courses - Many to Many Relationship

**student:**

```json
{
  _id: <number>,
 name: : <string>,
 otherDetails: { ... },
 courses: [
      { courseId:  <number>, courseName: <string> },
      { courseId:  <number>, courseName: <string> },
      ...
  ]
}
```

**course:**

```json
{
  _id: <number>,
  name: <string>,
  description: <string>,
  otherDetails: { ... }
}
```

Now, your application has some queries. To start with some queries I can think about is, get all students in a particular course and get all courses for a particular student. These are simple queries.

To get all courses for a specific student, the query would be:

```js
db.students.find( { name: "John Doe" }, { courses: 1, name: 1 } )
```

To get all students enrolled for a specific course, your query can be like this:

```js
db.students.find( { "courses.courseName": "Database Design" } )
```

This example is from [Many to many relationship and linked table/collection - Working with Data - MongoDB Developer Community Forums](https://www.mongodb.com/community/forums/t/many-to-many-relationship-and-linked-table-collection/130305/2)

## Query Operators

前面介绍了find函数的基本用法和projection参数, 在实际查询中, 我们还需要使用一些操作符来构建更复杂的查询条件, 接下来一一介绍. 

Learn more: [Query and Projection Operators — MongoDB Manual](https://www.mongodb.com/docs/manual/reference/operator/query/)

### Set operators

`$in`, `$nin`, `$all`

```js
// $in: Matches any of the values specified in an array.
db.products.find({
    'main_cat_id': {
        '$in': [
            ObjectId("6a5b1476238d3b4dd5000048"),         
            ObjectId("6a5b1476238d3b4dd5000051"),         
            ObjectId("6a5b1476238d3b4dd5000057")       
        ]
    }
}, null, null)

// Query nested documents
db.products.find({'details.color': {$in: ['blue', 'Green']}})
```

### Boolean operators

`$or`, `$and`, `$not`, `$nor`, `$exists`

```js
// $or: matches if any of the supplied set of query terms is true
// Finding all products that are either blue or made by Acme requires:
db.products.find({
    '$or': [
        {'details.color': 'blue'},
        {'manufacturer': 'Acme'},
    ]
})
```

## Update, atomic operations, and delete - Action in MongoDB chapter 7

### Update

You can either replace the document altogether, or you can use update operators to modify specific fields within the document. 

**modify by replacement:**

```js
user_id = ObjectId("4c4b1476238d3b4dd5003981") 
doc = db.users.findOne({_id: user_id}) 
doc['email'] = 'mongodb-user@mongodb.com' 
print('updating ' + user_id)
db.users.update({_id: user_id}, doc)
```

The final line says, “Find the document in the users collection with the given _id, and replace that document with the one we’ve provided.”

**modify by operator:**

```js
user_id = ObjectId("4c4b1476238d3b4dd5000001") 
db.users.update({_id: user_id},  {$set: {email: 'mongodb-user2@mongodb.com'}})
```

> Performance-conscious users may balk at the idea of re-aggregating all product reviews for each update. **Much of this depends on the ratio of reads to writes**; it’s likely that more users will see product reviews than write their own, so it makes sense to re-aggregate on a write.

### Standard update operators

Certainly! Let's go through each MongoDB update operator with an explanation followed by a real-world example:

1. **`$set`**: Used to set the value of a field in a document. If the field does not exist, `$set` will add a new field with the specified value.
   
   Example: Updating a user's email address.
   ```javascript
   db.users.update({ username: 'johndoe' }, { $set: { email: 'johndoe@example.com' } });
   ```

2. **`$unset`**: Removes the specified field from a document.
   
   Example: Removing a phone number field from a user's profile.
   ```javascript
   db.users.update({ username: 'johndoe' }, { $unset: { phoneNumber: "" } });
   ```

3. **`$inc`**: Increments the value of a field by the specified amount. If the field does not exist, it is set to the increment amount.
   
   Example: Incrementing a user's reward points.
   ```javascript
   db.users.update({ username: 'johndoe' }, { $inc: { rewardPoints: 100 } });
   ```

4. **`$push`**: Adds an element to an array. If the field is not an array, this operator will create an array with one element.
   
   Example: Adding a new product to a user's wishlist.
   ```javascript
   db.users.update({ username: 'johndoe' }, { $push: { wishlist: 'productId1234' } });
   ```

5. **`$pull`**: Removes all instances of a value from an existing array.
   
   Example: Removing an item from a user's shopping cart.
   ```javascript
   db.users.update({ username: 'johndoe' }, { $pull: { shoppingCart: 'itemId5678' } });
   ```

6. **`$addToSet`**: Adds a value to an array unless the value is already present, in which case `$addToSet` does nothing to ensure uniqueness.
   
   Example: Adding a tag to a blog post without creating duplicates.
   ```javascript
   db.blogPosts.update({ title: 'MongoDB Tips' }, { $addToSet: { tags: 'NoSQL' } });
   ```

7. **`$rename`**: Renames a field.
   
   Example: Changing a field name in a contact document.
   ```javascript
   db.contacts.update({ name: 'Jane Doe' }, { $rename: { 'cellphone': 'mobileNumber' } });
   ```

8. **`$mul`**: Multiplies the value of the field by the specified amount. If the field does not exist, the operation sets the field to zero.
   
   Example: Updating the price of a product in inventory.
   ```javascript
   db.products.update({ productId: 'A123' }, { $mul: { price: 2 } });
   ```

## Slow queries - Chapter 8 值得反复阅读

Finding slow queries is easy with MongoDB’s profiler. Discovering why these queries are slow is trickier and may require some detective work. As mentioned, the causes of slow queries are manifold. If you’re lucky, resolving a slow query may be as easy as adding an index. In more difficult cases, you might have to rearrange indexes, restructure the data model, or upgrade hardware.

MongoDB’s explain command provides detailed information about a given query’s path. 

```json
db.values.find({}).sort({close: -1}).limit(1).explain() 
{
    "cursor" : "BasicCursor",              
    "isMultiKey" : false,             
    “  "n" : 1,                    #A   Number returned
    "nscannedObjects" : 4308303,           
    "nscanned" : 4308303,          #B   Number scanned
    "nscannedObjectsAllPlans" : 4308303,    
    "scanAndOrder" : true,                
    "millis" : 10927,              #C   Time in milliseconds, 11 seconds this query took
    ...                 
} 
```

The `cursor` field tells you that you’ve been using a `BasicCursor`, which only confirms that you’re scanning the collection itself and not an index. If you had used an index, the value would’ve been `BTreeCursor`.

A second datum here further explains the slowness of the query: the `scanAndOrder` field. This indicator appears when the query optimizer can’t use an index to return a sorted result set. Therefore, in this case, not only does the query engine have to scan the collection, it also has to sort the result set manually.

1. Avoid `scanAndOrder`. If the query includes a sort, attempt to sort using an index.
2. Satisfy all fields with useful indexing constraints—attempt to use indexes for the fields in the query selector.
3. If the query implies a range or includes a sort, choose an index where that last key used can help satisfy the range or sort.

当提到“last key used”这个术语，特别是在上下文中关于选择索引以优化范围查询或排序操作的讨论中，它指的是在复合索引中的最后一个字段。在复合索引中，字段的顺序是至关重要的，因为它决定了数据库如何组织和访问索引数据。让我们通过一个例子来解释这个概念。

假设你有一个MongoDB集合，其中包含以下字段：`a`, `b`, 和 `c`。现在，假设你创建了一个复合索引 `{ a: 1, b: 1, c: 1 }`。在这个索引中：

- `a` 是第一个键，
- `b` 是第二个键，
- `c` 是“last key”或最后一个键。

在处理查询时，如果查询涉及到这三个字段中的任意一个的范围条件或排序要求，索引的效率将取决于这些条件是如何与索引中的键匹配的。在理想情况下，你希望查询中的范围或排序操作直接对应于复合索引中的最后一个键，因为这样可以最大化索引的效用。

例如，考虑以下查询：

```javascript
db.collection.find({ a: 10, b: { $gt: 5 } }).sort({ c: 1 })
```

在这个查询中：

- `a` 是一个精确匹配条件，
- `b` 是一个范围查询条件，
- `c` 是一个排序条件。

索引 `{ a: 1, b: 1, c: 1 }` 在这种情况下是高效的，因为：

- 它首先使用 `a` 来快速定位数据（第一个键），
- 接着，利用 `b` 来进一步过滤范围内的记录（第二个键），
- 最后，使用 `c` 进行排序（“last key”或最后一个键）。

在这里，“last key” (`c`) 使得查询可以在使用索引的同时完成排序，从而避免了额外的排序步骤，提高了查询效率。所以，“last key”在复合索引中指的是最后一个被用来支持查询中的范围或排序条件的字段。
