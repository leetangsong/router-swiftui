//
//  RouterNamespace.swift
//  Router-SwiftUI
//
//  Created by leetangsong on 2026/7/11.
//

import SwiftUI

private struct RouterNamespaceKey: EnvironmentKey {
     static let defaultValue: Namespace.ID? = nil
}

public extension EnvironmentValues{
    var routerNamespace: Namespace.ID? {
        get { self[RouterNamespaceKey.self]}
        set {
            self[RouterNamespaceKey.self] = newValue
        }
    }
}

public extension View {
    func routerNamespace(_ namespace: Namespace.ID) -> some View {
        environment(\.routerNamespace, namespace)
    }
}
