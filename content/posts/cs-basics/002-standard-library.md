---
title: C 标准库 运行时库(动静态链接库) 浅析
date: 2023-10-17 17:58:57
categories:
 - 计算机基础
tags:
 - 计算机基础
 - 编译原理
 - c语言
 - c++
---

## 1. ISO 制定标准库规范

**ISO/IEC** 制定 C 和 C++ 编程语言的标准，其中包括**标准库**的规范。这些标准定义了语言的语法、语义以及标准库中包含的函数、类型和宏

**标准库**是标准定义的一组函数和类型, 标准库的规范只定义了接口（即函数原型、类型定义等），而没有定义具体的实现

**glibc**（GNU C Library）是 GNU 项目为 GNU 系统（包括 Linux）提供的 C 语言标准库的**一种实现**, 它是 Linux 系统中最常用的 C 库, 提供了符合 ISO C 标准的函数和类型, 以及一些 Linux 特有的扩展

**MSVCRT**（Microsoft Visual C Runtime）是 Microsoft 为 Windows 操作系统提供的 C 和 C++ 运行时库, 其中包含了 C 语言标准库的**一种实现**, 它与 Microsoft Visual Studio 编译器紧密集成，为 Windows 应用程序提供必要的运行时支持。

> ISO 定义了标准库的规范, glibc 和 MSVCRT 是标准库的不同实现, 分别用于不同的操作系统（Linux 和 Windows）
>
> 为什么要实现不同版本的运行时库: There are functions for memory allocation, creating threads, and input/output operations (such as those in `stdio.h`)  in C language. All of these functions rely on system calls. Therefore, when third-party manufacturers implement the standard library of C language, they must create different versions for the different OS because each OS has its own set of system calls. 

## 2. 运行时 (runtime) 库

运行时库分为静态链接库和动态链接库两种形式, 我们在源代码中使用 printf 时, 编译器看到的只是一个函数声明, 这些函数(比如 printf、malloc 等)的真正实现代码在运行时库文件中, 在 **链接 阶段**, 链接器会把运行时库中我们用到的函数实现和我们的代码链接到一起, 然后**生成可执行文件**, 有两种链接方式: 

- 静态链接方式：编译阶段 直接把 静态链接库文件 和obj 二进制文件链接, 生成可执行文件
- 动态链接方式：程序运行时从动态链接库文件中加载运行时库的代码

|                   | 静态链接库                                    | 动态链接库                                                   |
| ----------------- | --------------------------------------------- | ------------------------------------------------------------ |
| Windows 扩展名    | .lib                                          | .dll (Dynamic Link Library)                                  |
| Linux/Unix 扩展名 | .a (archive)                                  | .so (Shared Object)                                          |
| 加载时机          | 编译时完整复制到可执行文件                    | 程序运行时才加载                                             |
| 优点              | 程序独立性强，不依赖外部环境                  | • 可执行文件较小<br>• 多个程序可共享同一库文件<br>• 库文件更新不需重新编译程序 |
| 缺点              | 生成的可执行文件较大，内存占用较多            | • 程序运行依赖特定动态链接库<br>• 可能出现版本兼容性问题     |
| C语言标准库示例   | • Linux/Unix: libc.a<br>• Windows: libcmt.lib | • Linux/Unix: libc.so<br>• Windows: msvcrt.dll               |

> **The term `library` (runtime library) and `header` are not same**. `Library` are the implementations of the `header`, which exist as binary files (the static library `.a`/`.lib` or the dynamic library `.so`/`.dll` ), whereas headers are `.h` files. Therefore, we usually cannot find the source code of the implementation of C standard library, such as function `printf()`. Because the implementation of these functions are provided as compiled binary files. But you can find the glibc's implementation of `printf()` on  the internet, because glibc is open source. 

## 3. libc.a va libc.so

The size of libc.a is `5.8 MB` which is huge for codes, `libc.a` is a static library, also known as a "archive" library, It contains compiled object code that gets linked into the final executable at compile time.

```shell
$ ls -lh /usr/lib/x86_64-linux-gnu/libc.a
-rw-r--r-- 1 root root 5.8M Sep 25 14:45 /usr/lib/x86_64-linux-gnu/libc.a
```

```shell
# Don't archive libc.a directly, archive it on a different folder
$ ar -x libc.a
$ ls | grep printf
printf.o
sprintf.o
...
```

> 为什么静态运行库里面一个目标文件只包含一个函数？比如libc.a里面printf.o只有printf()函数、strlen.o只有strlen()函数，为什么要这样组织？
>
> 链接器在链接静态库的时候是以目标文件为单位的, 比如我们引用了`printf()`函数, 如果进行静态链接的话, 那么链接器就只会把库中包含printf()函数的那个目标文件链接进来, 由于运行库有成百上千个函数, 如果把这些函数都放在一个目标文件中就会很大... 
>
> 如果把整个链接过程比作一台计算机, 那么ld链接器就是计算机的CPU, 所有的目标文件、库文件就是输入, 链接结果输出的可执行文件就是输出, 而链接控制脚本正是这台计算机的“程序”, 它控制CPU的运行, 以“程序”要求的方式将输入加工成所须要的输出结果.

