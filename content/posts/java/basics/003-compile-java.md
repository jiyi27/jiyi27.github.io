---
title: 手动编译运行 Java 程序 - JVM 加载类的顺序
date: 2023-07-26 17:52:40
categories:
 - java
tags:
 - java
 - jvm
---

## 1. java & javac

Technically, `javac` is the program that translates Java code into bytecode (.class file).

And `java` is the program that starts the **JVM**, which in turn, loads the `.class` file, verifies the bytecode and executes it. 

## 2. 手动编译并运行java程序

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

## 3. How JVM Finds Classes

The virtual machine searches for and loads classes in this order:

- Bootstrap Classes 引导类, 加载核心库, 主要包含 Java 标准库的基础类 如 `java.lang.*` (`String`、`Object`、`Math`、`System`)

- Extension ClassLoader 加载扩展库

- User classes - Classes defined by developers and third parties that do not take advantage of the extension mechanism. You identify the location of these classes using the `-classpath` option on the command line (the preferred method) or by using the CLASSPATH environment variable. 

In general, you only have to specify the location of user classes. Bootstrap classes and extension classes are found "automatically".

> 在 Java 项目中，代码通常会被编译成多个 `.class` 文件。如果直接分发 `.class` 文件，管理起来会很麻烦。因此，Java 提供了 `.jar` 这种格式，可以把多个 `.class` 文件打包在一起，便于 分发、部署和加载。

