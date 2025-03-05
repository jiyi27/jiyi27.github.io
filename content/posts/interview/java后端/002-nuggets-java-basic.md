---
title: Java 基础八股文
date: 2025-02-15 10:30:20
categories:
 - 面试
tags:
 - 面试
 - 八股文
 - 零碎知识
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

   - 访问类的静态成员（静态变量、静态方法 类级别）
     
- 调用 Class.forName("类名") 反射加载: `Class.forName()` 直接强制 JVM 加载并初始化该类
  
- 子类初始化时，父类会先被初始化

引用类的静态常量（`static final`）：不会触发类的加载, 因为 `static final` 常量在编译时已确定, 编译器会直接替换值

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

## 6. Lambda 表达式

把一个字符串转成整数，正常情况下可能要写一个完整的函数：

```java
interface Converter {
    int convert(String s);
}

class MyConverter implements Converter {
    public int convert(String s) {
        return Integer.parseInt(s);
    }
}
```

但用 Lambda 表达式，可以简化为一行：

```java
Converter converter = (s) -> Integer.parseInt(s);
```

> 为什么 `(s) -> Integer.parseInt(s)` 可以赋值给 `Converter`?
>
> Converter 是一个接口，里面有一个方法叫 convert, 任何实现这个接口的东西，都必须实现这个方法, Lambda 表达式 `(s) -> Integer.parseInt(s)` 正好匹配 Converter 接口里 convert 方法的签名, 因为这个 Lambda 表达式完全符合 Converter 接口的要求，Java 允许把它直接赋值给 Converter 类型的变量。换句话说，`(s) -> Integer.parseInt(s)` 就像是一个临时的、匿名的 Converter 实现

## 7. 函数式接口

Java 中有两种接口,  普通接口 和 函数式接口, 普通接口用于定义**一组**相关的行为规范, 通常用于面向对象编程中的抽象和多态, 通过 implements 关键字由类显式实现, 函数式接口专为函数式编程设计, 表示**单一**功能的抽象, 通常通过 Lambda 表达式、方法引用或匿名内部类实现, 不需要显式定义一个完整的类

假设我们定义一个简单的函数式接口 Calculator，用于表示两个数的计算操作：

```java
@FunctionalInterface // 可选注解，确保接口只有一个抽象方法
interface Calculator {
    int calculate(int a, int b);
}
```

使用 Lambda 表达式实现:

```java
Calculator addition = (a, b) -> a + b;
System.out.println("加法结果: " + addition.calculate(5, 3)); // 输出: 加法结果: 8
```

使用方法引用实现:

```java
public class Main {
    public static int add(int a, int b) {
        return a + b;
    }

    public static void main(String[] args) {
        Calculator addition = Main::add;
        System.out.println("加法结果: " + addition.calculate(5, 3)); // 输出: 加法结果: 8
    }
}
```

使用匿名内部类实现:

```java
public class Main {
    public static void main(String[] args) {
        // 使用匿名内部类实现减法
        Calculator subtraction = new Calculator() {
            @Override
            public int calculate(int a, int b) {
                return a - b;
            }
        };
        System.out.println("减法结果: " + subtraction.calculate(5, 3)); // 输出: 减法结果: 2
    }
}
```

Java 8 提供了一些常用的内置函数式接口，主要在 `java.util.function` 包中：

| 函数式接口       | 抽象方法            | 作用                                 |
| ---------------- | ------------------- | ------------------------------------ |
| `Consumer<T>`    | `void accept(T t)`  | 只接收参数，没有返回值               |
| `Supplier<T>`    | `T get()`           | 不接收参数，返回一个值               |
| `Function<T, R>` | `R apply(T t)`      | 接收一个参数，返回一个结果           |
| `Predicate<T>`   | `boolean test(T t)` | 进行条件判断，返回 `true` 或 `false` |

`Function<T, R>` 也是函数式接口, 并不是什么高级的东西, 只不过添加了泛型, 定义如下:

```java
@FunctionalInterface
public interface Function<T, R> {
    // 唯一抽象方法
    R apply(T t);

    // 默认方法：函数组合
    default <V> Function<V, R> compose(Function<? super V, ? extends T> before) {
        Objects.requireNonNull(before);
        return (V v) -> apply(before.apply(v));
    }

    ...
}
```

