---
title: Predefined Styles SwiftUI
date: 2024-06-07 22:02:30
categories:
 - ios
---

### 1. Color

#### 1.1 `Color.red` vs `.red`

`background()` 应该传入 `Color.red` 而不是直接 `.red`, 否则显示可能会不符合预期, 这和 [Implicit Member Expression](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/expressions/#Implicit-Member-Expression) 有关系.  

> Swift 的类型推断能力意味着编译器能够自动理解表达式的类型而无需显式声明。在 SwiftUI 的视图中，很多属性（如 `foregroundColor`）期望的是一个 `Color` 类型。当你提供 `.primary` 时，Swift 知道这个上下文需要一个 `Color` 实例，因此它会查找 `Color` 类型中名为 `primary` 的静态属性。
>

如下定义所示, 调用 foregroundColor 时就可以直接使用 `.red`, 不必指定类型, 而 background 却不行, 

```swift
func foregroundColor(_ color: Color?) -> some View

func background<S>(
    _ style: S,
    ignoresSafeAreaEdges edges: Edge.Set = .all
) -> some View where S : ShapeStyle
```

#### 1.2. Auto Color

If you **want the `foregroundStyle` color to adapt automatically** **to the system theme** (such as light mode and dark mode), you can use some predefined colors like `.primary`, `.secondary`, `.label`, etc. These colors will automatically adjust according to different themes. However, it's important to note that using system colors like `.label` directly in `foregroundStyle` might encounter issues because `foregroundStyle` is more commonly used to define composite styles or gradients, rather than just a single color.

考虑到 foregroundColor 已经被 foregroundStyle 替代, 有时候使用 primiary 并不能修改字体颜色, 比如 NavigationLink 默认是蓝色, 此时使用 primiary, 依然会是蓝色, 所以可以使用 label: `.foregroundStyle(Color(.label))`

