//
//  Router.swift
//
//
//  Created by leetangsong on 2026/7/11.
//

import SwiftUI

@MainActor
public final class RouteRegistry {
    
    private typealias Builder = (AnyRoutable) -> AnyView
    private var builders: [ObjectIdentifier: Builder] = [:]
    
    
    public init() {}
    
    
    public func register(_ registrableTypes: RouteRegistrable.Type...) {
        registrableTypes.forEach { registrableType in
            registrableType.register(self)
        }
    }
    
    public func register<Route: Routable, Destination: View>(
        _ type: Route.Type,
        @ViewBuilder builder: @escaping(Route) -> Destination
    ) {
        let key = ObjectIdentifier(type)
        if builders[key] != nil {
            assertionFailure(
                "路由类型重复注册：\(String(reflecting: type))"
            )
        }
        
        
        builders[key] = { anyRoute in
            guard let route = anyRoute.unwrap(type) else {
                assertionFailure(
                            """
                            路由类型转换失败：
                            预期类型：\(String(reflecting: type))
                            实际类型：\(anyRoute.routeTypeName)
                            """
                )
                
                return AnyView(EmptyView())
            }
            
            return AnyView(builder(route))
        }
        
    }
    
    func resolve(_ route: AnyRoutable) -> AnyView {
        let key = ObjectIdentifier(type(of: route.value))
        guard let builder = builders[key] else {
            assertionFailure(
                "路由尚未注册：\(route.routeTypeName)"
            )

            return AnyView(EmptyView())
        }

        return builder(route)
    }
    
}
