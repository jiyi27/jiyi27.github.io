---
title: SwiftUI UNUserNotificationCenterDelegate, UIApplicationDelegate, UISceneDelegate 协议
date: 2024-07-03 10:37:20
categories:
 - ios
---

### 1. UNUserNotificationCenterDelegate & UIApplicationDelegate

使用 `UNUserNotificationCenterDelegate` 时, 要记得初始化, 因为其方法都是在特定条件下被系统自动调用的, 如果你不告诉系统谁是你的 通知代表, 系统只会调用默认 通知代表的方法, 即什么都不做. 

> 更新: 最简单的初始化方法, 放在@main的View的 init 函数中: `UNUserNotificationCenter.current().delegate = yourDelegate.self` 即可, 下面只是为了解释 UNUserNotificationCenterDelegate 和 UIApplicationDelegate 是如何使用的, 另外 UIApplicationDelegate 的一些方法也都被 SceneDelegate 取代了, 了解更多: https://stackoverflow.com/a/56508769/16317008

初始化方法一, 在实现 UNUserNotificationCenterDelegate 接口的类的 init() 函数中指定, 然后在程序启动时创建改该类的实例 (间接调用 init 函数)

```swift
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  // 单例模式
  static let shared = NotificationDelegate()
  
  override init() {
    super.init()
    // 告诉系统谁是你的 通知代表 是谁
    UNUserNotificationCenter.current().delegate = self
  }

    func userNotificationCenter(willPresent notification...) {
        // In App, no sound, just banner.
        completionHandler([.banner])
    }
    ...
}

class AppDelegate: NSObject, UIApplicationDelegate {
    // 应用 launch (杀后台再进) 时被调用, 从后台切入不会被调用
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 确保 NotificationDelegate 的 init 函数被调用, 即初始化 NotificationDelegate.shared
        _ = NotificationDelegate.shared
        return true
    }
    // 进入前台 active 的时候被调用
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("aaa")
        NotificationManager.clearBadges()
    }
}

@main
struct todolistApp: App {
     // ApplicationDelegate 被指定为 AppDelegate, 程序启动会调用其application(...) 函数, 也就会初始化 NotificationDelegate.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDeleagte
    
    init() {
        NotificationManager.requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
    }
}
```

方法二, 合并  UNUserNotificationCenterDelegate 和 UIApplicationDelegate 

```swift
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: - UIApplicationDelegate
    
    // 应用 launch (杀后台再进) 时被调用, 从后台切入不会被调用
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 这行代码很重要
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationManager.clearBadges()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Tells the delegate how to handle a notification that arrived while the app was running in the foreground. 
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // In App, no sound, just banner.
        completionHandler([.banner])
    }
    
    // When there is a notification, and user click the notification, this function will be called.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

// @main...
@UIApplicationDelegateAdaptor(AppDelegate.self) var appDeleagte
```

> UIApplicationDelegate,  UNUserNotificationCenterDelegate 的方法都是在特定场景被自动调用的, 我们只需要写好方法体内的逻辑就好了, 要做的就是指定 UIApplicationDelegate 是谁, UNUserNotificationCenterDelegate  是谁:
>
> ```swift
> // 指定 UNUserNotificationCenterDelegate 
> UNUserNotificationCenter.current().delegate = self
> // 指定 UIApplicationDelegate
> @UIApplicationDelegateAdaptor(AppDelegate.self) var appDeleagte
> ```

### 2. UIApplicationDelegate 不起作用?

我们的类实现了  `application(...)` 和 `applicationWillEnterForeground(...)`, 每次重启应用时, `application(...)` 确实被调用了, 但是每次切入进软件 (background -> foreground) 时,  applicationWillEnterForeground() 并没有按预期被调用, 

```swift
class AppDelegate: NSObject, UIApplicationDelegate {
    // 应用 launch (杀后台再进) 时被调用, 从后台切入不会被调用
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("aaa")
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationManager.clearBadges()
    }
}
```

