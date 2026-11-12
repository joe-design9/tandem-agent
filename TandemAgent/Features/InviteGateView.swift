import SwiftUI

/// Der Gatekeeper: Tandem startet als geschlossene Research Preview.
/// Ohne eingelösten Invite-Key bleibt die Stadt hinter Glas.
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
            VStack(spacing: 18) {
                Spacer(minLength: 12)
                emblem

                VStack(spacing: 7) {
                    Text("TANDEM")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .tracking(9)
                        .foregroundStyle(
                            LinearGradient(colors: [.white,
                                                    VicePalette.gold,
                                                    VicePalette.coral,
                                                    VicePalette.magenta],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: VicePalette.magenta.opacity(0.70), radius: 22)
                    Text("LEONIDA RESEARCH PREVIEW")
                        .font(.system(size: 9.5, weight: .black, design: .rounded))
                        .tracking(3.2)
                        .foregroundStyle(VicePalette.cyan)
                        .shadow(color: VicePalette.cyan.opacity(0.85), radius: 9)
                    HStack(spacing: 5) {
                        Image(systemName: "sun.horizon.fill").font(.system(size: 8, weight: .bold))
                        Text("VICE CITY · INVITE ONLY")
                            .font(.system(size: 8.5, weight: .black, design: .rounded))
                            .tracking(1.6)
                    }
                    .foregroundStyle(VicePalette.gold.opacity(0.85))
                    .padding(.top, 2)
                }

                gateCard

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showFounderHint.toggle()
                    }
                    Haptics.tap()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "key.horizontal.fill").font(.system(size: 10, weight: .bold))
                        Text("Wie komme ich nach Leonida?").font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(VicePalette.cyan.opacity(0.9))
                }
                .buttonStyle(.plain)

                if showFounderHint {
                    Text("Tandem ist geschlossen. Den Key bekommst du von Joel — oder du nutzt einen Founder-Zugang:\n\(InviteKeys.masterHint)")
                        .font(.system(size: 11.5, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 22)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer(minLength: 12)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill").font(.system(size: 9))
                    Text("Lokal geprüft · kein Konto nötig · v1.1.0 Leonida")
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
                .fill(RadialGradient(colors: [VicePalette.hotPink.opacity(0.50),
                                              VicePalette.violet.opacity(0.28),
                                              .clear],
                                     center: .center, startRadius: 4, endRadius: 104))
                .frame(width: 204, height: 204)
                .blur(radius: glow ? 9 : 0)
                .scaleEffect(glow ? 1.05 : 0.95)

            Circle()
                .strokeBorder(
                    AngularGradient(colors: [
                        VicePalette.cyan.opacity(0.9),
                        Color.white.opacity(0.04),
                        VicePalette.magenta.opacity(0.85),
                        Color.white.opacity(0.04),
                        VicePalette.gold.opacity(0.7),
                        VicePalette.cyan.opacity(0.9),
                    ], center: .center),
                    lineWidth: 1.4
                )
                .frame(width: 198, height: 198)
                .rotationEffect(.degrees(glow ? 360 : 0))
                .animation(.linear(duration: 18).repeatForever(autoreverses: false), value: glow)

            ViceEmblem()
                .frame(width: 178, height: 178)
                .shadow(color: VicePalette.magenta.opacity(0.55), radius: 20)
        }
        .frame(height: 200)
    }

    private var gateCard: some View {
        GlassCard(tint: VicePalette.magenta, glow: true, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [VicePalette.magenta, VicePalette.coral],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 38, height: 38)
                            .shadow(color: VicePalette.magenta.opacity(0.7), radius: 10)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(Color.black.opacity(0.80))
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Invite erforderlich")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                        Text("Tandem ist eine geschlossene Preview. Löse deinen Key ein, dann gehört dir der Agent — und die Stadt.")
                            .font(.system(size: 12.5, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(VicePalette.cyan)
                        .shadow(color: VicePalette.cyan.opacity(0.9), radius: 7)
                    TextField("VICE-XXXX-XXXX", text: $key)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(.white)
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
                        .fill(Color.black.opacity(colorScheme == .light ? 0.06 : 0.28))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(fieldBorder, lineWidth: 1.3)
                        }
                        .shadow(color: error == nil ? VicePalette.cyan.opacity(0.35) : Color(red: 1, green: 0.30, blue: 0.45).opacity(0.5),
                                radius: 12)
                }
                .modifier(ShakeEffect(shakes: shake))

                if let error {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10))
                        Text(error).font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.58))
                    .transition(.opacity)
                }

                Button(action: attempt) {
                    HStack(spacing: 8) {
                        if unlocking {
                            ProgressView().controlSize(.small).tint(.black.opacity(0.7))
                        } else {
                            Image(systemName: "lock.open.fill")
                        }
                        Text(unlocking ? "Stadt wird geöffnet…" : "Vice City betreten")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryGlassButtonStyle(tint: VicePalette.magenta))
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

    private var fieldBorder: LinearGradient {
        error == nil
            ? LinearGradient(colors: [VicePalette.cyan, VicePalette.magenta, VicePalette.gold],
                             startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(colors: [Color(red: 1, green: 0.30, blue: 0.45),
                                      Color(red: 1, green: 0.30, blue: 0.45)],
                             startPoint: .topLeading, endPoint: .bottomTrailing)
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
