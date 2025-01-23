---
title: C Go Java Python内存结构及对比
date: 2023-05-27 19:59:17
categories:
 - other
tags:
 - golang
 - java
 - c
 - python
 - other
---

## 1. Javascript

Taken from [JavaScript | MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Memory_management) but **this applies for all language with GC**: 

Low-level languages like C, have manual memory management primitives such as [`malloc()`](https://pubs.opengroup.org/onlinepubs/009695399/functions/malloc.html) and [`free()`](https://en.wikipedia.org/wiki/C_dynamic_memory_allocation#Overview_of_functions). In contrast, JavaScript automatically allocates memory when objects are created and frees it when they are not used anymore (*garbage collection*). This automaticity is a potential source of confusion: it can give developers the false impression that they don't need to worry about memory management.

Regardless of the programming language, the memory life cycle is pretty much always the same:

1. **Allocate** the memory you need
2. Use the allocated memory (read, write), **each variable exists as long as there are references to it**.
3. **Release** the allocated memory when it is not needed anymore (Usually done by GC)

The second part is explicit in all languages. The first and last parts are explicit in low-level languages but are mostly implicit in high-level languages like JavaScript.

### 1.1. Allocation

```js
const n = 123; // allocates memory for a number
const s = "azerty"; // allocates memory for a string

const o = {
  a: 1,
  b: null,
}; // allocates memory for an object and contained values

// (like object) allocates memory for the array and
// contained values
const a = [1, null, "abra"];

function f(a) {
  return a + 2;
} // allocates a function (which is a callable object)

// function expressions also allocate an object
someElement.addEventListener(
  "click",
  () => {
    someElement.style.backgroundColor = "blue";
  },
  false,
);

```

### 1.2. Using values

Using values basically means reading and writing in allocated memory. This can be done by reading or writing the value of a variable or an object property or even passing an argument to a function.

### 1.3. Release when the memory is not needed anymore

The majority of memory management issues occur at this phase. The most difficult aspect of this stage is determining when the allocated memory is no longer needed.

**Low-level languages** require the developer to manually determine at which point in the program the allocated memory is no longer needed and to release it.

Some **high-level languages**, such as JavaScript, utilize a form of automatic memory management known as [garbage collection](https://en.wikipedia.org/wiki/Garbage_collection_(computer_science)) (GC). The purpose of a garbage collector is to monitor memory allocation and determine when a block of allocated memory is no longer needed and reclaim it.

Learn more: [Memory management - JavaScript | MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Memory_management)

## 2. Python

Memory management in Python involves a private heap containing **all Python objects** and data structures. The management of this private heap is ensured internally by the ***Python memory manager***. The Python memory manager has different components which deal with various dynamic storage management aspects, like sharing, segmentation, preallocation or caching.

> Everything is an object in Python, even types such as `int` and `str`.

Learn more: [Memory Management — Python 3.12.0 documentation](https://docs.python.org/3/c-api/memory.html)

## 3. Golang

From a correctness standpoint, you don't need to know. Each variable in Go exists as long as there are references to it. The storage location chosen by the implementation is irrelevant to the semantics of the language. 

The storage location does have an effect on writing efficient programs. When possible, the Go compilers will allocate variables that are local to a function in that function's **stack frame**. However, if the compiler cannot prove that the variable is not referenced after the function returns, then the compiler must allocate the variable on the **garbage-collected heap** to avoid dangling pointer errors. Also, if a local variable is very large, it might make more sense to store it on the heap rather than the stack. 

In the current compilers, if a variable has its address taken, that variable is a candidate for allocation on the heap. However, a basic *escape analysis* recognizes some cases when such variables will not live past the return from the function and can reside on the stack. 

## 4. Java

Learn more: https://davidzhu.xyz/post/java/basics/005-memory-structure/

## 5. C/C++

C has three different pools of memory: 

- **static**: global variable storage, permanent for the entire run of the program.
- **stack**: local variable storage (automatic, continuous memory).
- **heap**: dynamic storage (large pool of memory, not allocated in contiguous order).

### 5.1. Static memory

Static memory persists throughout the entire life of the program, and is usually used to store things like *global* variables, or variables created with the static clause. If a variable is declared *outside* of a function, it is considered global, meaning it is accessible anywhere in the program. Global variables are static, and there is only one copy for the entire program. Inside a function the variable is allocated on the stack. It is also possible to force a variable to be static using the **static** clause. For example, the same variable created inside a function using the static clause would allow it to be stored in static memory.

```c
static int theforce;
```

### 5.2. Stack memory

The *stack* is used to store variables used on the inside of a function (including the `main()` function). It’s a LIFO, “**L**ast-**I**n,-**F**irst-**O**ut”, structure. Every time a function declares a new variable it is “pushed” onto the stack. Then when a function finishes running, all the variables associated with that function on the stack are deleted, and the memory they use is freed up. This leads to the “local” scope of function variables. 

Note that there is generally a limit on the size of the stack – which can vary with the operating system (for example OSX currently has a default stack size of 8MB). If a program tries to put too much information on the stack, **stack overflow** will occur. Stack overflow happens when all the memory in the stack has been allocated, and further allocations begin overflowing into other sections of memory. Stack overflow also occurs in situations where recursion is incorrectly used.

- the stack grows and shrinks as variables are created and destroyed
- stack variables only exist whilst the function that created them exists

### 5.3. Heap Memory

The *heap* is the diametrical opposite of the stack. The *heap* is a large pool of memory that can be used dynamically – it is also known as the “free store”. This is memory that is not automatically managed in C/C++ – you have to explicitly allocate (using functions such as malloc), and deallocate (e.g. free) the memory. Failure to free the memory when you are finished with it will result in what is known as a *memory leak* – memory that is still “being used”, and not available to other processes. Unlike the stack, there are generally no restrictions on the size of the heap (or the variables it creates), other than the physical size of memory in the machine. Variables created on the heap are accessible anywhere in the program.

## 6. Conclusion

Most of languages are designed with stack and heap, the concept of stack and heap are not mentioned in Javascript, but some concepts like the function stack frame, heap are shared among the modern languages designs. Our goal is to grab the lifetime of objects so that can write good and robust codes, not stack and heap. 

References:

- [Memory in C – the stack, the heap, and static – The Craft of Coding](https://craftofcoding.wordpress.com/2015/12/07/memory-in-c-the-stack-the-heap-and-static/)
- [When will a string be garbage collected in java - Stack Overflow](https://stackoverflow.com/questions/18406703/when-will-a-string-be-garbage-collected-in-java)
- [Choosing a GC Algorithm in Java | Baeldung](https://www.baeldung.com/java-choosing-gc-algorithm)
- [Golang Memory Management: Allocation Efficiency in Go Services](https://segment.com/blog/allocation-efficiency-in-high-performance-go-services/)
- [Memory Management — Python 3.11.3 documentation](https://docs.python.org/3/c-api/memory.html)
- [Memory Management in Python - Honeybadger Developer Blog](https://www.honeybadger.io/blog/memory-management-in-python/)
- [CPython](https://en.wikipedia.org/wiki/CPython)
- [🚀 Visualizing memory management in Golang | Technorage](https://deepu.tech/memory-management-in-golang/)
- [methods - Is Java "pass-by-reference" or "pass-by-value"? - Stack Overflow](https://stackoverflow.com/a/73021/16317008)
- [Stack vs heap allocation of structs in Go, and how they relate to garbage collection - Stack Overflow](https://stackoverflow.com/questions/10866195/stack-vs-heap-allocation-of-structs-in-go-and-how-they-relate-to-garbage-collec)
- [python - How do I pass a variable by reference? - Stack Overflow](https://stackoverflow.com/questions/986006/how-do-i-pass-a-variable-by-reference)
- [Garbage Collector Design](https://devguide.python.org/internals/garbage-collector/)
- [🚀 Demystifying memory management in modern programming languages | Technorage](https://deepu.tech/memory-management-in-programming/)