---
title: JS 继承之 Prototype Chain 的意义
date: 2023-06-21 11:08:32
categories:
  - javascript
  - basics
tags:
  - javascript
---

## 1. Objects are values in Javascript

> `{}` 就是个空对象, `{}` 在 Python 里是个 dictionary, 当然 dictionary 也是个对象, 

在说继承之前还要提一下 JS 对象与其它语言不同的地方, 举个例子, 

```js
const student = {
  name: 'John',
  study: function () {
      return 'study'
  }
}

console.log(student)  // { name: 'John', study: [Function: study] }
student.age = 99 // 这里没有出错竟然!
console.log(student)  // { name: 'John', study: [Function: study], age: 99 }
```

在其它面向对象语言里, 如果我们尝试赋值或者访问对象不存在的 field就会报错, 在 JS 里并不会, 当你尝试读取不存在的 feild 的时候 (包括 prototype chain, 下面会讨论) 才会报错, 

原因是, JS 的对象与其它语言如 Java, Python不同, Java里对象的 fields 是有类决定的, 类似所有对象的蓝图, JS并不是,  JS里的对象不是由类创建的, 更像一个 map, 

我们知道 JS 的值分为两类, Primitive values: immutable, object values: mutable, 这里的 mutable 其实就是指 你可以随意给对象增加属性, 一个对象就是一个value, 

当尝试读取对象的属性时, 会触发 prototype chain, 看下面代码:

```js
const person = {
  name: 'Jack',
  sayHello: function () {
    console.log('hello from ' + this.name)
  },
}
// 注意: 通过对象属性 __proto__ 访问对象 prototype
const student = {
  age: 13,
  __proto__: person
}

console.log(student.name)     // student没有name属性, 通过prototype chain访问其他对象的name属性
console.log(student)         // { age: 13 }
student.name = 'John'       // 为 student 创建新属性 name
console.log(student.name)  // student 此时已有name属性 直接访问其name属性
console.log(student)      // { age: 13, name: 'John' }
student.sayHello()       // 因student无sayHello函数, 通过prototype chain查找sayHello函数, 找到后, sayHello中的this被替换为student
```

## 2. Prototype

### 2.1. Ways to access prototype

Every **object value** in JavaScript has a built-in property, which is called its `prototype`. The `prototype` is itself **an object value**, so the `prototype` will have its own `prototype`, making what's called a **prototype chain**. The chain ends when we reach a prototype that has `null` for its own prototype. 

关于prototype有一个迷惑的地方, 通过`obj.prototype`访问到的并不是上面我们讨论的prototype, 只能通过`obj.__proto__`和全局函数`Object.getPrototypeOf()`来获取一个对象的`prototype`属性:

```js
const person = {
    name: 'Jack',
    greet: function () {
        return 'Hi, I am' + this.name;
    }
}

console.log(person.prototype)
console.log(person.__proto__)
console.log(Object.getPrototypeOf(person))

// undefined
// [Object: null prototype] {}
// [Object: null prototype] {}
```

根据打印可以看出 `person.prototype`跟`person.__proto__`压根就不是一个东西, 

### 2.2. Prototype 的获取与赋值

`obj.__proto__` 不是访问对象 prototype 属性的标准方法, 因为有的browser可能没实现, 所以访问(只读)一般用`Object.getPrototypeOf(student)`, 通过创建该对象的时候为其 `__proto__` 属性赋值的方法给一个对象的 prototype 赋值, 如下: 

```js
const person = {
  name: 'Jack',
  sayHello: function () {
    console.log('hello from ' + this.name)
  },
}

const student = {
  age: 13,
  // Check the assignment here:
  __proto__: person
}

console.log(Object.getPrototypeOf(student))  // { name: 'Jack', sayHello: [Function: sayHello] }

// 或者创建对象后赋值, 
student.__proto__ = person
// 注意若student没有__proto__属性则这里自动为student创建__proto__并赋值, 赋值后我们就可以访问了
// 所以这和上面我们说的不要通过 `obj.__proto__`  访问一个对象的 prototype 并不矛盾
```

## 3. Prototype Chain 的意义

> Javascript is an object-based language, not a class-based language.

If you know Java or C++, you should be familiar with the inheritance concept. **In this programming paradigm**, a class is a blueprint for creating objects. If you want a new class to reuse the functionality of an existing class, you can create a new class that extends the existing class. This is called **classical inheritance**.

JavaScript doesn’t use **classical inheritance**. Instead, it uses **prototypal inheritance**. In prototypal inheritance, an object “inherits” properties from another object via the `prototype` linkage.

Prototype chain 的意义正是代替了传统语言中的继承机制, 只不过是对象之间的继承, 而不是类之间, 

## 4. Javascript 不存在真正的类

JS 不存在真正的类, 即使是ES6之后的类也不过是个语法糖 (syntactic sugar) 而已, 

```js
class Person {
    constructor(name) {
        this.name = name;
    }
    getName() {
        return this.name;
    }
}

console.log(typeof Person); //function
```


> Unlike other programming languages such as Java and C#, JavaScript classes are syntactic sugar over the **prototypal inheritance**. In other words, ES6 classes are just special functions. But class declarations are not **hoisted** like function declarations. 

上面提到 `obj.prototype` 和 `obj.__proto__` 不是一个东西, 当创建对象后 (除函数对象) 它们的 `obj.prototype` 是 `undefined`, 而创建函数对象后, 这个函数的`func.prototype`会被自动创建, 并且值为一个空对象`{}`:

```js
const func = function () {
    this.name = 'John';
}
const cap = {
    size: 36,
    price: '30CAD',
}

console.log(func.prototype); //{}
console.log(cap.prototype); //undefined
```

思考下面代码发生了什么:
```js
function Person(name) {
    this.name = name;
}

Person.prototype.getName = function () {
    return this.name;
};

console.log(Person.prototype); // { getName: [Function (anonymous)] }

const john = new Person("John Doe");
console.log(Object.getPrototypeOf(john)); // { getName: [Function (anonymous)] }

console.log(john); // Person { name: 'John Doe' }
console.log(john.getName()); // John Doe
```
第一步发生在定义函数Person时:

1. `Person.prototype` 被创建, 并被赋值为一个空对象`{}`

2. `Person.prototype `对象增加一个函数 `getName()`

此时 `Person.prototype `不再是个空对象, 而是有一个名为`getName`函数的对象`{ getName: [Function (anonymous)] }`

之后三步发生在调用`new Person("John Doe")`时:

3. 新创建空对象`{}`并赋值给john
4. 执行`john.__proto__ = Person.prototype`
5. 执行函数Person, 函数体里的 `this.name = name`变为 `john.name = name`

> 综上: The `john` object is an instance of the `Person` through **prototypal inheritance**. 

参考: 

- https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Objects/Object_prototypes
- https://stackoverflow.com/a/34948211/16317008
- https://www.javascripttutorial.net/es6/javascript-class/
