---
title: Rust 引发的类型安全的思考
date: 2023-08-05 18:32:53
categories:
  - 计算机基础
tags:
  - Rust
  - 类型安全
---

关于 type safety, 一直没有一个确切的定义, 每个语言的作者对 type safety 可能有不同的理解, 我比较喜欢的是维基百科对 type safety 的定义, 即 type safety 阻止或者使 type errors 不容易发生, 而什么是 type errors 在下面这段话里也给出了定义: 

> In computer science, **type safety** is the extent to which a programming language discourages or prevents **type errors**. The behaviors classified as type errors are usually that result from attempts to perform operations on values that are not of the appropriate data type, e.g., **adding a string to an integer when there's no definition on how to handle this case**. This classification is partly based on opinion. https://en.wikipedia.org/wiki/Type_safety

感觉维基百科对类型安全的定义与 Why Rust 一书的作者观点不谋而合:

> If a program has been written so that no possible execution can exhibit undefined behavior, we say that program is well defined. If a language’s type system ensures that every program is well defined, we say that language is type safe. 

undefined behavior: 在 c99 的定义中, undefined behaviors 有很多: 如分母为 0, 访问超出数组大小的位置 (c 是没有越界检查的), 让一个int能表示的最大数加一, 

```c
int main(int argc, char **argv) {
  unsigned long a[1];
  a[3] = 0x7ffff7b36cebUL;
  return 0;
}
```

According to C99, because this program accesses an element off the end of the array `a`, its behavior is undefined, meaning that it can do anything whatsoever. 

A carefully written C or C++ program might be well defined, but C and C++ are not type safe: the program shown earlier has no type errors, yet exhibits undefined behavior. By contrast, Python is type safe. Python is willing to spend processor time to detect and handle out-of-range array indices in a friendlier fashion than C:

```shell
>>> a = [0]
>>> a[3] = 0x7ffff7b36ceb
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
IndexError: list assignment index out of range
>>>
```

Python raised an exception, which is not undefined behavior: the Python documentation specifies that the assignment to `a[3]` should raise an `IndexError` exception, as we saw. Certainly, a module like `ctypes` that provides unconstrained access to the machine can introduce undefined behavior into Python, but the core language itself is type safe. Java, JavaScript, Ruby, and Haskell are similar in this way.

> Note that being type safe is independent of whether a language checks types at compile time or at runtime: C checks at compile time, and is not type safe; Python checks at runtime, and is type safe.  

以上讨论来自: [Why Rust Chapter 1](https://www.oreilly.com/library/view/programming-rust/9781491927274/ch01.html) , 感兴趣可以自己翻阅, 