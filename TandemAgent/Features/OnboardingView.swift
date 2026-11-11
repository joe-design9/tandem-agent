import SwiftUI

/// Nach dem Invite: drei Prinzipien und die Eckdaten, die Tandem für
/// Briefings braucht. Kurz — der Agent soll danach übernehmen.
struct OnboardingView: View {
    @Environment(TandemStore.self) private var store

    @State private var page = 0
    @State private var name = ""
    @State private var city = ""
    @State private var role = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("TANDEM")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(store.accent)
                Spacer()
                if store.isFounder {
                    StatusBadge(text: "FOUNDER", tint: store.accent, icon: "crown.fill")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            ScrollView {
                if page == 0 {
                    welcome
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)))
                } else {
                    identity
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)))
                }
            }
            .scrollBounceBehavior(.basedOnSize)

            footer
        }
        .onAppear {
            name = store.userName
            city = store.city
            role = store.role
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Willkommen.")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Ich bin Tandem — ein Agent, der im Hintergrund mitdenkt und dir fertige Entscheidungen hinlegt, statt dir noch ein Chatfenster zu geben.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            GlassCard(tint: store.accent, glow: true) {
                VStack(alignment: .leading, spacing: 16) {
                    principle(icon: "sun.horizon.fill",
                              title: "Proaktiv",
                              text: "Briefing am Morgen, Scans über den Tag: Mails, Kalender, Repos, Gerät.")
                    principle(icon: "hand.raised.fill",
                              title: "Erst fragen, dann handeln",
                              text: "E-Mails, Zahlungen und Kalenderänderungen gehen nie ohne dein Ja raus.")
                    principle(icon: "brain.head.profile",
                              title: "Gedächtnis mit Aus-Schalter",
                              text: "Was ich über dich weiß, steht sichtbar im Gedächtnis-Tab — löschbar.")
                }
            }

            GlassCard(tint: nil, glow: false) {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(store.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Läuft sofort, auch ohne API-Key")
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        Text("Der eingebaute Simulator übernimmt den ersten Lauf. Echte Modelle schaltest du später in den Einstellungen dazu.")
                            .font(.system(size: 11.5, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, 18)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Wie darf ich dich nennen?")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Drei Felder, dann kann ich Briefings und Gedächtnis richtig sortieren.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            GlassCard(tint: store.accent, glow: true) {
                VStack(alignment: .leading, spacing: 14) {
                    field(title: "Name", icon: "person.fill", text: $name, placeholder: "Joel")
                    Divider().opacity(0.2)
                    field(title: "Stadt", icon: "mappin.and.ellipse", text: $city, placeholder: "Köln")
                    Divider().opacity(0.2)
                    field(title: "Rolle", icon: "hammer.fill", text: $role, placeholder: "Entwickler")
                }
            }

            GlassCard(tint: nil, glow: false) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(store.accent)
                        Text("Was du hier einträgst, bleibt auf dem Gerät")
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    }
                    Text("Kein Konto, kein Server von Tandem. Nur wenn du einen echten Anbieter anschließt, geht der jeweilige Chat dorthin.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, 18)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(0..<2) { index in
                    Capsule()
                        .fill(index == page ? store.accent : Color.white.opacity(0.18))
                        .frame(width: index == page ? 18 : 6, height: 6)
                }
            }
            Button {
                Haptics.tap()
                if page == 0 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { page = 1 }
                } else {
                    focused = false
                    store.completeOnboarding(name: name, city: city, role: role)
                }
            } label: {
                HStack(spacing: 8) {
                    Text(page == 0 ? "Weiter" : "Tandem starten")
                    Image(systemName: page == 0 ? "arrow.right" : "sparkles")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryGlassButtonStyle(tint: store.accent))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private func principle(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(store.accent.opacity(0.14))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(store.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                Text(text)
                    .font(.system(size: 11.5, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private func field(title: String, icon: String, text: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(store.accent.opacity(0.9))
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.tertiary)
                TextField(placeholder, text: text)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .focused($focused)
            }
        }
    }
}
