---
title: 未初始化的变量和未定义行为
date: 2023-05-15 09:57:02
categories:
 - c++
 - basics
tags:
 - c++
---

## 1. Uninitialized variables

Uninitialized variables就是你定义它了但是却没有给它赋过值(即通过assignment操作或者initialization操作), 如下`a`就是个uninitialized variable: 

```c++
int a; 
```

为什么要说这个呢, C++编译器在这有点狗, 如果你定义局部变量的时候没有给它值, 如上面的变量`a`, 那编译器也并不会给`a`一个特定的初始值, 然后你运行程序编译器也不会报错:

```c++
int b;
int main() {
    int a;
    cout << a << endl; // 打印72433004
    cout << b << endl; // 打印0
    return 0;
}
```

Java的话是直接不允许你使用未定义的局部变量, 会报错, 如下:

```java
public static void main(String []args) {
        int a;
        System.out.println(a);
}
// error: java: variable a might not have been initialized
```

golang就会省事一些, 不论局部全局, 你若定义的时候没有给值, 编译器会自动给个初始值, Golang明确说明:

> Variables declared without an explicit initial value are given their ***zero value***. 

对比完不同的语言, 那我们继续上面的说C++, 为什么这么问题很严重, 这也是所谓的野指针(wild pointer)问题, 

假如这时候你定义的是个指针, 然后没有初始化, 这个时候该指针的值是”随机“的(其实页并不是随机, 即编译器为该指针变量分的那块内存里原本有什么, 那指针的值就是什么), 如果你此时尝试访问这个指针就可能会造成未定义行为(undefined behavior), 因为你不知道该指针的“随机”指向哪块内存, 你修改了该块内存的内容就有可能让你的的程序崩溃crush, 如下:

```c++
int* p;
*p = 6;
// 有时候程序会崩溃, 有时候程序会正常运行, 取决于p指向的哪块内存地址
```

> Unlike some programming languages, C/C++ does not initialize most variables to a given value (such as zero) automatically. Thus when a variable is given a memory address to use to store data, the default value of that variable is whatever (garbage) value happens to already be in that memory address! A variable that has not been given a known value (usually through initialization or assignment) is called an **uninitialized**.

最后对于上面未初始化的变量`a`打印了一个“随机”的值, 可能会有疑问, 看到[一篇文章](https://www.learncpp.com/cpp-tutorial/uninitialized-variables-and-undefined-behavior/)解释的不错, 分享一下:

```c++
#include <iostream>
int main() {
    // define an integer variable named x
    int x; // this variable is uninitialized because we haven't given it a value

    // print the value of x to the screen
    std::cout << x << '\n'; // who knows what we'll get, because x is uninitialized
}
```

In this case, the computer will assign some unused memory to *x*. It will then send the value residing in that memory location to *std::cout*, which will print the value (interpreted as an integer). But what value will it print? The answer is “who knows!”, and the answer may (or may not) change every time you run the program. When the author ran this program in Visual Studio, *std::cout* printed the value `7177728` one time, and `5277592` the next. Feel free to compile and run the program yourself (your computer won’t explode).

## 2. Undefined behavior

Using the value from an uninitialized variable is our first example of undefined behavior. **Undefined behavior** is the result of executing code whose behavior is not well-defined by the C++ language. In this case, the C++ language doesn’t have any rules determining what happens if you use the value of a variable that has not been given a known value. Consequently, if you actually do this, undefined behavior will result.

Code implementing undefined behavior may exhibit *any* of the following symptoms:

- Your program produces different results every time it is run.
- Your program consistently produces the same incorrect result.
- Your program behaves inconsistently (sometimes produces the correct result, sometimes not).
- Your program seems like it’s working but produces incorrect results later in the program.
- Your program crashes, either immediately or later.
- Your program works on some compilers but not others.
- Your program works until you change some other seemingly unrelated code.

References:

- [1.6 — Uninitialized variables and undefined behavior – Learn C++](https://www.learncpp.com/cpp-tutorial/uninitialized-variables-and-undefined-behavior/)