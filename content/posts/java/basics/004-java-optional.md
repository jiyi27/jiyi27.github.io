---
title: Java 8 Optional & Method Reference
date: 2023-08-06 15:44:52
categories:
 - Java
 - Basics
tags:
 - Java
---

## 1. Optional Class

Java 8 Optional 定义如下:

```java
// A container object which may or may not contain a non-null value. If a value is present, `isPresent()` will return `true` and `get()` will return the value. 
public final class Optional<T>
extends Object
```

之前讨论的 [`java.lang.Class`](https://davidzhu.xyz/2023/08/05/Java/Basics/002-reflection-object-class/), 也是一个类包装器, 若一个函数的返回值为 ` Optional<?>` 则就是返回` Optional<?>` 的对象, 这很容易看出来, 不要加个泛型就迷了, 如一个方法的签名为 ` public Cat foo();`  则该方法返回的一定是 ` Cat`  的对象, 

Optional 就是为了减少我们的 null check 代码, Helps you avoid NullPointerException, 所以不要乱用 optional,  [下面这个视频](https://youtu.be/vKVzRbsMnTQ)讲的很好:

{% youtube vKVzRbsMnTQ %}

看完视频再啰嗦几句, 此文章看似是了解 Java 8 Optional, 其实涉及到了generics和functional interface, 了解后阅读源码也会容易很多, 因为很多都用到了这两个特性, 了解更多: 

- [Functional Interfaces & Anonymous Classes & Lambda Expressions - Java | 橘猫小八的鱼](https://davidzhu.xyz/2023/08/06/Java/Basics/003-functional-interfaces/)
- [java.lang.Object & java.lang.Class | 橘猫小八的鱼](https://davidzhu.xyz/2023/08/05/Java/Basics/002-reflection-object-class/)

## 2. Method Reference

学 Spring Security, 看到一段自定义代码, 用来获取通过 Open ID 登录用户的 email:

```java 
private static String getName(Authentication authentication) {
        return Optional.of(authentication.getPrincipal())
                .filter(OidcUser.class::isInstance)
                .map(OidcUser.class::cast)
                .map(OidcUser::getEmail)
                .orElseGet(authentication::getName);
}
```

### 2.1. ` filter()` 

简单分析一下 `filter()`, 

```java
public Optional<T> filter(Predicate<? super T> predicate);
```

关于 ` filter()` 的介绍: *If a value is present, and the value matches the given predicate, return an Optional describing the value, otherwise return an empty Optional.* 这是什么意思呢? 

假设我们有个方法 getCat() 可以从数据库获取 Cat 对象, 然后我们调用它:

``` java
Optional<Cat> optionalCat = getCat("Milo");
```

此时 optionalCat 就是一个 Cat 对象的包装器, a Optional that describes the value, 然后我们接着做下面的事情:

``` java
optionalCat.filter(cat -> cat.getName().equals("Milo"));
```

如果 optionalCat 不为空, 且 lambada 表达式返回值为 true 即上面表述: *If a value is present, and the value matches the given predicate,* 则 *return an Optional describing the value*, 即相当于对 cat 对象进行二次筛选, 第一次不为空, 第二次需要 cat 名字为 “milo”, 若这俩条件都满足, 此时 filter() 才会返回一个 `Optional<Cat>` 对象, 也就是和最初的 optionalCat 相同, 若那两个条件有一个没满足, 则 filter()  返回一个空 Optional 对象, 

另外该方法参数类型是一个 functional interface, 即 ` Predicate<? super T>` , 可以看看其定义, 

``` java
@FunctionalInterface
public interface Predicate<T> {
    boolean test(T t);
    ...
}
```

如果你了解 functional interface, 不难发现对于这种参数类型我们可以直接传 lambda expression, 但是上面代码传的是 `OidcUser.class::isInstance` 这是什么鬼?  别慌, 这不是 c++ 的 namespace, 这是 Java 8 的新特性 Method Reference, 

> **Method references are a special type of lambda expressions**. They're often used to create simple lambda expressions by referencing existing methods. [Method References in Java](https://www.baeldung.com/java-method-references)

不得不说 Java 8 带来了很多的新的特性: Optional, Method Reference, Lambda, 

### 2.2. ` map()` 

对于另一个方法 ` map()` , 则是会返回一个新类型的 Optional 对象, 

``` java
public <U> Optional<U> map(Function<? super T,? extends U> mapper);
```

If a value is present, apply the provided mapping function to it, and if the result is non-null, return an `Optional` describing the result. Otherwise return an empty `Optional`.

```java
public class Main {
    public static void main(String[] args) {
        Optional<Cat> optionalCat = getCat("Milo");
        int age = optionalCat
                    .filter(cat -> cat.getName().equals("Milo") )
                    .map(Cat::getAge) 
                    .orElse(0);
        System.out.println(age);
    }

    public static Optional<Cat> getCat(String name) {
        // 模拟查找数据
        Cat cat = new Cat(name, 2);
        return Optional.ofNullable(cat);
    }
}
```

若 filter() 返回的不是空 Optional, 且 Cat::getAge 没有返回空值, 则返回一个新的 Optional, 类型为 Optional<Integer>,  即 return an `Optional` describing the result, 
