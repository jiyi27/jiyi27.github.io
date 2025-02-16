---
title: Java 基础八股文
date: 2025-02-15 10:30:20
categories:
 - 面试
tags:
 - 面试
 - 八股文
---

## 1. 访问控制修饰符

| 访问修饰符              | 同一个类 | 同一个包 | 子类（不同包） | 其他包 |
| ----------------------- | -------- | -------- | -------------- | ------ |
| **private**             | ✅        | ❌        | ❌              | ❌      |
| **default**（无修饰符） | ✅        | ✅        | ❌              | ❌      |
| **protected**           | ✅        | ✅        | ✅              | ❌      |
| **public**              | ✅        | ✅        | ✅              | ✅      |

## 2. Java 类的生命周期

### 2.1. 基本概念

1. 类的生命周期包括: 加载 --> 验证 --> 准备 --> 解析 --> 初始化 --> 使用 --> 卸载

2. **类只会被加载一次**, 即使 `new` 了多个对象, 也不会重复加载,

3. 类的加载是个连续的过程, 加载完就会进入验证, 准备等阶段

4. 类的初始化 vs 对象的初始化

   - 类初始化是 JVM 处理静态变量和静态代码块的过程, 发生在类的生命周期中, 类的初始化只执行一次（类第一次被加载时）

   - 对象初始化是创建对象并赋值实例变量的过程, 发生在实例化阶段（`new` 关键字）

5. JVM 不会在程序启动时一次性加载所有类, 而是按需加载, 触发类加载的条件：

   - 创建类的实例（`new` 操作）

   - 访问类的静态成员（静态变量、静态方法）
     - 静态变量/方法属于**类级别**，JVM 在访问它之前必须确保类已经被加载

   - 调用 Class.forName("类名") 反射加载: `Class.forName()` 直接强制 JVM 加载并初始化该类

   - 子类初始化时，父类会先被初始化

引用类的静态常量（`static final`）：不会触发类的加载, 因为 `static final` 常量在编译时已确定, 编译器会直接替换值

```java
class A {
    static final int CONST = 100;  // 常量
    static int value = 10;         // 静态变量
    static {
        System.out.println("A 类初始化");
    }
}

public class Test {
    public static void main(String[] args) {
        System.out.println(A.CONST);  // 不会触发 A 的加载
        System.out.println(A.value);  // 触发 A 的加载
    }
}

```

### 2.2. 过程

#### 2.2.1. 加载

- JVM 通过类的全限定名找到 `.class` 文件，并读取字节码

- 创建 `java.lang.Class` 对象（这只是一个描述类的对象，而不是类的实例！）

#### 2.2.2. 验证

#### 2.2.3. 准备

为类的静态变量（`static` 变量）分配内存，并赋默认值（不会执行具体的赋值操作）, 这里的 "默认值" 不是程序员写的值，而是 JVM 规定的默认初值

```java
public class Test {
    static int a = 10;  // 在 "准备" 阶段 a = 0
    static final int b = 20; // b 是编译期常量，直接在 class 文件常量池中存储
}
```

#### 2.2.4. 解析 动态链接

在 Java 中，类、方法、变量等在 `.class` 文件中以符号引用的形式**存储在常量池**中。当 JVM 运行到 解析阶段 时，JVM 会**根据符号引用找到实际的内存地址**，并替换掉符号引用。

符号引用 是 `.class` 文件中使用的逻辑地址，用于表示：

1. 类和接口（如 `"java/lang/String"`）
2. 字段（静态变量、实例变量）（如 `java/lang/System.out`）
3. 方法（实例方法、静态方法）（如 `java/lang/String.length()`）

```java
String s = "Hello";
int len = s.length();
```

在 `.class` 文件的常量池中：

```
#1 = Class              #2 // java/lang/String
#2 = Utf8               java/lang/String
#3 = Methodref          #1.#4 // String.length()I
#4 = NameAndType        #5:#6 // length:()I
#5 = Utf8               length
#6 = Utf8               ()I
```

这里的 `#3 = Methodref` 代表 `"java/lang/String.length()"` 方法的符号引用

**为什么要用符号引用，而不是一开始就存储内存地址？**

如果一开始就存储内存地址, 就意味着 **编译时**（而非运行时）就已经确定了一些关键的信息, 

