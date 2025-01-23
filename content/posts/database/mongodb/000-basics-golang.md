---
title: MongoDB Docs - Golang Basics
date: 2024-04-23 08:38:35
categories:
 - database
tags:
 - database
 - mongodb
---

## Bson & Marshalling & Unmarshalling

The process of converting a Go type to BSON is called **marshalling**, while the reverse process is called **unmarshalling**.

**Why need convert Go type to BSON?** MongoDB stores documents in [BSON](https://www.mongodb.com/docs/manual/reference/bson-types/), when we store data (our struct) into MongoDB,  MongoDB Go-driver convert our struct value into bson automatically.

The Go driver provides four main types for working with BSON data:

- `D`: An ordered representation of a BSON document (slice)
- `M`: An unordered representation of a BSON document (map)
- ...

D is an ordered representation of a BSON document. This type should be used when the order of the elements matters, such as MongoDB command documents. If the order of the elements does not matter, an M should be used instead. This usually used as filter in a query operation. 

Like what we said before, our Go struct value needs to be converted to bson, there are **Struct Tags**, which is used to modify the default marshalling and unmarshalling behavior of a struct field. 

After we read data from MongoDB, we need to convert bson to Go struct, this is called **unmarshalling**. You can unmarshal BSON documents by using the `Decode()` method on the result of the `FindOne` method or any `*mongo.Cursor` instance. 

> Note that when using `FindOne()` it returns a bson document, so you need decode it back to a Go struct value. 
>
> Method `Find()` returns a `*mongo.Cursor`, we usually iterate through it so get more than one (probably) result. And `*mongo.Cursor` needs to be closed usually to free resources. 

Learn more: 

[mongodb - bson.D vs bson.M for find queries - Stack Overflow](https://stackoverflow.com/questions/64281675/bson-d-vs-bson-m-for-find-queries)

[Work with BSON - Go Driver v1.15](https://www.mongodb.com/docs/drivers/go/current/fundamentals/bson/)

## Read Operation - Cursor

To match a subset of documents, specify a **query filter**. In a query filter, you can match fields with [literal values](https://www.mongodb.com/docs/drivers/go/current/fundamentals/crud/read-operations/query-document/#std-label-golang-literal-values) or with [query operators](https://www.mongodb.com/docs/drivers/go/current/fundamentals/crud/read-operations/query-document/#std-label-golang-query-operators). When you don't know which method you should use, you can go to the [mongo driver go API](https://pkg.go.dev/go.mongodb.org/mongo-driver/mongo@v1.15.0#Collection) to check how to use them. 

### `*mongo.Cursor`

A cursor is used to iterate over database results from read operations. **A cursor is not goroutine safe**. Do not use the same cursor in multiple goroutines at the same time. Method `Find()` returns a cursor. 

You can retrieve results individually or get all results at a time, it depends on if the number of the result is very large. 

```go
cursor, _ := coll.Find(context.TODO(), bson.D{})

// retrieve results individually
for cursor.Next(context.TODO()) {
	var result MyStruct
	if err := cursor.Decode(&result); err != nil {
		log.Fatal(err)
	}
	fmt.Printf("%+v\n", result)
}

// get all results at a time
var results []MyStruct
if err = cursor.All(context.TODO(), &results); err != nil {
	panic(err)
}
```

If the number and size of documents returned by your query exceeds available application memory, your program will crash. If you except a large result set, you should [consume your cursor iteratively.](https://www.mongodb.com/docs/drivers/go/current/fundamentals/crud/read-operations/cursor/#std-label-golang-individual-documents)

> When your application no longer requires a cursor, close the cursor with the `Close()` method. This method frees the resources your cursor consumes in both the client application and the MongoDB server.  Close the cursor when you [retrieve documents individually](https://www.mongodb.com/docs/drivers/go/current/fundamentals/crud/read-operations/cursor/#std-label-golang-individual-documents) because those methods make a cursor [tailable.](https://www.mongodb.com/docs/manual/core/tailable-cursors/)

## Others

- If the necessary database and collection don't exist when you perform a write operation, the server implicitly creates them. So you don't need to create database explicitly when use MongoDB. 

- collection: you can use it concurrentlly

  ```go
  type Repository struct {
  	db *mongo.Client
  	//Collection is safe for concurrent use by multiple goroutines.
  	PokemonColl *mongo.Collection
  }
  
  func NewRepository(db *mongo.Client) *Repository {
  	return &Repository{
  		db:          db,
  		PokemonColl: db.Database("pokemon").Collection("pokemons"),
  	}
  }
  ```

- modify behvavior when query: opts third parameter

  ```go
  // Note that there is three parameters, last is optional. 
  func (coll *Collection) Find(ctx context.Context, filter interface{},
  	opts ...*options.FindOptions) (cur *Cursor, err error)
  ```
  
- `findByIdAndUpdate()`: `FindOneAndUpdate` returns the original document **before updating**.

  ```go
  opts := options.FindOneAndUpdate().SetReturnDocument(options.After)
  result := coll.FindOneAndUpdate(context.TODO(), filter, update, opts)
  ...
  ```

You may wonder how do I know `opts := options.FindOneAndUpdate().SetReturnDocument(options.After)` this to create an operation? And how can I know the behavior of a method? The answer is the [mongo-api](https://pkg.go.dev/go.mongodb.org/mongo-driver@v1.15.0/mongo#Collection.FindOneAndUpdate), you can see there is the behavor and example and all the thing you need to know before you use it. 

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/04/d835acb545649837f06bbc2ce323cb3f.jpg)

And you can check the `FindOneAndUpdateOptions` just click, to check what is it:

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/04/e8455c6379df455fee9182e24b45305e.jpg)

You can see this option is in the `options` package, and you can create it with `FindOneAndUpdate()`, so it's not difficult to write the codes like this:

```go
opts := options.FindOneAndUpdate().SetReturnDocument(options.After)
result := coll.FindOneAndUpdate(context.TODO(), filter, update, opts)
...
```

## References

[mongo package - go.mongodb.org/mongo-driver/mongo - Go Packages](https://pkg.go.dev/go.mongodb.org/mongo-driver/mongo@v1.15.0#pkg-overview)

[CRUD Operations - Go Driver v1.15](https://www.mongodb.com/docs/drivers/go/current/fundamentals/crud/)