可以看到 `Function<T, R>` 只有一个抽象方法 `R apply(T t)`, 也就是说实现了这个方法的 lambda 或者其他类, 都算是实现了该接口, 比如:

```java
Function<Double, Double> addTax = price -> price * 1.13; // 加13%的税
double priceWithTax = addTax.apply(discountedPrice);
System.out.println("折扣后加税价: " + priceWithTax); // 输出: 90.4
```

> 泛型在 java 中有三种情况可以用: 类, 接口, 方法

## 8. 方法引用

当你的 Lambda 表达式只是调用一个**已经存在的方法**时，可以用方法引用来代替，简单来说，方法引用是 Lambda 表达式的“快捷方式”

```
类名::静态方法
对象名::实例方法
类名::实例方法（特殊情况）
类名::new（构造方法引用）
```

类名::静态方法

```java
// 使用 Lambda 表达式
Function<String, Integer> lambdaFunc = s -> Integer.parseInt(s);

// 使用方法引用, 类名::静态方法
Function<String, Integer> methodRefFunc = Integer::parseInt;

// 测试
System.out.println(lambdaFunc.apply("100")); // 输出 100
System.out.println(methodRefFunc.apply("200")); // 输出 200
```

对象名::实例方法

```java
String str = "hello";

// 使用 Lambda 表达式
Runnable lambda = () -> System.out.println(str.toUpperCase());

// 使用方法引用, 对象名::实例方法
Runnable methodRef = str::toUpperCase;

// 执行
lambda.run(); // 输出 HELLO
methodRef.run(); // 输出 HELLO
```

## 9. 项目中哪里用到了泛型?

```java
public class PageDTO<T> {
    private List<T> content;
    private int pageNumber;
    private long totalElements;
    private boolean hasNext;
}

public class PageConverter {
    public <T, DTO> PageDTO<DTO> convertToPageDTO(Page<T> entityPage, Function<T, DTO> converter) {
        List<DTO> dtoList = entityPage.getContent().stream()
                .map(converter)
                .collect(Collectors.toList());

        PageDTO<DTO> pageDTO = new PageDTO<>();
        pageDTO.setContent(dtoList);
        pageDTO.setPageNumber(entityPage.getNumber());
        pageDTO.setTotalElements(entityPage.getTotalElements());
        pageDTO.setHasNext(entityPage.hasNext());

        return pageDTO;
    }
}

public PageDTO<PostDTO> getUserPosts(Long userId, int page, int size) {
    // 按创建时间降序排序，获取分页对象
    Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));

    // 查询该用户发布的帖子
    Page<Post> postPage = postRepository.findByUserIdAndStatus(userId, 1, pageable);

    // 查询该用户点赞过的帖子 ID
    List<Long> likedPostIds = postLikeRepository.findPostIdsByUserId(userId);

    return pageConverter.convertToPageDTO(postPage,
            post -> convertToDTO(post, likedPostIds.contains(post.getId())));
}
```

这段代码的作用是：
- 从 `entityPage` 中获取当前页的实体列表（`List<T>`）
- 使用 `converter` 函数将每个实体 `T` 转换为对应的 `DTO` 对象
- 将转换后的结果收集到一个新的 `List<DTO>` 中

假设：
- `T` 是 `User`（实体类），有字段 `id` 和 `name`
- `DTO` 是 `UserDTO`（数据传输对象），有字段 `userId` 和 `fullName`
- `converter` 定义为：`user -> new UserDTO(user.getId(), user.getName())`

如果 `entityPage.getContent()` 返回 `[User(1, "Alice"), User(2, "Bob")]`：
1. `stream()` 创建一个流：`[User(1, "Alice"), User(2, "Bob")]`
2. `map(converter)` 转换为：`[UserDTO(1, "Alice"), UserDTO(2, "Bob")]`
3. `collect(Collectors.toList())` 得到：`List<UserDTO>`，包含 `[UserDTO(1, "Alice"), UserDTO(2, "Bob")]`

最终，`dtoList` 是一个包含转换后 `UserDTO` 对象的列表

## 10. 反射

