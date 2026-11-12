import SwiftUI

struct RootView: View {
    @Environment(TandemStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        ZStack(alignment: .bottom) {
            AmbientBackdrop(theme: store.themeChoice, accent: store.accent, light: isLight)

            Group {
                if !store.hasUnlocked {
                    InviteGateView()
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                } else if !store.hasOnboarded {
                    OnboardingView()
                        .transition(.opacity)
                } else {
                    MainTabs()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.45), value: store.hasUnlocked)
            .animation(.easeInOut(duration: 0.35), value: store.hasOnboarded)

            // Ruhige Vignette über allem, damit die Kanten nicht klettern.
            ObsidianVignette(strength: isLight ? 0.35 : 1)
                .zIndex(2)

            if let toast = store.toast {
                ToastView(toast: toast)
                    .padding(.bottom, 96)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(3)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.8), value: store.toast)
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
            Tab("Heute", systemImage: "circle.hexagongrid.fill", value: 0) {
                HomeView()
            }
            Tab("Läufe", systemImage: "bolt.horizontal.fill", value: 1) {
                TasksView()
            }
            Tab("Agent", systemImage: "bubble.left.and.bubble.right.fill", value: 2) {
                ChatView()
            }
            Tab("Gedächtnis", systemImage: "brain.head.profile", value: 3) {
                MemoryView()
            }
            Tab("Mehr", systemImage: "gearshape.fill", value: 4) {
                SettingsView()
            }
        }
    }
}

struct ToastView: View {
    var toast: ToastMessage

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.style.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(toast.style.color)
            Text(toast.text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay { Capsule().fill(toast.style.color.opacity(0.10)) }
        }
        .overlay {
            Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
        }
        .shadow(color: Color.black.opacity(0.40), radius: 16, y: 6)
        .padding(.horizontal, 24)
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
