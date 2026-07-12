//
//  Router.swift
//  
//
//  Created by leetangsong on 2026/7/11.
//

import Foundation
import SwiftUI


@MainActor
@Observable
public final class Router {
    
    
    public let mode: RouterMode
    
    /// 是否输出 Router 调试日志
    public var isLoggingEnabled: Bool
    
    ///路由注册器
    private let registry: RouteRegistry
    
    // MARK: - 导航状态
    
    ///单个navigationStack使用
    public var path: [AnyRoutable] = []
    
    ///多个navigationStack
    public var tabPaths: [AnyHashable: [AnyRoutable]] = [:]
    
    public var presentedSheet: AnyRoutable?
    
    public var presentedFullScreenCover: AnyRoutable?
    
    
    ///当前tab
    public var selectedTab: AnyHashable? {
        didSet {
            guard let selectedTab = selectedTab, oldValue != selectedTab else {
                return
            }
            log("[Router] 切换 Tab: \(String(describing: oldValue)) → \(String(describing: selectedTab))")
            switchToTab(oldValue, selectedTab)
        }
    }
    
    /// URL 处理器列表
    @ObservationIgnored
    private var urlHandlers: [(URL) -> (tab: AnyHashable, route: any Routable)?] = []
    
    // MARK: - 事件回调
    public let eventObserver: RouterEventMulticaster = RouterEventMulticaster()
    
    /// 导航回调（跳转后触发）
    public var onNavigate: ((AnyRoutable) -> Void)?
    
    /// 返回回调
    public var onPop: (() -> Void)?
    
    // MARK: - 拦截器
    
    @ObservationIgnored
    public let interceptor = RouteInterceptor()
    
    // MARK: - 计算属性
    
    /// 是否可以返回
    public var canGoBack: Bool {
        return !path.isEmpty
    }
    
    /// 当前路由
    public var currentRoute: AnyRoutable? {
        return path.last
    }
    
    
    /// 上一个路由
    public var previousRoute: AnyRoutable? {
        guard path.count >= 2 else { return nil }
        return path[path.count - 2]
    }
    
    public init(
        registry: RouteRegistry,
        isLoggingEnabled: Bool = false
    ) {
        self.mode = .single
        self.registry = registry
        self.isLoggingEnabled = isLoggingEnabled
    }
    
    public init(
        mode: RouterMode = .multi,
        initialTab: AnyHashable,
        registry: RouteRegistry,
        isLoggingEnabled: Bool = false
    ) {
        self.mode = mode
        self.selectedTab = initialTab
        self.registry = registry
        self.isLoggingEnabled = isLoggingEnabled
    }
    
    private func switchToTab(_ oldSelectedTab: AnyHashable?, _ selectedTab: AnyHashable?) {
        guard mode == .multi,
                oldSelectedTab != selectedTab,
                let oldSelectedTab = oldSelectedTab,
                let selectedTab = selectedTab else { return }
        
        // 保存当前路径
        tabPaths[oldSelectedTab] = path
        
        // 恢复目标路径
        path = tabPaths[selectedTab] ?? []
    }
    
    
    // MARK: - 拦截器管理
    
    /// 添加拦截器
    public func addInterceptor(_ interceptor: @escaping (AnyRoutable) -> InterceptResult) {
        self.interceptor.addInterceptor(interceptor)
    }
    
    /// 移除所有拦截器
    public func removeAllInterceptors() {
        interceptor.removeAllInterceptors()
    }
    
    public func resolve(_ route: AnyRoutable) -> AnyView {
        registry.resolve(route)
    }
    // MARK: - 私有方法
    
    /// 发送导航事件
    private func notifyEvent(_ event: RouterEvent) {
        eventObserver.router(self, didTrigger: event)
    }
    
    private func log(_ message: @autoclosure () -> String) {
        guard isLoggingEnabled else { return }
        print(message())
    }
}


extension Router {
    // MARK: - Push
    
    /// Push 新页面
    /// - Parameters:
    ///   - route: 目标路由
    public func push(_ route: any Routable) {
        push(AnyRoutable(route))
    }
    
