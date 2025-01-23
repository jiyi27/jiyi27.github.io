---
title: Typing in Programming Language
date: 2023-11-28 20:30:17
categories:
 - other
tags:
 - c
 - java
 - golang
 - python
 - javascript
---

## 1. Compiled vs interpreted language

Programming languages are for humans to read and understand. The program (source code) must be translated into machine language so that the computer can execute the program. **The time when this translation occurs** depends on whether the programming language is a **compiled language** or an **interpreted language**. Instead of translating the source code into machine language before the executable file is created, an interpreter converts the source code into machine language at the same time the program runs. So you can't say a language doesn’t have compilation step, because any language needs to be translated to machine code.  

## 2. Statically vs dynamically typing

Also know as statically/dynamically typed, **static/dynamic language**. 

Static Typing:

- In statically typed languages, the type of a variable is known at compile time.
- The programmer must explicitly declare the data type of each variable.
- Examples of statically typed languages include Java, C, C++, and Go.

- Static typing allows for early detection of type-related errors during the compilation process.

Dynamic Typing:

- In dynamically typed languages, the type of a variable is determined at runtime.
- The programmer does not need to explicitly declare the data type of each variable.
- Examples of dynamically typed languages include Python, JavaScript, Ruby, and PHP.
- Type checking occurs during runtime, which means that type-related errors may only be discovered when the code is executed.

For example in Java:

```
String str = "Hello";  //statically typed as string
str = 5;               //would throw an error since java is statically typed
```

Whereas in a **dynamically typed language** the type is *dynamic*, meaning after you set a variable to a type, you CAN change it. That is because typing is associated with the value rather than the variable. For example in Python:

```
str = "Hello" # it is a string
str = 5       # now it is an integer; perfectly OK
```

## 3. Strong vs weak typing

The strong/weak typing in a language is related to **implicit type conversions** (partly taken from @Dario's answer):

For example in Python:

```
str = 5 + "hello" 
# would throw an error since it does not want to cast one type to the other implicitly. 
```

whereas in PHP:

```
$str = 5 + "hello"; // equals 5 because "hello" is implicitly casted to 0 
// PHP is weakly typed, thus is a very forgiving language.
```

Static typing allows for checking type correctness at compile time. Statically typed languages are usually compiled, and dynamically typed languages are interpreted. Therefore, dynamicly typed languages can check typing at run time.

Source: https://stackoverflow.com/a/34004765/16317008

## 4. Conclusion

Dynamically typing languages (where type checking happens at run time) can also be strongly typed (Python for example). 

Note that in dynamically checking languages, **values have types**, not variables (have types). Whereas, in statically checking languages, variables have types. 

>*Static/Dynamic Typing* is about **when** type information is acquired (Either at compile time or at runtime)
>
>*Strong/Weak Typing* is about **how strictly** types are distinguished (e.g. whether the language tries to do an implicit conversion from strings to numbers).