//
//  Router.swift
//
//
//  Created by leetangsong on 2026/7/11.
//

/// 导航事件多播器
///
/// 将导航事件分发给多个观察者（多播模式）。
/// 使用组合模式实现了 1 对多的事件分发。
///
/// 使用示例：
/// ```
/// let multicaster = RouterEventMulticaster<AppRoute>()
/// multicaster.addObserver(PageTracker())
/// multicaster.addObserver(NavigationLogger())
/// navigationManager.eventObserver = multicaster
/// ```
public final class RouterEventMulticaster{
    
    /// 已注册的观察者列表
    private var observers: [any RouterEventObserver] = []
    
    /// 注册观察者
    ///
    /// - Parameter observer: 要注册的观察者
    ///
    /// 注意：如果观察者已存在，不会重复添加。
    public func addObserver(_ observer: some RouterEventObserver) {
        if !observers.contains(where: { $0 === observer as AnyObject }) {
            observers.append(observer)
        }
    }
    
    /// 移除观察者
    ///
    /// - Parameter observer: 要移除的观察者
    public func removeObserver(_ observer: some RouterEventObserver) {
        observers.removeAll { $0 === observer as AnyObject }
    }
    
    /// 移除所有观察者
    public func removeAllObservers() {
        observers.removeAll()
    }
    
    /// 观察者数量
    public var observerCount: Int { observers.count }
    
    /// 是否没有任何观察者
    public var isEmpty: Bool { observers.isEmpty }
    
    /// 分发导航事件给所有观察者
    public func router(
        _ router: Router,
        didTrigger event: RouterEvent
    ) {
        for observer in observers {
            observer.router(router, didTrigger: event)
        }
    }
}

