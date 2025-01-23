---
title: Pass by Value or Reference
date: 2023-11-28 23:02:06
categories:
 - other
tags:
 - c
 - java
 - golang
 - python
 - javascript
typora-root-url: ../../../static
---

## 1. Python

```python
def test_function(x, y):
    x += 1
    y.append(4)

def main():
    a = 1
    b = [2, 3]

    test_function(a, b)
    print("a =", a)
    print("b =", b)

main()
```

Output:

```python
a = 1
b = [2, 3, 4]
```

- If you pass a *mutable* object into a method, the method gets a reference to that same object and you can mutate it to your heart's delight, but if you rebind the reference in the method, the outer scope will know nothing about it, and after you're done, the outer reference will still point at the original object. 
  - integer, str are immutable objects in Python

- If you pass an *immutable* object to a method, you still can't rebind the outer reference, and you can't even mutate the object.

```shell
>>> def main():
...     n = 9001
...     print(f"Initial address of n: {id(n)}")
...     increment(n)
...     print(f"  Final address of n: {id(n)}")
...
>>> def increment(x):
...     print(f"Initial address of x: {id(x)}")
...     x += 1
...     print(f"  Final address of x: {id(x)}")
...
>>> main()
Initial address of n: 140562586057840
Initial address of x: 140562586057840
Final address of x: 140562586057968
Final address of n: 140562586057840
```

## 2. Javascript

```js
function changeStuff(a, b, c) {
  a = a * 10;
  b.item = "changed";
  c = {item: "changed"};
}

var num = 10;
var obj1 = {item: "unchanged"};
var obj2 = {item: "unchanged"};

changeStuff(num, obj1, obj2);

console.log(num);
console.log(obj1.item);
console.log(obj2.item);
```

This produces the output:

```none
10
changed
unchanged
```

## 3. Golang, Java, C++ & Javascript 

Python, Java, C++ and JS are all pass by value, but they do have references. When you assign or pass a reference-type, the copied value is still the value of the reference, namely the address, giving us the illusion of "pass by reference not value."

C++ has another application where passing const references is preferred to enhance efficiency. However, in Java, Python, and JS, references are passed every time, but they lack the concept of const references.

Actually Golang doesn't have reference type (all are values), reference type often refers to the maps, slice, channels and strings in Golang which are pointers themselves or a struct holding a pointer to the underlying data structure. 
