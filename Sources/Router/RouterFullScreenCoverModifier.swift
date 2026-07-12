//
//  RouterFullScreenCoverModifier.swift
//  Router-SwiftUI
//
//  Created by leetangsong on 2026/7/11.
//

import SwiftUI

public struct RouterFullScreenCoverModifier: ViewModifier {
    
    
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
        #if os(iOS) || os(tvOS)
        content.fullScreenCover(
            item: $router.presentedFullScreenCover,
            onDismiss: {
                onDismiss?()
            }
        ) { route in
            router.resolve(route)
        }
        #else
        content.sheet(item: $router.presentedFullScreenCover, onDismiss: {
            onDismiss?()
        }) { route in
            router.resolve(route)
        }
        #endif
    }
}

public extension View {
    func routerFullScreenCover(_ router: Router, onDismiss: (() -> Void)? = nil) -> some View {
        modifier(RouterFullScreenCoverModifier(router, onDismiss: onDismiss))
    }
}
