---
title: Java 反射和动态代理
date: 2025-05-02 20:22:36
categories:
 - java
tags:
 - java
---

## 1. `java.lang.Object `所有对象的基类

```java
public class Object {...}
```

The `java.lang.Object` class is the root of the class hierarchy. Every class has `Object` as a superclass. 所有的类(包括自定义类)都自动继承了类 `java.lang.Object`, 你可以自己创建个类, 然后查看其对象可调用的方法, 如下:

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2025/05/79ab1d70411bdb3d60fd348c631f6b03.png)

可以看到一些方法如 `equals()`, `getClass()`, 这都是 `Cat` 继承自类 `Object` 所得

## 2. ` java.lang.Class` 包装类 反射的基础

### 2.1. `java.lang.Class` 和 `java.lang.Object` 的区别 

 `java.lang.Class` 定义如下 (注意区分`class` 和  `java.lang.Class`, 前者是关键字, 后者是个类):

```java
public final class Class<T>
extends Object
implements Serializable, GenericDeclaration, Type, AnnotatedElement
```

- `java.lang.Class` 是 `final`, 所以没有类可以继承它, 而且它唯一的构造函数也是私有的, 这意味着我们不能通过正常的方式来创建 `Class` 的对象
  - 与 `java.lang.Objetct` 不同, `java.lang.Objetct` 是所有类的基类

- 注意 `java.lang.Class`  是泛型类, 因此我们经常可以见到类似 `Class<?> xxx = cat.getClass()`  的声明

### 2.2. 每个类都有一个 `java.lang.Class` 实例

每个类在 JVM 中只有一个唯一的 `java.lang.Class` 实例, 所有这个类的所有对象**共享**这个实例:

- 每个类（不管创建多少个对象）在 JVM 中只会有一个对应的 `Class` 实例
- 每个对象都可以通过 `getClass()` 方法获取它所属类的 `Class` 对象
- 你也可以通过 `类名.class` 获取这个类的 `Class` 实例

可是我们自定义类的时候也没有定义 `class` 字段呀, 这是怎么回事?

- 所有对象在内存中都有一个“隐藏的指针”指向它所属类的 `Class` 实例
- 这个“指针”在 Java 层是不可见的，但通过 `getClass()` 方法就可以访问它
- 而 `getClass()` 方法其实是定义在 `java.lang.Object` 中的, 不要忘了  `java.lang.Object` 是所有类的基类

```java
public class Object {
    public final native Class<?> getClass();
}
```

这个方法是用 `native` 修饰的，说明它的实现不是用 Java 写的，而是由 JVM 在底层（C/C++）实现的

### 2.3. ` java.lang.Class` 为何存在

刚开始一直想不明白类 `java.lang.Class` 是什么, 为什么存在?

因为在我的印象里, 一个泛型类一般都是作为 collection 存在, 如 `ArrayList`, `List` 等, 他们使用泛型是为了代码的 reuse, 比如存 string, Integer, 等, 但是 `java.lang.Class` 呢? 它又不是 collection, 为什么要用泛型呢? 

可以把 `java.lang.Class` 理解为一个 **类包装器**, 它是反射的基础, 因为它包含很多反射相关的方法, 一些对象用它包装后, 就可以使用这些方法, 在运行时获得对象的类型等信息, `java.lang.Class` 类提供了许多方法, 用于获取类的相关信息:

- `getName()`: 返回类的完全限定名（包括包名
- `getSimpleName()`: 返回类的简单名称（不包括包名
- `getDeclaredConstructors()`: 返回类的所有声明的构造函数
- `getFields()`: 返回类及其父类的所有公共字段
- ...

```java
public class Person {
    private String name;
    public int age;

    public Person() {}
    public Person(String name, int age) {
        this.name = name;
        this.age = age;
    }

    private void greet() {
        System.out.println("Hello!");
    }
}

public class Main {
    public static void main(String[] args) throws NoSuchFieldException {
        // 获取 Person 类的 Class 对象
        // 也可以通过: Person person = new Person().getClass() 获取
        Class<?> clazz = Person.class;

        // 打印类的完全限定名和简单名
        System.out.println("类名: " + clazz.getName());
        System.out.println("简单类名: " + clazz.getSimpleName());

        // 获取所有声明的构造函数
        System.out.println("构造函数:");
        for (var constructor : clazz.getDeclaredConstructors()) {
            System.out.println("  " + constructor);
        }

        // 获取所有公共字段（包括父类的）
        System.out.println("公共字段:");
        for (var field : clazz.getFields()) {
            System.out.println("  " + field);
        }
    }
}
```

不难发现所有的类都可以用到这些方法, 这也是反射的根基, runtime 的时候用来获取某个类的信息, 在介绍 `java.lang.Object` 的时候, `Object` 的一个方法如下:

```java
public final Class<?> getClass()
```

这个返回值 `Class<?>` 代表什么? 

代表方法可以返回 `getClass()` 任何类型的对象, 如 `Class<Integer>`, `Class<String>`, or `Class<Object>`

> Every time JVM creates an object , it also creates a `java.lang.Class` object that describes the type of the object . All instances of the same class **share** the same  `java.lang.Class`  object and you can obtain the  `java.lang.Class`  object by calling the `getClass()` method of the object. This method is inherited from `java.lang.Object` class . 

### 2.4. 为什么需要反射

We need java.lang.Class.forName() and java.lang.Class.newInstance() because many times it happens that we don't know the name of the class to instantiate while writing code , we may get it from config files , database , network or from any Java application . This is the reflective way of creating an object which is one of the most powerful feature of Java and which makes way for many frameworks e.g. Spring , Struts which uses Java reflection.

**Can you create an object without using new operator in Java?**

```java
Class c = Class.forName("java.lang.String");
String object = (String) c.newInstance();
```

## 3. 动态代理





> 动态代理就是在运行时创建一个“代理对象”, 它可以在不修改原始类代码的前提下, 对方法调用做增强处理（拦截、添加逻辑、记录日志、鉴权、事务等等）

参考: 

- [java lang Class Class - java.lang.Class Class in Java](https://www.hudatutorials.com/java/lang/class)
- https://qr.ae/pyJqWx
