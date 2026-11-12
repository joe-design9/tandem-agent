import SwiftUI
import UIKit

/// Der Invite-Generator: Tandem ist eine geschlossene Preview, also
/// verteilt Joel die Zugänge selbst — ein Tipp erzeugt einen Code,
/// ein zweiter teilt ihn. Codes kommen im Vice-Style.
struct InviteKeysView: View {
    @Environment(TandemStore.self) private var store
    @State private var justCopied: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                founderCard
                generateButton

                SectionHeader(title: "Deine Codes", subtitle: nil, icon: "key.horizontal.fill",
                              trailing: "\(store.inviteKeys.count)")
                if store.inviteKeys.isEmpty {
                    GlassCard(tint: VicePalette.cyan, glow: false) {
                        Text("Noch keine Codes. Erzeuge den ersten — er gilt für genau eine Installation.")
                            .font(.system(size: 11.5, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(store.inviteKeys) { key in
                            keyRow(key)
                        }
                    }
                }

                SectionHeader(title: "Leonida Master-Keys", subtitle: nil, icon: "crown.fill", trailing: "immer gültig")
                GlassCard(tint: VicePalette.gold, glow: false, padding: 8) {
                    VStack(spacing: 0) {
                        ForEach(InviteKeys.masterKeys, id: \.self) { master in
                            HStack(spacing: 9) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(VicePalette.gold)
                                    .shadow(color: VicePalette.gold.opacity(0.8), radius: 5)
                                    .frame(width: 16)
                                Text(master)
                                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.92))
                                Spacer()
                                Text(master == store.unlockedKey ? "dein Key" : "gültig")
                                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                    .foregroundStyle(master == store.unlockedKey ? VicePalette.cyan : .tertiary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 9)
                            if master != InviteKeys.masterKeys.last {
                                NeonDivider()
                                    .opacity(0.5)
                            }
                        }
                    }
                }

                Text("Ein Code schaltet eine Installation frei. Sobald jemand ihn im Gatekeeper einträgt, erscheint er hier als eingelöst. Codes lassen sich jederzeit löschen — bereits freigeschaltete Geräte bleiben drin.")
                    .font(.system(size: 10.5, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Invite Keys")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var founderCard: some View {
        GlassCard(tint: VicePalette.magenta, glow: true, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [VicePalette.gold, VicePalette.coral, VicePalette.magenta],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 48, height: 48)
                            .shadow(color: VicePalette.magenta.opacity(0.75), radius: 14)
                        PalmGlyph(tint: Color(red: 0.05, green: 0.01, blue: 0.10), rim: nil)
                            .frame(width: 26, height: 30)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("VIP FOUNDER")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(LinearGradient(colors: [.white, VicePalette.gold],
                                                                startPoint: .top, endPoint: .bottom))
                                .shadow(color: VicePalette.gold.opacity(0.55), radius: 10)
                            StatusBadge(text: "Leonida", tint: VicePalette.cyan, icon: "sun.horizon.fill")
                        }
                        Text("Eingelöst mit \(store.unlockedKey.isEmpty ? "—" : store.unlockedKey)")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }

                NeonDivider()

                HStack(spacing: 18) {
                    stat(value: "\(store.inviteKeys.count)", label: "erzeugt")
                    stat(value: "\(store.inviteKeys.filter { $0.redeemed }.count)", label: "eingelöst")
                    stat(value: "\(store.inviteKeys.filter { !$0.redeemed }.count)", label: "offen")
                }
            }
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(size: 19, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(label.uppercased())
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.secondary)
        }
    }

    private var generateButton: some View {
        Button {
            let key = store.generateInvite()
            copy(key.code)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Neuen Vice-Key erzeugen")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryGlassButtonStyle(tint: VicePalette.magenta))
    }

    private func keyRow(_ key: InviteKey) -> some View {
        GlassCard(tint: key.redeemed ? nil : VicePalette.cyan, glow: !key.redeemed, padding: 13) {
            HStack(spacing: 11) {
                Image(systemName: key.redeemed ? "checkmark.seal.fill" : "key.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(key.redeemed ? Color(red: 0.40, green: 1.00, blue: 0.74) : VicePalette.cyan)
                    .shadow(color: (key.redeemed ? VicePalette.mint : VicePalette.cyan).opacity(0.7), radius: 6)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(key.code)
                        .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                        .tracking(0.6)
                        .foregroundStyle(.white)
                    HStack(spacing: 5) {
                        Text(key.redeemed ? "eingelöst" : "offen")
                        Text("·")
                        Text(RelativeTime.string(from: key.createdAt))
                    }
                    .font(.system(size: 9.5, design: .rounded))
                    .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)

                Button {
                    copy(key.code)
                } label: {
                    Image(systemName: justCopied == key.code ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(justCopied == key.code ? VicePalette.cyan : .secondary)
                        .frame(width: 30, height: 30)
                        .background { Circle().fill(Color.white.opacity(0.08)) }
                }
                .buttonStyle(.plain)

                ShareLink(item: shareText(for: key.code)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background { Circle().fill(Color.white.opacity(0.08)) }
                }
                .buttonStyle(.plain)

                Menu {
                    Button {
                        copy(key.code)
                    } label: {
                        Label("Kopieren", systemImage: "doc.on.doc")
                    }
                    if !key.redeemed {
                        Button {
                            if let index = store.inviteKeys.firstIndex(where: { $0.id == key.id }) {
                                store.inviteKeys[index].redeemed = true
                                store.inviteKeys[index].redeemedAt = Date()
                                store.persist()
                                store.showToast("Als eingelöst markiert", style: .info)
                            }
                        } label: {
                            Label("Als eingelöst markieren", systemImage: "checkmark.seal")
                        }
                    }
                    Button(role: .destructive) {
                        store.revokeInvite(key.id)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background { Circle().fill(Color.white.opacity(0.08)) }
                }
            }
        }
    }

    private func shareText(for code: String) -> String {
        """
        Tandem ist in der Research Preview — hier ist dein Invite-Key: \(code)

        So kommst du rein:
        1. Tandem installieren (Sideloadly / AltStore, IPA von github.com/joe-design9/tandem-agent/releases)
        2. App öffnen, Key eintragen
        3. Fertig — der Agent läuft sofort, auch ohne API-Key. Willkommen in Leonida.

        Der Key gilt für eine Installation. Behalte ihn für dich.
        """
    }

    private func copy(_ code: String) {
        UIPasteboard.general.string = code
        Haptics.success()
        withAnimation(.easeOut(duration: 0.2)) { justCopied = code }
        store.showToast("\(code) kopiert", style: .success)
        Task {
            try? await Task.sleep(for: .seconds(2))
            if justCopied == code {
                withAnimation { justCopied = nil }
            }
        }
    }
}