    private func push(_ route: AnyRoutable) {
        push(route, redirectDepth: 0)
    }
    
    private func push(_ route: AnyRoutable, redirectDepth: Int) {
        log("[Router] 开始处理跳转: \(route)")
        
        // 执行 Router 拦截器
        let localResult = interceptor.process(route)
        
        switch localResult {
        case .allow:
            // 没有全局拦截器，直接导航
            performPush(route)
            
        case .deny(let reason):
            log("[本地拦截器] 拒绝: \(reason)")
            notifyInterceptDenied(reason: reason)
            
        case .redirect(let newRoute):
            log("[本地拦截器] 重定向: \(route) → \(newRoute)")
            if route != newRoute {
                guard redirectDepth < 8 else {
                    notifyInterceptDenied(reason: "路由重定向次数过多")
                    return
                }
                push(newRoute, redirectDepth: redirectDepth + 1)
            }
            
        case .modify(let newRoute):
            log("[本地拦截器] 修改: \(route) → \(newRoute)")
            performPush(newRoute)
        }
    }
    
    /// 执行实际导航
    private func performPush(_ route: AnyRoutable) {
        let from = path.last
        
        notifyEvent(.willPush(from: from, to: route))
        
        path.append(route)
        
        notifyEvent(.didPush(from: from, to: route))
        onNavigate?(route)
    }
    
    /// 通知拦截被拒绝
    private func notifyInterceptDenied(reason: String) {
        // 可以通过事件或通知 UI 显示提示
        // 例如：发送一个通知，让 PresentationManager 显示 Alert
        NotificationCenter.default.post(
            name: .interceptDenied,
            object: nil,
            userInfo: ["reason": reason]
        )
    }
    
    // MARK: - Pop
    
    /// 返回上一
    public func pop() {
        guard let from = path.last else { return }
        let to = path.count >= 2 ? path[path.count - 2] : nil
        
        notifyEvent(.willPop(from: from, to: to))
        
        path.removeLast()
        
        notifyEvent(.didPop(from: from, to: to))
        onPop?()
    }
    
    /// 返回根页面
    public func popToRoot() {
        guard let from = path.last else { return }
        
        notifyEvent(.willPop(from: from, to: nil))
        
        path.removeAll()
        
        notifyEvent(.didPop(from: from, to: nil))
        onPop?()
    }
    
    
    /// 返回到指定路由
    /// - Parameters:
    ///   - route: 目标路由
    public func popTo(_ route: any Routable) {
        popTo(AnyRoutable(route))
    }
    
    private func popTo(_ route: AnyRoutable) {
        guard let index = path.firstIndex(where: { $0 == route }),
              let from = path.last else { return }
        
        notifyEvent(.willPop(from: from, to: route))
        
        path.removeLast(path.count - index - 1)
        
        notifyEvent(.didPop(from: from, to: route))
        onPop?()
    }
    
    /// 返回多步
    /// - Parameters:
    ///   - step: 要返回的步数（1 = 返回一页）
    public func pop(step: Int) {
        guard step > 0 && step <= path.count else { return }
        
        let from = path.last
        let targetIndex = path.count - step - 1
        let to = targetIndex >= 0 ? path[targetIndex] : nil
        
        if let from {
            notifyEvent(.willPop(from: from, to: to))
        }
        
        path.removeLast(step)
        
        if let from {
            notifyEvent(.didPop(from: from, to: to))
        }
        
        onPop?()
    }
}

extension Router {
    // MARK: - URL 路由
    
    
    /// 注册 URL 处理器
    public func registerURLHandler(
        _ handler: @escaping (URL) -> (tab: AnyHashable, route: any Routable)?
    ) {
        urlHandlers.append(handler)
    }
    
