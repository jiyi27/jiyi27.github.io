---
title: Java Packages介绍及使用
date: 2023-07-27 20:11:43
categories:
 - Java
 - Basics
tags:
 - Java
---

## Java Packages & API

A package is a namespace that organizes a set of related classes and interfaces. Think of it as **a folder in a file directory**. We use packages to avoid name conflicts, and to write a better maintainable code. Packages are divided into two categories:

- Built-in Packages (packages from the Java API)
- User-defined Packages (create your own packages)

## Built-in Packages

The **Java API is a library** of prewritten classes, that are free to use, included in the Java Development Environment. The library contains components for managing input, database programming, and much much more. The complete list can be found at Oracles website: https://docs.oracle.com/javase/8/docs/api/.

The library (Java API) is divided into **packages** and **classes**. Meaning you can either import a single class (along with its methods and attributes), or a whole package that contain all the classes that belong to the specified package.

Java API 就是所谓的 Built-in Packages咯, 直观感受下

![1](/000-packages/1.png)

![2](/000-packages/2.png)

## User-defined Packages

To create your own package, you need to understand that Java uses a file system directory to store them. Just like folders on your computer:

```java
└── src
  └── mypack
    └── Cat.java
```

To create a package, use the `package` keyword:

```java
package mypack;
class Cat {
  ...
}
```

> 注意哦, package 应该在 src 目录下, 然后含有 main 函数的主类也应该在 src 下, 不然在导入package时是没办法找到 package的, 

### e.g.,

注意看目录结构, 

![1](/000-packages/1-0506006.png)

注意看第一行, 声明所在的package

![2](/000-packages/2-0506029.png)

若无声明

![3](/000-packages/3.png)

> 最后注意, 真正的完整类名是`包名.类名`, JVM 只看完整类名, JVM 认为只要包名不同, 类就不同, 
>
> 另外package没有父子关系, `java.util`和`java.util.zip`是不同的包, 两者没有任何继承关系, 

## Import a Package

To import a whole package, end the sentence with an asterisk sign (`*`). The following example will import ALL the classes in the `java.util` package:

```java
import java.util.*;
```

## Import a Class

If you find a class you want to use, for example, the `Scanner` class, **which is used to get user input**, write the following code:

```java
import java.util.Scanner;
```

In the example above, `java.util` is a package, while `Scanner` is a class of the `java.util` package.

参考:

- [What Is a Package? (The Java™ Tutorials > Learning the Java Language > Object-Oriented Programming Concepts)](https://docs.oracle.com/javase/tutorial/java/concepts/package.html)
- [Java Packages](https://www.w3schools.com/java/java_packages.asp)