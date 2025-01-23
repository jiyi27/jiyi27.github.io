---
title: Swift Functions
date: 2024-05-26 16:03:35
categories:
 - swift
 - ios
---


### 1. Optional Parameters

Swift中可选参数的行为很容易误导人, 让人错误的以为可选参数在调用函数的时候可以不提供, 然而并不是这样, 可选参数只是允许该参数值为 `nil`, 即使该值是 `nil`, 也必须显示提供. 

```swift
// withGreeting: external parameter name (or argument label)
func greet(name: String, withGreeting greeting: String?) {
    if let greeting = greeting {
        print("\(greeting), \(name)!")
    } else {
        print("\(name)!")
    }
}

// 即使 withGreeting 为 nil, 也必须提供 
greet(name: "Alice", withGreeting: nil) // No greeting: "Alice!"
greet(name: "Bob", withGreeting: "Hi") // Uses the provided greeting: "Hi, Bob!"
```

> "if let greeting = greeting" 这不是这个赋值语句吗, 怎么能用来判断呢?
>
> 在 Swift 中，`if let` 常用来 unwrap optional value，名字叫可选绑定（optional binding）, 形式如下：
>
> ```swift
>if let unwrappedValue = optionalValue {
>  // 使用 unwrappedValue
> } else {
>     // optionalValue 为 nil
> }
>    ```
> 

### 2. Default Parameters

默认参数为参数提供一个默认值，这样在调用函数时**可以忽略这些参数**。

```swift
func greet(name: String, withGreeting greeting: String = "Hello") {
    print("\(greeting), \(name)!")
}

greet(name: "Alice") // 输出: "Hello, Alice!"
greet(name: "Bob", withGreeting: "Hi") // 输出: "Hi, Bob!"
```

```swift
func greet(name: String, withGreeting greeting: String) {
    print("\(greeting), \(name)!")
}

// compile error: 'nil' is not compatible with expected argument type 'String'
greet(name: "Alice", withGreeting: nil)
```

> 分清你要的东西是什么, 是允许参数为 nil 还是调用函数的时候不提供参数. 

### 3. Optional Chaining

尝试访问可选值的属性或方法时会用到, 如果可选值有值, 那么调用成功, 如果可选值是 `nil`, 则调用返回 `nil`, 整个过程不会因为尝试访问 `nil` 的属性而导致程序崩溃. 

```swift
class Cat {
    var name: String
    init(name: String) {
        self.name = name
    }
}

func printCatName(_ cat: Cat?) {
    // 若 cat 为 nil, 不会出现 nil 不存在 name 属性的异常
    if let name = cat?.name {
        print("The cat's name is \(name).")
    } else {
        print("No cat provided.")
    }
}
```

注意 Optional chaining 可以用于一切尝试访问可选值属性的行为, 以避免尝试访问 nil 的属性不存在异常发生,  上面的例子只是参数为可选值的情况, 

观察下面这段代码, 从逻辑上来说 selectedTaskItem 在 if 语句后必不为空, 所以下意识会想到 这里的 Optional Chaining 是不是多余的? 

```swift
@State var selectedTaskItem: TaskItem?

withAnimation {
    if selectedTaskItem == nil {
        selectedTaskItem = TaskItem(context: viewContext)
    }

    selectedTaskItem?.created = Date()
    selectedTaskItem?.name = name
    selectedTaskItem?.dueDate = dueDate
    selectedTaskItem?.scheduleTime = scheduleTime

    self.presentationMode.wrappedValue.dismiss()
}
```

答案并不是, 如果直接写为 `selectedTaskItem.name = name`, 则编译器会报错: `Value of optional type 'TaskItem?' must be unwrapped to refer to member 'created' of wrapped base type 'TaskItem'`

这是因为在 Swift 中，即使你在条件分支中对一个可选变量进行了赋值，这个变量的类型仍然保持为可选类型 (`Optional`)。因此，即使我们已经确信该可选变量不为 `nil`，编译器仍要求我们对其进行安全访问，因为从类型系统的角度来看，该变量仍然是可选的。

### 4. Parameter Labels

> 关于参数的 label, 如果不指定, 参数的 label 被设置为参数名, 即调用函数的时候必须指定label, 如 `getName(id: 123)`, id 就是label, 必须指定不可以写为 `getName(123)`
>
> 因此常有些 `_` 来忽略 label, 为了调用函数的时候不用显示指出 label. 

### 5. Unwrapping Optional Value

SafariView 是个自定义 view, 构造函数需要传递一个 URL 类型的参数, 而下面代码却报错, 

```swift
// error: Value of optional type 'URL?' must be unwrapped to a value of type 'URL'
SafariView(url: URL(string: urlString))
```

根据报错信息可以看出, URL构造函数应该是返回了一个 optional value, 即可能为 nil, 因此编译器提示我们要 unwrap `URL?`, 

```swift
// URL 的一个构造函数
init?(string: String)
```

有多种方法 unwrap 可选类型, 分别为 Optional Binding, Force Unwrapping 和 Nil-Coalescing, 其中 Force Unwrapping 不推荐使用, 因为可能导致运行时错误. 

```swift
// Optional Binding
if let url = URL(string: urlString) {
    SafariView(url: url)
} else {
    Text("Invalid URL")
}

// Force Unwrapping
let urlString = "https://www.apple.com"
let url = URL(string: urlString)! // Force unwrap

// Nil-Coalescing 
let url = URL(string: urlString) ?? URL(string: "https://www.example.com")! 
```

在这个地方的 Nil-Coalescing 也用到了 Force Unwrapping, 因为 URL() 总是会返回可选类型, 所以此时最优解是使用 Optional Binding. 

