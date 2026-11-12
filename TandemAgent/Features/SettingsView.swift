import SwiftUI

struct SettingsView: View {
    @Environment(TandemStore.self) private var store

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    backboneCard
                    section("Backbone", icon: "cpu") {
                        NavigationLink {
                            ProviderSettingsView()
                        } label: {
                            row(icon: store.provider.icon,
                                tint: store.provider.tint,
                                title: store.provider.title,
                                subtitle: store.isSimulator ? "Offline, ohne API-Key" : store.selectedModel,
                                trailing: "wechseln")
                        }
                        .buttonStyle(.plain)
                    }

                    section("Zugang", icon: "key.fill") {
                        NavigationLink {
                            InviteKeysView()
                        } label: {
                            row(icon: "person.badge.key.fill",
                                tint: store.accent,
                                title: "Invite Keys teilen",
                                subtitle: "\(store.inviteKeys.filter { !$0.redeemed }.count) offen · \(store.inviteKeys.count) erzeugt",
                                trailing: store.isFounder ? "Founder" : "öffnen")
                        }
                        .buttonStyle(.plain)
                    }

                    section("Vice City Design", icon: "sun.horizon.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 9) {
                                ForEach(GlacierTheme.allCases) { theme in
                                    themeTile(theme)
                                }
                            }
                            Text(store.themeChoice.subtitle)
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                .foregroundStyle(VicePalette.gold.opacity(0.85))
                            NeonDivider()
                            HStack(spacing: 8) {
                                ForEach(AccentChoice.allCases) { accent in
                                    accentDot(accent)
                                }
                                Spacer(minLength: 0)
                            }
                            Text("Akzent: \(store.accentChoice.title)")
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                            NeonDivider()
                            HStack(spacing: 4) {
                                ForEach(Appearance.allCases) { appearance in
                                    appearanceButton(appearance)
                                }
                            }
                        }
                    }

                    section("Verhalten", icon: "slider.horizontal.3") {
                        VStack(spacing: 12) {
                            toggleRow(icon: "wand.and.stars", title: "Glow-Effekte",
                                      subtitle: "Akzentlicht auf Glasflächen", isOn: $store.glowEnabled)
                            Divider().opacity(0.15)
                            toggleRow(icon: "hand.tap.fill", title: "Haptik",
                                      subtitle: "Feedback bei Entscheidungen", isOn: $store.hapticsEnabled)
                            Divider().opacity(0.15)
                            toggleRow(icon: "dot.radiowaves.left.and.right", title: "Proaktive Scans",
                                      subtitle: "Alle 15 Minuten im Hintergrund", isOn: $store.proactiveEnabled)
                            Divider().opacity(0.15)
                            toggleRow(icon: "moon.zzz.fill", title: "Ruhezeit 23–7 Uhr",
                                      subtitle: "Keine Push-Störungen in der Nacht", isOn: $store.quietHoursEnabled)
                        }
                    }

                    section("Standard-Autonomie", icon: "figure.walk.motion") {
                        VStack(spacing: 8) {
                            ForEach(AutonomyLevel.allCases) { level in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                        store.defaultAutonomy = level
                                    }
                                    Haptics.selection()
                                } label: {
                                    HStack(spacing: 9) {
                                        Image(systemName: level.icon)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(level.tint)
                                            .frame(width: 18)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(level.title)
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            Text(level.detail)
                                                .font(.system(size: 10, design: .rounded))
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: store.defaultAutonomy == level ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 14))
                                            .foregroundStyle(store.defaultAutonomy == level ? store.accent : Color.white.opacity(0.18))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    section("Über Tandem", icon: "info.circle") {
                        VStack(spacing: 10) {
                            infoRow("Version", value: version)
                            Divider().opacity(0.15)
                            infoRow("Bundle", value: "dev.joe.tandem")
                            Divider().opacity(0.15)
                            Link(destination: URL(string: "https://github.com/joe-design9/tandem-agent")!) {
                                HStack {
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                    Text("Quellcode auf GitHub")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            Divider().opacity(0.15)
                            HStack {
                                Text("Gebaut für \(store.userName)")
                                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                                Spacer()
                                Text("Research Preview")
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Mehr")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "2"
        return "\(short) (\(build)) · Leonida"
    }

    private var backboneCard: some View {
        GlassCard(tint: store.provider.tint, glow: true, padding: 18) {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(store.provider.tint.opacity(0.16))
                        .frame(width: 46, height: 46)
                    Image(systemName: store.provider.icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(store.provider.tint)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.isSimulator ? "Simulator aktiv" : "Modell verbunden")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text(store.isSimulator
                         ? "Tandem denkt lokal. Schalte einen Anbieter dazu, wenn du echte Modelle willst."
                         : "\(store.provider.title) · \(store.provider.models.first { $0.id == store.selectedModel }?.name ?? store.selectedModel)")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Circle()
                    .fill(store.isSimulator ? store.accent : Color(red: 0.50, green: 0.92, blue: 0.74))
                    .frame(width: 8, height: 8)
                    .shadow(color: store.accent, radius: 6)
            }
        }
    }

    private func section<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: title, subtitle: nil, icon: icon, trailing: nil)
            GlassCard(tint: nil, glow: false, padding: 14) {
                content()
            }
        }
    }

    private func row(icon: String, tint: Color, title: String, subtitle: String, trailing: String?) -> some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 10.5, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if let trailing {
                Text(trailing)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.tertiary)
        }
    }

    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(store.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(store.accent)
                .scaleEffect(0.82)
        }
    }

    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11.5, design: .rounded))
            Spacer()
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private func themeTile(_ theme: GlacierTheme) -> some View {
        let selected = store.themeChoice == theme
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                store.themeChoice = theme
            }
            Haptics.selection()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(previewGradient(theme))
                        .frame(height: 56)
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 34, height: 12)
                        .overlay {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.40), lineWidth: 0.6)
                        }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(selected ? VicePalette.cyan : Color.white.opacity(0.10),
                                      lineWidth: selected ? 1.6 : 0.8)
                }
                .shadow(color: selected ? VicePalette.cyan.opacity(0.55) : .clear, radius: 8)
                Text(theme.title)
                    .font(.system(size: 9.5, weight: selected ? .black : .medium, design: .rounded))
                    .foregroundStyle(selected ? VicePalette.cyan : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func previewGradient(_ theme: GlacierTheme) -> LinearGradient {
        switch theme {
        case .electricVice:
            return LinearGradient(stops: [
                .init(color: Color(red: 0.16, green: 0.02, blue: 0.34), location: 0.0),
                .init(color: Color(red: 0.86, green: 0.09, blue: 0.49), location: 0.42),
                .init(color: VicePalette.coral, location: 0.62),
                .init(color: VicePalette.gold, location: 0.74),
                .init(color: Color(red: 0.10, green: 0.02, blue: 0.18), location: 0.78),
                .init(color: Color(red: 0.05, green: 0.01, blue: 0.10), location: 1.0),
            ], startPoint: .top, endPoint: .bottom)
        case .aurora:
            return LinearGradient(colors: [Color(red: 0.06, green: 0.07, blue: 0.22),
                                           Color(red: 0.18, green: 0.42, blue: 0.45),
                                           store.accent.opacity(0.75)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .neonVice:
            return LinearGradient(colors: [Color(red: 0.18, green: 0.02, blue: 0.28),
                                           Color(red: 0.85, green: 0.12, blue: 0.48),
                                           Color(red: 1.0, green: 0.62, blue: 0.35)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .titanium:
            return LinearGradient(colors: [Color(red: 0.14, green: 0.15, blue: 0.17),
                                           Color(red: 0.35, green: 0.37, blue: 0.40),
                                           Color(red: 0.10, green: 0.11, blue: 0.12)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func accentDot(_ accent: AccentChoice) -> some View {
        let selected = store.accentChoice == accent
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                store.accentChoice = accent
            }
            Haptics.selection()
        } label: {
            Circle()
                .fill(accent.gradient)
                .frame(width: 23, height: 23)
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(selected ? 0.9 : 0.25), lineWidth: selected ? 2 : 0.8)
                }
                .overlay {
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.black.opacity(0.70))
                    }
                }
                .shadow(color: selected ? accent.color.opacity(0.8) : .clear, radius: 7)
        }
        .buttonStyle(.plain)
    }

    private func appearanceButton(_ appearance: Appearance) -> some View {
        let selected = store.appearance == appearance
        return Button {
            withAnimation(.easeInOut(duration: 0.25)) { store.appearance = appearance }
            Haptics.selection()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: appearance.icon).font(.system(size: 10, weight: .semibold))
                Text(appearance.title).font(.system(size: 10.5, weight: .medium, design: .rounded))
            }
            .foregroundStyle(selected ? Color.black.opacity(0.85) : .secondary)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background {
                if selected {
                    Capsule().fill(store.accent.gradient)
                } else {
                    Capsule().fill(Color.white.opacity(0.06))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Provider

struct ProviderSettingsView: View {
    @Environment(TandemStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var keyDraft = ""
    @State private var showKey = false
    @State private var baseURLDraft = ""
    @State private var customModelDraft = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                engineBanner

                SectionHeader(title: "Anbieter", subtitle: nil, icon: "cpu", trailing: nil)
                VStack(spacing: 8) {
                    ForEach(ProviderID.allCases) { provider in
                        providerRow(provider)
                    }
                }

                SectionHeader(title: "Modell", subtitle: nil, icon: "square.stack.3d.up", trailing: store.provider.title)
                VStack(spacing: 6) {
                    ForEach(store.provider.models) { model in
                        modelRow(model)
                    }
                }

                if store.provider == .custom {
                    GlassCard(tint: nil, glow: false) {
                        VStack(alignment: .leading, spacing: 10) {
                            fieldLabel("Modellname")
                            TextField("z. B. qwen3-32b", text: $customModelDraft)
                                .font(.system(size: 12.5, design: .monospaced))
                                .padding(10)
                                .background { RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.06)) }
                                .onSubmit { store.customModel = customModelDraft }
                            fieldLabel("Base-URL")
                            TextField("https://dein-server/v1", text: $baseURLDraft)
                                .font(.system(size: 12.5, design: .monospaced))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(10)
                                .background { RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.06)) }
                                .onSubmit { store.setBaseURL(baseURLDraft) }
                            Button {
                                store.customModel = customModelDraft
                                store.setBaseURL(baseURLDraft)
                                store.showToast("Endpoint gespeichert", style: .success)
                            } label: {
                                Text("Übernehmen").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryGlassButtonStyle())
                        }
                    }
                }

                if store.provider.needsKey {
                    keySection
                } else {
                    GlassCard(tint: store.accent, glow: false) {
                        HStack(spacing: 10) {
                            Image(systemName: "wifi.slash").foregroundStyle(store.accent)
                            Text("Der Simulator braucht keinen Key. Er antwortet aus dem App-Zustand und läuft auch im Flugmodus.")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                testSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Backbone")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            keyDraft = store.apiKey(for: store.provider)
            baseURLDraft = store.baseURLs[store.provider.rawValue] ?? store.provider.defaultBaseURL
            customModelDraft = store.customModel
        }
        .onChange(of: store.provider) { _, _ in
            keyDraft = store.apiKey(for: store.provider)
            baseURLDraft = store.baseURLs[store.provider.rawValue] ?? store.provider.defaultBaseURL
            store.testResult = nil
        }
    }

    private var engineBanner: some View {
        GlassCard(tint: store.provider.tint, glow: true) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(store.provider.tint.opacity(0.16)).frame(width: 40, height: 40)
                    Image(systemName: store.isSimulator ? "sparkles" : "antenna.radiowaves.left.and.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(store.provider.tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.isSimulator ? "Simulator" : store.provider.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text(store.isSimulator
                         ? "Läuft ohne Netz. Gut zum Ausprobieren."
                         : "Aktives Modell: \(store.selectedModel)")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func providerRow(_ provider: ProviderID) -> some View {
        let selected = store.provider == provider
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                store.provider = provider
            }
            Haptics.selection()
        } label: {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(provider.tint.opacity(0.14))
                        .frame(width: 32, height: 32)
                    Image(systemName: provider.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(provider.tint)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(provider.title)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    Text(provider.subtitle)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if provider.needsKey {
                    Image(systemName: store.keyPresence[provider.rawValue] == true ? "key.fill" : "key.slash")
                        .font(.system(size: 9))
                        .foregroundStyle(store.keyPresence[provider.rawValue] == true ? store.accent : Color.secondary.opacity(0.5))
                }
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(selected ? provider.tint : Color.white.opacity(0.18))
            }
            .padding(11)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? provider.tint.opacity(0.10) : Color.white.opacity(0.03))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(selected ? provider.tint.opacity(0.40) : Color.white.opacity(0.08),
                                          lineWidth: 0.9)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    private func modelRow(_ model: ModelOption) -> some View {
        let selected = store.selectedModel == model.id
        return Button {
            store.setModel(model.id)
            store.testResult = nil
            Haptics.selection()
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(model.name)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                    Text(model.note)
                        .font(.system(size: 9.5, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13))
                    .foregroundStyle(selected ? store.accent : Color.white.opacity(0.16))
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? store.accent.opacity(0.08) : Color.white.opacity(0.02))
            }
        }
        .buttonStyle(.plain)
    }

    private var keySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "API-Key", subtitle: nil, icon: "key.fill",
                          trailing: store.keyPresence[store.provider.rawValue] == true ? "gesichert" : "fehlt")
            GlassCard(tint: nil, glow: false) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Group {
                            if showKey {
                                TextField(store.provider.keyHint, text: $keyDraft)
                            } else {
                                SecureField(store.provider.keyHint, text: $keyDraft)
                            }
                        }
                        .font(.system(size: 12, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    }

                    HStack(spacing: 8) {
                        Button {
                            store.saveKey(keyDraft, for: store.provider)
                        } label: {
                            Text("Sichern").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryGlassButtonStyle(tint: store.provider.tint))

                        if store.keyPresence[store.provider.rawValue] == true {
                            Button {
                                store.removeKey(for: store.provider)
                                keyDraft = ""
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 11)
                            }
                            .buttonStyle(SecondaryGlassButtonStyle())
                        }
                    }

                    Text("Der Key liegt im iOS-Keychain, nicht in den Einstellungen und nicht im Code. Er geht nur an den gewählten Anbieter.")
                        .font(.system(size: 9.5, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var testSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            GlassCard(tint: nil, glow: false) {
                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 8) {
                        Button {
                            store.testProvider()
                        } label: {
                            HStack(spacing: 6) {
                                if store.isTesting {
                                    ProgressView().controlSize(.mini).tint(.black.opacity(0.7))
                                } else {
                                    Image(systemName: "bolt.horizontal.circle.fill")
                                }
                                Text(store.isTesting ? "Teste…" : "Verbindung testen")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryGlassButtonStyle())
                        .disabled(store.isTesting)
                    }
                    if let result = store.testResult {
                        Text(result)
                            .font(.system(size: 10.5, design: .rounded))
                            .foregroundStyle(result.hasPrefix("Verbunden")
                                             ? Color(red: 0.50, green: 0.92, blue: 0.74)
                                             : Color(red: 1.0, green: 0.60, blue: 0.60))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if store.provider.needsKey, let url = dashboardURL {
                        Link(destination: url) {
                            HStack(spacing: 4) {
                                Text("Key besorgen")
                                Image(systemName: "arrow.up.right").font(.system(size: 8, weight: .bold))
                            }
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(store.provider.tint)
                        }
                    }
                }
            }
        }
    }

    private var dashboardURL: URL? {
        switch store.provider {
        case .anthropic: return URL(string: "https://console.anthropic.com/settings/keys")
        case .openai: return URL(string: "https://platform.openai.com/api-keys")
        case .deepseek: return URL(string: "https://platform.deepseek.com/api_keys")
        case .openrouter: return URL(string: "https://openrouter.ai/keys")
        default: return nil
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .tracking(1.1)
            .foregroundStyle(.tertiary)
    }
}
