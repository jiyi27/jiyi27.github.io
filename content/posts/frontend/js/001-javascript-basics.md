---
title: Objects & Collections in Javascript
date: 2023-06-20 20:51:31
categories:
  - javascript
tags:
  - javascript
  - 前端开发
---

## 1. Javascript objects

在其他语言, 如C++, Java, 对象是一个类的实例(instance), 对象必须由对应类的constructor生成. 

可是在JS里面, 类的概念变得模糊了, 我很少用到 `new`, 但又有人说 “JavaScript is designed on a simple object-based paradigm”, I‘m confused now. 

什么是 variable, type, type 和 object 的关系是什么? 什么又是value? 我尝试在迷惑中找出答案:

> Javascript is dynamic language, which means values have types, not variables. 
>
> Values can have two main types: primitives (immutable), object. 

所以 object 是 data types 中的一种, 显然这和其他语言不一样, 那 object type 具体是什么呢? 

An object is a collection of properties, and a property is an association between a name (or key) and a value. A cup is an object, with properties. A cup has a color, a design, weight, a material it is made of, etc. The same way, JavaScript objects can have properties, which define their characteristics. 

杯子有颜色, 容量等属性, 颜色比如蓝色, 容量1000ml, `蓝色`, `1000ml`就是所谓的 value, 这个 value 有 type (type 可以是 object 或 primitives), 前者蓝色是string, 后者1000是number类型. `color="bule"` 这就是对象的一个属性. 突然感觉JS里的对象更像是其他语言里的类, 只是js的对象没有构造函数, 不能实例化. 

所以现在搞清楚了什么是 object type, 那就看看另外的一个 primitives type, 

## 2. Data types in JS

类型可以分为两大类 `primitive values` and `objects` (Java 的是 [primitive types 和 reference type](https://davidzhu.xyz/post/java/basics/006-variables-vs-references/))

**1. Primitive values** (**immutable datum** represented directly at the lowest level of the language)

+ Boolean type
+ Null type
+ Undefined type
+ Number type: 比如上面例子中, 杯子的property: 容量的value: 1000, 的type就是 Number type
+ String type: 比如上面例子中, 杯子的property: 颜色的value: blue, 的type就是 String type

**2. Objects** (collections of properties)

说白了 JS 中的对象就是个值, 只不过这个值的类型是对象, 到这也算是弄清了其中的关系, object, value, type, variable. 这一切从杯子开始举例, 便可以捋清关系. 变量有类型吗? 严格来说没有type, 是变量的值才有类型. 对象和变量的关系呢? 变量的值的类型可以是对象. 

```js
let person = {
    firstName:"John", 
    lastName:"Doe", 
    age:50, 
    eyeColor:"blue", 
    eat: (food)=>{}
};

// or
let person = new Object();
person.firstName = "John";
person.lastName = "Doe";
person.age = 50;
person.eyeColor = "blue";
```

**JS 的对象长得很像 json**, 所以在以后的学习中不要与json弄混. 

## 3. "everything is an object in Javascript", Really? 

No, not everything is an object in JavaScript. Many things that you interact with regularly (`strings`, `numbers`, `booleans`) are **primitives**, not **objects**. **Unlike objects, primitive values are immutable.** The situation is complicated by the fact that these primitives do have object wrappers (String, Number and Boolean); these objects have methods and properties while the primitives do not, but the primitives appear to have methods because JavaScript silently creates a wrapper object when code attempts to access any property of a primitive.

For example, consider the following code:

```js
var s = "foo";
var sub = s.substring(1, 2); // sub is now the string "o"
```

Behind the scenes, `s.substring(1, 2)` behaves as if it is performing the following (approximate) steps:

+ Create a wrapper String object from `s`, equivalent to using `new String(s)`
+ Call the `substring()` method with the appropriate parameters on the `String object` returned by step 1
+ Dispose of the `String` object
+ Return the string (primitive) from step 2.

A consequence of this is that while it looks as though you can assign properties to primitives, it is pointless because you cannot retrieve them:

```js
var s = "foo";
s.bar = "cheese";
alert(s.bar); // undefined
```

This happens because the property is effectively defined on a String object that is immediately discarded.'

Numbers and Booleans also behave this way. Functions, however, are fully-fledged objects, and inherit from `Object` (actually `Object.prototype`, but that's another topic). Functions therefore can do anything objects can, including having properties:

```js
function foo() {}
foo.bar = "tea";
alert(foo.bar); // tea
```

Original post: https://stackoverflow.com/a/9110389/16317008

## 4. JS Collections

> The key difference is that **Objects** only support string and Symbol keys where as **Maps** support more or less any key type. https://stackoverflow.com/a/37994079/16317008

- The keys of an `Object` are [`Strings`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String) or [`Symbols`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol), where they can be of any value for a `Map`.
- You can get the `size` of a `Map` easily, while you have to manually keep track of size for an `Object`.

These three tips can help you to decide whether to use a `Map` or an `Object`:

- Use maps over objects when keys are unknown until run time, and when all keys are the same type and all values are the same type.
- Use maps if there is a need to store primitive values as keys because object treats each key as a string whether it's a number value, boolean value or any other primitive value.
- Use objects when there is logic that operates on individual elements.

> It is useful to remember which operations on arrays mutate them, and which don’t. For example, `push`, `pop`, `reverse`, and sort will mutate the original array, but `slice`, `filter`, and `map` will create a new one.

References: [Keyed collections - JavaScript | MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Keyed_collections)