函数、变量地址已经确定, 无法加载动态库（DLL、so）, 不同操作系统的 `syscall` 地址不同也会导致兼容性问题。

那 Java 还怎么实现跨平台呢? 就连 C, 大部分时候都是采用动态链接, 即一些标准库函数在编译后也只是符号连接, 在执行的时候动态链接阶段才会把符号引用换成内存地址, 

**C 语言的静态编译：地址是否确定？**

在 C 语言的静态编译 过程中，编译器和链接器（linker）会对程序进行地址分配，但这些地址是 相对地址（Relative Address），并不是 物理地址（Physical Address）。具体来说：

1. 编译阶段（Compilation）
   - C 源代码（`.c`）转换成 目标文件（`.o` 或 `.obj`），此时变量和函数的地址是 符号引用（Symbolic Reference），还没有实际地址。
2. 链接阶段（Linking）
   - 静态编译 时，链接器（Linker）会分配相对地址，并替换符号引用。
   - 可执行文件（`.exe` / ELF）中的地址是 虚拟地址（Virtual Address），而非物理地址。
3. 加载（Loading）
   - 操作系统（OS） 在运行 C 语言程序时，会使用 内存管理单元（MMU） 将虚拟地址映射到 实际物理地址。

所以若程序编译后直接存储物理地址, 是不现实的, 除非一个机器只运行特定的一个程序, 

## 3. Java 基本类型和包装类型的区别

包装类型 (也叫引用类型) 就是把基础值包装成一个类然后添加一些常用工具方法, 基础类型就是最基本的, 告诉编译器分配多大内存空间

>  注意：**基本数据类型存放在栈中是一个常见的误区！** 基本数据类型的存储位置取决于它们的作用域和声明方式。如果它们是局部变量，那么它们会存放在栈中；如果它们是成员变量，那么它们会存放在堆/方法区/元空间中。

## 4. 自动装箱与拆箱

**装箱**：将基本类型用它们对应的引用类型包装起来；

**拆箱**：将包装类型转换为基本数据类型；调用包装类型对象的 `valueOf()`方法

```java
Integer i = 10;  //装箱
int n = i;   //拆箱
```

## 5. 泛型

**泛型类（需要显式声明）**

```java
class Box<T> {
    private T value;
    public Box(T value) { this.value = value; }
}

// 使用时必须写 <Integer>
Box<Integer> box = new Box<>(123);
```

**泛型方法（自动推断）**

```java
public <T> void print(T value) {
    System.out.println(value);
}

print(123);      // 自动推断 T = Integer
print("Hello");  // 自动推断 T = String
```

上面的函数声明也可以改写为:
```java
public <T> T print(T value) {
    System.out.println(value);
}
```

意思是, 函数 print 接受的参数值类型为 T, 返回值类型也是 T, 

```java
String str = print("Hello, Generics!");  // 传入 String
Integer num = print(100);                // 传入 Integer
Double decimal = print(99.99);           // 传入 Double
```

**泛型方法可以定义多个类型参数**

```java
// 泛型方法可以定义多个类型参数
public static <T, U> void showPair(T first, U second) {
    System.out.println("First: " + first + ", Second: " + second);
}

showPair("Age", 25);     // String 和 Integer
showPair(3.14, true);    // Double 和 Boolean
showPair('A', "Apple");  // Character 和 String

// 输出
First: Age, Second: 25
First: 3.14, Second: true
First: A, Second: Apple
```



```bash
curl -X POST "http://localhost:8080/api/posts" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0dXNlciIsInVzZXJJZCI6MSwiaWF0IjoxNzM5NjczNjI1LCJleHAiOjE3Mzk3NjAwMjV9.T4CYnCRlVidX0V2K8ag5ETINSH-YMmporfqC8fLNQdo" \
     -d '{
           "title": "My First Post",
           "content": "This is a test post content."
         }' -v

curl -X POST "http://localhost:8080/api/posts/user/1" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0dXNlciIsInVzZXJJZCI6MSwiaWF0IjoxNzM5NjczNjI1LCJleHAiOjE3Mzk3NjAwMjV9.T4CYnCRlVidX0V2K8ag5ETINSH-YMmporfqC8fLNQdo" -v
```

