//
//  RouteInterceptor.swift
//  Nova
//
//  Created by leetangsong on 2026/7/8.
//

/// 路由拦截器
///
/// 在路由跳转前进行拦截处理。
/// 可用于权限检查、日志记录、参数校验等。
///
/// 使用示例：
/// ```
/// let interceptor = RouteInterceptor<AppRoute>()
///
/// // 权限拦截器
/// interceptor.addInterceptor { route in
///     if case .profile = route, !isLoggedIn() {
///         return .redirect(to: .login)
///     }
///     return .allow
/// }
///
/// // 日志拦截器
/// interceptor.addInterceptor { route in
///     print(" 访问: \(route)")
///     return .allow
/// }
/// ```
@MainActor
public final class RouteInterceptor{
    
    /// 拦截器列表
    private var interceptors: [(AnyRoutable) -> InterceptResult] = []
    
    /// 添加拦截器
    /// - Parameter interceptor: 拦截器闭包
    public func addInterceptor(_ interceptor: @escaping (AnyRoutable) -> InterceptResult) {
        interceptors.append(interceptor)
    }
    
    /// 移除所有拦截器
    public func removeAllInterceptors() {
        interceptors.removeAll()
    }
    
    /// 处理拦截器链
    ///
    /// - Parameter route: 要检查的路由
    /// - Returns: 拦截结果
    ///
    /// 处理流程：
    /// 1. 按顺序执行所有拦截器
    /// 2. 如果某个拦截器返回 .deny、.redirect 或 .modify，立即返回该结果
    /// 3. 如果所有拦截器都返回 .allow，返回 .allow
    public func process(_ route: AnyRoutable) -> InterceptResult {
        for interceptor in interceptors {
            let result = interceptor(route)
            switch result {
            case .allow:
                continue
            case .deny, .redirect, .modify:
                return result
            }
        }
        return .allow
    }
}
