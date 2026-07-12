# Router-SwiftUI

一个轻量的 SwiftUI 路由库，支持类型安全导航、多 Tab 导航栈、Sheet、FullScreenCover、Deep Link、路由拦截器和导航事件监听。

## 环境要求

- Swift 6.3+
- iOS 17+
- macOS 14+
- tvOS 17+
- watchOS 10+

## 安装

在 Xcode 里添加 Swift Package：

```swift
.package(url: "https://github.com/leetangsong/router-swiftui.git", from: "1.0.1")
```

然后把 `Router` product 添加到 App target，并在代码中导入：

```swift
import Router
```

## 快速开始

先定义业务路由：

```swift
enum AppRoute: Routable {
    case detail(id: Int)
    case profile(userID: String)
    case login
}
```

注册路由对应的页面：

```swift
@MainActor
func makeRouter() -> Router {
    let registry = RouteRegistry()
    
    registry.register(AppRoute.self) { route in
        switch route {
        case .detail(let id):
            DetailView(id: id)
        case .profile(let userID):
            ProfileView(userID: userID)
        case .login:
            LoginView()
        }
    }
    
    return Router(registry: registry)
}
```

在 `NavigationStack` 中绑定 router 的 `path`：

```swift
struct RootView: View {
    @Environment(Router.self) private var router
    
    var body: some View {
        @Bindable var router = router
        
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AnyRoutable.self) { route in
                    router.destination(route)
                }
        }
    }
}
```

跳转和返回：

```swift
router.push(AppRoute.detail(id: 42))
router.pop()
router.popToRoot()
```

## 单栈模式

适合没有 Tab，只有一个 `NavigationStack` 的 App：

```swift
@main
struct MyApp: App {
    @State private var router = makeRouter()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .routerSheet(router)
                .routerFullScreenCover(router)
        }
    }
}
```

创建单栈 router：

```swift
let router = Router(registry: registry)
```

## 多 Tab 模式

先定义 Tab：

```swift
enum AppTab: Hashable {
    case home
    case settings
}
```

创建多 Tab router：

```swift
let router = Router(
    mode: .multi,
    initialTab: AppTab.home,
    registry: registry
)
```

把 `TabView` 的 selection 绑定到 `selectedTab`：

```swift
struct TabRootView: View {
    @Environment(Router.self) private var router
    
    var body: some View {
        @Bindable var router = router
        
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: router.pathBinding(for: AppTab.home)) {
                HomeView()
                    .navigationDestination(for: AnyRoutable.self) { route in
                        router.destination(route)
                    }
            }
            .routerTab(AppTab.home)
            .tabItem { Label("首页", systemImage: "house") }
            
            NavigationStack(path: router.pathBinding(for: AppTab.settings)) {
                SettingsView()
                    .navigationDestination(for: AnyRoutable.self) { route in
                        router.destination(route)
                    }
            }
            .routerTab(AppTab.settings)
            .tabItem { Label("设置", systemImage: "gear") }
        }
    }
}
```

每个 Tab 都绑定自己的 path，切换 Tab 时不会触发其他 `NavigationStack` 同步刷新。

## Sheet 和 FullScreenCover

在根视图附近挂载一次 presentation modifier：

```swift
RootView()
    .environment(router)
    .routerSheet(router) {
        print("Sheet 已关闭")
    }
    .routerFullScreenCover(router)
```

展示和关闭：

```swift
router.presentSheet(AppRoute.profile(userID: "lee"))
router.dismissSheet()

router.presentFullScreenCover(AppRoute.login)
router.dismissFullScreenCover()
```

说明：macOS 和 watchOS 没有可用的 `fullScreenCover` API，所以 `routerFullScreenCover` 会自动退回为 `sheet`。

## Deep Link

注册路径匹配：

```swift
router.registerURL(pathPattern: "/profile/:userID", targetTab: AppTab.home) { params in
    guard let userID = params["userID"] else { return nil }
    return AppRoute.profile(userID: userID)
}
```

注册 host/path 匹配：

```swift
router.registerURL(host: "settings", path: "/about", targetTab: AppTab.settings) { _ in
    AppRoute.about
}
```

处理系统传入的 URL：

```swift
.onOpenURL { url in
    router.handleDeepLink(url)
}
```

也可以直接通过字符串触发：

```swift
router.push("example://settings/about")
```

## 路由拦截器

拦截器会在跳转前执行，可以允许、拒绝、重定向或修改路由。

```swift
router.addInterceptor { route in
    guard case .profile? = route.unwrap(AppRoute.self), !isLoggedIn else {
        return .allow
    }
    
    return .redirect(to: AnyRoutable(AppRoute.login))
}
```

`redirect` 表示跳到另一个路由，并让新路由重新走一遍拦截链。适合登录、权限等场景。

`modify` 表示改写当前路由，并继续完成这次导航。适合参数修正、默认值补齐等场景。

```swift
router.addInterceptor { route in
    guard case .detail(let id)? = route.unwrap(AppRoute.self), id < 0 else {
        return .allow
    }
    
    return .modify(to: AnyRoutable(AppRoute.detail(id: 0)))
}
```

监听被拒绝的导航：

```swift
NotificationCenter.default.addObserver(
    forName: .interceptDenied,
    object: nil,
    queue: .main
) { notification in
    let reason = notification.userInfo?["reason"] as? String
    print(reason ?? "导航被拒绝")
}
```

## 导航事件

实现观察者：

```swift
final class NavigationLogger: RouterEventObserver {
    func router(_ router: Router, didTrigger event: RouterEvent) {
        print(event)
    }
}
```

注册观察者：

```swift
let logger = NavigationLogger()
router.eventObserver.addObserver(logger)
```

可以监听到：

- `willPush`
- `didPush`
- `willPop`
- `didPop`

## 日志

Router 默认不输出日志。调试时可以打开：

```swift
let router = Router(
    mode: .multi,
    initialTab: AppTab.home,
    registry: registry,
    isLoggingEnabled: true
)
```

## 示例

查看 [Examples/RouterExample.swift](Examples/RouterExample.swift)，里面包含一个完整示例，覆盖：

- 类型安全路由
- 路由注册
- SwiftUI Environment 注入
- 多 Tab 导航
- Sheet
- FullScreenCover
- Deep Link
- 路由拦截器

## 注意事项

- `Routable` 目前要求遵守 `Codable`，但 `AnyRoutable` 还没有内置状态持久化。如果需要恢复导航状态，可以在业务层实现路由编码/解码，或者后续扩展 `RouteRegistry` 的解码能力。
- 路由类型建议保持小而稳定，使用 enum + associated value 会比较自然。
- 调用 `router.destination(_:)` 前，需要先注册对应路由类型。
- 多 Tab 模式下，每个 Tab 使用独立的 `NavigationStack(path: router.pathBinding(for: tab))`，避免多个 `NavigationStack` 同时监听同一个 path。
