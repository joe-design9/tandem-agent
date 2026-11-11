import SwiftUI

@main
@MainActor
struct TandemApp: App {
    @State private var store = TandemStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(store.appearance.colorScheme)
                .tint(store.accent)
                .task {
                    store.startProactiveLoop()
                }
        }
    }
}
