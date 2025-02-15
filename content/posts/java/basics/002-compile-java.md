---
title: JVM 启动时都加载了哪些类 - Java 编译原理
date: 2025-02-15 15:07:57
categories:
 - java
tags:
 - java
 - jvm
 - 编译原理
---

## 1.  Java 代码的执行流程

1. 源代码编译：Java 源代码（`.java` 文件）首先由 Java 编译器 (Javac) 编译成 字节码 (Bytecode), 生成二进制的 `.class` 文件, 字节码是一种中间表示, 不是直接的机器码
2. Java 源代码在编译后会变成 `.class` 字节码文件, JVM 在执行时会采用 **两种方式**：
   - 解释执行 (Interpretation)：JVM 逐行翻译字节码, 并立即执行, 这就是“边翻译边执行”
   - JIT (Just-In-Time Compilation)：JVM 发现高频代码（如循环、热点方法）, 会使用 JIT Compiler 将其编译成本地机器码, 避免重复翻译, 提高执行效率
   -  JIT Compiler: 如 HotSpot VM 的 C1/C2 编译器

> **扩充1:** 类的生命周期 主要发生在 JVM 运行时, 且仅在类第一次被使用时触发, 并不是 JVM 启动时就一次性加载所有类, 
>
> 类的生命周期包括: 加载→验证→准备→解析→初始化

> **扩充2: ** 编译时, 每个单独的 `.java` 源码文件被认为是一个单独的编译单元, 被单独编译成一个 .class 字节码文件, 所以在 Java 项目中, 通常会被编译成多个 `.class` 文件, 如果直接分发 `.class` 文件, 管理起来会很麻烦, 因此, Java 提供了 `.jar` 这种格式, 可以把多个 `.class` 文件打包在一起, 便于 分发、部署和加载

## 2. 手动编译并运行 java 程序

目录结构:

```shell
├── myproject
│   └── src
│       ├── Main.java
│       └── animal
│           └── Cat.java
```

代码内容:

```java
// Cat.java
package animal;
public class Cat {
    String name;
    public Cat(String name) {
        this.name = name;
        System.out.println("mew~");
    }
}

// Main.java
import animal.Cat;
public class Main {
    public static void main(String []args){
        Cat cat = new Cat("kitty");
    }
}
```

在`src`下编译:

```shell
javac Main.java
```

编译后多出了两个字节码文件,  如下:

```shell
├── myproject
│   └── src
│       ├── Main.class
│       ├── Main.java
│       └── animal
│           ├── Cat.class
│           └── Cat.java
```

可以发现, 我们只是编译了`Main.java`, 被其用到的类 `Cat.java` 也被编译了, 然后在其它文件夹下执行该程序, 用 `-cp` 来指明 classpath, 即告诉 JVM 去哪找 user-defined class 字节码文件, `-cp` 默认值为当前文件夹: `./`

```shell
$ java -cp myproject/src Main 
mew~
```

> **Note:** Technically, `javac` is the program that translates Java code into bytecode (.class file). And `java` is the program that starts the **JVM**, which in turn, loads the `.class` file, verifies the bytecode and executes it. 

## 3. JVM 启动时都加载了哪些类

The virtual machine searches for and loads classes in this order:

- Bootstrap Classes 引导类, 加载核心库, 主要包含 Java 标准库的基础类 如 `java.lang.*` (`String`、`Object`、`Math`、`System`)

- Extension ClassLoader 加载扩展库

- User classes - Classes defined by developers and third parties that do not take advantage of the extension mechanism. You identify the location of these classes using the `-classpath` option on the command line (the preferred method) or by using the CLASSPATH environment variable. 

> In general, you only have to specify the location of user classes. Bootstrap classes and extension classes are found "automatically".
