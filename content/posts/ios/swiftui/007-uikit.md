---
title: UIKit in SwiftUI
date: 2024-06-08 21:55:30
categories:
 - ios
---

### 1. UIViewControllerRepresentable

`UIViewControllerRepresentable` is a view that represents a UIKit view controller. Use a [`UIViewControllerRepresentable`](https://developer.apple.com/documentation/swiftui/uiviewcontrollerrepresentable) instance to create and manage a [`UIViewController`](https://developer.apple.com/documentation/uikit/uiviewcontroller) object in your SwiftUI interface. 

SwiftUI cannot use `SFSafariViewController` directly, so we wrap it in a `UIViewControllerRepresentable`. 

```swift
import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    // typealias Context = UIViewControllerRepresentableContext<Self>
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // This method is usually left empty for SFSafariViewController.
    }
}
```

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/06/09bfd9ae3e90671f9516329428798591.jpg)

### 2. Delegate Pattern

The Delegate Pattern, a common design pattern in traditional iOS development with UIKit, involves defining a protocol that outlines the responsibilities that can be delegated to another class or structure. This pattern allows for the separation of responsibilities, enhancing modularity and reusability of code. 

通过在 UIViewControllerRepresentable 中嵌入 UIViewController 来实现在 SwiftUI 中使用 UIKit 的组件, 前者是 SwiftUI View, 后者其实就是 UIKit 的组件. UIKit 通常把不同功能的代码进行分类, 因此又在 UIViewController 中弄了个 Delegate 协议, 然后让 UIViewControllerRepresentable 创建个协调者实现这个协议, 这样 这个协调者就能在 UIkit 和 SwiftUI 组件间传递信息, 真的是离谱这个设计（¯﹃¯）

忘了说, 协议在 Swift 语法里其实就是其他语言里的 接口, 即只声明一些函数, 由继承该协议的类进行实现, 可以实现多态...

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/06/9da1df8146b465d5381307c38da4f103.jpg)

### 3. Do not Pass Reference of a View

I would definitely *not* recommend using references to SwiftUI views via `self`, passing them to other views. SwiftUI views are transient and you shouldn't rely on a reference like this. You can, however, pass closures back and forth or bindings like you suggested. Check original: [ios - Is delegate pattern a good approach in SwiftUI? - Stack Overflow](https://stackoverflow.com/questions/70219779/is-delegate-pattern-a-good-approach-in-swiftui)
