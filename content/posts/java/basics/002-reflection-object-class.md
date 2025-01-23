---
title: java.lang.Object & java.lang.Class
date: 2023-08-05 19:47:51
categories:
 - Java
 - Basics
tags:
 - Java
---

## 1. `java.lang.Object`

定义:

```java
public class Object {...}
```

The `java.lang.Object` class is the root of the class hierarchy. Every class has `Object` as a superclass. 所有的类(包括自定义类)都自动继承了类 `java.lang.Object`, 你可以自己创建个类, 然后查看其对象可调用的方法, 如下:

![1](/002-reflection-object-class/1.png)

可以看到一些方法如 `equals()`, `getClass()`, 这都是 `Cat` 继承自类 `Object` 所得, 

```java
public final Class<?> getClass()
```

了解更多: [Object (Java Platform SE 8 )](https://docs.oracle.com/javase/8/docs/api/java/lang/Object.html), 

## 2. ` java.lang.Class`

 `Class` 定义如下 (注意区分 `Class` 和 `class`, 前者是类, 后者是关键字):

```java
public final class Class<T>
extends Object
implements Serializable, GenericDeclaration, Type, AnnotatedElement
```

- 与 `java.lang.Objetc` 不同, `java.lang.Class` 是 `final `的, 所以没有类可以继承它, 而且它唯一的构造函数是私有的, 这意味着我们不能通过正常的方式来创建 `Class` 的对象. 

- 注意 `java.lang.Class`  是泛型类, 因此我们经常可以见到类似 `Class<?> xxx = cat.getClass()`  的声明, 

## 2.1. ` java.lang.Class` 为何存在

其实刚开始一直想不明白类 `java.lang.Class` 到底是什么, 为什么存在?

因为在我的印象里, 一个泛型类一般都是作为 collection 存在, 如 `ArrayList`, `List` 等, 他们使用泛型是为了代码的 reuse, 比如存 string, Integer, 等, 但是 `java.lang.Class` 呢? 它又不是 collection, 为什么要用泛型呢? 

我现在的理解是 `java.lang.Class`  是一个类的包装器, 也是为了代码的 reuse, 查看 `java.lang.Class`  的方法:

- getClassLoader(), getDeclaredMethods(), getFields()

```java
class Employee extends Person {
    ...
    ...
}

public class Main {
    public static void main(String[] args) throws NoSuchFieldException {
        Class<?> myClass = Employee.class;
        System.out.println("Name: " + myClass.getName());
        System.out.println("Simple name: " + myClass.getSimpleName());
        System.out.println("Superclass: " + myClass.getSuperclass());
        System.out.println("Interfaces: " + Arrays.toString(myClass.getInterfaces()));
        System.out.println("Methods: " + Arrays.toString(myClass.getMethods()));
        System.out.println("Fields" + Arrays.toString(myClass.getFields()));
    }
}
```

不难发现所有的类都可以用到这些方法, 这也是反射的根基, runtime 的时候用来获取某个类的信息, 在介绍 `java.lang.Object` 的时候, `Object` 的一个方法如下:

```java
public final Class<?> getClass()
```

这个返回值 `Class<?>` 代表什么? 代表方法可以返回 `getClass()` 任何类型的对象, 如 `Class<Integer>`, `Class<String>`, or `Class<Object>`. 你可能会反驳, 不是任何类型的对象啊, 你看你返回的是 `Class<Integer>` 而不可以返回 `Integer` 的对象, ummm, 别忘了前面说的, `java.klang.Class` 是作为一个类额包装器存在的, 为什么需要这样的一个类包装器? 因为反射机制, 

> Every time JVM creates an object , it also creates a `java.lang.Class` object that describes the type of the object . All instances of the same class share the same  `java.lang.Class`  object and you can obtain the  `java.lang.Class`  object by calling the `getClass()` method of the object. This method is inherited from `java.lang.Object` class . 这里说的很晕各种 object, 比如一个类 Cat, 当你第一次创建 Cat 的对象时, 如 cat_1, 此时一个  `java.lang.Class`  的对象就会被创建, 类型是 `Class<Cat>` 用来描述类 Cat, 之后你想获得刚被创建的这个 `java.lang.Class`  的对象(类型为`Class<Cat>` ) , 你可以调用 `getClass()` 方法, 即  `cat_1.getClass()`, 此时刚好说明了泛型 wildcard 的重要性, 即 `getClass()` 的返回值类型只能是 `Class<?>` , 否则当你再创建一个类的对象如 Dog 的时候, 难道还要再另重载个 `getClass()` 函数吗?  即: `public final Class<Cat> getClass()`, `public final Class<Dog> getClass()`, 这也太离谱了, 

When a class (say, `Cat`) is accessed for the very first time (e.g., say an instance of it is created ~ new Hello()), then **class loader** (a component of JVM) loads it (the bytecodes) and creates an instance of `java.lang.Class` that represents the class in context, i.e., `Cat`. Thereafter, when you are creating an object of that same class (`Cat`), this `java.lang.Class` instance would be used by JVM to create the object. This `java.lang.Class` object is also the entry point to use reflection and it can also be used to get meta-information about the class like the class name, super-class name, etc. 

## 2.2. 为什么需要反射

We need java.lang.Class.forName() and java.lang.Class.newInstance() because many times it happens that we don't know the name of the class to instantiate while writing code , we may get it from config files , database , network or from any Java application . This is the reflective way of creating an object which is one of the most powerful feature of Java and which makes way for many frameworks e.g. Spring , Struts which uses Java reflection .

**Can you create an object without using new operator in Java?**

```java
Class c = Class.forName("java.lang.String");
String object = (String) c.newInstance();
```

## 3. Creating a `java.lang.Class` object 

### 3.1. `Class.forName()`

Since class `Class` doesn’t contain any constructor, there is static factory method present in class `Class`, which is `Class.forName()`, used for creating object of class `Class`. Below is the syntax :

```java
public class Main {
    public static void main(String[] args) throws ClassNotFoundException {
        String nameOfClass = "Employee";
        Class<?> cls = Class.forName(nameOfClass);
        ClassLoader cLoader = cls.getClassLoader();
        System.out.println(cLoader);
    }
}
```

## 3.2. Myclass.class

Please note that this method is used with class name, not with class instances. 

### 3.3. obj.getClass()

`obj.getClass()`定义在`java.lang.Object.java`下:
```java
public final native Class<?> getClass();

e.g.,
A a = new A();   // Any class A
Class c = a.getClass();
```

参考: 

- [java lang Class Class - java.lang.Class Class in Java](https://www.hudatutorials.com/java/lang/class)
- https://qr.ae/pyJqWx
