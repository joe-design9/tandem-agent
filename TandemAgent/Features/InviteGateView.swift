import SwiftUI

/// Der Gatekeeper: Tandem startet als geschlossene Research Preview.
/// Ohne eingelösten Invite-Key bleibt alles hinter Glas.
struct InviteGateView: View {
    @Environment(TandemStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    @State private var key = ""
    @State private var error: String?
    @State private var shake: CGFloat = 0
    @State private var unlocking = false
    @State private var glow = false
    @State private var showFounderHint = false
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 18)
                emblem

                VStack(spacing: 6) {
                    Text("TANDEM")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .tracking(8)
                        .foregroundStyle(
                            LinearGradient(colors: [.white, store.accent.opacity(0.9)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: store.accent.opacity(0.5), radius: 18)
                    Text("RESEARCH PREVIEW")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(.secondary)
                }

                gateCard

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showFounderHint.toggle()
                    }
                    Haptics.tap()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "key.horizontal.fill").font(.system(size: 10))
                        Text("Wie komme ich an einen Key?").font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                if showFounderHint {
                    Text("Tandem ist geschlossen. Den Key bekommst du von Joel — oder du nutzt einen Founder-Zugang:\n\(InviteKeys.masterHint)")
                        .font(.system(size: 11.5, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 28)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer(minLength: 16)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill").font(.system(size: 9))
                    Text("Lokal geprüft · kein Konto nötig · v1.0.0")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.tertiary)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 22)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }

    private var emblem: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [store.accent.opacity(0.45), .clear],
                                     center: .center, startRadius: 4, endRadius: 92))
                .frame(width: 184, height: 184)
                .blur(radius: glow ? 6 : 0)
                .scaleEffect(glow ? 1.04 : 0.96)

            Circle()
                .strokeBorder(
                    AngularGradient(colors: [
                        store.accent.opacity(0.9),
                        Color.white.opacity(0.05),
                        store.accentChoice.deep.opacity(0.8),
                        Color.white.opacity(0.05),
                        store.accent.opacity(0.9),
                    ], center: .center),
                    lineWidth: 1.5
                )
                .frame(width: 118, height: 118)
                .rotationEffect(.degrees(glow ? 360 : 0))
                .animation(.linear(duration: 18).repeatForever(autoreverses: false), value: glow)

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular.tint(store.accent.opacity(0.22)),
                             in: RoundedRectangle(cornerRadius: 34, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.05)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                }
                .frame(width: 92, height: 92)
                .overlay {
                    Image(systemName: "person.line.dotted.person.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .shadow(color: store.accent.opacity(0.6), radius: 10)
                }
                .shadow(color: store.accent.opacity(0.35), radius: 24, y: 8)
        }
        .frame(height: 176)
    }

    private var gateCard: some View {
        GlassCard(tint: store.accent, glow: true, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle().fill(store.accent.opacity(0.16)).frame(width: 38, height: 38)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(store.accent)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Invite erforderlich")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Text("Tandem ist eine geschlossene Preview. Löse deinen Key ein, dann gehört der Agent dir.")
                            .font(.system(size: 12.5, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(store.accent.opacity(0.9))
                    TextField("TANDEM-XXXX-XXXX", text: $key)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .tracking(1.2)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .focused($fieldFocused)
                        .onSubmit(attempt)
                        .onChange(of: key) { _, newValue in
                            let formatted = InviteKeys.formatted(newValue)
                            if formatted != newValue { key = formatted }
                            if error != nil { withAnimation { error = nil } }
                        }
                    if !key.isEmpty {
                        Button {
                            key = ""
                            fieldFocused = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(colorScheme == .light ? 0.55 : 0.07))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(error == nil ? Color.white.opacity(0.18) : Color(red: 1, green: 0.45, blue: 0.52),
                                              lineWidth: 1)
                        }
                }
                .modifier(ShakeEffect(shakes: shake))

                if let error {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10))
                        Text(error).font(.system(size: 11.5, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(Color(red: 1.0, green: 0.52, blue: 0.58))
                    .transition(.opacity)
                }

                Button(action: attempt) {
                    HStack(spacing: 8) {
                        if unlocking {
                            ProgressView().controlSize(.small).tint(.black.opacity(0.7))
                        } else {
                            Image(systemName: "lock.open.fill")
                        }
                        Text(unlocking ? "Freischalten…" : "Zugang freischalten")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryGlassButtonStyle(tint: store.accent))
                .disabled(key.trimmingCharacters(in: .whitespaces).isEmpty || unlocking)

                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 9))
                    Text("Jeder Key schaltet genau eine Installation frei.")
                        .font(.system(size: 10.5, design: .rounded))
                }
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 2)
    }

    private func attempt() {
        guard !unlocking else { return }
        fieldFocused = false
        if store.redeem(key) {
            unlocking = true
            Haptics.success()
        } else {
            withAnimation(.linear(duration: 0.4)) { shake += 1 }
            withAnimation(.easeOut(duration: 0.2)) {
                error = key.isEmpty ? "Bitte gib einen Invite-Key ein." : "Dieser Key ist ungültig oder bereits verbraucht."
            }
            Haptics.warning()
        }
    }
}

/// Klassischer Shake-Effekt für die Key-Eingabe.
struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 8
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: travel * sin(shakes * .pi * 2), y: 0))
    }
}
