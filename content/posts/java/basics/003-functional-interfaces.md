---
title: Functional Interfaces & Anonymous Classes & Lambda Expressions - Java
date: 2023-08-06 12:03:53
categories:
 - Java
 - Basics
tags:
 - Java
---

## 1. Anonymous Classes

- Anonymous Class Extending a Class
- Anonymous Class Implementing an Interface

如何理解呢, 如 `Cat cat = new Cat() {...}`, 若 Cat 是个类, 那对象 ` cat` 就是个类型为匿名的类, 只不过这个类继承了 ` Cat` , 同理若 ` Cat` 是个接口 interface, 那对象 ` cat` 的类型就是 a class that implements the interface ` Cat` , 具体可参考下面[这个视频](https://www.youtube.com/watch?v=DwtPWZn6T1A), 讲得很好:

{% youtube DwtPWZn6T1A %}

## 2. Functional Interfaces & Lambda Expressions 

- 若想定义一个方法, 且这个方法的参数也是一个方法, 就可以考虑使用 functional interface
- All a Lambda is, is a shorcut to define an implementation of a functional interface. 
- Functional interface 只可以有一个 abstract method, 但可以有多个 default, static methods, 
- 最好使用注解` @FunctionalInterface` , 它告诉编译器相关信息, 若接口有多个 abstract methods, 那编译器就会报错, 
- 常见的 functional interface 有: Runnable, ActionListener, and Comparable, 

举个例子, Java 创建线程一般如下:

```java
public class Main {
    public static void main(String[] args) {
        // Creating and starting a thread using lambda expression
        Thread myThread = new Thread(() -> {
            // Code to be executed in the thread
            System.out.println("Thread is running");
        });

        myThread.start();
    }
}
```

你看 ` Thread() ` 的构造方法可以接受一个 lambda 表达式, 我们去看看其函数原型, 

```java
public Thread(Runnable task) {
        ...
}
```

此时不用看, `Runnable` 肯定是个 functional interface, 不然是没办法接受 lambda的, 

```java
/**
 * Represents an operation that does not return a result.
 *
 * <p> This is a {@linkplain java.util.function functional interface}
 * whose functional method is {@link #run()}.
 *
 * @author  Arthur van Hoff
 * @see     java.util.concurrent.Callable
 * @since   1.0
 */
@FunctionalInterface
public interface Runnable {
    /**
     * Runs this operation.
     */
    void run();
}
```

具体参考[下面这个视频](https://youtu.be/), 讲的很好:

{% youtube tj5sLSFjVj4 %}

细品这句话: 

> One of the most welcome changes in Java 8 was the introduction of [lambda expressions](https://www.baeldung.com/java-8-lambda-expressions-tips), as these allow us to forego anonymous classes, greatly reducing boilerplate code and improving readability.  [Method References in Java](https://www.baeldung.com/java-method-references)

Back in ye olden times before Java 8, we had to use the clunky old [anonymous class syntax](https://docs.oracle.com/javase/tutorial/java/javaOO/anonymousclasses.html#syntax-of-anonymous-classes) for this sort of thing, leading to code that looked something like this:

```java
object.gimmeFunction(new SingleMethodInterface(){
     @Override 
     public bool really(int n){
        return n=="really".hashCode();
    }
});

Collections.sort(emplyeesList, new Comparator() {
 public int compare(Employee a1, Employee a2){
  return a1.getId().compareTo(a2.getId());
 }});

File[] hiddenFiles = new File("directory_name").listFiles(new FileFilter() {
 public boolean accept(File file) {
  return file.getName().endsWith(".xml");
 }});
// With lambda: 
File[] hiddenFiles = new File("directory_name").listFiles( file -> file.getName().endsWith(".xml"));
```

另外 Functional Interface 也多用在返回值, 如下:

```java
@FunctionalInterface
public interface ApplicationListener<E extends ApplicationEvent> extends EventListener {...};

@Bean
// ApplicationListener<AuthenticationSuccessEvent> 是个 functional interface
// 所以该方法返回的是个 lambda expression
public ApplicationListener<AuthenticationSuccessEvent> successListener() {
		return event -> System.out.printf(
				"\uD83C\uDF89 Success [%s] %s %n",
				event.getAuthentication().getClass().getName(),
				event.getAuthentication().getName()
		);
}
```

了解更多: 

- [lambda - What did Java programmers do before Java 8 if they wanted to pass a function around? - Stack Overflow](https://stackoverflow.com/questions/38416701/what-did-java-programmers-do-before-java-8-if-they-wanted-to-pass-a-function-aro)

- [Lambda Expressions Before And After Java 8 - Java Code Geeks - 2023](https://www.javacodegeeks.com/2020/05/lambda-expressions-before-and-afterjava-8.html)