    /// 注册 URL 路由（路径模式）
    ///
    /// 示例：
    /// ```
    /// appRouter.registerURL(
    ///     pathPattern: "/profile/:userId",
    ///     targetTab: .home
    /// ) { params in
    ///     guard let userId = params["userId"] else { return nil }
    ///     return .profile(userID: userId)
    /// }
    /// ```
    public func registerURL(
        pathPattern: String,
        targetTab: AnyHashable,
        handler: @escaping ([String: String]) -> (any Routable)?
    ) {
        registerURLHandler { url in
            
            let patternComponents = pathPattern.split(separator: "/").map(String.init)
            let pathComponents = url.path.split(separator: "/").map(String.init)
            
            guard patternComponents.count == pathComponents.count else { return nil }
            
            var params: [String: String] = [:]
            
            for (index, patternComponent) in patternComponents.enumerated() {
                if patternComponent.hasPrefix(":") {
                    let key = String(patternComponent.dropFirst())
                    params[key] = pathComponents[index]
                } else if patternComponent != pathComponents[index] {
                    return nil
                }
            }
            
            // 提取查询参数
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                for item in components.queryItems ?? [] {
                    params[item.name] = item.value ?? ""
                }
            }
            
            guard let route = handler(params) else { return nil }
            return (targetTab, route)
        }
    }
    
    /// 注册 URL 路由（完整 URL 匹配）
    ///
    /// 示例：
    /// ```
    /// appRouter.registerURL(host: "settings") { url in
    ///     return .settings
    /// }
    /// ```
    public func registerURL(
        host: String? = nil,
        path: String? = nil,
        targetTab: AnyHashable,
        handler: @escaping (URL) -> (any Routable)?
    ) {
        registerURLHandler { url in
            if let host = host, url.host != host { return nil }
            if let path = path, url.path != path { return nil }
            
            guard let route = handler(url) else { return nil }
            return (targetTab, route)
        }
    }
    
    /// 注册 URL 路由（自定义处理器）
    ///
    /// 示例：
    /// ```
    /// appRouter.registerURL { url in
    ///     if url.scheme == "myapp" && url.host == "custom" {
    ///         return (.home, .detail(title: "Custom", content: ""))
    ///     }
    ///     return nil
    /// }
    /// ```
    public func registerURL(
        _ handler: @escaping (URL) -> (tab: AnyHashable, route: any Routable)?
    ) {
        urlHandlers.append(handler)
    }
    
    /// 处理深层链接
    ///
    /// - Parameter url: 要处理的 URL
    /// - Returns: 是否成功处理
    @discardableResult
    public func handleDeepLink(_ url: URL) -> Bool {
        log("[Router] 处理 URL: \(url)")
        
        for handler in urlHandlers {
            if let result = handler(url) {
                // 1. 切换到目标 Tab
                selectedTab = result.tab
                
                // 3. 执行跳转
                push(result.route)
                
                log("[Router] URL 处理成功: \(url) → Tab \(result.tab) → \(result.route)")
                return true
            }
        }
        
        log("[Router] 无法处理 URL: \(url)")
        return false
    }
    
    public func push(_ url: URL) {
        handleDeepLink(url)
    }
    
    public func push(_ urlStr: String) {
        guard let url = URL(string: urlStr) else {
            log("[Router] 无效的 URL 字符串: \(urlStr)")
            return
        }
        handleDeepLink(url)
    }
    
    
}

extension Router {
    // MARK: - Sheet
    public func presentSheet(_ route: any Routable) {
        presentedSheet = AnyRoutable(route)
    }

    public func dismissSheet() {
        presentedSheet = nil
    }
    public func presentFullScreenCover(_ route: any Routable) {
        presentedFullScreenCover = AnyRoutable(route)
    }

    public func dismissFullScreenCover() {
        presentedFullScreenCover = nil
    }
    
}


extension Router {
    // MARK: - 路由注册
    
    public func register<Route: Routable>(
        _ type: Route.Type,
        builder: @escaping(Route) -> AnyView
    ) {
        registry.register(type, builder: builder)
    }
    
    public func destination(
        _ route: AnyRoutable
    ) -> AnyView{
        registry.resolve(route)
    }
    
}

public extension View {
    func routerTab<Tab: Hashable>(_ tab: Tab) -> some View {
        tag(AnyHashable(tab))
    }
    
}

public extension Notification.Name {
    static let interceptDenied = Notification.Name("interceptDenied")
}
