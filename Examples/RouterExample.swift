//
//  RouterExample.swift
//  Router-SwiftUI
//
//  将这个文件复制到 App target 中，即可体验 Router 的基本用法。
//

import SwiftUI
import Router

enum AppTab: Hashable {
    case home
    case settings
}

enum AppRoute: Routable {
    case detail(id: Int)
    case profile(userID: String)
    case login
    case about
    case editProfile
}

@main
struct RouterExampleApp: App {
    @State private var router = RouterExampleApp.makeRouter()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .routerSheet(router)
                .routerFullScreenCover(router)
                .onOpenURL { url in
                    router.handleDeepLink(url)
                }
        }
    }
    
    @MainActor
    private static func makeRouter() -> Router {
        let registry = RouteRegistry()
        
        registry.register(AppRoute.self) { route in
            switch route {
            case .detail(let id):
                DetailView(id: id)
            case .profile(let userID):
                ProfileView(userID: userID)
            case .login:
                LoginView()
            case .about:
                AboutView()
            case .editProfile:
                EditProfileView()
            }
        }
        
        let router = Router(
            mode: .multi,
            initialTab: AppTab.home,
            registry: registry,
            isLoggingEnabled: true
        )
        
        router.registerURL(pathPattern: "/profile/:userID", targetTab: AppTab.home) { params in
            guard let userID = params["userID"] else { return nil }
            return AppRoute.profile(userID: userID)
        }
        
        router.registerURL(host: "settings", path: "/about", targetTab: AppTab.settings) { _ in
            AppRoute.about
        }
        
        var isLoggedIn = false
        router.addInterceptor { route in
            guard case .profile? = route.unwrap(AppRoute.self), !isLoggedIn else {
                return .allow
            }
            
            isLoggedIn = true
            return .redirect(to: AnyRoutable(AppRoute.login))
        }
        
        return router
    }
}

struct RootView: View {
    @Environment(Router.self) private var router
    
    var body: some View {
        @Bindable var router = router
        
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: router.pathBinding(for: AppTab.home)) {
                HomeView()
                    .navigationTitle("首页")
                    .navigationDestination(for: AnyRoutable.self) { route in
                        router.destination(route)
                    }
            }
            .routerTab(AppTab.home)
            .tabItem {
                Label("首页", systemImage: "house")
            }
            
            NavigationStack(path: router.pathBinding(for: AppTab.settings)) {
                SettingsView()
                    .navigationTitle("设置")
                    .navigationDestination(for: AnyRoutable.self) { route in
                        router.destination(route)
                    }
            }
            .routerTab(AppTab.settings)
            .tabItem {
                Label("设置", systemImage: "gear")
            }
        }
    }
}

struct HomeView: View {
    @Environment(Router.self) private var router
    
    var body: some View {
        List {
            Button("进入详情页") {
                router.push(AppRoute.detail(id: 42))
            }
            
            Button("打开个人主页") {
                router.push(AppRoute.profile(userID: "lee"))
            }
            
            Button("弹出编辑 Sheet") {
                router.presentSheet(AppRoute.editProfile)
            }
        }
    }
}

struct SettingsView: View {
    @Environment(Router.self) private var router
    
    var body: some View {
        List {
            Button("关于") {
                router.push(AppRoute.about)
            }
            
            Button("全屏打开关于页") {
                router.presentFullScreenCover(AppRoute.about)
            }
            
            Button("触发 Deep Link") {
                router.push("example://settings/about")
            }
        }
    }
}

struct DetailView: View {
    let id: Int
    
    var body: some View {
        Text("详情 \(id)")
    }
}

struct ProfileView: View {
    let userID: String
    
    var body: some View {
        Text("个人主页 \(userID)")
    }
}

struct LoginView: View {
    @Environment(Router.self) private var router
    
    var body: some View {
        VStack(spacing: 16) {
            Text("登录")
            Button("返回") {
                router.pop()
            }
        }
    }
}

struct AboutView: View {
    @Environment(Router.self) private var router
    
    var body: some View {
        VStack(spacing: 16) {
            Text("关于")
            Button("关闭") {
                router.dismissFullScreenCover()
            }
        }
    }
}

struct EditProfileView: View {
    @Environment(Router.self) private var router
    
    var body: some View {
        VStack(spacing: 16) {
            Text("编辑资料")
            Button("完成") {
                router.dismissSheet()
            }
        }
        .padding()
    }
}
