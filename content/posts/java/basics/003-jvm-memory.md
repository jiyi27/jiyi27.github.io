---
title: JVM 内存结构 两种分类方式
date: 2023-05-14 21:50:26
categories:
 - 面试
tags:
 - 面试
 - java
---

## 1. Java SE / JVM Specification

[JVM Specification](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-2.html) 标准把并没有提到 JVM 内存结构的概念, 但是有个区域叫: Run-Time Data Areas. 在官方的 Java Virtual Machine Specification 中，JVM 运行时数据区大体包含以下几个主要区域（有些区域是线程私有的，有些是线程共享的）：

1. **程序计数器 (PC Register)**
   - 线程私有，每个线程都有一个程序计数器，用来指示下一条将要执行的字节码指令
2. **Java 虚拟机栈 (Java Virtual Machine Stack)**
   - 线程私有，为每个 Java 方法调用创建栈帧(Stack Frame)，存放局部变量表、操作数栈、方法返回值等
3. **本地方法栈 (Native Method Stack)**
   - 线程私有，执行 Native 方法（JNI 等）时使用的一块栈空间
4. **堆 (Heap)**
   - 线程共享，用于存储对象实例，绝大部分对象都在此分配；现代商业虚拟机通常又将堆分为年轻代 (Young) 和老年代 (Old) 等细分区域
5. **方法区 (Method Area)**
   - 线程共享，用于存储类信息、运行时常量池、方法元数据 (字节码、方法声明等)
   - HotSpot 从 Java 8 开始用 Metaspace 来实现方法区（在此之前是 PermGen）
   - 运行时常量池 (Runtime Constant Pool) 也是方法区的一部分

```
┌─────────────────────────────────────────┐
│       JVM (规范) - Run-Time Data Areas │
└─────────────────────────────────────────┘
                  
1. 线程私有 (Thread Private)
   ├─ 程序计数器 (PC Register)
   ├─ Java 虚拟机栈 (Java Virtual Machine Stack)
   │   └─ 栈帧 (Stack Frame)
   │      ├─ 局部变量表 (Local Variables)
   │      ├─ 操作数栈 (Operand Stack)
   │      └─ 方法返回值等信息
   └─ 本地方法栈 (Native Method Stack)

2. 线程共享 (Thread Shared)
   ├─ 堆 (Heap)
   │   └─ (绝大部分对象实例都在此分配)
   └─ 方法区 (Method Area)
       └─ 运行时常量池 (Runtime Constant Pool)
```

> **注意**：在 JVM 规范里，还有“运行时常量池 (Runtime Constant Pool)”往往被单独列为一个关键概念，但它实际上属于方法区的一部分。
>
> The Run-Time Data Areas of JVM is vary from different JVM specifications. https://docs.oracle.com/javase/specs/index.html

## 2. HotSpot 实现

在日常调优或查看监控 (比如 `jmap -heap`、`jconsole`、`jvisualvm` 等) 时，人们更多地会使用**堆 / 非堆**这样的概念来区分内存：

Heap (堆内存)

- 用于存放 Java 对象，按年龄或回收算法又分为：
  - 年轻代 (Young Generation)：进一步细分为 Eden、Survivor0 (S0) 和 Survivor1 (S1)
  - 老年代 (Old Generation)

Non-Heap (非堆内存)

- 大致包括：
  1. Metaspace (方法区)：存储类元数据、运行时常量池等
  2. Code Cache (代码缓存)：存放 JIT 编译后的机器码
  3. 线程栈 (Thread Stack)：包括 Java 虚拟机栈和本地方法栈，在运维角度往往也被认为不是堆的一部分。
  4. Direct Memory (直接内存)：通过 `Unsafe` 或 NIO 分配的堆外内存，不在 Java 堆里，但受 `-XX:MaxDirectMemorySize` 限制

```
┌───────────────────────────────────────────────────┐
│       HotSpot JVM (实现&运维) - 内存结构示意图    │
└───────────────────────────────────────────────────┘

1. 线程私有 (Thread Private)
   ├─ 程序计数器 (PC Register)
   ├─ Java 虚拟机栈 (JVM Stack)
   └─ 本地方法栈 (Native Method Stack)
   
2. 堆 (Heap)  [线程共享]
   ├─ Young Generation (年轻代)
   │   ├─ Eden
   │   ├─ Survivor 0 (S0)
   │   └─ Survivor 1 (S1)
   └─ Old Generation (老年代)

3. 非堆 (Non-Heap) [线程共享，笼统归类为非堆]
   ├─ Metaspace (方法区的 HotSpot 实现)
   │   └─ 存储类元数据、运行时常量池等
   ├─ Code Cache (代码缓存，JIT 编译后机器码)
   ├─ Direct Memory (直接内存，通过 NIO / Unsafe 分配)
   └─ 其它 HotSpot 自身管理的结构
```

> 从“是否在 Java 堆中”的角度，Metaspace、线程栈、Code Cache、Direct Memory 都被放入了 “非堆 (Non-Heap)” 这个大筐里。所以**“非堆”并不对应 JVM 规范中的某个单一概念**，而是 HotSpot 实际实现或运维时的一种统称。

在讨论 JVM 内存结构时，通常会看到两种“分类视角”：

1. 来自 JVM 规范 (Java Virtual Machine Specification) 的“运行时数据区 (Run-Time Data Areas)”
2. 来自 HotSpot 实现/日常运维中常用的“堆 (Heap) / 非堆 (Non-Heap)”划分

这两种视角其实是同一个问题的两种不同表述方式，不同程度地抽象了底层实现。