`libc.so` is a shared library, often referred to as a "dynamic link library." It contains compiled code that is loaded into memory at runtime, allowing multiple programs to share the same code in memory.

Both `libc.a` and `libc.so` are implementations of the C library, but they differ in their form and how they are linked to programs. 

When we staticlly compile a source file, then `libc.a` will be used at compiled time, if we dynamically compile a source file (compile with dynamically linked) then `libc.so` will be used at runtime. 

```shell
$ gcc -static -o main main.c         

$ file main
main: ELF 64-bit LSB executable, x86-64, version 1 (GNU/Linux), statically linked, BuildID[sha1]=7fd47f129d345aa2ef6c44b06ffa01be4174d098, for GNU/Linux 3.2.0, not stripped

$ ls -lh main
-rwxrwxr-x 1 ubuntu ubuntu 880K Oct 18 00:51 main
```

```shell
$ gcc -o main main.c 

$ file main
main: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=f14bf2e15cabc179d82a09a2de5bf15da6e5b75c, for GNU/Linux 3.2.0, not stripped

$ ls -lh main
-rwxrwxr-x 1 ubuntu ubuntu 16K Oct 18 00:54 main
```

As you can see, the dynamically linked binary is very small just 1`6k` compared with the statically linked binary `880K`. 

## 4. glibc vs libc

| 特性     | libc              | glibc                     | 其他libc实现(如musl/uClibc) |
| -------- | ----------------- | ------------------------- | --------------------------- |
| 定义     | C标准库的接口规范 | GNU项目开发的libc具体实现 | 轻量级/嵌入式场景的libc实现 |
| 性质     | 概念性称呼        | 实际库文件                | 实际库文件                  |
| 使用范围 | -                 | Linux系统主流实现         | 嵌入式系统、资源受限环境    |
| 体积     | -                 | 较大                      | 小巧精简                    |
| 功能     | 定义基础接口      | 完整的功能实现，特性丰富  | 基础功能实现，针对性优化    |
| 运行环境 | -                 | 主要用于桌面和服务器      | 嵌入式设备、IoT设备等       |
| 特点     | -                 | 功能全面，向后兼容性好    | 启动快、内存占用小          |


## 5. Conclusion

程序如何使用操作系统提供的API(system call)? 在一般的情况下，一种语言的开发环境往往会附带有语言库（Language Library也可以说是标准库,运行时库）。这些库就是对操作系统的API的包装，比如我们经典的C语言版“Hello World”程序，它使用C语言标准库的“printf”函数来输出一个字符串，“printf”函数对字符串进行一些必要的处理以后，最后会调用操作系统提供的API。各个操作系统下，往终端输出字符串的API都不一样，在Linux下，它是一个“write”的系统调用，而在Windows下它是“WriteConsole”系统API。**标准库函数(运行库)依赖的是system call**。库里面还带有那些很常用的函数，比如C语言标准库里面有很常用一个函数取得一个字符串的长度叫strlen()，该函数即遍历整个字符串后返回字符串长度，这个函数并没有调用任何操作系统的API，也没有做任何输入输出。但是很大一部分库函数(运行库)都是要调用操作系统的API的.

> “Any problem in computer science can be solved by another layer of indirection.”

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2025/01/1f35f2b6abb298af70e6c922f5be2f32.png)

每个层次之间都须要相互通信，既然须要通信就必须有一个通信的协议，我们一般将其称为接口（Interface），接口的下面那层是接口的提供者，由它定义接口；接口的上面那层是接口的使用者，它使用该接口来实现所需要的功能.

> 运行时库(标准库, static library, dynamic library) 依赖 system call, 它提供头文件(`stdio.h`, `math.h`)供我们使用. 所以它很重要, 它在应用层和操作系统中间. 我们使用它提供的接口(`printf()`)和操作系统进行交流(通过system call).

我们的软件体系中，位于最上层的是应用程序，比如我们平时用到的网络浏览器、Email客户端、多媒体播放器、图片浏览器等。从整个层次结构上来看，开发工具与应用程序是属于同一个层次的，因为它们都使用一个接口，那就是操作系统应用程序编程接口（Application Programming Interface, 就是标准库的头文件）。应用程序接口(头文件)的提供者是运行库，什么样的运行库提供什么样的API，比如Linux下的Glibc库提供POSIX的API；Windows的运行库提供Windows API，最常见的32位Windows提供的API又被称为Win32。

运行库使用操作系统提供的系统调用接口（System call Interface），系统调用接口在实现中往往以软件中断（Software Interrupt）的方式提供，比如Linux使用0x80号中断作为系统调用接口，Windows使用0x2E号中断作为系统调用接口（从Windows XP Sp2开始，Windows开始采用一种新的系统调用方式）。

操作系统内核层对于硬件层来说是硬件接口的使用者，而硬件是接口的定义者，硬件的接口定义决定了操作系统内核，具体来讲就是驱动程序如何操作硬件，如何与硬件进行通信。这种接口往往被叫做硬件规格（Hardware Specification），硬件的生产厂商负责提供硬件规格，操作系统和驱动程序的开发者通过阅读硬件规格文档所规定的各种硬件编程接口标准来编写操作系统和驱动程序。

---程序员的自我修养：链接、装载与库
