---
title: Typing in Programming Language - Example
date: 2023-11-28 19:20:17
categories:
 - other
tags:
 - c
 - java
 - golang
 - python
 - javascript
---

Previous post: [Typing in Programming Language - David's Blog](https://davidzhu.xyz/post/other/000-languge-types-design/)

## 1. Javascript

JavaScript is a dynamic language with dynamic types. Variables in JavaScript are not directly associated with any particular value type, and any variable can be assigned (and re-assigned) values of all types:

```js
let foo = 42; // foo is now a number
foo = "bar"; // foo is now a string
foo = true; // foo is now a boolean
```

This is in dynamic languages (dynamically typing), values have types, not variables. 

> You don't need know what is **dynamic languages**, you just need know values have types, not variables. 

JavaScript is also a **weakly typed** language, which means it allows implicit type conversion when an operation involves mismatched types, instead of throwing type errors.

```js
const foo = 42; // foo is a number
const result = foo + "1"; // JavaScript coerces foo to a string, so it can be concatenated with the other operand
console.log(result); // 421
```

> As you can see, **weakly typed** language means it allows implicit type conversion when an operation involves mismatched types, instead of throwing type errors.

## 2. Python

Python is dynamic language, and is strongly typed. 

```py
bob = 1
bob = "bob"
```

This works because the variable does not have a type; it can name any object. After `bob=1`, you'll find that `type(bob)` returns `int`, but after `bob="bob"`, it returns `str`. (Note that `type` is a regular function, so it evaluates its argument, then returns the type of the value.)

```py
# Attempting to add a string and an integer
string_var = "Hello"
integer_var = 42

# This line will result in a TypeError
result = string_var + integer_var
```

## 3. C/C++

Bbviously, they are static language, but strong or weak?

> It's hard to classify every language into 'weakly' or 'strongly' typed -- it's more of a continuum. But, in comparison to other languages, C is fairly strongly typed. Every object has a compile-time type, and the compiler will let you know (loudly) if you're doing something with an object that its type doesn't let you do. For example, you can't call functions with the wrong types of parameters, access struct/union members which don't exist, etc.
>
> But there are a few weaknesses. One major weakness is typecasts - they essentially say that you're going to be mucking around with the types of objects, and the compiler should be quiet (when it can). `void*` is also another weakness -- it's a generic pointer to an unknown type, and when you use them, you have to be extra careful that you're doing the right thing. The compiler can't statically check most uses of `void*`. `void*` can also be converted to a pointer to any type without a cast (only in C, not in C++), which is another weakness.
>
> https://stackoverflow.com/a/430204/16317008

## 4. Java

Java is static and strongly typed. 

In Java or C/C++, every variable must have a declared type, and the type is checked at compile-time. Once a variable is declared with a specific type, it cannot be assigned a value of a different type. Here's an example:

```java
int num = 10; // The variable 'num' is declared as an integer
num = "Hello"; // This will result in a compilation error because we are trying to assign a string to an integer variable
```

Strongly Typed: Java is also a strongly typed language, which means that type conversions or implicit type coercion are limited. In Java, you cannot perform operations between incompatible types without explicitly converting them. Here's an example:

```java
int num1 = 10;
String str = "20";
int sum = num1 + str; // This will result in a compilation error because we are trying to add an integer and a string without explicit conversion
```

## 4. Golang

Golang is indeed a static and strongly typed language:

```go
a := 2
b := 3.2
fmt.Println(a + b) // invalid operation: a + b (mismatched types int and float64)
```

