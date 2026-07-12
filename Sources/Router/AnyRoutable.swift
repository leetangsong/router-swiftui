//
//  Router.swift
//
//
//  Created by leetangsong on 2026/7/11.
//

import Foundation


/// 类型擦除
public struct AnyRoutable: Hashable, Identifiable {
    
    
    private(set) var boxedValue: AnyHashable
    
    public let routeTypeName: String
    
    public let typeID: ObjectIdentifier
    
    public var value: Any {
        boxedValue.base
    }
    
    public var id: AnyHashable {
        AnyHashable(RouteIdentity(typeID: typeID, value: boxedValue))
    }
    
    public init<Route: Routable>(
        _ value: Route
    ) {
        
        self.boxedValue = value
        self.typeID = ObjectIdentifier(Route.self)
        self.routeTypeName = String(reflecting: Route.self)
    }
    
    
    
    public func unwrap<T>(
        _ type:T.Type
    ) -> T? {
        value as? T
    }
    
    
    public func hash(
        into hasher: inout Hasher
    ) {
        
        hasher.combine(typeID)
        
        hasher.combine(boxedValue )
        
    }
    
    
    
    public static func ==(
        lhs:AnyRoutable,
        rhs:AnyRoutable
    ) -> Bool{
        
        lhs.typeID == rhs.typeID &&
        lhs.boxedValue == rhs.boxedValue
    }
}

private struct RouteIdentity: Hashable {
    let typeID: ObjectIdentifier
    let value: AnyHashable
    
}
