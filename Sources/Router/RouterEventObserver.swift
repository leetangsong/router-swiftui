//
//  Router.swift
//
//
//  Created by leetangsong on 2026/7/11.
//

import Foundation

/// 导航事件代理协议
///
/// 实现此协议可以接收所有导航事件。
public protocol RouterEventObserver: AnyObject {
        
    func router(
            _ router: Router,
            didTrigger event: RouterEvent
        )
 
}
