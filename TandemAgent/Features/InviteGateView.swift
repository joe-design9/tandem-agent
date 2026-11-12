import SwiftUI

/// Der Einstieg: eine ruhige Seite, ein Feld, ein Knopf. Kein Gate,
/// keine Clearance, keine Kulisse.
struct InviteGateView: View {
    @Environment(TandemStore.self) private var store

    @State private var key = ""
    @State private var error: String?
    @State private var unlocking = false
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 64)

                TandemMark(size: 52)

                Text("Tandem")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.top, 18)

                Text("Dein persönlicher Agent.")
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Willkommen")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Palette.textPrimary)
                        Text("Bitte gib deinen Einladungscode ein.")
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.textSecondary)
                    }

                    HStack(spacing: 8) {
                        TextField("Einladungscode", text: $key)
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundStyle(Palette.textPrimary)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .submitLabel(.go)
                            .focused($fieldFocused)
                            .onSubmit(attempt)
                            .onChange(of: key) { _, newValue in
                                let formatted = InviteKeys.formatted(newValue)
                                if formatted != newValue { key = formatted }
                                if error != nil { error = nil }
                            }
                        if !key.isEmpty {
                            Button {
                                key = ""
                                fieldFocused = true
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Palette.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Palette.surface)
                    }

                    if let error {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.danger)
                    }

                    Button(action: attempt) {
                        HStack(spacing: 8) {
                            if unlocking {
                                ProgressView().controlSize(.small)
                            }
                            Text(unlocking ? "Wird geprüft…" : "Weiter")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(key.trimmingCharacters(in: .whitespaces).isEmpty || unlocking)

                    Text("Code: JOEL-VIP")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textTertiary)
                }
                .padding(.top, 44)

                Spacer(minLength: 48)

                Text("Lokal geprüft · kein Konto nötig")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textTertiary)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func attempt() {
        guard !unlocking else { return }
        fieldFocused = false
        if store.redeem(key) {
            unlocking = true
            Haptics.success()
        } else {
            error = key.trimmingCharacters(in: .whitespaces).isEmpty
                ? "Bitte gib einen Einladungscode ein."
                : "Dieser Code ist ungültig."
            Haptics.warning()
        }
    }
}

/// Die Marke: zwei feine, ineinandergreifende Ringe. Statisch, kein Licht.
struct TandemMark: View {
    var size: CGFloat = 44
    var line: Color = Palette.textPrimary
    var accent: Color = Palette.accent

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(line, lineWidth: max(1, size * 0.045))
                .frame(width: size * 0.72, height: size * 0.72)
                .offset(x: -size * 0.14)
            Circle()
                .strokeBorder(accent, lineWidth: max(1, size * 0.045))
                .frame(width: size * 0.72, height: size * 0.72)
                .offset(x: size * 0.14)
        }
        .frame(width: size, height: size)
    }
}
