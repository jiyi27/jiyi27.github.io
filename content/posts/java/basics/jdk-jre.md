---
title: JDK & JRE
date: 2023-07-26 21:49:41
categories:
 - Java 
 - Basics
tags:
 - Java
---

我的电脑有两个jdk, 一个是我自己下载的jdk17, 一个是电脑预安装的jdk19:

```shell
ls /Library/Java/JavaVirtualMachines/jdk-19.jdk/Contents/Home/
LICENSE bin     include legal   man README  conf    jmods   lib     release

ls ~/Downloads/Programs/jdk-17-0-3-1/Home/
LICENSE README  bin     conf    include jmods   legal   lib     release
```

都说JDK包括JRE, 然后JRE里面有JVM, 但是现在新版本的JDK里没有JRE文件夹了, JRE被单独安装了, 那么现在对于新版本的JDK来说, JRE是不是仍然属于JDK呢? 知道这个问题和现实就行了, 至于属不属于无所谓, 想怎么说就怎么说呗, 关键是我们得知道, 什么是JVM, 什么是JDK才是重要的. 


- In macOS, the JDK installation path is `/Library/Java/JavaVirtualMachines/jdk-10.jdk/Contents/Home/`.
- In macOS, the JRE installation path is `/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/`.

但是我去找jre却没找到, 官方说 When you install JDK 10, the public JRE (Release 10) also gets installed automatically. 他说的这种安装是下载dmg文件, 而我下的是免安装版本的zip包, 解压出来就用了, 所以ummmm, 具体也不清楚以后再想吧...