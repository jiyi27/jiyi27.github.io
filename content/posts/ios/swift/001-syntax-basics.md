---
title: Swift Basic Syntax and Data types
date: 2024-05-15 22:03:35
categories:
 - ios
---

# 1. Implicit returns SE-0255

This is a feature in Swift (SE-0255) that, for the sake of syntactic conciseness, allows the `return` keyword to be omitted when a method, computed property, or closure contains only a single expression.

```swift
// function or methods
// for: external parameter name or call it 'parameter label'
func greeting(for person: String) -> String {
    "Hello, " + person + "!"
}
print(greeting(for: "Dave"))
// Prints "Hello, Dave!"
```

```swift
// computed property
struct Circle {
    var radius: Double

    var circumference: Double {
        2 * .pi * radius
    }
}
```

```swift
// closures before
let square: (Int) -> Int = { (number: Int) in
    return number * number
}

// closures now, no returns
let square: (Int) -> Int = { number in
    number * number
}
```

## 2. Closure

### 2.1. Closure Syntax

```swift
{ (<#parameters#>) -> <#return type#> in
   <#statements#>
}
```

```swift
let coo = {() -> Void in
     print("closure")
}

// 因为 coo 无返回值也无参数, 可以简写为如下:
let coo = {
     print("closure")
}

// 带参数以及返回值的闭包
let foo = { (str:String) -> String in
    return str
}

coo()
print(foo("closure"))
```

### 2.2 Trailing Closure

If the last parameter to a function is a closure, Swift lets you use special syntax called *trailing closure syntax*. Rather than pass in your closure as a parameter, you pass it directly after the function inside braces.

```swift
func travel(action: () -> Void) {
    print("I'm getting ready to go.")
    action()
    print("I arrived!")
}
```

Because its last parameter is a closure, we can call `travel()` using trailing closure syntax like this:

```swift
travel() {
    print("I'm driving in my car")
}
```

In fact, because there aren’t any other parameters, we can eliminate the parentheses entirely:

```swift
travel {
    print("I'm driving in my car")
}
```

疑问: 参数 `action` 的类型是 `() -> Void`, 而 `print()` 接受了一个参数, 他们明明不是同一个类型, 为什么把 `print("I'm driving in my car")` 当参数传给了 `action` 呢?

解答: 当你调用 `travel` 并传递 `print("I'm driving in my car")` 时(如下)：

```swift
travel {
    print("I'm driving in my car")
}
```

你传递的是一个闭包。这个闭包的定义如下：

```swift
{
    print("I'm driving in my car")
}
```

这个闭包本身符合 `() -> Void` 类型，因为它不接受任何参数并且不返回任何值. 虽然闭包单个语句会自动加上 return, 但是 print 返回为空, 在此合法. 

