---
title: Java Array
date: 2023-08-05 16:14:53
categories:
 - Java
 - Basics
tags:
 - Java
---

两点很重要:

- **Arrays are objects in Java**, we can find their length using the object property `length`. This is different from C/C++, where we find length using `sizeof()`.
- The length of an array is established when the array is created. **After creation, its length is fixed**.  However, an array reference can be made to point to another array.

---

数组进行排序的话，可以使用 Arrays 类提供的 `sort()` 方法:

```java
int[] anArray = new int[] {5, 2, 1, 4, 8};
Arrays.sort(anArray);
```

有时要从数组中查找某个具体的元素, 如果数组提前进行了排序就可以使用二分查找法, 
```java
int[] anArray = new int[] {1, 2, 3, 4, 5};
int index = Arrays.binarySearch(anArray, 4);
```

---
在没有范型出现的时候, 容器一般利用 `Object` 实现, 缺点显而易见, 每次取出数据都需要强制转换, 这就容易出现因忘记显示转换类型或转换错类型而导致的类型相关错误, 即降低了 Java 的 type safety, 如下: 
```java
public class Main {
    public static void main(String []args){
        MyContainer container = new MyContainer(6);
        container.addItem("Hello");
        container.addItem(42);
        container.addItem(true);
      
      	// We have to cast and must cast the correct type to avoid ClassCastException!
        String str = (String) container.getItem(0);
        int number = (int) container.getItem(1);
        boolean bool = (boolean) container.getItem(2);

        System.out.println(str);
        System.out.println(number);
        System.out.println(bool);
    }
}

class MyContainer {
    private Object[] items;
    private int size;

    public MyContainer(int capacity) {
        size = 0;
        items = new Object[capacity];
    }

    public int getSize() {
        return size;
    }

    public void addItem(Object item) {
        if (size < items.length) {
            items[size] = item;
            size++;
        } else {
            // Handle array resizing or throw an exception
            System.out.println("Error: array is full.");
        }
    }

    public Object getItem(int index) {
        if (index >= 0 && index < items.length) {
            return items[index];
        } else {
            // Handle index out of bounds or throw an exception
            return null;
        }
    }
}
```

