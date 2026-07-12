//
//  Router.swift
//
//
//  Created by leetangsong on 2026/7/11.
//

import Foundation


/// 导航事件
///
/// 用于监听导航生命周期的各个环节。
public enum RouterEvent {
    /// 即将跳转
    case willPush(from: AnyRoutable?, to: AnyRoutable)
    /// 已经跳转
    case didPush(from: AnyRoutable?, to: AnyRoutable)
    /// 即将返回
    case willPop(from: AnyRoutable, to: AnyRoutable?)
    /// 已经返回
    case didPop(from: AnyRoutable, to: AnyRoutable?)
}
