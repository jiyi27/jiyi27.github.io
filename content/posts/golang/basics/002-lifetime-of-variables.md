---
title: Lifetime of a Local Variable - Go
date: 2023-05-15 22:52:03
categories:
 - golang
 - basics
tags:
 - golang
---

## Returns a address of local variable

Find codes below:

```go
func f() *int {
    v := 1
    return &v
}
```

New to golang from cpp so don't understand why can do this, this is returning a local variable's address 😱. And find a [doc](https://go.dev/doc/faq) talks about this:

**How do I know whether a variable is allocated on the heap or the stack?**

From a correctness standpoint, you don't need to know. **Each variable in Go exists as long as there are references to it**. The storage location chosen by the implementation is irrelevant to the semantics of the language. 

The storage location does have an effect on writing efficient programs. When possible, the Go compilers will allocate variables that are local to a function in that function's stack frame. However, if the compiler cannot prove that the variable is not referenced after the function returns, then the compiler must allocate the variable on the garbage-collected heap to avoid dangling pointer errors. Also, if a local variable is very large, it might make more sense to store it on the heap rather than the stack. 

In the current compilers, if a variable has its address taken, that variable is a candidate for allocation on the heap. However, a basic *escape analysis* recognizes some cases when such variables will not live past the return from the function and can reside on the stack. 

You probably think this quite like java's reference type ( java variable has two type: primitive and reference type), but you are wrong, a avriable actually another name of a address in golang. We say that each variable in Go exists as long as there are references to it, means we can reach to the value stored in the address which variable point to. Variable has value, its just a address. 

> For a mental model, you can treat variable names as references, which exists till their scope exists.
>
> For implementation, Go's variables are NOT references - for reference, use a pointer.
>
> These variables can be allocated on the stack, or on the heap. Both have pros and cons, the compiler decides. For correctness, it does not make any difference. "You don't have to know". 
>
> Source: https://www.reddit.com/r/golang/comments/s0m2h9/comment/hs2kvyo/?utm_source=share&utm_medium=web2x&context=3

```go
func foo1() *int {
	a := 3
	fmt.Println(&a)
	return &a
}

func foo2() int {
	b := 3
	fmt.Println(&b)
	return b
}

func main() {
	pa := foo1()
	fmt.Println(pa)
	fmt.Println("------------------")
	b := foo2()
	fmt.Println(&b)
}

0x1400011a018
0x1400011a018
------------------
0x1400011a038
0x1400011a030
```

