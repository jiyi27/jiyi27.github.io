---
title: 手动编译运行Java程序之JVM加载类的顺序
date: 2023-07-26 17:52:40
categories:
 - Java
 - Basics
tags:
 - Java
---

## java & javac

两个指令

- Technically, `javac` is the program that translates Java code into bytecode (.class file) - an intermediate format which is understandable by the Java Virtual Machine (JVM).

- And `java` is the program that starts the **JVM**, which in turn, loads the `.class` file, verifies the bytecode and executes it.
  - `-classpath` *classpath*, or `-cp` *classpath*, specifies a list of directories, JAR files, and ZIP archives to search for **class files**.

  - On Windows, semicolons (`;`) separate entities in this list; on other platforms it is a colon (`:`).

  - Specifying *classpath* overrides any setting of the `CLASSPATH` environment variable. If the class path option isn't used and *classpath* isn't set, then the user class path consists of the current directory (`.`).

> 注意上面说的, java 启动 JVM, 然后 JVM 导入字节码文件, 别理解错了, 至于 -cp 就是用来告诉 JVM 去哪搜索用程序中到的类的字节码文件`.calss`, 

### 手动编译并运行java程序

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

可以发现, 我们只是编译了`Main.java`, 被其用到的类 `Cat.java` 也被编译了, 然后在其它文件夹下执行该程序, 用 `-cp` 来指明 classpath, 即告诉 JVM 去哪找 user-defined class 字节码文件, 

```shell
$ java -cp myproject/src Main 
mew~
```

## How JVM Finds Classes

这个标题本来是"How the Java Launcher Finds Classes",很具有迷惑性, 因为加载类的是 JVM, 下面也指出了是 JVM 加载类, 所以直接改了标题, 原文来自[oracle](https://docs.oracle.com/javase/1.5.0/docs/tooldocs/findingclasses.html), 

The Java launcher, java, initiates the Java virtual machine. **The virtual machine searches for and loads classes in this order:**

- Bootstrap classes - Classes that comprise the Java platform, including the classes in `rt.jar` and several other important jar files.

- Extension classes - Classes that use the Java Extension mechanism. These are bundled as `.jar` files located in the extensions directory.

- User classes - Classes defined by developers and third parties that do not take advantage of the extension mechanism. You identify the location of these classes using the `-classpath` option on the command line (the preferred method) or by using the CLASSPATH environment variable. 

In general, you only have to specify the location of user classes. Bootstrap classes and extension classes are found "automatically".

> 注意这里说的其实就是类加载的过程, 即 JVM 怎么查找并加载类对应的每个字节码文件, 而不是 java launcher, 它只是负责启动 JVM 的,  `-cp` 的作用在这再次被指出, 可以参考上面的例子

### How JVM Finds Bootstrap Classes

Bootstrap classes are the classes that implement the Java 2 Platform. Bootstrap classes are in the `rt.jar` and several other jar files in the `jre/lib` directory. These archives are specified by the value of the bootstrap class path which is stored in the `sun.boot.class.path` system property. This system property is for reference only, and should not be directly modified.

### How JVM Finds Extension Classes

Extension classes are classes which extend the Java platform. Every `.jar` file in the extension directory, `jre/lib/ext`, is assumed to be an extension and is loaded using the [Java Extension Framework](https://docs.oracle.com/javase/1.5.0/docs/guide/extensions/index.html). Loose class files in the extension directory will not be found. They must be contained in a `.jar` file (or `.zip` file). There is no option provided for changing the location of the extension directory.

If the `jre/lib/ext` directory contains multiple `.jar` files, and those files contain classes with the same name, such as:

```
smart-extension1_0.jar contains class smart.extension.Smartsmart-extension1_1.jar contains class smart.extension.Smart
```

the class that actually gets loaded is undefined.

### How JVM Finds User Classes

User classes are classes which build on the Java platform. To find user classes, the launcher refers to the *user class path* -- a list of directories, JAR archives, and ZIP archives which contain class files.

A class file has a subpath name that reflects the class's fully-qualified name. For example, if the class `com.mypackage.MyClass` is stored under `/myclasses`, then `/myclasses` must be in the user class path and the full path to the class file must be /`myclasses/com/mypackage/MyClass.class`. If the class is stored in an archive named `myclasses.jar`, then `myclasses.jar` must be in the user class path, and the class file must be stored in the archive as `com/mypackage/MyClass.class`.

The user class path is specified as a string, with a colon (**`:`**) separating the class path entries on Solaris, and a semi-colon (**`;`**) separating entries on Microsoft Windows systems. The **java** launcher puts the user class path string in the `java.class.path` system property. The possible sources of this value are:

- The default value, ".", meaning that user class files are all the class files in the current directory (or under it, if in a package).
- The value of the `CLASSPATH` environment variable, which overrides the default value.
- The value of the `-cp` or `-classpath` command line option, which overrides both the default value and the CLASSPATH value.
- The JAR archive specified by the `-jar` option, which overrides all other values. If this option is used, all user classes must come from the specified archive.

原文:

- [How Classes are Found](https://docs.oracle.com/javase/1.5.0/docs/tooldocs/findingclasses.html)