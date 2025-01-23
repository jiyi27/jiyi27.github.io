---
title: slice & array - Go
date: 2023-12-06 23:40:59
categories:
 - golang
 - basics
tags:
 - golang
---

## 1. Array

An array's length is part of its type, so arrays cannot be resized. Its length is part of its type (`[4]int` and `[5]int` are distinct, incompatible types). 

Go’s arrays are values. An array variable denotes the entire array; it is not a pointer to the first array element (as would be the case in C). This means that **when you assign or pass around an array value you will make a copy of its contents**. (To avoid the copy you could pass a *pointer* to the array, but then that’s a pointer to an array, not an array.) 

## 2. Slice

### 2.1. Slice is just a Struct

A slice is just a struct. It consists of a **pointer** to the array, the **length** of the underlying array, its **capacity** (the maximum length of the underlying array).

```go
type slice struct {
    data uintptr
    len int
    cap int
}
```

> So the overhead of assigning or passing a slice value, is just 3 words (12 bytes on 32bit, 24 bytes on 64bit), which is very cheap. This is different from assigning or passing an array value, which will copy the entire array.


### 2.2. Slicing

When you create a new slice from an existing array or slice (e.g., `newSlice := oldSlice[start:end]`), the new slice does not copy the elements. Instead, **it refers to the same underlying array as the original slice**. Slice is just a struct, as we have talked above. 

```go
originalSlice := []int{1, 2, 3, 4, 5}
newSlice := originalSlice[:3]
originalSlice[0] = 99 // This also changes newSlice[0]
newSlice[1] = 101  // This also changes originalSlice[1]
fmt.Println("Original slice:", originalSlice)
fmt.Println("New slice:", newSlice)

// ouput
Original slice: [99 101 3 4 5]
New slice: [99 101 3]
```

> Note: if you append to the slice and the capacity of the underlying array is exceeded, Go will allocate a new array and copy the elements over, **causing the slices to diverge**.

> There is a trick, we usually use `d = d[:0]` to generate a new slice `d` whose length is 0 but capacity not change, which can make program more efficient. 

### 2.3. `var` vs `make()`


```go
var cats []string
// or
dogs := make([]string, 0)
```

We have know that any varibles declared with `var` without an explicit initial value are given their zero value, `nil` is zero for `map`, `slice` and `pointer`. 

Therefore, the value of `cats` is `nil` for sure, then for `make([]string, 0)`it allocates a memory with 0 elements, which means `dog != nil`. But there probably no difference when you use, because **you can append a `nil` slice directly**:

```go
var expired []string
// it's totally fine to do this:
expired = append(expired, "hello")
fmt.Println(expired)
```

## 3. Commone usage of slice

### 3.1. Remove elements by reslicing

```go
func (s *MemoryStore) gc() {
	var expired []string
	for {
    // A new cycle begins, "remove" all elements from 'expired'
		expired = expired[:0]
    // add elements to 'expired', and use them
    ...
	}
}
```

```go
// Stimulate stack
stack := make([]rune, 0)
for _, r := range s {
	if _, ok := pairs[r]; ok {
		stack = append(stack, r)
	} else {
    // reslice, "delete" the last one element
		stack = stack[:len(stack)-1]
	}
}
```

### 3.2. Passing a slice to channel

```go
func main() {
	ready := make(chan []string)
  
	go func() {
		var expired []string
		expired = append(expired, "Coco")
		expired = append(expired, "Bella")
		ready<- expired
	}()
  
	go func() {
    // this will block until there is a data sent to the channel "ready"
		for s := range ready {
			for _, name := range s{
				fmt.Println(name)
			}
		}
	}()
  
	time.Sleep(time.Second)
}
```

Bacsuse a slice likes a pointer, the two goroutines above share a same underlying array. You have to consider if there is a data race, if yes, consider make a deep copy of the slice: [Everything Passed by Value - Go - David's Blog](https://davidzhu.xyz/post/golang/basics/009-everything-passed-by-value/) 

> Note that [iteration variable is re-used in each iteration](https://github.com/golang/go/wiki/CommonMistakes). 