References: [Trailing closure syntax - a free Hacking with Swift tutorial](https://www.hackingwithswift.com/sixty/6/5/trailing-closure-syntax)

### 2.3. Call function without parentheses

Only when you call a function with trailing closure, you can call it without parenthese. 

```swift
func getName(action: () -> Void) -> String {
    action()
    return "Jack"
}

// call function getName, and pass a closure which contains two expressions
let a = getName {
    print("hello...")
    print("Getting your name...")
}

print(a)
```

> 对于上面的代码, 因为闭包参数和返回值皆为空, 我们省略了一些东西, 完整的写法应该如下
>
> ```swift
> let a = getName {() -> Void in
>     print("hello...")
>     print("Getting your name...")
> }
> ```
>
> 如果你需要更完整的写法, 即不使用尾随闭包, 写法应该如下:
>
> ```swift
> let a = getName(action: { () -> Void in
>     print("hello...")
>     print("Getting your name...")
> })
> ```

Assume `getName` doesn't have parameters, you cannot omit the parentheses when call it:

```swift
func getName() -> String {
    return "Jack"
}

let a = getName // This is not calling getName, this is assign a function to variable 'a'
```

### 2.4. Trailing Closure in SwiftUI

VStack 的简单定义:

```swift
struct VStack<Content: View>: View {
    // 最后一个参数是闭包, 因此构建 VStack 可以使用 尾随闭包语法
    init(@ViewBuilder content: () -> Content)

    var body: some View {
        // 内部实现
    }
}
```

实际使用
```swift
var body: some View { 
    VStack { // 这里使用了尾随闭包, 因为这里没有给VStack构造函数传递其他参数, 因此调用时可省略括号()
        Text("Hello World")
        Text("Title")
    }
}

// 不使用尾随闭包
var body: some View {
    VStack(content:{
        Text("Hello World")
        Text("Title")
    })
}
```

`@ViewBuilder` 允许你在一个闭包中返回多个视图，并且会自动将这些视图组合成一个视图。比如：

```swift
VStack {
    Text("Hello, world!")
    Text("Hello World")
}
```

在这里，`VStack` 的闭包传递给了 `content` 参数。这个闭包内部包含了两个 `Text` 视图。`@ViewBuilder` 属性包装器会处理这个闭包，将其转换为单一的视图内容。

**具体工作机制**

1. **闭包定义**：你在 `VStack` 中传递了一个闭包，这个闭包包含多个视图。
2. **`@ViewBuilder` 处理**：`@ViewBuilder` 会将闭包中的多个视图组合成一个视图。它会将这些视图收集起来，构建一个包含所有子视图的视图树。
3. **传递组合视图**：最终，这个组合视图被传递给 `VStack`，作为其内容。

因此，尽管看起来你传递了多个视图（比如 `Text("Hello, world!")` 和 `Text("Hello World")`），但实际上你传递的是一个闭包，这个闭包在 `@ViewBuilder` 的帮助下返回了一个组合视图。

> `@ViewBuilder` 实际上是 Swift 中的一种 Result Builder, 后面会讲. 

综上:

```swift
struct ContentView: View {
    // 计算属性 省略 return
    var body: some View {
        // Trailing Closure 和 Result Builder 特性
        VStack {
            Text("Hello World")
            Text("Title")
        }
    }
}
```

References: [(一) SwiftUI - 声明式语法分析 - 掘金](https://juejin.cn/post/6897910455138779144)

### 2.5. Trailing Closure in SwiftUI

```swift
private func addItem() {
    withAnimation {
        let newItem = Item(context: viewContext)
        newItem.timestamp = Date()

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
```

`withAnimation` 是个函数,  最后一个参数是个闭包, 因此调用 withAnimation 时可以直接将参数闭包放于函数体内, 从而省略了圆括号, 这个语法上面讲了,  另外这里传递闭包的时候我们还省略的闭包的返回值, 因为当返回值为 Void, 原本的写法应该是这样:

```swift
withAnimation { () -> Void in
    // 闭包体
}
```

我们省略了闭包的返回值类型, 即如下:

```swift
withAnimation {
    // 闭包体
}
```

withAnimation 定义如下:

```swift
func withAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: () throws -> Result
) rethrows -> Result
```

可以看出withAnimation 有一个返回值, 切参数闭包 body 也有返回值, 但是上面我们调用  withAnimation 时却忽略了闭包的返回值, 这是因为 `<Result>` 可以为任何类型, 所以也可以为 Viod, 这是泛型的用法.

## 3. Functions

### 3.1. Variadic Parameters

A *variadic parameter* accepts zero or more values of a specified type. 

```swift
func total(_ numbers: Double...) -> Double {
    var total: Double = 0
    for number in numbers {
        total += number
    }
    return total
}
total(1, 2, 3) // 6
```

### 3.2. In-Out Parameters

Function parameters are constants by default. Trying to change the value of a function parameter from within the body of that function results in a compile-time error. 

If you want a function to modify a parameter’s value, and you want those changes to persist after the function call has ended, define that parameter as an *in-out parameter* instead.

```swift
func swapTwoInts(_ a: inout Int, _ b: inout Int) {
    let temporaryA = a
    a = b
    b = temporaryA
}

var someInt = 3
var anotherInt = 107
swapTwoInts(&someInt, &anotherInt)
print("someInt is now \(someInt), and anotherInt is now \(anotherInt)")
// Prints "someInt is now 107, and anotherInt is now 3"
```

## 4. Opaque type

A function or method that returns an opaque type **hides** its return value’s **type information**. Instead of providing a concrete type as the function’s return type, the return value is described in terms of the protocols it supports.

```swift

protocol Animal {
    func makeSound() -> String
}

struct Dog: Animal {
    func makeSound() -> String {
        return "Woof"
    }
}

struct Cat: Animal {
    func makeSound() -> String {
        return "Meow"
    }
}

// Although we know that it returns either a Cat or a Dog, the exact type is hidden.
func getAnimal() -> some Animal {
    return Dog()
}
```

```swift
var myCar: some Vehicle = Car()
myCar = Car() // 🔴 Compile error: Cannot assign value of type 'Car' to type 'some Vehicle'


var myCar1: some Vehicle = Car()
var myCar2: some Vehicle = Car()
myCar2 = myCar1 // 🔴 Compile error: Cannot assign value of type 'some Vehicle' (type of 'myCar1') to type 'some Vehicle' (type of 'myCar2')
```

- [Understanding the "some" and "any" keywords in Swift 5.7 - Swift Senpai](https://swiftsenpai.com/swift/understanding-some-and-any/)
- [How to use Swift's opaque types | Reintech media](https://reintech.io/blog/understanding-using-swifts-opaque-types)

## 6. Result Builders

```swift
func makeSentence1() -> String { 
     // single expression, implicit return
    "Why settle for a Duke when you can have a Prince?"
}

print(makeSentence1())
```

That works great, but what if had several strings we wanted to join together? Just like SwiftUI, we might want to provide them all individually and have Swift figure it out, however this kind of code won’t work:

```swift
// This is invalid Swift, and will not compile.
// func makeSentence2() -> String {
//     "Why settle for a Duke"
//     "when you can have"
//     "a Prince?"
// }
```

By itself, that code won’t work because Swift no longer understands what we mean. However, we could create a result builder that understands how to convert several strings into one string using whatever transformation we want, like this:

```swift
@resultBuilder
struct SimpleStringBuilder {
    static func buildBlock(_ parts: String...) -> String {
        parts.joined(separator: "\n")
    }
}
```

There’s nothing to stop us from using `SimpleStringBuilder.buildBlock()` directly, like this:

```swift
let joined = SimpleStringBuilder.buildBlock(
    "Why settle for a Duke",
    "when you can have",
    "a Prince?"
)

print(joined)
```

However, because we used the `@resultBuilder` annotation with our `SimpleStringBuilder` struct, we can also apply that to functions, like this:

```swift
@SimpleStringBuilder func makeSentence3() -> String {
    "Why settle for a Duke"
    "when you can have"
    "a Prince?"
}

print(makeSentence3())
```

References: [Result builders – available from Swift 5.4](https://www.hackingwithswift.com/swift/5.4/result-builders)



