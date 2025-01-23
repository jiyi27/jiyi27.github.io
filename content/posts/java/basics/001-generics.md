---
title: Java Generics
date: 2023-08-05 18:44:52
categories:
 - Java
 - Basics
tags:
 - Java
---

## 1. Why Generics?

至于泛型提高类型安全性的话题, 暂不讨论, 这太哲学了, 只举例子, 没有泛型之前, 考虑如何实现一个容器(可以装所有的类型), 提示, 可以用 `Object` 类, 

具体实现可参考: [Java Array | 橘猫小八的鱼](https://davidzhu.xyz/2023/08/05/Java/Basics/000-array/), 

可以看出, 在 retrieve 数据的时候, 每次都需要 type cast, 这很麻烦也很容易出错, 也不优雅, 

使用泛型实现一个简单的容器, 如下:

```java
class MyContainer<T> {
    private static final int DEFAULT_CAPACITY = 10;
    private int size;
    private Object[] elements;

    public MyContainer() {
        elements = new Object[DEFAULT_CAPACITY];
        size = 0;
    }

    public void addItem(T element) {
        if (size < elements.length) {
            elements[size] = element;
            size++;
        } else {
            // Handle array resizing or throw an exception
        }
    }

    @SuppressWarnings("unchecked")
    public T get(int index) {
        if (index < 0 || index >= size) {
            // handle exception
        }
        return (T) elements[index];
    }
}

public class Main {
    public static void main(String []args){
        MyContainer<String> container = new MyContainer<>();
        container.addItem("Hello");
        // container.addItem(2); // this will cause error
        String str_1 = container.get(0); // no need to explicit cast
        System.out.println(str_1);
    }
}
```

此次学泛型主要是为了阅读源码, 常见符号:

- `E`: Element
- `K`: Key
- `N`: Number
- `T`: Type
- `V`: Value

S,U,V etc. - 2nd, 3rd, 4th types

## 2. Bounded Types

Oftentimes there are cases where we need to specify a generic type, but we want to control which types can be specified, rather than keeping the gate wide open. *Bounded types* can be used to restrict the bounds of the generic type by specifying the `extends` or the `super` keyword in the type parameter section to restrict the type by using an upper bound or lower bound, respectively. 

```java
<T extends UpperBoundType>
  
<T super LowerBoundType>
```

e.g., 

```java
public class GenericNumberContainer <T extends Number> {
  // ...
}

GenericNumberContainer<Integer> gn = new GenericNumberContainer<Integer>();
gn.setObj(3);
// Type argument String is not within the upper bounds of type variable T
GenericNumberContainer<String> gn2 = new GenericNumberContainer<String>();
```

## 3. Wildcards

In some cases, it is useful to write code that specifies an unknown type. The question mark (`?`) wildcard character can be used to represent an unknown type using generic code. **Wildcards can be used with parameters, fields, local variables, and return types**. However, it is a best practice to not use wildcards in a return type, because it is safer to know exactly what is being returned from a method.

Consider the case where we would like to write a method to verify whether a specified object exists within a specified `List`. We would like the method to accept two arguments: a `List` of unknown type as well as an object of any type. 

```java
public static <T> void checkList(List<?> myList, T obj){
        if(myList.contains(obj)){
            System.out.println("The list contains the element: " + obj);
        } else {
            System.out.println("The list does not contain the element: " + obj);
        }
}
```

**Oftentimes wildcards are restricted using upper bounds or lower bounds**. Much like specifying a generic type with bounds, for example, if we wanted to alter the `checkList` method to accept only `List`s that extend the `Number` type, 

```java
public static <T> void checkNumber(List<? extends Number> myList, T obj){

    if(myList.contains(obj)){
        System.out.println("The list " + myList + " contains the element: " + obj);
    } else {
        System.out.println("The list " + myList + " does not contain the 
element: " + obj);
    }
}
```

### 3.1. Wildcards vs Object

Now, since *Object* is the inherent super-type of all types in Java, we would be tempted to think that it can also represent an unknown type. In other words, *List<?>* and *List<Object>* could serve the same purpose. But they don't.

```java
public static void printListObject(List<Object> list) {    
    for (Object element : list) {        
        System.out.print(element + " ");    
    }        
}    

public static void printListWildCard(List<?> list) {    
    for (Object element: list) {        
        System.out.print(element + " ");    
    }     
}
```

Given a list of *Integer*s, say:

```java
List<Integer> li = Arrays.asList(1, 2, 3);
```

`printListObject(li)` will not compile, and we'll get this error:

```java
The method printListObject() is not applicable for the arguments (List<Integer>)
```

Whereas *`printListWildCard(li)`* will compile and will output *1 2 3* to the console.

## 3.2. Wildcards vs `T`

```java
// 指定集合元素只能是T 类型
List<T> list=new ArrayList<T>();
// 集合元素可以是任意类型, 这种没有意义, wildcard 经常用在方法的形参声明中, 在这只是为了说明用法
List<?> list=new ArrayList<?>();
```

`？`和 `T` 都表示不确定的类型，区别在于我们可以对 `T` 进行操作，但是对 `?` 不行：

```java
T t = operate();  // 可以
？ car = operate(); // 不可以
```

`T` 是一个 确定的 类型, 通常用于**泛型类**和**泛型方法**的**定义**, `？`是一个 不确定 的类型, 通常用于声明泛型方法的形参, 返回值, 或创建变量如`Class<?> xxx = cat.getClass()`, 

如果还无法理解可以参考: [java.lang.Object & java.lang.Class | 橘猫小八的鱼](https://davidzhu.xyz/2023/08/05/Java/Basics/002-reflection-object-class/)

## 4. Type Erasure

> Java generics only exit during compile time. Java的泛型基本上都是在编译器这个层次上实现的，在生成的 bytecode 中不包含泛型中的类型信息的，使用泛型的时候加上类型参数，在编译器编译的时候会discard，这个过程成为type erasure 

### 4.1. 通过两个例子证明Java类型的类型擦除

- **原始类型相等**

```java
public class Test {

    public static void main(String[] args) {

        ArrayList<String> list1 = new ArrayList<String>();
        list1.add("abc");

        ArrayList<Integer> list2 = new ArrayList<Integer>();
        list2.add(123);

        System.out.println(list1.getClass() == list2.getClass());
    }
}
```

- **通过反射添加其它类型元素**

```java
public class Test {

    public static void main(String[] args) throws Exception {

        ArrayList<Integer> list = new ArrayList<Integer>();

        list.add(1);  //这样调用 add 方法只能存储整形，因为泛型类型的实例为 Integer

        list.getClass().getMethod("add", Object.class).invoke(list, "asd");

        for (int i = 0; i < list.size(); i++) {
            System.out.println(list.get(i));
        }
    }
}
```

### 4.2. 类型擦除后保留的原始类型
在上面，两次提到了原始类型，什么是原始类型？

原始类型 就是擦除去了泛型信息, 最后在字节码中的类型变量的真正类型, 无论何时定义一个泛型，相应的原始类型都会被自动提供，类型变量擦除，并使用其bound type（unbounded type的变量用Object）替换, 

```java
public class Pair<T> {  
    private T value;  
    public T getValue() {  
        return value;  
    }  
    public void setValue(T  value) {  
        this.value = value;  
    }  
}  

// Pair的原始类型为
public class Pair {  
    private Object value;  
    public Object getValue() {  
        return value;  
    }  
    public void setValue(Object  value) {  
        this.value = value;  
    }  
}
```
因为在`Pair<T>`中，`T` 是一个无限定的类型变量，所以用`Object`替换，其结果就是一个普通的类，但如果类型变量是bound，那么原始类型就用第一个边界的类型变量类替换。

比如: Pair这样声明的话, 那么原始类型就是`Comparable` 

```java
public class Pair<T extends Comparable> {}
```

## 5. 类型擦除引起的问题及解决方法

### 5.1. 自动类型转换

因为类型擦除的问题，所以所有的泛型类型变量最后都会被替换为原始类型。

既然都被替换为原始类型，那么为什么我们在获取`get()`的时候，不需要进行强制类型转换呢？因为`get()`已经帮我们cast了. 

看下`ArrayList.get()`方法：

```java
public E get(int index) {
    Objects.checkIndex(index, size);
    return elementData(index);
}

E elementData(int index) {
    return (E) elementData[index];
}
```

### 5.2. 泛型类型变量不能是基本数据类型
```
ArrayList<int> arr; //error
ArrayList<Integer> arr;
```

不能用类型参数替换基本类型。就比如，没有`ArrayList<double>`，只有`ArrayList<Double>`。因为当类型擦除后，`ArrayList`的原始类型变为`Object`，但是`Object`类型不能存储`double`值，只能引用`Double`的值。

### 5.3. 泛型在静态方法和静态类中的问题

```java
public class Test2<T> {    
    public static T one;   //编译错误    
    public static  T show(T one){ //编译错误    
        return null;    
    }    
}
```
因为泛型类中的泛型参数的实例化是在定义对象的时候指定的，而静态变量和静态方法不需要使用对象来调用。对象都没有创建，如何确定这个泛型参数是何种类型，所以当然是错误的。


但是要注意区分下面的一种情况：
```java
public class Test2<T> {    
    public static <T >T show(T one){ //这是正确的    
        return null;    
    }    
}
```

因为这是一个泛型方法，在泛型方法中使用的T是自己在方法中定义的 T，而不是泛型类中的T

参考: 

- [Generics: How They Work and Why They Are Important](https://www.oracle.com/technical-resources/articles/java/juneau-generics.html)
-  https://www.cnblogs.com/wuqinglong/p/9456193.html
-  [聊一聊-JAVA 泛型中的通配符 T，E，K，V，？ - 掘金](https://juejin.cn/post/6844903917835419661)

