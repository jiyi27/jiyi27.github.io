---
title: C++ Variable Assignment and Initialization
date: 2023-05-14 18:29:32
categories:
 - c++
 - basics
tags:
 - c++
---

## 1. Define

```c++
int x;    // define an integer variable named x
int y, z; // define two integer variables, named y and z
```

## 2. Variable Assignment

After a variable has been defined, you can give it a value (in a separate statement) using the `=` operator. This process is called **copy assignment** (or just **assignment**) for short:

```c++
int width; // define an integer variable named width
width = 5; // copy assignment of value 5 into variable width
```

## 3. Initialization

Initialization in C++ is surprisingly complex, so we’ll present a simplified view here.

There are 6 basic ways to initialize variables in C++:

```c++
int a;         // no initializer (default initialization)
int b = 5;    // initializer after equals sign (copy initialization)
int c(6);    // initializer in parenthesis (direct initialization)

// List initialization methods (C++11) (preferred)
int d{7};       // initializer in braces (direct list initialization)
int e = {8};   // initializer in braces after equals sign (copy list initialization)
int f {};     // initializer is empty braces (value initialization)
```

### 3.1. Default Initialization

When no initialization value is provided (such as for variable *a* above), this is called **default initialization**. In most cases, default initialization leaves a variable with an indeterminate value.

```c++
int a;         // no initializer (default initialization)
```

### 3.2. Copy Initialization

```c++
int width = 5; // copy initialization of value 5 into variable width
```

> Copy initialization is also used whenever values are implicitly copied or converted, such as when passing arguments to a function by value, returning from a function by value, or catching exceptions by value.

### 3.3. List Initialization

The modern way to initialize objects in C++ is to use a form of initialization that makes use of curly braces: **list initialization** (also called **uniform initialization** or **brace initialization**). List initialization comes in three forms:

```c++
int width {5};    // direct list initialization of value 5 into variable width
int height = {6}; // copy list initialization of value 6 into variable height
int depth {};     // value initialization (see next section)
```

List initialization has an added benefit: it disallows “narrowing conversions”. This means that if you try to brace initialize a variable using a value that the variable can not safely hold, the compiler will produce an error. For example:

```cpp
int width { 4.5 }; // error: a number with a fractional value can't fit into an int
```

References:

[1.4 — Variable assignment and initialization – Learn C++](https://www.learncpp.com/cpp-tutorial/variable-assignment-and-initialization/)
