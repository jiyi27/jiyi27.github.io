---
title: CLASSPATH & PATH
date: 2023-04-25 14:53:30
categories:
 - Java
 - Basics
tags:
 - Java
---

## PATH
You should set the `PATH` variable if you want to be able to run the executables (javac, java, javadoc, and so on) from any directory without having to type the full path of the command. If you do not set the PATH variable, you need to specify the full path to the executable every time you run it, such as:

```bash
/usr/local/jdk1.7.0/bin/javac MyClass.java
```

怎么设置PATH呢, 也就是怎么添加环境变量呢? 编辑`~/.bashrc`或者`.zshrc`, 看你用的什么shell, 默认的是bash, 我用的是zsh

```shell
export PATH=$PATH:/place/with/the/file
```

其实这个很容易看出什么意思, PATH = `$PATH` + `/place/with/the/file`, 句子里面的分号就是个separator而已. 比如下面的输出, 一看就明白了:

```bash
echo $PATH
/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin
```

On most systems (Linux, Mac OS, UNIX, etc) the colon character (`:`) is the classpath separator. In windowsm the separator is the semicolon (`;`)

> 其实PATH就是告诉terminal可执行指令的位置信息, 而CLASSPATH是用来告诉JRE相关程序 用户自定义类 的位置信息 

## CLASSPATH

阅读此节前, 可先参考: [手动编译运行Java程序之JVM加载类的顺序](https://davidzhu.xyz/2023/07/26/Java/Basics/how-jvm-find-class/)

> Similar to the classic dynamic loading behavior, when executing Java programs, the Java Virtual Machine finds and loads classes lazily (it loads the bytecode of a class only when the class is first used). The classpath tells Java where to look in the filesystem for files defining these classes. - [Wiki](https://en.wikipedia.org/wiki/Classpath)

> 注意: **从 Java5 开始 CLASSPATH 默认就是当前路径, 一般情况下就不需要再设定了**, 

下面我们就介绍一下 CLASSPATH 的用, 以便对CLASSPATH有更加深入的理解: 因为Java是编译型语言，源码文件是`.java`，而编译后的`.class`文件才是真正可以被JVM执行的字节码。因此，如果要加载一个`abc.xyz.Hello`的类，JVM需要知道应该去哪搜索对应的`Hello.class`文件。所以，classpath就是一组目录的集合，它设置的搜索路径与操作系统相关。例如，在Windows系统上，用`;`分隔，带**空格的目录**用`""`括起来，可能长这样：

```
C:\work\project1\bin;C:\shared;"D:\My Documents\project1\bin"
```

在Linux系统上，用`:`分隔，可能长这样：

```
/usr/shared:/usr/local/bin:/home/liaoxuefeng/bin
```

现在我们假设`classpath`是`.;C:\work\project1\bin;C:\shared`，当JVM在加载`abc.xyz.Hello`这个类时，会依次查找：

- <当前目录>\abc\xyz\Hello.class
- C:\work\project1\bin\abc\xyz\Hello.class
- C:\shared\abc\xyz\Hello.class

注意到`.`代表当前目录。如果JVM在某个路径下找到了对应的`class`文件，就不再往后继续搜索。如果所有路径下都没有找到，就报错。

我们强烈不推荐在系统环境变量中设置classpath，那样会污染整个系统环境。**在启动JVM时设置`classpath`才是推荐的做法**。实际上就是给java命令传入`-classpath`或`-cp`参数：

```shell
java -cp .;C:\work\project1\bin;C:\shared abc.xyz.Hello
```

没有设置系统环境变量classpath也没有传入-cp参数时，那么JVM默认的classpath为`.`，即当前目录. 

```
java abc.xyz.Hello
```

上述命令告诉JVM搜索class文件路径为:`./abc/xyz/Hello.class`. 

例子, 比如我写个`Cat`类, 在包`com.zhu.servlet`, 编译运行指令如下:

```java
package com.zhu.servlet;

public class Cat {
    public static void main(String[] args) {
        System.out.println("hello world!");
    }
}
```

```shell
javac com/zhu/servlet/Cat.java 

java Cat                      
Error: Could not find or load main class Cat
Caused by: java.lang.ClassNotFoundException: Cat

java com.zhu.servlet.Cat
hello world!
```

所以这也说明了类的全名应该是包名+类名, 而不只是一个简单的类名. 

You can check value of classpath in java inside your application by looking at following system property “java.class.path”:
```
System.getProperty("java.class.path")
```

## Set Classpath

```shell
export CLASSPATH=$PATH:/home/myaccount/myproject/lib/CoolFramework.jar:/home/myaccount/myproject/output/
```

这只是举个例子, 更好的做法就是用第二种方法, 就是启动JVM的通过`-cp`来指定classpath, 不要在环境变量中设置classpath！默认的当前目录`.`对于绝大多数情况都够用了

```
C:\work> java -cp . com.example.Hello
```

参考:

- [classpath和jar - 廖雪峰的官方网站](https://www.liaoxuefeng.com/wiki/1252599548343744/1260466914339296)

