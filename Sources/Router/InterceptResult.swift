//
//  InterceptResult.swift
//  Nova
//
//  Created by leetangsong on 2026/7/8.
//

/// 拦截结果
///
/// 拦截器处理完路由后返回的结果。
public enum InterceptResult {
    /// 允许继续导航
    case allow
    /// 拒绝导航，并显示原因
    case deny(reason: String)
    /// 重定向到另一个路由
    case redirect(to: AnyRoutable)
    /// 修改为另一个路由
    case modify(to: AnyRoutable)
}
