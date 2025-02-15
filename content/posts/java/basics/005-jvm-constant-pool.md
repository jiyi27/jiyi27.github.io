---
title: JVM 运行时常量池 - 动态链接
date: 2025-02-04 08:50:26
categories:
 - java
tags:
 - java
 - jvm
 - 编译原理
---

## 1. 前言

JVM 规范中只有 Run-Time Data Areas 的概念, 它的主要分类逻辑就是线程共享和线程私有区域, 而我们平时更倾向于站在堆栈传统角度对内存进行分类, 因为这样很容易理解, 

在 JVM 类加载过程中 Run-Time Data Areas 方法区的 Runtime Constant Pool 很重要, 相当于编译中的符号表, 在动态链接的时候主要就靠它来告诉 JVM 该类用到了哪些标准库的东西, 外部的类和函数, 去哪加载等等元数据信息, 今天就来研究一下

```
Run-Time Data Areas
 └─ Method Area
     └─ Runtime Constant Pool
```

## 2. 每个 .class 文件都有一个常量池

在 Java 中，**每一个 `.class` 文件**里都带有一张自己的**常量池**。这张常量池的存在是为了在字节码里用 “符号引用” 或 “常量” 来代替真正的类、方法、字段、字符串、数值等内容，并且让它们可以在 JVM 运行时 被 “解析” 成真实的类、方法或者对象引用。

为什么每个 `.class` 文件都有自己的常量池？

- 每个 `.class` 文件是一个**独立的编译单元**，它可能引用不同的类、不同的方法、不同的字符串、不同的常量
- 在 Java 编译阶段，`javac` 会为**该类**所需的一切外部引用（类、字段、方法等）和字面量**记录到它自己的常量池**中
- 当这个类加载到 JVM 里时候, 需要使用其中任何符号引用或常量，就会通过它**自己**的常量池去做解析

## 3. 看个例子

```java
public class Demo {
    public static void main(String[] args) {
        System.out.println("Hello World");
    }
}
```

编译后执行 `javac Demo.java`，得到 `Demo.class`, 然后用 `javap -v Demo.class` 查看其常量池部分：

```
Classfile .../Demo.class
  Last modified ...; size ...
  MD5 checksum ...
public class Demo
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #7.#22         // java/io/PrintStream.println:(Ljava/lang/String;)V
   #2 = String             #23            // Hello World
   #3 = Fieldref           #8.#24         // java/lang/System.out:Ljava/io/PrintStream;
   #4 = Class              #25            // Demo
   #5 = Class              #26            // java/io/PrintStream
   #6 = Utf8               Demo
   #7 = Utf8               java/io/PrintStream
   #8 = Utf8               java/lang/System
   #9 = Utf8               main
   #10 = Utf8              ([Ljava/lang/String;)V
   #11 = Utf8              Code
   ...
   #22 = NameAndType       #27:#28        // println:(Ljava/lang/String;)V
   #23 = Utf8              Hello World
   #24 = NameAndType       #29:#30        // out:Ljava/io/PrintStream;
   #25 = Utf8              Demo
   #26 = Utf8              java/io/PrintStream
   #27 = Utf8              println
   #28 = Utf8              (Ljava/lang/String;)V
   #29 = Utf8              out
   #30 = Utf8              Ljava/io/PrintStream;
   ...
{
  public Demo();
    ...
  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=1, args_size=1
         0: getstatic     #3      // Field java/lang/System.out:Ljava/io/PrintStream;
         3: ldc           #2      // String Hello World
         5: invokevirtual #1      // Method java/io/PrintStream.println:(Ljava/lang/String;)V
         8: return
      ...
}
```

## 4. 常量池里都有啥？

`#1 = Methodref #7.#22 // java/io/PrintStream.println:(Ljava/lang/String;)V`
表示：这是一个 `Methodref` 常量，指向“类 #7”与“NameAndType #22”的组合

- “类 #7” 就是 `java/io/PrintStream`（见后面 `#7 = Utf8 "java/io/PrintStream"`）
- “NameAndType #22” 则表示方法名和方法描述符——在 `#22` 里你会看到 `<println:(Ljava/lang/String;)V>`

`#2 = String #23 // Hello World`

表示：这是一个 `String` 常量，对应了 “字符串 #23”；“#23” 实际是一个 `Utf8` 条目，存放 `"Hello World"` 的字符

`#3 = Fieldref #8.#24 // java/lang/System.out:Ljava/io/PrintStream;`
表示：这是一个 `Fieldref` 常量，指向“类 #8”与“NameAndType #24”的组合

- “类 #8” -> `java/lang/System`
- “NameAndType #24” -> “`out:Ljava/io/PrintStream;`”

`#22 = NameAndType #27:#28 // println:(Ljava/lang/String;)V`
表示：这是一个 `NameAndType` 常量，`#27` 是方法名 `println`，`#28` 是方法描述符 `"(Ljava/lang/String;)V"`

`#23 = Utf8 "Hello World"`
表示：这是一个存放字符串 `"Hello World"` 的 `Utf8` 常量

可以看到，编译器把你写的代码里所有用到的类名、方法名、字段名、描述符以及字符串字面量，都以 各种类型的 cp_info（`Methodref`、`Fieldref`、`NameAndType`、`Utf8`、`String` 等）记录到了同一个常量池数组里。

