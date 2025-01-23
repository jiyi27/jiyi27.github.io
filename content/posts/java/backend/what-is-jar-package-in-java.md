---
title: What is Jar Package in Java
date: 2023-04-25 15:04:48
categories:
 - Java
 - Backend
tags:
 - Java
---

>  JAR stands for Java ARchive. It's a file format based on the popular ZIP file format and is used for aggregating many files into one. Although JAR can be used as a general archiving tool, the **primary motivation** for its development was so that Java applets and their requisite components (.class files, images and sounds) can be downloaded to a browser in a single HTTP transaction, rather than opening a new connection for each piece. This greatly improves the speed with which an applet can be loaded onto a web page and begin functioning. [JAR File Overview](https://docs.oracle.com/javase/8/docs/technotes/guides/jar/jarGuide.html)

上面的话是在说一些Java程序(比如一些库)会有很多`.class`文件(因为有很多源代码`.java`各种类)和其他资源文件如图片,  如果我们想用这个库, 得一个一个下载这个库用到的每个`.class`文件(依赖之类), 这很麻烦. 

所以Java ARchive出现了, 按照Java ARchive规定的格式压缩文件后(也就是jar包), 你可以将这个jar包直接放进项目然后使用jar包中的类 (*注意jar包里可能还会有jar包, 比如有的库也会依赖其他的库*), 依赖一般放在jar包的`BOOT-INF`文件夹的lib目录下。这是我的Spring Boot Web项目形成的Jar包大致结构(我删除了一些文件, 太多了):

```shell
.
├── BOOT-INF
│   ├── classes
│   │   ├── application.properties
│   │   ├── com
│   │   │   └── choo
│   │   │       └── springdemo
│   │   │           └── SpringDemoApplication.class
│   │   └── static
│   │       └── index.html
│   ├── classpath.idx
│   └── lib
│       ├── jackson-annotations-2.14.2.jar
│       ├── spring-web-6.0.7.jar
│       ├── spring-webmvc-6.0.7.jar
│       ├── tomcat-embed-core-10.1.7.jar
│       └── tomcat-embed-websocket-10.1.7.jar
├── META-INF
│   ├── MANIFEST.MF
│   └── maven
│       └── com.choo
│           └── SpringDemo
│               ├── pom.properties
│               └── pom.xml
└── org
    └── springframework
        └── boot
            └── loader
                ├── ClassPathIndexFile.class
                ├── ExecutableArchiveLauncher.class
                ├── JarLauncher.class
```

如果我们要执行jar包的里面的某个`class`，就可以把jar包放到`classpath`中：

```
java -cp ./hello.jar abc.xyz.Hello
```

这样JVM会自动在`hello.jar`文件里去搜索某个类。

因为jar包就是zip包，所以，直接在资源管理器中，找到正确的目录，点击右键，在弹出的快捷菜单中选择“发送到”，“压缩(zipped)文件夹”，就制作了一个zip文件。然后，把后缀从`.zip`改为`.jar`，一个jar包就创建成功。

下面是简单项目编译输出的目录：

```
package_sample
└─ bin
   ├─ hong
   │  └─ Person.class
   │  ming
   │  └─ Person.class
   └─ mr
      └─ jun
         └─ Arrays.class
```

这里需要注意 遇上面输出相比, 压缩后的jar包内第一层目录并不是 `bin`, 而是package, 在Windows的资源管理器中看，应该长这样：

![](/what-is-jar-package-in-java/a.png)

就说明打包打得有问题, 因此JVM无法从jar包中查找正确的class, 原因是`hong.Person`必须按`hong/Person.class`存放，而不是`bin/hong/Person.class`。

jar包还可以包含一个特殊的`/META-INF/MANIFEST.MF`文件，`MANIFEST.MF`是纯文本，可以指定Main-Class和其它信息。JVM会自动读取这个MANIFEST.MF文件，如果存在Main-Class，我们就不必在命令行指定启动的类名，而是用更方便的命令：

```shell
java -jar hello.jar
```

在大型项目中，不可能手动编写`MANIFEST.MF`文件，再手动创建zip包。Java社区提供了大量的开源构建工具，例如**Maven**，可以非常方便地创建jar包

推荐阅读: [How Classes are Found](https://docs.oracle.com/javase/1.5.0/docs/tooldocs/findingclasses.html)

参考:

- https://docs.oracle.com/javase/8/docs/technotes/tools/findingclasses.html
- https://www.liaoxuefeng.com/wiki/1252599548343744/1260466914339296
