import SwiftUI

/// Zwei kurze Schritte nach dem Einladungscode: was Tandem tut, und wie
/// du angesprochen werden willst.
struct OnboardingView: View {
    @Environment(TandemStore.self) private var store

    @State private var page = 0
    @State private var name = ""
    @State private var city = ""
    @State private var role = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if page == 0 {
                    welcome
                } else {
                    identity
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
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Willkommen bei Tandem")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                Text("Ich denke im Hintergrund mit, bereite Entscheidungen vor und lege sie dir hin — statt dir noch ein Chatfenster zu geben.")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Card(padding: 0) {
                VStack(spacing: 0) {
                    principle(icon: "sun.horizon",
                              title: "Proaktiv",
                              text: "Briefing am Morgen, Prüfungen über den Tag: Mails, Kalender, Repos, Gerät.")
                    ThinDivider().padding(.leading, 54)
                    principle(icon: "hand.raised",
                              title: "Erst fragen, dann handeln",
                              text: "E-Mails, Zahlungen und Kalenderänderungen gehen nie ohne dein Ja raus.")
                    ThinDivider().padding(.leading, 54)
                    principle(icon: "brain",
                              title: "Gedächtnis mit Aus-Schalter",
                              text: "Was ich über dich weiß, steht sichtbar im Gedächtnis und ist löschbar.")
                }
            }

            Card(padding: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 16))
                        .foregroundStyle(Palette.icon)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Läuft sofort, auch ohne API-Key")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Palette.textPrimary)
                        Text("Der eingebaute Simulator übernimmt den ersten Lauf. Echte Modelle schaltest du später in den Einstellungen dazu.")
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 56)
        .padding(.bottom, 20)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Wie darf ich dich nennen?")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                Text("Drei Felder, dann können Briefings und Gedächtnis richtig sortieren.")
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.textSecondary)
            }

            Card(padding: 0) {
                VStack(spacing: 0) {
                    field(title: "Name", text: $name, placeholder: "Joel")
                    ThinDivider().padding(.leading, 16)
                    field(title: "Stadt", text: $city, placeholder: "Köln")
                    ThinDivider().padding(.leading, 16)
                    field(title: "Rolle", text: $role, placeholder: "Entwickler")
                }
            }

            Text("Was du hier einträgst, bleibt auf dem Gerät. Kein Tandem-Konto, kein Server. Nur wenn du einen Anbieter anschließt, geht der jeweilige Chat dorthin.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 2)
        }
        .padding(.horizontal, 24)
        .padding(.top, 56)
        .padding(.bottom, 20)
    }

    private func principle(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Palette.icon)
                .frame(width: 24)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.textPrimary)
                Text(text)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func field(title: String, text: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(Palette.textSecondary)
                .frame(width: 62, alignment: .leading)
            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .foregroundStyle(Palette.textPrimary)
                .focused($focused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var footer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(0..<2, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Palette.accent : Palette.hairlineStrong)
                        .frame(width: index == page ? 16 : 6, height: 6)
                }
            }
            Button {
                Haptics.tap()
                if page == 0 {
                    withAnimation(.easeInOut(duration: 0.25)) { page = 1 }
                } else {
                    focused = false
                    store.completeOnboarding(name: name, city: city, role: role)
                }
            } label: {
                Text(page == 0 ? "Weiter" : "Los geht's")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}
