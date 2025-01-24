---
title: C++ Operator Overloading
date: 2023-05-22 23:03:12
categories:
 - c++
 - basics
tags:
 - c++
---

## 1. Operators as functions

Consider the following example:

```cpp
int x { 2 };
int y { 3 };
std::cout << x + y << '\n';
```

When you see the expression `x + y`, you can translate this in your head to the function call `operator+(x, y)` (where `operator+` is the name of the function).

Now consider what happens if we try to add two objects of a program-defined class:

```cpp
Mystring string1 { "Hello, " };
Mystring string2 { "World!" };
std::cout << string1 + string2 << '\n';
```

What would you expect to happen in this case? The intuitive expected result is “Hello, World!” . However, because `Mystring` is a program-defined type, the compiler does not have a built-in version of the **plus operator** that it can use for `Mystring` operands. So in this case, it will give us an error. In order to make it work like we want, we’d need to write an **overloaded function** to tell the compiler how the `+` operator should work with two operands of type `Mystring`. 

## 2. Overloading the arithmetic operators using friend functions

使用 friend function 的好处是我们可以直接访问类的私有成员, 另外注意 friend function 并不是类的成员函数, 

```cpp
#include <iostream>

class Cents {
private:
	int m_cents {};

public:
	Cents(int cents) : m_cents{ cents } { }

	// add Cents + Cents using a friend function
  // 另外friend function并不是类的成员函数, 但你仍可以在类里面实现它 而不是像我们这样在外面实现
  // 如果是成员函数重载, 这里只用一个参数就行了, 因为*this会默认为左操作数, 具体文章下面部分会讲
	friend Cents operator+(const Cents& c1, const Cents& c2);

	int getCents() const { return m_cents; }
};

// note: this function is not a member function!
// 可以看到, 在类里已经声明的性质(friend, static, virtual) 不用再在外面声明了
Cents operator+(const Cents& c1, const Cents& c2) {
	// use the Cents constructor and operator+(int, int)
	// we can access m_cents directly because this is a friend function
	return c1.m_cents + c2.m_cents;
}

int main() {
	Cents cents1{ 6 };
	Cents cents2{ 2 };
	Cents centsSum{ cents1 + cents2 };
	std::cout << "I have " << centsSum.getCents() << " cents.\n";
	return 0;
}
```

### Not everything can be overloaded as a friend function

The assignment (=), subscript ([]), function call (()), and member selection (->) operators must be overloaded as member functions, because the language requires them to be.

## 3. Overloading operators using normal functions

Using a friend function to overload an operator is convenient because it gives you direct access to the internal members of the classes you’re operating on. However, if you don’t need that access, you can write your overloaded operators as normal functions. 这个normal function既不是friend function, 也不是member function. 

```cpp
#include <iostream>

class Cents {
private:
  int m_cents{};

public:
  Cents(int cents) : m_cents{ cents } {}

  int getCents() const { return m_cents; }
};

// note: this function is not a member function nor a friend function!
// 注意哦, 这个函数既不是friend function, 也不是成员函数
Cents operator+(const Cents& c1, const Cents& c2) {
  // use the Cents constructor and operator+(int, int)
  // we don't need direct access to private members here
  return Cents{ c1.getCents() + c2.getCents() };
}

int main() {
  Cents cents1{ 6 };
  Cents cents2{ 8 };
  Cents centsSum{ cents1 + cents2 };
  std::cout << "I have " << centsSum.getCents() << " cents.\n";
  return 0;
}
```

Because the **normal and friend functions** work almost identically (they just have different levels of access to private members), we generally won’t differentiate them. The one difference is that the friend function declaration inside the class serves as a prototype as well. With the normal function version, you’ll have to provide your own function prototype:

Cents.h:

```cpp
#ifndef CENTS_H
#define CENTS_H

class Cents {
private:
  int m_cents{};

public:
  Cents(int cents)
    : m_cents{ cents }
  {}

  int getCents() const { return m_cents; }
};

// Need to explicitly provide prototype for operator+ so uses of operator+ in other files know this overload exists
Cents operator+(const Cents& c1, const Cents& c2);
#endif
```

## 4. Overloading operators using member functions

You learned how to overload the arithmetic operators using **friend functions**. You also learned you can overload operators as **normal functions**. Many operators can be overloaded in a different way: as a **member function**.

Overloading operators using a member function is very similar to overloading operators using a friend function. When overloading an operator using a member function:

- The overloaded operator must be added as a member function of the left operand.
- The left operand becomes the implicit *this object. (比如`+`需要左右两个操作数, 如果你用成员函数来重载它, 那重载函数`operator+`只需要一个参数即`+`右边的操作数, 左边的默认为`*this`, 可以看下面的实现, 注意与上面friend function对比)
- All other operands become function parameters.

注意与上面friend function的实现做对比:

```cpp
#include <iostream>

class Cents {
private:
    int m_cents {};

public:
    Cents(int cents) : m_cents { cents } { }
  
    // Overload Cents + int
    Cents operator+ (int value);
    int getCents() const { return m_cents; }
};

// note: this function is a member function!
// the cents parameter in the friend version is now the implicit *this parameter
// 只有一个参数~, 和friend function一样, 可以访问私有成员, 因为人家是成员函数啊, 肯定可以访问
Cents Cents::operator+ (int value) {
    return Cents { m_cents + value };
}

int main() {
	Cents cents1 { 6 };
	Cents cents2 { cents1 + 2 };
	std::cout << "I have " << cents2.getCents() << " cents.\n";
	return 0;
}
```
