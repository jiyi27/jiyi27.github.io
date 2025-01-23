---
title: 左值和右值
date: 2023-05-17 11:27:07
categories:
 - c++
 - basics
tags:
 - c++
---

经常看到左值右值, 刚好有讲到, 摘取一些记录在这, 原文: [9.2 — Value categories (lvalues and rvalues) – Learn C++](https://www.learncpp.com/cpp-tutorial/value-categories-lvalues-and-rvalues/)

## 1. Rvalue expression vs Lvalue expression

### 1.1. The properties of an expression

To help determine how expressions should evaluate and where they can be used, all expressions in C++ have two properties: a type and a value category. 

### 1.2. The type of an expression

The type of an expression is equivalent to the type of the value, object, or function that results from the evaluated expression. For example:

```cpp
int main() {
    auto v1 { 12 / 4 }; // int / int => int
    auto v2 { 12.0 / 4 }; // double / int => double
}
```

> Note that the type of an expression must be determinable at compile time (otherwise type checking and type deduction wouldn’t work) -- however, the value of an expression may be determined at either compile time (if the expression is constexpr) or runtime (if the expression is not constexpr).

### 1.3. The value category of an expression

Now consider the following program:

```cpp
int main() {
    int x{};
    x = 5; // valid: we can assign 5 to x
    5 = x; // error: can not assign value of x to literal value 5
}
```

How does the compiler know which expressions can legally appear on either side of an assignment statement?

The answer lies in the second property of expressions: the `value category`. The **value category** of an expression (or subexpression) indicates whether an expression resolves to a value, a function, or an object of some kind.

Prior to C++11, there were only two possible value categories: `lvalue` and `rvalue`.

In C++11, three additional value categories (`glvalue`, `prvalue`, and `xvalue`) were added to support a new feature called `move semantics`.

### 1.4. **Lvalue and rvalue expressions**

An **lvalue** (pronounced “ell-value”) is an expression that evaluates to an identifiable object or function (or bit-field).

Entities (such as an object or function) with identities can be accessed via an identifier, reference, or pointer, and typically have a lifetime longer than a single expression or statement. 这里的identifier就是变量名和reference, pointer并列. 比如`int x = 3; `, `x`就是identifier, `3`就是object. 

An **rvalue** (pronounced “arr-value”) is an expression that is not an l-value. Commonly seen rvalues include literals (except C-style string literals, which are lvalues) and the return value of functions and operators. Rvalues aren’t identifiable (meaning they have to be used immediately), and only exist within the scope of the expression in which they are used.

```cpp
#include <iostream>

int return5() {
    return 5;
}

int main() {
    int x{ 5 }; // 5 is an rvalue expression
    const double d{ 1.2 }; // 1.2 is an rvalue expression

    int y { x }; // x is a modifiable lvalue expression
    const double e { d }; // d is a non-modifiable lvalue expression
    int z { return5() }; // return5() is an rvalue expression (since the result is returned by value)

    int w { x + 1 }; // x + 1 is an rvalue expression
    int q { static_cast<int>(d) }; // the result of static casting d to an int is an rvalue expression

    return 0;
}
```

You may be wondering why `return5()`, `x + 1`, and `static_cast<int>(d)` are rvalues: the answer is these expressions produce temporary values that are not identifiable objects.

Now we can answer the question about why `x = 5` is valid but `5 = x` is not: an assignment operation requires the **left operand** of the assignment to be a modifiable lvalue expression, and the **right operand** to be an rvalue expression. The latter assignment (`5 = x`) fails because the left operand expression `5` isn’t an lvalue. 这里说一下, 原文中提到lvalue expression又分为modifiable和non-modifiable, 后者就是加上`const`修饰的, 感兴趣可以去原文查看, 

```cpp
int main() {
    int x{};
    // Assignment requires the left operand to be a modifiable lvalue expression and the right operand to be an rvalue expression
    x = 5; // valid: x is a modifiable lvalue expression and 5 is an rvalue expression
    5 = x; // error: 5 is an rvalue expression and x is a modifiable lvalue expression
}
```

### 1.5. l-value to r-value conversion

We said above that the assignment operator expects the right operand to be an rvalue expression, so why does code like this work?

```cpp
int main() {
    int x{ 1 };
    int y{ 2 };
    x = y; // y is a modifiable lvalue, not an rvalue, but this is legal
}
```

The answer is because lvalues will implicitly convert to rvalues, so an lvalue can be used wherever an rvalue is required.

## 2. Lvalue reference variables

Modern C++ contains two types of references: `lvalue references`, and `rvalue references`. Rvalue references are covered in the chapter on `move semantics` ([chapter M](https://www.learncpp.com/#ChapterM)).

An **lvalue reference** (commonly just called a `reference` since prior to C++11 there was only one type of reference) acts as an alias for an existing lvalue (such as a variable). 说白了我们平时使用的引用都是lvalue reference, 

```cpp
int      // a normal int type
int&     // an lvalue reference to an int object
double&  // an lvalue reference to a double object

int x { 5 };    // x is a normal integer variable
int& ref { x }; // ref is an lvalue reference variable that can now be used as an alias for variable x
```

### 2.1. Dangling references

When an object being referenced is destroyed before a reference to it, the reference is left referencing an object that no longer exists. Such a reference is called a **dangling reference**. Accessing a dangling reference leads to undefined behavior. 

## 3. 总结

- assignment operation, left operand, right operand
- rvalue expression, lvalue expression, modifiable lvalue expression, non-modifiable lvalue expression
- value category of an expression,  type of an expression
-  lvalue references, and rvalue references
- dangling reference