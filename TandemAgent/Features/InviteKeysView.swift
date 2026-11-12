import SwiftUI
import UIKit

/// Invite-Codes: erzeugen, kopieren, teilen, löschen. Eine schlichte Liste.
struct InviteKeysView: View {
    @Environment(TandemStore.self) private var store
    @State private var justCopied: String?

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(store.inviteKeys.count) erzeugt")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                    Text("\(store.inviteKeys.filter { $0.redeemed }.count) eingelöst · \(store.inviteKeys.filter { !$0.redeemed }.count) offen")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textSecondary)
                }
                .padding(.vertical, 2)
            } footer: {
                Text("Ein Code schaltet genau eine Installation frei. Sobald jemand ihn einträgt, erscheint er hier als eingelöst.")
            }

            Section {
                Button {
                    let key = store.generateInvite()
                    copy(key.code)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .medium))
                        Text("Neuen Code erzeugen")
                    }
                    .foregroundStyle(Palette.textPrimary)
                }
            }

            if !store.inviteKeys.isEmpty {
                Section("Deine Codes") {
                    ForEach(store.inviteKeys) { key in
                        keyRow(key)
                    }
                }
            }

            Section {
                ForEach(InviteKeys.masterKeys, id: \.self) { master in
                    HStack(spacing: 10) {
                        Text(master)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(Palette.textPrimary)
                        Spacer(minLength: 8)
                        Text(master == store.unlockedKey ? "dein Code" : "gültig")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.textTertiary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            copy(master)
                        } label: {
                            Label("Kopieren", systemImage: "doc.on.doc")
                        }
                    }
                }
            } header: {
                Text("Immer gültig")
            } footer: {
                Text("Diese Codes laufen nicht ab und lassen sich nicht widerrufen.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground(theme: store.themeChoice, accent: store.accent))
        .navigationTitle("Invite-Codes")
        .navigationBarTitleDisplayMode(.inline)
        .tint(store.accent)
    }

    private func keyRow(_ key: InviteKey) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(key.code)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Palette.textPrimary)
                Text("\(key.redeemed ? "eingelöst" : "offen") · \(RelativeTime.string(from: key.createdAt))")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer(minLength: 8)

            Button {
                copy(key.code)
            } label: {
                Image(systemName: justCopied == key.code ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 14))
                    .foregroundStyle(justCopied == key.code ? Palette.accent : Palette.icon)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kopieren")

            ShareLink(item: shareText(for: key.code)) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.icon)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.revokeInvite(key.id)
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }

    private func shareText(for code: String) -> String {
        """
        Hier ist dein Invite-Code für Tandem: \(code)

        1. Tandem installieren (IPA von github.com/joe-design9/tandem-agent/releases)
        2. App öffnen, Code eintragen
        3. Loslegen — der Agent läuft sofort, auch ohne API-Key.

        Der Code gilt für eine Installation.
        """
    }

    private func copy(_ code: String) {
        UIPasteboard.general.string = code
        Haptics.success()
        justCopied = code
        store.showToast("\(code) kopiert", style: .success)
        Task {
            try? await Task.sleep(for: .seconds(2))
            if justCopied == code { justCopied = nil }
        }
    }
}
