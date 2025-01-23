---
title: Objects & Variables Python
date: 2023-11-29 14:51:31
categories:
  - python
tags:
  - python
typora-root-url: ../../../../static
---

## 1. Objects in Python

Everything in Python is an object. *Classes*, *functions*, and even simple data types, such as *integers*, *floats*, and *strings*, are objects in Python. When we define an integer in Python, CPython internally creates an object of type *integer*. These objects are stored in heap memory.

Each Python object consists of three fields:

- Value
- Type
- Reference count

Let's consider a simple example:

```python
a = 100
```

When the above code is executed, CPython creates an object of type `integer` and allocates memory for this object on the heap memory.

The `type` indicates the type of the object in CPython, and the `value` field, as the name suggests, stores the value of the object (`100` in this case). We will discuss the `ref_count` field later in the article.

<img src="/001-objects-variables/a.png" alt="a" style="zoom:33%;" />

> **CPython** is the default and most widely used implementation of the Python language. When we say Python, it essentially means we're referring to CPython. When you download Python from [python.org](https://www.python.org/), you basically download the CPython code. Thus, CPython is a program written in C language that implements all the rules and specifications defined by the Python language. CPython can be defined as both an interpreter and a compiler as it compiles Python code into bytecode before interpreting it.

## 2. Variables in Python

Variables in Python are just references to the actual object in memory. They are like names or labels that point to the actual object in memory. They do not store any value.

Consider the following example:

```
a = 100
```

As discussed earlier, when the above code is executed, CPython internally creates an object of type *integer*. The variable `a` points to this integer object as shown below:

<img src="/001-objects-variables/b.png" alt="b" style="zoom:33%;" />

We can access the integer object in the Python program using the variable `a`.

> 读到这可以看出Java还不是真正的万物皆对象 (如果想在heap上创建primitive对象 需要Integer声明创建), 但Python就是所有的东西都是对象, 即使是一个int类型, 甚至一个函数也是个对象, 另外Java与python的GC (Python中不叫GC叫Python memory manager)对对象的管理方式基本上是一样的, 即分为引用和对象两部分, 引用在stack, 对象在heap, 不像c++那种在函数里声明的就是局部对象(除malloc和new), 对于Java与python来说无论你在哪创建一个对象, 他们都会被创建到heap上, 且根据引用计数来判断对象是否reachable, 然后判断是否回收对象, 所以你完全可以返回一个“局部对象”的引用, 但C++中, 肯定就不行了, 这会造成野指针问题, 

Let's assign this integer object to another variable `b`:

```python
b = a
```

When the above code is executed, the variables `a` and `b` both point to the same integer object, as shown below:

<img src="/001-objects-variables/c.png" alt="c" style="zoom:33%;" />

Let's now increment the value of the integer object by 1:

Let's now increment the value of the integer object by 1:

```
# Increment a by 1
a = a + 1
```

When the above code is executed, CPython creates a new integer object with the value `101` and makes variable `a` point to this new integer object. Variable `b` will continue to point to the integer object with the value `100`, as shown below:

<img src="/001-objects-variables/d.png" alt="d" style="zoom:33%;" />

Here, we can see that instead of overwriting the value of `100` with `101`, CPython creates a new object with the value `101` **because integers in Python are immutable**. Once created, they cannot be modified. Please note that **floats and string data types are also immutable in Python**.

Let's consider a simple Python program to further explain this concept:

```python
i = 0
while i < 100:
    i = i + 1
```

The above code defines a simple `while` loop that increments the value of the variable `i` until it is less than `100`. When this code is executed, for every increment of the variable `i`, CPython will create a new integer object with the incremented value, and the old integer object will be deleted (to be more precise, this object would become eligible for deletion) from memory.

CPython calls the `malloc` method for each new object to allocate memory for that object. It calls the `free` method to delete the old object from memory.

```Python
i = 0  # malloc(i)
while i < 100:
    # malloc(i + 1)
    # free(i)
    i = i + 1
```

We can see that CPython creates and deletes a large number of objects, even for this simple program. If we call the `malloc` and `free` methods for each object creation and deletion, it will degrade the program’s execution performance and make the program slow.

Hence, CPython introduces various techniques to reduce the number of times we have to call `malloc` and `free` for each small object creation and deletion. Let’s now understand how CPython manages memory!

Learn more: [Memory Management in Python - Honeybadger Developer Blog](https://www.honeybadger.io/blog/memory-management-in-python/)