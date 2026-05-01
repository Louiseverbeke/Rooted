import SwiftUI

@main
struct RootedApp: App {
    @StateObject private var session = AppSession()
    @State private var isShowingLaunchScreen = true

    init() {
        FirebaseBootstrap.configureIfAvailable()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView(session: session)

                if isShowingLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                }
            }
            .task {
                guard isShowingLaunchScreen else { return }
                try? await Task.sleep(for: .seconds(1.2))
                withAnimation(.easeOut(duration: 0.35)) {
                    isShowingLaunchScreen = false
                }
            }
        }
    }
}
