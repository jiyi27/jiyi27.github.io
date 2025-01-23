---
title: SwiftUI Views
date: 2024-06-06 21:55:30
categories:
 - ios
---

### 1. Custom Button 

```swift
struct AFButton: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.semibold)
            .frame(width: 250, height: 50)
            .background(Color.red)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
    }
}

// ---------------------------------

Button {
    isShowingSafariView = true
} label: {
    AFButton(title: "Learn More")
}
```

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/06/0ae5d310c2858d87849da41815dcdf22.jpg)

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/06/9c65f6e30f91557aafbd388f268c4bea.jpg)

### 2. System Button

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/06/793f52e618bd81d76dd8d2c3e2aa8345.jpg)

### 3. Sheet

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/06/2499a584512d308df3ef3d8080cc3651.jpg)

Learn more: [sheet(isPresented:onDismiss:content:) | Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/view/sheet(ispresented:ondismiss:content:))

### 4. Label & `.infinity`

指定宽度或高度时使用, 填充宽度或者高度整个屏幕, 无论屏幕多宽或者多高,

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/06/2c32221b7ca5738e95775e5f1dc9b81e.jpg)



