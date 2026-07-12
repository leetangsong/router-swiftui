//
//  Router.swift
//
//
//  Created by leetangsong on 2026/7/11.
//

public enum RouterMode {
    ///单 NavigationStack
    case single
    
    
    ///多 navigationStack
    ///一个tab 一个 stack
    case multi

}

@MainActor
public protocol RouteRegistrable {
    static func register(_ registry: RouteRegistry)
}

/// 路由协议
///
/// 所有业务路由必须遵守此协议。
/// 遵守此协议的类型可以用于导航和状态持久化。
///
/// 使用示例：
/// ```
/// enum AppRoute: Routable {
///     case home
///     case profile(userID: String)
/// }
/// ```
public protocol Routable: Hashable, Codable {}
