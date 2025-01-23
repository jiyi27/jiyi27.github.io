---
title: Tricks and Common Mistakes - Go
date: 2023-08-27 17:12:55
categories:
 - golang
 - practice
tags:
 - golang
---

## Tricks

### remove an element from a slice

```go
// remove the element at index i from a

a = append(a[:i], a[i+1:]...)
```

### handle `close()`

```go
// credit to: https://gist.github.com/benbjohnson/9eebd201ec096ab6430e1f33411e6427
func doSomething() error {
	f, err := os.Create("foo")
	if err != nil {
		return err
	}
  // ensure that it's definitely closed by the end
	defer f.Close()
	if _, err := f.Write([]byte("bar"); err != nil {
		return err
	}
  return f.Close()
}
```

Why we bother to care about getting error from `f.Close()`? We have got error from  `f.Write()`. Well, there are a lot to say, learn more: [Don't Defer Close() on Writable Files - Go Notes](https://davidzhu.xyz/post/golang/advance/010-defer-close/)

## Common mistakes

#### 1. Encoding non-exported fields struct value with gobs

gobs can encode the exported fields of a struct value, if a sturct without exported field, when you try encode its value, you will get a `nil`. 

> Functions and channels will not be sent in a gob. Attempting to encode such a value at the top level will fail. A struct field of chan or func type is treated exactly like an unexported field and is ignored. 

#### 2. Use `var` to declare channel 

Variables declared without an explicit initial value are given their zero value. Zero value for a channel is `nil`, read and write a `nil` channel will block forever. The code below is a common mistake:

```go
go func() {
		var expiredSessions chan []*Session // expiredSessions == nil
		var errSession := chan error // errSession == nil
		store.GetExpiredSessions(expiredSessions, errSession)
		select {
		case sessions, _ := <-expiredSessions:
      ...
		}
	}()
```

**Don't use `var` to declare** **channel**, **map** **or slice values**, use `make()`, keep this convension you will won't make mistakes. 

Learn more: https://davidzhu.xyz/post/golang/basics/003-collections/#5-var-vs-make

#### 3. Using goroutines on a loop iterator variable

In Go, the loop iterator variable is a single variable that takes different values in each loop iteration. 

```go
func main() {
	var out []*int
	for i := 0; i < 3; i++ {
		out = append(out, &i)
	}
	fmt.Println("Values:", *out[0], *out[1], *out[2])
	fmt.Println("Addresses:", out[0], out[1], out[2])
}

Values: 3 3 3
Addresses: 0x40e020 0x40e020 0x40e020
```

For example, you might write something like this, using a closure:

```go
// this is bad
for _, val := range values {
	go func() {
		fmt.Println(val)
	}()
}
```

Because the closures are all only bound to that one variable, **there is a very good chance that** when you run this code you will see the last element printed for every iteration instead of each value in sequence, because the goroutines will probably not begin executing until after the loop.

The proper way to write that closure loop is:

```go
for _, val := range values {
	go func(val interface{}) {
		fmt.Println(val)
	}(val)
}
```

> Avoid mixing anonymous functions and goroutines. [Concurrency Made Easy](https://youtu.be/DqHb5KBe7qI?si=IW3zRKFc1Wtk4ZJh) 

Learn more: 

- https://go.dev/doc/effective_go#channels
- https://github.com/golang/go/wiki/CommonMistakes