## 5. 这些条目在运行时怎么被用到？

在实际运行过程中，你可以从反汇编的字节码看到：

```
0: getstatic     #3      // Field java/lang/System.out:Ljava/io/PrintStream;
3: ldc           #2      // String Hello World
5: invokevirtual #1      // Method java/io/PrintStream.println:(Ljava/lang/String;)V
8: return
```

`#3`、`#2`、`#1` 都是**常量池索引**。当 JVM 执行到这条指令时，它会到 Demo 类的常量池里找相应记录，再看看**那条记录**里描述了什么类、字段或方法名、描述符，然后去解析并链接到真实的 `System.out` 字段或 `PrintStream.println(...)` 方法上。

## 6. 类的加载、验证、准备、解析、初始化

在 Java 中，类加载（Class Loading）之后，紧随其后（或在实际使用时触发）的过程，通常称为 类的链接（Linking）和 初始化（Initialization）。而链接过程里最关键的一步就是 解析（Resolution）。有时我们也把 在**运行时将常量池符号引用转成直接引用** 称为动态链接（Dynamic Linking），因为它跟 C/C++ 的 “编译期/链接期绑定” 不一样，而是在Java 程序执行期间由 JVM 来完成。

> 第 4 步的解析（Resolution）往往就是我们所说的“动态链接”的核心：把**字节码中符号形式的引用**——例如 “`java/lang/System`” 、“`out`” 、“`println`”——**映射到 JVM 内部真正的方法、字段、类结构**

编译后字节码（通过 `javap -v`）大概是：

```text
0: getstatic     #3      // Field java/lang/System.out:Ljava/io/PrintStream;
3: ldc           #2      // String Hello World
5: invokevirtual #1      // Method java/io/PrintStream.println:(Ljava/lang/String;)V
8: return
```

这里的 `#3`, `#2`, `#1` 是常量池索引, 当 JVM 在解释或JIT 编译这些指令时，如果某个索引还没解析，就会触发解析逻辑。

**解析 `#3` (getstatic …)**

- `#3` 在常量池中是一个 `Fieldref`，比如 “`java/lang/System.out:Ljava/io/PrintStream;`”

- JVM 首先看 这个类 `java/lang/System` 加载了没？如果没有，就让 Bootstrap ClassLoader 去加载并验证、准备（以及后续可能触发解析和初始化）

- 找到它后，在 `java.lang.System` 的元数据里查找名为 `out`、描述符 `Ljava/io/PrintStream;`、并且是 `static` 的字段

- 若能找到，就把这个常量池引用标记为已解析，并存储一个指向 `System.out` 字段的内部标识（可能是一个指针/偏移量）

- 此时还要检查 `System` 类是否已经初始化过。如果没初始化，就先初始化 `System`（调用其 `<clinit>`）。在 `<clinit>` 里会将 `System.out` 赋值为一个新的 `PrintStream` 对象。

- 执行 `getstatic #3` 时，JVM 发现“已解析”，就能直接去拿 `System.out` 这个静态字段的对象引用

**2.2 解析 `#2` (ldc …)**

- `#2` 在常量池中是一个 `String` 类型常量，如 “Hello World”
- 当执行 `ldc #2` 时，如果还没解析，就去常量池里取出对应的 UTF-8 字符串，将其intern或放到字符串池，生成一个 `java.lang.String` 实例（或从已有字符串池中返回）
- 然后把这个 `String` 对象引用压栈，用于后续 `println` 调用。

**2.3 解析 `#1` (invokevirtual …)**

- `#1` 在常量池是一个 `Methodref`，如 “`java/io/PrintStream.println:(Ljava/lang/String;)V`”
- JVM 会检查 `java.io.PrintStream` 这个类加载了吗？没的话，去加载它
- 在它的元数据里找到对应的方法表项 `println(String)`
- 若找到，就把常量池条目更新为已解析，后续执行指令 `invokevirtual #1` 时，就能通过对象的类型信息 + 方法表来跳转到 `PrintStream.println(String)` 的实现

以上步骤就是“解析 + 动态链接”最本质的行为：从常量池的“符号引用”（例如 “`Field java/lang/System.out`” 或 “`Method java/io/PrintStream.println`”）转成 JVM 内部可执行、可定位的实际字段或方法引用

## 7. 动态链接 VS. 静态链接

**静态链接（C/C++）**：

- 编译和链接器阶段就把对 `printf` 等函数的调用解析到某个符号表里，生成可执行文件，运行时再由 OS 的动态加载器做符号重定位，最终把 `printf` 的地址映射到可执行程序里。
- 也就是说，C/C++ 大部分链接工作在编译期/链接期就做好了，运行时只剩下操作系统层面的动态库装载、重定位

**Java 的动态链接**：

- **`.class` 文件只保留对 `System.out`、`println(String)` 等的符号引用**

- 真正的解析、绑定过程在JVM 运行时发生：

  1. 加载对应的类（可能还要加载该类所依赖的其他类），
2. 验证和准备，
  3. 在用到这些常量池引用时触发“解析”，最终把它指向 JVM 内部的真实方法或字段对象

- 这使得 Java 可以做到“类的动态加载”：运行中可以从网络或别的地方得到一个 `.class`，用自定义 ClassLoader 加载并解析它。而不需要像 C++ 一样必须在编译/链接时就知道所有符号
