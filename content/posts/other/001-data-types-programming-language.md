---
title: Data Types in Programming Languages
date: 2023-11-28 20:50:06
categories:
 - other
tags:
 - c
 - java
 - golang
 - python
 - javascript
typora-root-url: ../../../static
---

# Data Types in Programming Languages

> Programs are collections of instructions that manipulate data to produce a desired result. 

## 1. Javascript

> As you have know that javascript is a dynamic language from [previous post](https://davidzhu.xyz/post/other/000-languge-types-practice/), which means the values have types, not variables. 

Javascript value types can be categorized into two main categories: **objects** and **primitives**. Among these types, the **objects are mutable**, which means their values can be modified or changed after they are created. On the other hand, the **primitive types are immutable**, meaning their values cannot be changed once they are assigned.

### 1.1. Primitive types

| Type                                                         | `typeof` return value | Object wrapper                                               |
| :----------------------------------------------------------- | :-------------------- | :----------------------------------------------------------- |
| [Null](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures#null_type) | `"object"`            | N/A                                                          |
| [Undefined](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures#undefined_type) | `"undefined"`         | N/A                                                          |
| [Boolean](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures#boolean_type) | `"boolean"`           | [`Boolean`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean) |
| [Number](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures#number_type) | `"number"`            | [`Number`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number) |
| [BigInt](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures#bigint_type) | `"bigint"`            | [`BigInt`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt) |
| [String](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures#string_type) | `"string"`            | [`String`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String) |
| [Symbol](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures#symbol_type) | `"symbol"`            | [`Symbol`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol) |

All primitive types, except [`null`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/null) and [`undefined`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/undefined), have their corresponding object wrapper types, which provide useful methods for working with the primitive values. For example, the [`Number`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number) object provides methods like [`toExponential()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/toExponential). 

> All primitive types, except [`null`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/null), can be tested by the [`typeof`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/typeof) operator. `typeof null` returns `"object"`, so one has to use `=== null` to test for `null`.

### 1.2. Object types

Learn more: 

[Objects & Collections in Javascript - David's Blog](https://davidzhu.xyz/post/js/basics/001-javascript-basics/)

[JavaScript data types and data structures - JavaScript | MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures)

## 2. Python

> Python is a dynamic language which means **the values have types, not variables**. 

In Python **all values are objects**, so doesn't like Java, there is no primitives, **all variable are references**. (Variables are associated with values, values have types)

### 2.1. Data types

Python has the following data types built-in by default, in these categories:

| Text Type:      | `str`                              |
| --------------- | ---------------------------------- |
| Numeric Types:  | `int`, `float`, `complex`          |
| Sequence Types: | `list`, `tuple`, `range`           |
| Mapping Type:   | `dict`                             |
| Set Types:      | `set`, `frozenset`                 |
| Boolean Type:   | `bool`                             |
| Binary Types:   | `bytes`, `bytearray`, `memoryview` |
| None Type:      | `NoneType`                         |

### 2.2. Mutable and immutable objects

Everything in Python is an object. And all objects in Python can be either **mutable** or **immutable**. Mutable objects are those that allow you to change their value or data in place without affecting the object’s identity. In contrast, immutable objects don’t allow this kind of operation, you have to create a new objects of the same type with different values.

Objects of built-in types like (***int**, float, bool, **str**, tuple, unicode*) are immutable. Objects of built-in types like (*list, set, dict*) are mutable. Custom classes are generally mutable.

Find [a good explanation](https://stackoverflow.com/a/62177555/16317008): 

> The integer is immutable. When you write x=5, x points to a memory location that holds 5. When you go on and code y=x, the variable y points to the same location as x.
>
> Then you type x+1=6, and now x points to a new location that holds 6, and not the previous location. ( Here, the integer still holds immutable because the original integer 5 still exists, but the variable x is not bound to it now. x is now bound to a new location. But y is still bound to the integer 5)
>
> But y still points to the same location that holds 5. So, integers are still immutable and this is how it works. To see it better, use id(x) or id(y) after every step.
>
> **The *variable* is not immutable; the `int` object *referred to* by the variable is.**

## 3. Java

> Java is a static language which means **the variable have types, not values have types**. 

Types of variables in Java are divided into two categories—**primitive types** and **reference types**. 

<img src="/001-data-types-programming-language/b.png" alt="b" style="zoom:33%;" />

### 3.1. Primitive types

The primitive types are `boolean`, `byte`, `char`, `short`, `int`, `long`, `float` and `double`. All other types are reference types. 

• A primitive-type variable can store exactly one value of its declared type at a time.

• Primitive-type instance variables are initialized by default. Variables of types `byte`, `char`, `short`, `int`, `long`, `float` and `double` are initialized to `0`. Variables of type `boolean` are initialized to `false`.

### 3.2. Reference types

Reference types in Java are non-primitive data types. It's called reference ecause it holds **the memory address** (or reference) of the objects.

In Java, **all objects** are allocated on Heap. This is different from C++ where objects can be allocated memory either on Stack or on Heap. 

- Whenever you use `new`, an object is created on the heap.
- Local variables are stored on the stack. That includes primitives (such as `int`) and the **references** to any objects created. The actual objects themselves aren't created on the stack, as I mentioned when you use `new` they'll be created on the heap. https://stackoverflow.com/a/8061692/16317008

```java
// variable age: primitive, stored on stack
int age = 77;
// variable person: reference, stored on stack, 
// its value is the address of the object stored on heap
Person person = new Person();
```

<img src="/001-data-types-programming-language/a.png" alt="a" style="zoom: 33%;" />

Just as men and women are fundamentally different (according to John Gray, author of Men Are from Mars, Women Are from Venus), **primitive variables** and **object reference variables** differ from each other in multiple ways. The basic difference is that **primitive variables store the actual values**, whereas reference variables store the addresses of the objects they refer to. Let’s assume that a class Person is already defined. If you create an int variable a, and an object reference variable person, they will store their values in memory as shown in figure 2.13. https://stackoverflow.com/a/32049775/16317008

> Note that similar to Python, strings in Java are objects, and they are immutable. 

## 4. Golang

> Golang is static language,  golang has no concept of object, all are values. So you can think the variable have types or values have types, all are fine. 

Golang has no refernce-type, all are values. But there is a concept of pointer, some types like `slice`, `map`, `channel`, `function` which are a pointer or a struct that has a pointer element, we usually catagorize them as reference-type. 

## 5. C++

> C++ is a static language which means **the variable have types, not values have types**. 

C++ has variable, reference and object. A **variable** is a named object that can hold a value of a specific data type. A **reference** is an alias for a variable, which means that it refers to the same memory location as the variable it is referencing.  An **object** is used to store a value in memory. 

A variable is an object that has a name (identifier). Naming our objects let us refer to them again later in the program. Although objects in C++ can be unnamed (anonymous), more often we name our objects using an identifier. An object with a name is called a **variable**.

```c++
int x; // define a variable named x, of type int
```

> In C++, we use objects to access memory. A named object is called a variable. Variables have an identifier, a type, and a value (and some other attributes that aren’t relevant here). A variable’s type is used to determine how the value in memory should be interpreted.

> You can think of RAM as a series of numbered boxes that can be used to store data while the program is running. In some older programming languages (like Applesoft BASIC), you could directly access these boxes (e.g. you could write a statement to “go get the value stored in mailbox number 7532”).  In C++, direct memory access is discouraged. Instead, we access memory indirectly through an object. An **object** is a region of storage (usually memory) that can store a value, and has other associated properties. 
>
> [1.3 — Introduction to objects and variables – Learn C++](https://www.learncpp.com/cpp-tutorial/introduction-to-objects-and-variables/)

## 6. Conclusion

Variables, values, types, the concepts of these terms may a little different. Don't need to remember what exactly these terms mean in each language, our goal is to know the behavior of the language so that we can use the language correctly and efficiently. Such as pass by value or reference, and if can return a reference of a locla variable. 
