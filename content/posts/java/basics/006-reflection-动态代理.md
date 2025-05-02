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

## 3. 面向切面编程 - 动态代理

### 3.1. 什么是动态代理

动态代理是 Java 中一种在运行时动态创建代理对象的技术, 主要用于在不修改原始类代码的情况下, 对目标对象的方法进行拦截和增强, 主要基于 反射机制 和 代理模式实现, 面向切面编程的实现主要依赖的就是动态代理技术

在Java中**代理模式** 是一种设计模式, 允许你通过“代理对象”来控制对“目标对象”的访问, Java有两种代理方式:

- 静态代理: 提前写好代理类的代码, 手动实现

- 动态代理: 运行时生成代理类, 使用 `java.lang.reflect.Proxy` 和 `InvocationHandler` 实现, 不需要提前写好代理类代码

动态代理的核心是创建一个**代理对象**，代理对象会在调用目标对象的方法时，执行额外的逻辑（比如日志、事务、权限检查等）, 它的工作流程如下:

- 创建代理对象：在运行时动态生成一个代理类，代理类实现与目标对象相同的接口或继承目标类
- 拦截方法调用：代理对象的方法调用会被转发到指定的**处理器**（InvocationHandler 或 MethodInterceptor），由处理器决定如何处理方法调用
- 增强逻辑：在调用目标方法**前后**，处理器可以添加额外的逻辑

JDK 动态代理是基于接口的, 位于 `java.lang.reflect` 包中, 主要通过 `Proxy` 类和 `InvocationHandler` 接口实现:

### 3.2. JDK 动态代理的实现逻辑

定义目标接口和实现类, 目标对象必须实现一个或多个接口

```java
public interface UserService {
    void sayHello(String name);
}

public class UserServiceImpl implements UserService {
    public void sayHello(String name) {
        System.out.println("Hello, " + name);
    }
}
```

实现 `InvocationHandler` 接口, 定义代理逻辑, `invoke()` 方法会在代理对象的方法被调用时执行

```java
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;

public class LoggingInvocationHandler implements InvocationHandler {
    private Object target; // 目标对象

    public LoggingInvocationHandler(Object target) {
        this.target = target;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        System.out.println("Before method: " + method.getName()); // 前置增强
        Object result = method.invoke(target, args); // 调用目标对象的方法
        System.out.println("After method: " + method.getName()); // 后置增强
        return result;
    }
}
```

使用 `Proxy.newProxyInstance` 方法生成代理对象

```java
import java.lang.reflect.Proxy;

public class Main {
    public static void main(String[] args) {
        UserService target = new UserServiceImpl();
        // 创建一个 LoggingInvocationHandler 类的实例
        InvocationHandler handler = new LoggingInvocationHandler(target);
        // 为 UserService 创建代理对象
        UserService proxy = (UserService) Proxy.newProxyInstance(
            target.getClass().getClassLoader(), // 类加载器
            target.getClass().getInterfaces(),  // 目标接口
            handler                             // InvocationHandler
        );
        proxy.sayHello("Alice"); // 调用代理对象的方法
    }
}

// 输出：
// Before: sayHello
// Hello, Alice
// After: sayHello
```

**`Proxy.newProxyInstance(...)` 做了什么?**

它是 Java 提供的 用来创建动态代理对象的方法, 方法签名:

```java
public static Object newProxyInstance(
    ClassLoader loader,        // 类加载器
    Class<?>[] interfaces,     // 接口数组（代理哪些接口）
    InvocationHandler h        // 调用处理器（怎么处理方法）
)
```

返回的是一个实现了你指定接口的“代理对象”, 这也是为什么上面的代码 `new Proxy.newProxyInstance(...)` 返回的对象 `proxy` 可以类型转换为 `UserService` 接口类型的一个实例, 另外当你调用这个对象 `proxy` 的方法时, 实际上是由 `InvocationHandler` 中的 `invoke()` 方法来“拦截”处理的

上面创建代理对象的代码:

```java
UserService proxy = (UserService) Proxy.newProxyInstance(
    target.getClass().getClassLoader(),
    target.getClass().getInterfaces(),
    handler
);
```

`proxy` 是一个动态生成的代理类的实例（例如 `$Proxy001`）, 它实现了 `UserService` 接口, 动态生成的代理类 `proxy` 大致是这样的

```java
class $Proxy0 extends java.lang.reflect.Proxy implements UserService {
    // 构造函数，接收 InvocationHandler
    public $Proxy0(InvocationHandler handler) {
        super(handler); // 调用 Proxy 父类的构造函数，保存 handler
    }

    // 实现 UserService 的 sayHello 方法
    public void sayHello(String name) {
        try {
            // 获取 sayHello 方法的 Method 对象
            Method method = UserService.class.getMethod("sayHello", String.class);
            // 调用 InvocationHandler 的 invoke 方法
            handler.invoke(this, method, new Object[]{name});
        } catch (Throwable t) {
            throw new RuntimeException(t);
        }
    }
}
```

当你调用 `proxy.sayHello("Alice")`, 并不是直接调用 `UserServiceImpl.sayHello`, 而是由代理机制转向调用 `LoggingInvocationHandler.invoke(...)`:

```java
@Override
public Object invoke(Object proxy, Method method, Object[] args) {
    System.out.println("Before method: " + method.getName());
    Object result = method.invoke(target, args); // 调用目标对象的方法
    System.out.println("After method: " + method.getName());
    return result;
}
```

**为什么这样写有优势?**

我只用 实现一个 `LoggingInvocationHandler`, 之后所有的 xxxService 都可通过 `Proxy.newProxyInstance` 创建代理对象, 然后通过代理对象调用 service 对应的方法时, 执行的逻辑都是 `LoggingInvocationHandler` 的 `invoke()` 方法里的逻辑:

```java
System.out.println("Before method: " + method.getName()); // 前置增强
Object result = method.invoke(target, args); // 调用目标对象的方法
System.out.println("After method: " + method.getName()); // 后置增强
return result;
```

> 动态代理就是在运行时创建一个“代理对象”, 它可以在不修改原始类代码的前提下, 对方法调用做增强处理（拦截、添加逻辑、记录日志、鉴权、事务等等）

参考: 

- [java lang Class Class - java.lang.Class Class in Java](https://www.hudatutorials.com/java/lang/class)
- https://qr.ae/pyJqWx
