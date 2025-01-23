---
title: MongoDB Aggregate
date: 2024-01-04 17:51:35
categories:
 - database
tags:
 - database
 - mongodb
---

## Aggregate framework

The aggregation framework is MongoDB’s advanced query language, and it allows you to transform and combine data from multiple documents to generate new information not available in any single document.

## Common aggregation stages

Below is a list of common MongoDB aggregation pipeline stages and their typical order:

1. **`$match` Stage**
   - Usually at the beginning of the pipeline.
   - Filters the documents as early as possible, which reduces the amount of data processed by subsequent stages. 

2. **`$sort` Stage**
   - After `$match` and before `$limit` if sorting the entire dataset is necessary.
   - Be aware that `$sort` can be memory-intensive. If used before `$limit`, it sorts the entire dataset filtered by `$match`.

3. **`$limit` Stage**
   - Use `$limit` as early as possible, but after `$match` and `$sort` if sorting is needed.

4. **`$project` Stage**
   - Reduces the number of fields in the documents, decreasing the amount of data processed in later stages.
   - Keep in mind that some fields might be needed in subsequent stages. 
   - You can use `$project` more than once in a pipeline, you have to speficify all the fields you want to keep in each `$project` stage, even you have already specified them in the previous `$project` stage.
   - If you need to add new fields, consider using `$addFields` instead wich has more flexibility. 

5. **`$group` Stage**
   - After `$match`, `$sort`, `$limit`, and `$project`.
   - Groups documents by specified fields after they have been filtered and shaped.

6. **`$unwind` Stage**
   - Used to expand array fields into separate documents. 

```js
db.inventory.insertOne({ "_id" : 1, "item" : "ABC1", sizes: [ "S", "M", "L"] })
db.inventory.aggregate( [ { $unwind : "$sizes" } ] )

// The operation returns the following results:
{ "_id" : 1, "item" : "ABC1", "sizes" : "S" }
{ "_id" : 1, "item" : "ABC1", "sizes" : "M" }
{ "_id" : 1, "item" : "ABC1", "sizes" : "L" }
```

7. **`$lookup` Stage**
   - **Order**: After filtering and limiting stages like `$match` and `$limit`.
   - **Reason**: Performs a join to another collection, which can be data-intensive.
   - **Considerations**: Can significantly increase data volume, so use after reducing the dataset size.

8. **`$addFields` / `$set` Stage**
   - **Order**: After `$project`, `$unwind`, or `$group`.
   - **Reason**: Adds new fields or modifies existing ones, often based on existing fields.
   - **Considerations**: Useful for adding calculated fields. Similar to `$project`, but adds fields without removing existing ones.


The code below will result in an error "$size cannot be used for not array type", because during the project stage filters out the `likes` and `comments` fields, which results the `likes` and `comments` fields to be `null` instead of an array. 

```js
{
    $project: {
        text: 1,
        images: 1,
        comments: 1,
        createdAt: 1,
    }
},
{
    $addFields: {
        engagement: {
            numLikes: { $size: "$likes" },
            numComments: { $size: "$comments" },
            isLiked: { $in: [new mongoose.Types.ObjectId(userId), "$likes"] },
        }
    }
}
```

So in this case, you should put the `$addFields` stage before the `$project` stage.

