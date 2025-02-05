---
title: JDK JRE JVM JavaSE
date: 2023-07-26 21:49:41
categories:
 - java
tags:
 - java
 - 面试
---

## 1. JDK

JDK 是 **Java 开发者需要的完整开发环境**，它包含：

- **JRE**（即 JVM + Java 标准库）
- **Java 编译器（`javac`）**，用于将 `.java` 源代码编译成 `.class` 字节码
- **开发工具**（如 `jdb` 调试器、`javap` 反编译工具、`jar` 打包工具）

>适用于**开发者**，用于编写、编译和运行 Java 代码, 如果你是开发者，**安装 JDK 就可以包含 JRE 和 JVM**，无需额外安装 JRE
>
>JDK ≈ JRE + 开发工具

## 2. JRE

JRE 是 运行 Java 程序的环境，它包含：

- JVM（Java 虚拟机）
- Java 标准类库（Java API，如 `java.lang`, `java.util`）
- 运行 Java 程序的核心文件（如 `rt.jar` 以提供 Java SE API）

> 如果你只是运行 Java 程序，而不进行 Java 开发，只需要 JRE
>
> JRE ≈ JVM + Java 标准库

## 3. JVM

JVM 是 Java 运行环境的核心，它的作用是：

- 负责运行 Java 字节码（.class 文件）
- 提供跨平台能力（"Write Once, Run Anywhere"）
- 进行垃圾回收（GC）

JVM 是 Java 语言的运行时组件，不包含 Java 开发工具（如编译器 `javac`）

## 3. Java SE、Java EE、Java ME

这几个术语表示不同的 Java 版本（规格），不是具体的软件包：

### **（1）Java SE（Java Standard Edition，Java 标准版）**

- Java SE 是 Java 语言的核心，包含 **JVM、JDK、JRE 和标准库**（如 `java.lang`, `java.util`）
- 适用于**桌面应用**、**基础后端开发**（如 Spring Boot）
- JDK 默认指的是 **Java SE 的 JDK**

### **（2）Java EE（Java Enterprise Edition，Java 企业版）**

- 在 Java SE 的基础上，提供 **企业级开发功能**，如 **Servlet、JSP、JMS、EJB**
- 适用于**大型 Web 应用、分布式系统**（如 Spring Cloud）
- 现在由 Eclipse 基金会维护，改名为 **Jakarta EE**

## 4. JDK 版本

JDK 也有不同版本：

- **Oracle JDK**（商业版，需要许可证）
- **OpenJDK**（开源版，和 Oracle JDK 主要功能一致）
- **其他厂商 JDK**（如 Amazon Corretto, AdoptOpenJDK）

## 5. 疑问 JRE 还存在吗

我的电脑有两个 jdk, 一个是我自己下载的 jdk17, 一个是电脑预安装的 jdk19:

```shell
ls /Library/Java/JavaVirtualMachines/jdk-19.jdk/Contents/Home/
LICENSE bin     include legal   man README  conf    jmods   lib     release

ls ~/Downloads/Programs/jdk-17-0-3-1/Home/
LICENSE README  bin     conf    include jmods   legal   lib     release
```

都说 JDK 包括 JRE, JRE 里面有 JVM, 但是现在新版本的 JDK 里没有 JRE 文件夹了, JRE 被单独安装了, 那么现在对于新版本的 JDK 来说, JRE 是不是仍然属于 JDK 呢? 知道这个问题和现实就行了, 至于属不属于无所谓, 想怎么说就怎么说呗, 关键是我们得知道, 什么是 JVM, 什么是 JDK 才是重要的. 


- In macOS, the JDK installation path is `/Library/Java/JavaVirtualMachines/jdk-10.jdk/Contents/Home/`.
- In macOS, the JRE installation path is `/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/`.

但是我去找 jre 却没找到, 官方说 When you install JDK 10, the public JRE (Release 10) also gets installed automatically. 他说的这种安装是下载dmg文件, 而我下的是免安装版本的zip包, 解压出来就用了, 所以ummmm, 具体也不清楚以后再想吧...

> 从 JDK 9 开始，Oracle 官方对 Java 进行了 模块化（Project Jigsaw） 设计，JRE 被整合进了 JDK，JDK 里 不再单独有 JRE 目录
>
> JRE 仍然存在 也可以说不再存在, 因为现在 JDK 本身就已经包含完整的运行时环境 (JVM + 标准库), 它不再是 JDK 的单独部分, 所以在不在, 有句话说的好, 心中有佛, 所见皆佛
>
> 不要纠结 JRE 是不是 JDK 的一部分, 运行 Java 需要 JVM 和 标准库(动态链接时用), 

