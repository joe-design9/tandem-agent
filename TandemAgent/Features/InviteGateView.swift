import SwiftUI

/// Der Gatekeeper: Tandem startet als geschlossene Preview. Ohne
/// Clearance-Code bleibt alles hinter Glas — und das Glas ist schwarz.
struct InviteGateView: View {
    @Environment(TandemStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    @State private var key = ""
    @State private var error: String?
    @State private var shake: CGFloat = 0
    @State private var unlocking = false
    @State private var glow = false
    @FocusState private var fieldFocused: Bool

    private let tiers: [(code: String, level: String)] = [
        ("JOEL-VIP", "Founder"),
        ("VICE-VIP", "VIP"),
        ("LEONIDA-DEV", "Developer"),
        ("OCEAN-DRIVE", "Guest"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 10)
                emblem

                VStack(spacing: 8) {
                    Text("TANDEM")
                        .font(.system(size: 13, weight: .heavy))
                        .fontWidth(.expanded)
                        .tracking(7)
                        .foregroundStyle(Color.white.opacity(0.55))

                    Text("LEONIDA")
                        .font(.system(size: 46, weight: .heavy))
                        .fontWidth(.condensed)
                        .tracking(1.0)
                        .foregroundStyle(LinearGradient(colors: [.white, Color.white.opacity(0.62)],
                                                       startPoint: .top, endPoint: .bottom))

                    Text("CLEARANCE GATE")
                        .font(.system(size: 9.5, weight: .heavy))
                        .fontWidth(.expanded)
                        .tracking(4.4)
                        .foregroundStyle(VicePalette.cyan.opacity(0.85))

                    HStack(spacing: 6) {
                        Circle()
                            .fill(store.accent)
                            .frame(width: 4, height: 4)
                        Text("PRIVATE PREVIEW · INVITE ONLY")
                            .font(.system(size: 8, weight: .semibold))
                            .fontWidth(.condensed)
                            .tracking(1.8)
                    }
                    .foregroundStyle(Color.white.opacity(0.32))
                    .padding(.top, 2)
                }

                gateCard
                tierList

                Spacer(minLength: 10)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill").font(.system(size: 9))
                    Text("Lokal geprüft · kein Konto nötig · v1.2.0 The Autonomous Agent")
                        .font(.system(size: 9.5, weight: .medium))
                }
                .foregroundStyle(Color.white.opacity(0.24))
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 22)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }

    private var emblem: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [VicePalette.magenta.opacity(0.28),
                                              VicePalette.violet.opacity(0.12),
                                              .clear],
                                     center: .center, startRadius: 2, endRadius: 110))
                .frame(width: 210, height: 210)
                .blur(radius: glow ? 8 : 2)
                .scaleEffect(glow ? 1.04 : 0.97)

            AgentEmblem(tint: store.accent, rim: VicePalette.cyan)
                .frame(width: 176, height: 176)
        }
        .frame(height: 196)
    }

    private var gateCard: some View {
        GlassCard(tint: store.accent, glow: true, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .frame(width: 36, height: 36)
                        .background {
                            Circle().fill(.ultraThinMaterial)
                                .overlay { Circle().fill(store.accent.opacity(0.10)) }
                        }
                        .overlay { Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5) }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Clearance erforderlich")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.94))
                        Text("Gib deinen Code ein. Er schaltet genau diese Installation frei — der Agent startet sofort, auch ohne API-Key.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.44))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "key.horizontal.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(store.accent)
                    TextField("CODE", text: $key)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .tracking(2.2)
                        .foregroundStyle(Color.white.opacity(0.96))
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
                                .foregroundStyle(Color.white.opacity(0.28))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 15)
                .background {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(Color.black.opacity(colorScheme == .light ? 0.05 : 0.26))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .strokeBorder(fieldBorder, lineWidth: 0.7)
                        }
                }
                .modifier(ShakeEffect(shakes: shake))

                if let error {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 9))
                        Text(error).font(.system(size: 11.5, weight: .medium))
                    }
                    .foregroundStyle(VicePalette.coral)
                    .transition(.opacity)
                }

                Button(action: attempt) {
                    HStack(spacing: 8) {
                        if unlocking {
                            ProgressView().controlSize(.small).tint(.black.opacity(0.7))
                        } else {
                            Image(systemName: "lock.open.fill").font(.system(size: 12, weight: .semibold))
                        }
                        Text(unlocking ? "Clearance wird geprüft…" : "Clearance freigeben")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryGlassButtonStyle(tint: store.accent))
                .disabled(key.trimmingCharacters(in: .whitespaces).isEmpty || unlocking)

                Text("Jeder Code gilt für eine Installation. Founder-Codes bleiben dauerhaft gültig.")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.26))
            }
        }
    }

    private var tierList: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 6) {
                Text("BEKANNTE CLEARANCE")
                    .font(.system(size: 8.5, weight: .heavy))
                    .fontWidth(.expanded)
                    .tracking(2.0)
                Spacer()
                Text("tippen zum Einsetzen")
                    .font(.system(size: 9))
            }
            .foregroundStyle(Color.white.opacity(0.26))
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(tiers, id: \.code) { tier in
                    Button {
                        key = tier.code
                        error = nil
                        Haptics.tap()
                    } label: {
                        HStack(spacing: 10) {
                            Text(tier.level.uppercased())
                                .font(.system(size: 9, weight: .heavy))
                                .fontWidth(.condensed)
                                .tracking(1.2)
                                .foregroundStyle(Color.white.opacity(0.34))
                                .frame(width: 68, alignment: .leading)
                            Text(tier.code)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .tracking(1.0)
                                .foregroundStyle(Color.white.opacity(0.78))
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.20))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 11)
                    }
                    .buttonStyle(.plain)

                    if tier.code != tiers.last?.code {
                        Rectangle().fill(Color.white.opacity(0.05))
                            .frame(height: 0.5)
                            .padding(.leading, 12)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.02))
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            }
        }
    }

    private var fieldBorder: LinearGradient {
        error == nil
            ? LinearGradient(colors: [store.accent.opacity(0.55), Color.white.opacity(0.10)],
                             startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(colors: [VicePalette.coral, VicePalette.coral.opacity(0.4)],
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
                error = key.isEmpty ? "Bitte gib einen Clearance-Code ein." : "Dieser Code ist ungültig oder bereits verbraucht."
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
