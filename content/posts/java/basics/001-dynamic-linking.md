---
title: JVM 中发生的动态链接
date: 2025-02-04 19:15:20
categories:
 - java
tags:
 - java
 - 编译原理
---

```
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
```

我们用 `javac Hello.java` 编译得到 `Hello.class`, 可以用 `javap -c Hello.class` 查看编译后的字节码：

```
public static void main(java.lang.String[]);
Code:
   0: getstatic     #2 // Field java/lang/System.out:Ljava/io/PrintStream;
   3: ldc           #3 // String "Hello, World!"
   5: invokevirtual #4 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
   8: return
```

> **关键点**：在 `Hello.class` 的 **常量池 Constant Pool **里, `#2`、`#3`、`#4` 并不是被编码到某个内存地址或函数入口, 而是 符号引用, 类似于：
>
> 1. `class = "java/lang/System"`, `fieldName = "out"`, `fieldDescriptor = "Ljava/io/PrintStream;"`
> 2. `class = "java/io/PrintStream"`, `methodName = "println"`, `methodDescriptor = "(Ljava/lang/String;)V"`
> 3. 字符串 `"Hello"`
>
> 所以常量池的这些符号引用像是在说 (以 `getstatic #2` 为例): “我需要的是 `java/lang/System` 这个类，里面名为 `out`，类型是 `Ljava/io/PrintStream;` 的静态字段”

> **注意:** 在 Java 中，**每一个 `.class` 文件**里都带有一张自己的常量池（Constant Pool）。这张常量池的存在是为了在字节码里用 “符号引用” 或 “常量” 来代替真正的类、方法、字段、字符串、数值等内容，并且让它们可以在 JVM 运行时 被 “解析” 成真实的类、方法或者对象引用。

