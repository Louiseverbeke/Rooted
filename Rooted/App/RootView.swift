import SwiftUI

struct RootView: View {
    @ObservedObject var session: AppSession

    var body: some View {
        Group {
            switch session.authState {
            case .loading:
                ProgressView()
                    .tint(AppTheme.Colors.highlight)
            case .signedOut:
                AuthView()
                    .environmentObject(session)
            case .signedIn:
                if session.profile?.onboardingCompleted == true {
                    MainTabView(session: session)
                        .environmentObject(session)
                } else {
                    OnboardingView()
                        .environmentObject(session)
                }
            }
        }
    }
}

struct MainTabView: View {
    @ObservedObject var session: AppSession

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(session)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            DiscoverView()
                .environmentObject(session)
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }

            EventsView()
                .environmentObject(session)
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }

            MessagesView()
                .environmentObject(session)
                .tabItem {
                    Label("Messages", systemImage: "bubble.left.and.bubble.right.fill")
                }

            ProfileView()
                .environmentObject(session)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(AppTheme.Colors.primaryText)
        .task {
            await session.reloadContent()
        }
    }
}