找到了[答案](https://stackoverflow.com/a/56508769/16317008):

Here's how it works: If you have an "**Application Scene Manifest**" in your `Info.plist` and your app delegate has a `configurationForConnectingSceneSession` method, the `UIApplication` won't send background and foreground lifecycle messages to your app delegate. That means the code in these methods won't run:

- `applicationDidBecomeActive`
- `applicationWillResignActive`
- `applicationDidEnterBackground`
- `applicationWillEnterForeground`

The app delegate will still receive the `willFinishLaunchingWithOptions:` and `didFinishLaunchingWithOptions:` method calls so any code in those methods will work as before.

![](https://pub-2a6758f3b2d64ef5bb71ba1601101d35.r2.dev/blogs/2024/07/27b6cf8dbd446ef169f0d7ced56bbb5d.jpg)

我把 Application Scene Manifest 删除了, 依然不能正常工作, 好奇怪, 打算直接用 onReceive 或者复杂的情况使用 SceneDelegate. 

更新: 可能没办法根除 scene 吧? 刚开始学习, 太复杂了, 还是留着以后解决吧, 

```swift
// @main...
var body: some Scene {
    WindowGroup {
        HomeView()
    }
}
```

### 3. APP 三个状态的区别

再看一下 applicationWillEnterForeground 文档:

> In iOS 4.0 and later, UIKit calls this method as part of the transition from the **background** to the **active** state.

[Apple Documents](https://developer.apple.com/documentation/uikit/uiapplication/state/)对 state 的表述等于没说, 看到一个[很好解释](https://stackoverflow.com/a/40001368/16317008):

- `UIApplicationState.Active` - App is running in foreground. Simple.

- `UIApplicationState.Inactive` - E.g. App was in the background and is opening through a push notification (transitioning atm). Or the control/notification center is presented above your app. You kind of see it, is in foreground.

- `UIApplicationState.Background` - App is in the background, but still running. E.g. playing music. Then - this can take a while or not (depending on process you are running in background), but in one point your app is killed. You will see app's snapshot and icon between minimized apps, but the app will be **launch** again first.

注意, launch 和 简单的从后台切入到app页面不一样, 

### 4. UISceneDelegate

Before iOS 13, the main entry point for your app was the AppDelegate, and it was in charge of many logic and state handling. Now the work of the AppDelegate has been split, between the AppDelegate and the SceneDelegate [1 Dev].

The AppDelegate being only responsible for the initial app setup, the SceneDelegate will handle and manage the way your app is shown [1 Dev]. 

As an app could have multiple instances, a SceneDelegate will be called every time an instance of your app is created [1 Dev]. 

> Don’t create `UISceneDelegate` objects directly. Instead, specify the name of your custom delegate class as part of the configuration data for your scenes. 
>
> You can specify this information in your app’s `Info.plist` file, **or** in the UISceneConfiguration object you return from your app delegate’s `application:configurationForConnectingSceneSession:options:` method [2 App].

For the adivice of Apple Docs, we can write code like this:

```swift
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("App is entering the foreground")
    }
}

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    ...
}
```

### 5. Conclusion

After iOS 13, the management responsibilities for app states were subdivided. Previously, all tasks were handled by the AppDelegate, but now they are divided between the AppDelegate and the SceneDelegate. The AppDelegate primarily handles initial setup, such as startup initialization, while the SceneDelegate manages the logic for scene transitions, such as moving the app from the foreground to the background, or from an active state to an inactive state. 

If you have setup tasks, asign them to AppDelegate, like this:

```swift
final class AppDelegate: NSObject, UIApplicationDelegate {
    // Get called when app launchs, launch is not simply from background to foreground.
    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        NotificationManager.requestNotificationPermission()
        // Specify user notification delegate.
        UNUserNotificationCenter.current().delegate = self
        return true
    }
  
  func application(_ application: UIApplication, 
                     configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Specify scene delegate.
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}
```

If you want do something for scene transitions, implement SceneDelegate.

**References:** 

[1Dev] [Add a Scene Delegate to your current project - DEV Community](https://dev.to/kevinmaarek/add-a-scene-delegate-to-your-current-project-5on)

[2App] [UISceneDelegate | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiscenedelegate?language=objc)

举例解释如何在 SwiftUI 中使用 UISceneDelegate 的 **sceneWillEnterForeground() 方法**

