//
//  RouterSheetModifier.swift
//  Router-SwiftUI
//
//  Created by leetangsong on 2026/7/11.
//

import SwiftUI

public struct RouterSheetModifier: ViewModifier {
    
    
    @Bindable private var router: Router
    
    private let onDismiss: (() -> Void)?
    
    public init(
        _ router: Router,
        onDismiss: (() -> Void)? = nil
    ) {
        self.router = router
        self.onDismiss = onDismiss
    }
    
    public func body(content: Content) -> some View {
        content.sheet(item: $router.presentedSheet, onDismiss: {
            onDismiss?()
        }) { route in
            router.resolve(route)
        }
    }
}

public extension View {
    func routerSheet(_ router: Router, onDismiss: (() -> Void)? = nil) -> some View {
        modifier(RouterSheetModifier(router, onDismiss: onDismiss))
    }
}

