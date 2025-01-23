---
title: Basic Syntax - TypeScript
date: 2024-11-29 09:50:02
tags:
  - typescript
---

**Types**

JavaScript has three very commonly used [primitives](https://developer.mozilla.org/en-US/docs/Glossary/Primitive): `string`, `number`, and `boolean`. 

TypeScript also has a special type, `any`, that you can use whenever you don’t want a particular value to cause typechecking errors.

**Type Annotations on Variables**

When you declare a variable using `const`, `var`, or `let`, you can **optionally** add a type annotation to explicitly specify the type of the variable:

```ts
let myName: string = "Alice";
```

> In most cases, though, this isn’t needed. Wherever possible, TypeScript tries to automatically *infer* the types in your code. 

**Object Types**

Apart from primitives, the most common sort of type you’ll encounter is an *object type*. 

```ts
// The parameter's type annotation is an object type
function printCoord(pt: { x: number; y: number }) {
  console.log("The coordinate's x value is " + pt.x);
  console.log("The coordinate's y value is " + pt.y);
}
printCoord({ x: 3, y: 7 });
```

> Here, we annotated the parameter with a type with two properties - `x` and `y` - which are both of type `number`. You can use `,`or `;` to separate the properties, and the last separator is optional either way.

对象类型更常用的写法是直接结构其属性:
```ts
// 使用解构语法的对象类型参数
function printCoord({ x, y }: { x: number; y: number }) {
  console.log(`x坐标是: ${x}`);
  console.log(`y坐标是: ${y}`);
}

// 或者下面这样
interface Point {
  x: number;
  y: number;
  label?: string; // 可选属性使用 ?
}

function printPoint({ x, y, label = "默认点" }: Point) {
  console.log(`${label} - 坐标(${x}, ${y})`);
}
```

> 注意, 上面的例子包含两个语法, 首先是类型标注, 就像其它静态语言, 需要标注参数类型, 只不过 ts 标注参数类型的方式有很多种, 比如使用匿名对象, 其次还使用了另一个语法, 即 destructuring assignment, 直接把属性抽取出来, 

**Type Aliases**

We’ve been using ***object types*** and *union types* by writing them directly in **type annotations**. This is convenient, but it’s common to want to use the same type more than once and refer to it by a single name.

```ts
type Point = {
  x: number;
  y: number;
};
 
// Exactly the same as the earlier example
function printCoord(pt: Point) {
  console.log("The coordinate's x value is " + pt.x);
  console.log("The coordinate's y value is " + pt.y);
}
```

**Interfaces**

```ts
interface Point {
  x: number;
  y: number;
}
 
function printCoord(pt: Point) {
  console.log("The coordinate's x value is " + pt.x);
  console.log("The coordinate's y value is " + pt.y);
}
 
printCoord({ x: 100, y: 100 });
```

Just like when we used a type alias above, the example works just as if we had used an anonymous object type. TypeScript is only concerned with the *structure* of the value we passed to `printCoord` - it only cares that it has the expected properties. Being concerned only with the structure and capabilities of types is why we call TypeScript a *structurally typed* type system.

> TypeScript 使用结构类型系统(structural typing)，而大多数传统语言如 Java、C++ 使用名义类型系统(nominal typing) 
>
> ```ts
> // TypeScript中，两个类型的结构相同就被认为是兼容的
> interface Person {
>     name: string;
>     age: number;
> }
> 
> class Student {
>     name: string;
>     age: number;
>     constructor(name: string, age: number) {
>         this.name = name;
>         this.age = age;
>     }
> }
> 
> // 虽然 Student 类并没有显式实现 Person 接口
> // 但因为结构相同，所以这是允许的
> let person: Person = new Student("张三", 18);
> ```

---

**Destructuring Assignment  & Type Annotations**

基础的 Destructuring Assignment 用法:

```ts
const person = {
  name: "张三",
  age: 25
};

// Destructuring Assignment
// You cannot change the 'name' and 'age' to other world
const { name, age } = person;
```
进阶用法, 放在函数参数中, 
```tsx
// 使用 对象类型 标注 参数类型, 注意这里没有使用 destructuring assignment
// { name: string, age: number }: Object Type
function greet(person: { name: string, age: number }) {
  console.log(`你好，${person.name}`);
}

// 使用 对象类型 标注 参数类型, 且使用 destructuring assignment 解构对象类型中的属性
function greet({ name, age }: { name: string, age: number }) {
  console.log(`你好，${name}`);
}
```

next.js 也很经常在函数参数中使用 destructuring assignment 和对象类型标注:

```ts
export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <div>{children}</div>
  );
}
```

`{ children }: { children: React.ReactNode }` 使用了 TypeScript 的解构赋值（Destructuring Assignment）和类型注解的组合:

1. `{ children }` 是参数解构：从传入的对象中提取 children 属性

2. `: { children: React.ReactNode }` 是类型注解：定义了参数对象的类型

如果使用 `children : { children: React.ReactNode }` 是不正确的, 这是因为：

- 原始写法 `{ children }` 表示接收一个对象并解构出其 children 属性
- 如果改成 `children`，就变成了直接接收一个名为 children 的参数，其类型被声明为一个包含 children 属性的对象

```ts
// 原始写法
function Layout({ children }: { children: React.ReactNode }) {
  console.log(typeof children); // 可能是 object（React元素）
  return <div>{children}</div>; // 直接使用 children
}

// 修改后写法
function Layout(children: { children: React.ReactNode }) {
  console.log(typeof children); // 一定是 object
  return <div>{children.children}</div>; // 需要用 children.children
}
```

可是为什么要多此一举呢? 直接 `children: React.ReactNode` 当参数不行吗, 

答案是当然可以, 但是在 React 中，我们通常使用第一种写法（对象解构），原因是：

1. 这是 React 的约定。props 总是以对象的形式传递给组件，包括 children 在内
2. 如果之后需要添加其他 props，用对象解构的方式更容易扩展：

```ts
// 更容易添加新的 props
function Layout({ 
  children,
  title,
  className 
}: { 
  children: React.ReactNode;
  title?: string;
  className?: string;
}) {
  return (
    <div className={className}>
      <h1>{title}</h1>
      {children}
    </div>
  );
}
```

如果用直接参数的方式，当需要添加新的 props 时就需要改变整个参数结构。所以虽然一开始看起来是"多此一举"，但从长远来看这种写法更有优势。
