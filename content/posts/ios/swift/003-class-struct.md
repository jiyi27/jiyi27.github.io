---
title: Struct & Class - Swift
date: 2024-05-26 16:03:35
categories:
 - ios
---

## 1. Struct vs Class

### 1.1. Value Types and Reference Types

Structures are value types—unlike classes—local changes to a structure aren’t visible to the rest of your app unless you intentionally communicate those changes as part of the flow of your app. 

- **Structures are Value Types:** When you pass a structure to a function, or assign it to a variable, a *copy* of the structure's data is created. Modifying the copy doesn't affect the original.

- **Classes are Reference Types:** When you pass a class instance around, you're essentially passing a reference to the *same* underlying object. Changes made through one reference impact the original object and are visible everywhere else it's referenced.

References: [Choosing Between Structures and Classes | Apple Developer Documentation](https://developer.apple.com/documentation/swift/choosing-between-structures-and-classes)

### 1.2. Mutable and Immutable

Structs are immutable, classed are mutable. What does this mean?

#### 1.2.1. `let` and `var` instance of `struct`

```swift
struct Point {
    var x: Int
    var y: Int
}

var point1 = Point(x: 1, y: 2)
point.x = 10  // Can directly modify properties
let point2 = Point(x: 3, y: 4)
point2.x = 5  // This would cause a compile-time error, class has no this limit
```

#### 1.2.2. `mutating` keyword in `struct`

Structures and enumerations are *value types*. By default, the properties of a value type can’t be modified from within its instance methods. However, if you need to modify the properties of your structure or enumeration within a particular method, you can opt in to `mutating` behavior for that method. [--Apple Docs](

```swift
struct Rectangle {
    var width: Double = 0
    var height: Double = 0
    var area: Double {
        get {
            width = 9 // error: Cannot assign to property: 'self' is immutable
            return width * height
        }
        set {
            height = 3 // only here is allowed
        }
    }
  
    func setWidth(width: Double) {
        self.width = width // error: Cannot assign to property: 'self' is immutable.
    }
    
    mutating func setHeight(height: Double) {
      self.height = height // No error.
    }
}
```

#### 1.2.3. Weird Behavior

```swift
struct Rectangle {
    var width: Double = 0
    var height: Double = 0
    var area: Double {
        get {
            width = 9 // error: Cannot assign to property: 'self' is immutable
            return width * height
        }
        set {
            height = 3 // only here is allowed, don't know why...
        }
    }
}
```

> **Note:** `class` has no those limitations listed above. 

### `struct` in SwiftUI - Practice

除了使用 mutating 关键字, 在 SwiftUI 中, 我们常通过 @State 允许 struct 的属性被修改:

```swift
struct ContentView: View {
    @State private var age = 12
    private var name = "John"
    
    var body: some View {
        VStack {
            Text("Name: \(name), Age: \(age)")
            Button("Click to Increase Age by One") {
                age += 1 // No error. 
            }
            Button("Change Name") {
                //name = "Jane" // error: Cannot assign to property: 'self' is immutable
            }
        }
    }
}
```

细心观察可以发现 SwiftUI 的 Views 都是 struct 而不是 class, 这也是因为 struct 是值类型, 这样每当你进行拷贝或者传递一个 view 时, 被传递的是个新的单独的 view, 而不是传递一个引用, 这样便有很好的隔离性, 这是什么意思呢, 

The few posts here are missing the point. The point of structs is that they are copied on assignment. Why is that good? Because it’s the only thing that encourages local reasoning, which means the ability to look at one block of code and only have to think about what it is doing.

With classes, you pass them around by reference and all of a sudden you can have objects on the other side of the planet that are all referencing the same object. That’s not clear at all from looking at them, so you need to trace their origin back to some unrelated part of the system. This is known as reference aliasing. It’s not bad in itself, but when shared references are also allowed to be mutated, you can’t reason locally about anything. You have to know who had references to each object at all times. That can be the difference between looking at 10 and 100,000 lines of code. Which would you rather look at?

Yes, structs are also allocated on the stack. But that’s not what makes them useful. What makes them useful is their inability to be shared.

Reference: https://www.reddit.com/r/swift/comments/dg2lrp/comment/f39if54/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button

## 2. Property observers: `didSet` and `willSet`

Property observers let you execute code whenever a property has changed. To make them work, we use either `didSet` to execute code when a property has just been set, or `willSet` to execute code before a property has been set.

```swift
class LightBulb {
    var brightness: Int = 0 {
        willSet(newBrightness) { // 显式声明 newValue 参数
            print("旧亮度为 \(brightness)，即将调整为 \(newBrightness)")
        }
        didSet {
            print("亮度从 \(oldValue) 调整为 \(brightness)")
        }
    }
}

let bulb = LightBulb()
bulb.brightness = 50  // 输出：旧亮度为 0，即将调整为 50
                      // 输出：亮度从 0 调整为 50
```

The default parameter names are `newValue` for `willSet` and `oldValue` for `didSet`, or you can name them yourself as in `willSet(newTotalSteps)`.

## 3. Properties

*Stored* and *computed properties* are usually associated with instances of a particular type. However, properties can also be associated with the type itself. Such properties are known as *type properties*.

In addition, you can define **property observers** to monitor changes in a property’s value, which you can respond to with custom actions. Property observers can be added to stored properties you define yourself, and also to properties that a subclass inherits from its superclass. 

You can also use a **property wrapper** to reuse code in the getter and setter of multiple properties.

### 3.1. Lazy Stored Properties

A *lazy stored property* is a property whose initial value isn’t calculated until the first time it’s used. 

```swift
class DataManager {
    lazy var importer = DataImporter()
    var data: [String] = []
    // the DataManager class would provide data management functionality here
}

let manager = DataManager()
manager.data.append("Some data")
manager.data.append("Some more data")
// the DataImporter instance for the importer property hasn't yet been created

print(manager.importer.filename)
// the DataImporter instance for the importer property has now been created
// Prints "data.txt"
```

Because it’s possible for a `DataManager` instance to manage its data without ever importing data from a file, `DataManager` doesn’t create a new `DataImporter` instance when the `DataManager` itself is created. Instead, it makes more sense to create the `DataImporter` instance if and when it’s first used.

### 3.2. Computed Properties

In addition to stored properties, classes, structures, and enumerations can define *computed properties*. In Swift, a computed property does not store a value itself. Instead, it provides a getter to retrieve a value and an optional setter to indirectly set other properties or values. 

```swift
struct Rectangle {
   var width: Double
   var height: Double
   var area: Double {
      // implicit return
       width * height
   }
}

let rectangle = Rectangle(width: 5.0, height: 10.0)
print(rectangle.area)  // 50.0
```

如果对计算属性赋值会发生什么? 

```swift

let rectangle = Rectangle(width: 5, height: 3)
print(rectangle.area) // 15.0
rectangle.area = 20.0 // Error: Cannot assign to property: 'area' is a get-only property
```

上面的例子中是计算属性常见的样子, 即拥有一个默认的 getter, 此时它是一个只读属性,  你也可以让其可以被“赋值”, 如下: 

```swift
struct Cat {
    var age: Int
    var months: Int {
        get {
            age * 12
        }
        // newValue is default parameter name of the setter.
        set {
            age = newValue / 12
        }
    }
}

var cat = Cat(age: 2)
print(cat.months) // 24
cat.months = 12
print(cat.age) // 1
```

计算属性本身并不存储任何东西, 它更像是个函数, 为什么可以被“赋值”呢? 仔细看看 set 函数里, `months` 真的被赋值了吗? 仍然没有, 只是在其复制的时候执行了 `age = newValue / 12` 而已. 

代码 `cat.months = 12` 就是把 `12` 传给其 `setter`, 而 `cat.months` 就是调用其 `getter`, 返回 `age * 12`, 这也是为什么说其是计算属性. 所以有没有觉得如果在其 getter 里尝试访问 `months`的值很奇怪? 因为 months 本身就不存在啊, 它其实就是 `age * 12`, 

> Stored property has default setter and getter, you cannot override `get`/`set` for a stored property.  But You can use property observers `willSet`/`didSet` to achiveve what you want.  Source: https://stackoverflow.com/a/24116083/16317008 

设想一下, 每当你访问 area `rectangle.area`, 就会执行 `width * height` 并返回, 如果我们要在里面直接修改其他属性的值, 是不是很奇怪? 而 SwiftUI 中的 body 就是一个 read-only 计算属性, 所以直接在 body 中直接修改其属性是不推荐的, 
