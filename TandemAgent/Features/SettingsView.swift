import SwiftUI

/// Einstellungen im ganz normalen iOS-Format: gruppierte Listen, ein
/// Akzent, keine eigenen Kacheln.
struct SettingsView: View {
    @Environment(TandemStore.self) private var store

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                Section("Modell") {
                    NavigationLink {
                        ProviderSettingsView()
                    } label: {
                        RowLabel(icon: "cpu",
                                 title: store.isSimulator ? "Siri AI (On-Device)" : store.provider.title,
                                 detail: store.isSimulator
                                    ? "Apple Intelligence · ohne Key, ohne Netz"
                                    : store.provider.models.first { $0.id == store.selectedModel }?.name ?? store.selectedModel)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Siri & Shortcuts")
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.textPrimary)
                        Text("„Hey Siri, frag Tandem nach meinem Briefing“")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.textSecondary)
                        Text("„Hey Siri, lass Tandem meine Repos prüfen“")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.textSecondary)
                        Text("„Hey Siri, leg einen Auftrag in Tandem an“")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.textSecondary)
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("Siri")
                } footer: {
                    Text("Die Sätze funktionieren ohne Einrichtung. Eigene Kurzbefehle findest du in der Kurzbefehle-App unter „Tandem“.")
                }

                Section("Zugang") {
                    NavigationLink {
                        InviteKeysView()
                    } label: {
                        RowLabel(icon: "key",
                                 title: "Invite-Codes",
                                 detail: "\(store.inviteKeys.filter { !$0.redeemed }.count) offen · \(store.inviteKeys.count) erzeugt")
                    }
                }

                Section {
                    Picker("Bühne", selection: $store.themeChoice) {
                        ForEach(TandemTheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    Picker("Akzent", selection: $store.accentChoice) {
                        ForEach(AccentChoice.allCases) { accent in
                            Text(accent.title).tag(accent)
                        }
                    }
                } header: {
                    Text("Darstellung")
                } footer: {
                    Text("\(store.themeChoice.subtitle). Der Akzent markiert aktive Zustände.")
                }

                Section("Verhalten") {
                    Toggle("Haptik", isOn: $store.hapticsEnabled)
                    Toggle("Proaktive Prüfungen", isOn: $store.proactiveEnabled)
                    Toggle("Ruhezeit 23–7 Uhr", isOn: $store.quietHoursEnabled)
                }

                Section {
                    Picker("Standard", selection: $store.defaultAutonomy) {
                        ForEach(AutonomyLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                } header: {
                    Text("Autonomie")
                } footer: {
                    Text(store.defaultAutonomy.detail)
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(version)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    Link(destination: URL(string: "https://github.com/joe-design9/tandem-agent")!) {
                        HStack {
                            Text("Quellcode auf GitHub")
                                .foregroundStyle(Palette.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Palette.textTertiary)
                        }
                    }
                } header: {
                    Text("Über Tandem")
                } footer: {
                    Text("Gebaut für \(store.userName). Kein Tandem-Konto, kein Server.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground(theme: store.themeChoice, accent: store.accent))
            .navigationTitle("Mehr")
            .navigationBarTitleDisplayMode(.large)
            .tint(store.accent)
        }
    }

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.4.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "5"
        return "\(short) (\(build))"
    }
}

// MARK: - KI-Provider

struct ProviderSettingsView: View {
    @Environment(TandemStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var keyDraft = ""
    @State private var baseURLDraft = ""
    @State private var customModelDraft = ""

    var body: some View {
        Form {
            Section {
                ForEach(ProviderID.allCases) { provider in
                    Button {
                        Haptics.selection()
                        store.provider = provider
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(provider.title)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Palette.textPrimary)
                                Text(provider.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Palette.textSecondary)
                            }
                            Spacer(minLength: 8)
                            if store.provider == provider {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Palette.accent)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Anbieter")
            } footer: {
                Text("Ohne Key antwortet Siri AI (On-Device) direkt auf dem Gerät — kein Netz, keine Anfrage nach draußen.")
            }

            Section("Modell") {
                ForEach(store.provider.models) { model in
                    Button {
                        Haptics.selection()
                        store.setModel(model.id)
                        store.testResult = nil
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.name)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Palette.textPrimary)
                                Text(model.note)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Palette.textSecondary)
                            }
                            Spacer(minLength: 8)
                            if store.selectedModel == model.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Palette.accent)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            if store.provider == .custom {
                Section("Eigener Endpoint") {
                    TextField("Modellname", text: $customModelDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit { store.customModel = customModelDraft }
                    TextField("https://dein-server/v1", text: $baseURLDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .onSubmit { store.setBaseURL(baseURLDraft) }
                    Button("Übernehmen") {
                        store.customModel = customModelDraft
                        store.setBaseURL(baseURLDraft)
                        store.showToast("Endpoint gespeichert", style: .success)
                    }
                }
            }

            if store.provider.needsKey {
                Section {
                    SecureField(store.provider.keyHint, text: $keyDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    HStack {
                        Button("Key sichern") {
                            store.saveKey(keyDraft, for: store.provider)
                        }
                        .disabled(keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        Spacer()
                        if store.keyPresence[store.provider.rawValue] == true {
                            Button("Entfernen", role: .destructive) {
                                store.removeKey(for: store.provider)
                                keyDraft = ""
                            }
                        }
                    }
                } header: {
                    Text("API-Key")
                } footer: {
                    Text("Der Key liegt im iOS-Keychain und geht nur an \(store.provider.title).")
                }
            }

            Section {
                Button {
                    store.testProvider()
                } label: {
                    HStack(spacing: 8) {
                        if store.isTesting {
                            ProgressView().controlSize(.mini)
                        }
                        Text(store.isTesting ? "Verbindung wird geprüft…" : "Verbindung testen")
                            .foregroundStyle(Palette.textPrimary)
                    }
                }
                .disabled(store.isTesting)

                if let result = store.testResult {
                    Text(result)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.textSecondary)
                }

                if let url = dashboardURL {
                    Link("Key besorgen", destination: url)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground(theme: store.themeChoice, accent: store.accent))
        .navigationTitle("Modell")
        .navigationBarTitleDisplayMode(.inline)
        .tint(store.accent)
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

    private var dashboardURL: URL? {
        switch store.provider {
        case .anthropic: return URL(string: "https://console.anthropic.com/settings/keys")
        case .openai: return URL(string: "https://platform.openai.com/api-keys")
        case .deepseek: return URL(string: "https://platform.deepseek.com/api_keys")
        case .openrouter: return URL(string: "https://openrouter.ai/keys")
        default: return nil
        }
    }
}
