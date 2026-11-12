import SwiftUI

struct RootView: View {
    @Environment(TandemStore.self) private var store

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground(theme: store.themeChoice, accent: store.accent)

            Group {
                if !store.hasUnlocked {
                    InviteGateView()
                        .transition(.opacity)
                } else if !store.hasOnboarded {
                    OnboardingView()
                        .transition(.opacity)
                } else {
                    MainTabs()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: store.hasUnlocked)
            .animation(.easeInOut(duration: 0.25), value: store.hasOnboarded)

            if let toast = store.toast {
                ToastView(toast: toast)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 84)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .animation(.easeOut(duration: 0.25), value: store.toast)
        #if QA
        .fullScreenCover(isPresented: Binding(
            get: { store.qaScreen != nil },
            set: { if !$0 { store.qaScreen = nil } }
        )) {
            QAOverlay(screen: store.qaScreen ?? "")
        }
        #endif
    }
}

struct MainTabs: View {
    @Environment(TandemStore.self) private var store

    var body: some View {
        @Bindable var store = store
        TabView(selection: $store.selectedTab) {
            Tab("Heute", systemImage: "sun.max", value: 0) {
                HomeView()
            }
            Tab("Aufgaben", systemImage: "checklist", value: 1) {
                TasksView()
            }
            Tab("Chat", systemImage: "bubble.left.and.bubble.right", value: 2) {
                ChatView()
            }
            Tab("Gedächtnis", systemImage: "brain", value: 3) {
                MemoryView()
            }
            Tab("Mehr", systemImage: "gearshape", value: 4) {
                SettingsView()
            }
        }
        .tint(store.accent)
    }
}

struct ToastView: View {
    var toast: ToastMessage

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: toast.style.icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(toast.style.color)
            Text(toast.text)
                .font(.system(size: 13))
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background {
            Capsule().fill(Palette.surfaceRaised)
        }
        .shadow(color: Color.black.opacity(0.30), radius: 12, y: 5)
    }
}

#if QA
/// Nur im QA-Build: öffnet eine Unterseite direkt für die Screenshots.
struct QAOverlay: View {
    @Environment(TandemStore.self) private var store
    var screen: String

    var body: some View {
        Group {
            switch screen {
            case "approvals":
                NavigationStack { ApprovalsView() }
            case "invitekeys":
                NavigationStack { InviteKeysView() }
            case "provider":
                NavigationStack { ProviderSettingsView() }
            case "newtask":
                TasksView(showNewTask: true)
            case "settings":
                SettingsView()
            case "memory":
                MemoryView()
            default:
                HomeView()
            }
        }
        .preferredColorScheme(store.appearance.colorScheme)
    }
}
#endif
