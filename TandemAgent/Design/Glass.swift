import SwiftUI
import UIKit

// MARK: - Palette

/// Die Bühne ist ein Tiefschwarz mit zwei Lichtquellen: Neon-Magenta und
/// Electric-Cyan, die weich im Hintergrund atmen. Kein Grid, keine Sonne,
/// keine Palme — nur Licht, Material und Typografie.
enum VicePalette {
    static let obsidian = Color(red: 0.031, green: 0.020, blue: 0.051)       // #08050D
    static let obsidianDeep = Color(red: 0.043, green: 0.027, blue: 0.078)   // #0B0714
    static let obsidianEdge = Color(red: 0.012, green: 0.008, blue: 0.020)

    static let cyan = Color(red: 0.18, green: 0.88, blue: 1.00)       // #2EE0FF
    static let magenta = Color(red: 1.00, green: 0.18, blue: 0.52)    // #FF2E85
    static let hotPink = Color(red: 1.00, green: 0.09, blue: 0.40)
    static let coral = Color(red: 1.00, green: 0.44, blue: 0.32)
    static let gold = Color(red: 0.97, green: 0.85, blue: 0.62)
    static let mint = Color(red: 0.36, green: 0.95, blue: 0.78)
    static let violet = Color(red: 0.44, green: 0.32, blue: 0.98)

    static let midnight = Color(red: 0.043, green: 0.027, blue: 0.078)
    static let ink = Color(red: 0.012, green: 0.008, blue: 0.020)

    static let hairline = Color.white.opacity(0.16)
    static let hairlineDim = Color.white.opacity(0.07)

    /// Hauchdünne Kante für Glasflächen: Licht oben links, Schatten unten.
    static var edge: LinearGradient {
        LinearGradient(stops: [
            .init(color: Color.white.opacity(0.38), location: 0.0),
            .init(color: Color.white.opacity(0.08), location: 0.42),
            .init(color: Color.white.opacity(0.02), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var sunset: LinearGradient {
        LinearGradient(colors: [gold, coral, magenta],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var vice: LinearGradient {
        LinearGradient(colors: [hotPink, violet, cyan],
                       startPoint: .leading, endPoint: .trailing)
    }

    static var spectrum: LinearGradient {
        LinearGradient(colors: [magenta, violet.opacity(0.9), cyan],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Themes

/// Vier Kulissen. Alle dunkel — sie unterscheiden sich in der Temperatur
/// des Lichts, nicht in der Menge an Effekten.
enum GlacierTheme: String, CaseIterable, Identifiable, Codable {
    case electricVice
    case neonVice
    case aurora
    case titanium

    var id: String { rawValue }

    var title: String {
        switch self {
        case .electricVice: return "Obsidian Vice"
        case .neonVice: return "Neon Nocturne"
        case .aurora: return "Deep Aurora"
        case .titanium: return "Titanium"
        }
    }

    var subtitle: String {
        switch self {
        case .electricVice: return "Tiefschwarz, Magenta und Cyan — der Standard"
        case .neonVice: return "Pinkes Licht über kühlem Violett"
        case .aurora: return "Mint und Cyan, sehr leise"
        case .titanium: return "Graphit mit kaltem Silberlicht"
        }
    }

    var icon: String {
        switch self {
        case .electricVice: return "circle.hexagongrid.fill"
        case .neonVice: return "moon.stars.fill"
        case .aurora: return "sparkles"
        case .titanium: return "circle.lefthalf.filled"
        }
    }

    /// Die zwei Lichtfarben der Kulisse.
    var lights: (Color, Color) {
        switch self {
        case .electricVice: return (VicePalette.magenta, VicePalette.cyan)
        case .neonVice: return (VicePalette.hotPink, Color(red: 0.55, green: 0.36, blue: 1.00))
        case .aurora: return (VicePalette.mint, Color(red: 0.22, green: 0.62, blue: 1.00))
        case .titanium: return (Color(white: 0.62), Color(red: 0.42, green: 0.70, blue: 0.90))
        }
    }
}

enum AccentChoice: String, CaseIterable, Identifiable, Codable {
    case vicePink
    case viceCyan
    case sunset
    case viceGold
    case mint
    case violet
    case ice
    case amber

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vicePink: return "Vice Pink"
        case .viceCyan: return "Electric Cyan"
        case .sunset: return "Sunset Coral"
        case .viceGold: return "Champagne"
        case .mint: return "Mint"
        case .violet: return "Violet"
        case .ice: return "Ice"
        case .amber: return "Amber"
        }
    }

    var color: Color {
        switch self {
        case .vicePink: return VicePalette.magenta
        case .viceCyan: return VicePalette.cyan
        case .sunset: return VicePalette.coral
        case .viceGold: return VicePalette.gold
        case .mint: return Color(red: 0.42, green: 0.96, blue: 0.80)
        case .violet: return Color(red: 0.68, green: 0.58, blue: 1.00)
        case .ice: return Color(red: 0.46, green: 0.82, blue: 1.00)
        case .amber: return Color(red: 1.00, green: 0.80, blue: 0.46)
        }
    }

    var deep: Color {
        switch self {
        case .vicePink: return Color(red: 0.46, green: 0.02, blue: 0.28)
        case .viceCyan: return Color(red: 0.00, green: 0.28, blue: 0.44)
        case .sunset: return Color(red: 0.52, green: 0.08, blue: 0.20)
        case .viceGold: return Color(red: 0.55, green: 0.34, blue: 0.06)
        case .mint: return Color(red: 0.05, green: 0.44, blue: 0.38)
        case .violet: return Color(red: 0.24, green: 0.14, blue: 0.62)
        case .ice: return Color(red: 0.06, green: 0.32, blue: 0.62)
        case .amber: return Color(red: 0.58, green: 0.32, blue: 0.06)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: [color, deep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Farbe, die auf dem Akzent lesbar ist.
    var onAccent: Color { Color(red: 0.04, green: 0.03, blue: 0.06) }
}

enum Appearance: String, CaseIterable, Identifiable, Codable {
    case dark
    case light
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dark: return "Dunkel"
        case .light: return "Hell"
        case .system: return "System"
        }
    }

    var icon: String {
        switch self {
        case .dark: return "moon.stars.fill"
        case .light: return "sun.max.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    /// 1.2.0 ist bewusst eine Dark-Mode-App: Tiefschwarz, Glas und
    /// Neonlicht funktionieren nur auf dunklem Grund. Ein heller Modus
    /// würde die weiße Typografie unlesbar machen, deshalb bleibt die
    /// Bühne immer dunkel.
    var colorScheme: ColorScheme? { .dark }
}

// MARK: - Backdrop

/// Die Bühne: Obsidian, zwei weiche Lichtkegel, feine Körnung, Vignette.
/// Nichts bewegt sich schnell, nichts blinkt — das Bild atmet nur.
struct AmbientBackdrop: View {
    var theme: GlacierTheme = .electricVice
    var accent: Color = VicePalette.magenta
    var light: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    private var lights: (Color, Color) { theme.lights }

    private var base: LinearGradient {
        light
            ? LinearGradient(colors: [Color(red: 0.965, green: 0.955, blue: 0.975),
                                      Color(red: 0.925, green: 0.915, blue: 0.955)],
                             startPoint: .top, endPoint: .bottom)
            : LinearGradient(stops: [
                .init(color: VicePalette.obsidianDeep, location: 0.0),
                .init(color: VicePalette.obsidian, location: 0.45),
                .init(color: VicePalette.obsidianEdge, location: 1.0),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                base

                // Oben links: Magenta-Kegel, weit und weich.
                cone(lights.0, w: w * 1.45, h: h * 0.95, opacity: light ? 0.10 : 0.30)
                    .position(x: w * 0.10, y: h * 0.06)

                // Unten rechts: Cyan-Kegel, gegenläufig atmend.
                cone(lights.1, w: w * 1.35, h: h * 0.90, opacity: light ? 0.08 : 0.24)
                    .position(x: w * 0.94, y: h * 0.92)

                // Mitte: ein Hauch Akzent hinter dem Inhalt.
                cone(accent, w: w * 1.10, h: h * 0.55, opacity: light ? 0.06 : 0.12)
                    .position(x: w * 0.52, y: h * 0.46)

                grain
                    .opacity(light ? 0.35 : 0.55)
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                    breathe = true
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func cone(_ color: Color, w: CGFloat, h: CGFloat, opacity: Double) -> some View {
        Ellipse()
            .fill(RadialGradient(stops: [
                .init(color: color.opacity(opacity), location: 0.0),
                .init(color: color.opacity(opacity * 0.45), location: 0.45),
                .init(color: color.opacity(0.0), location: 1.0),
            ], center: .center, startRadius: 0, endRadius: max(w, h) * 0.5))
            .frame(width: w, height: h)
            .blur(radius: 34)
            .scaleEffect(breathe ? 1.05 : 0.96)
            .opacity(breathe ? 1 : 0.82)
    }

    /// Sehr feine Körnung gegen Banding — handwerklich, nicht sichtbar.
    private var grain: some View {
        Canvas { context, size in
            guard size.width > 8, size.height > 8 else { return }
            var seed: UInt64 = 0x5EED_1234
            func random() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double((seed >> 33) & 0xFFFFFF) / Double(0x1000000)
            }
            for _ in 0..<900 {
                let x = CGFloat(random()) * size.width
                let y = CGFloat(random()) * size.height
                let alpha = 0.02 + random() * 0.05
                context.fill(Path(CGRect(x: x, y: y, width: 1, height: 1)),
                             with: .color(Color.white.opacity(alpha)))
            }
        }
        .blendMode(.plusLighter)
    }
}

/// Vignette über allem, was scrollt. Keine Scanlines, kein CRT.
struct ObsidianVignette: View {
    var strength: Double = 1

    var body: some View {
        ZStack {
            LinearGradient(stops: [
                .init(color: Color.black.opacity(0.26 * strength), location: 0.00),
                .init(color: .clear, location: 0.16),
                .init(color: .clear, location: 0.86),
                .init(color: Color.black.opacity(0.30 * strength), location: 1.00),
            ], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [.clear, Color.black.opacity(0.22 * strength)],
                           center: .center, startRadius: 120, endRadius: 460)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Glass surfaces

/// Echte iOS-Glasfläche: `.ultraThinMaterial`, ein Tint in der Akzentfarbe,
/// eine 0.5-pt Kante mit Licht und ein tiefer, ruhiger Schatten.
struct GlassCard<Content: View>: View {
    var radius: CGFloat
    var tint: Color?
    var glow: Bool
    var padding: CGFloat
    var neon: Bool
    var content: Content

    init(radius: CGFloat = 24,
         tint: Color? = nil,
         glow: Bool = true,
         padding: CGFloat = 18,
         neon: Bool = true,
         @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.tint = tint
        self.glow = glow
        self.padding = padding
        self.neon = neon
        self.content = content()
    }

    private var accent: Color { tint ?? VicePalette.violet }

    private var fillTint: Color {
        accent.opacity(tint == nil ? 0.03 : 0.07)
    }

    private var strokeStyle: LinearGradient {
        neon
            ? LinearGradient(stops: [
                .init(color: Color.white.opacity(0.34), location: 0.0),
                .init(color: accent.opacity(0.22), location: 0.45),
                .init(color: Color.white.opacity(0.03), location: 1.0),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(stops: [
                .init(color: Color.white.opacity(0.22), location: 0.0),
                .init(color: Color.white.opacity(0.04), location: 1.0),
            ], startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(fillTint)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(LinearGradient(stops: [
                                .init(color: Color.white.opacity(0.07), location: 0.0),
                                .init(color: .clear, location: 0.35),
                            ], startPoint: .top, endPoint: .bottom))
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(strokeStyle, lineWidth: 0.5)
            }
            .shadow(color: Color.black.opacity(0.42), radius: 20, y: 10)
            .shadow(color: glow ? accent.opacity(0.16) : .clear, radius: 26, y: 8)
    }
}

/// Kleine Glas-Pille für Chips, Badges, Eingabefelder.
struct GlassPill<Content: View>: View {
    var tint: Color?
    var horizontal: CGFloat
    var vertical: CGFloat
    var content: Content

    init(tint: Color? = nil, horizontal: CGFloat = 12, vertical: CGFloat = 7,
         @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.horizontal = horizontal
        self.vertical = vertical
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, horizontal)
            .padding(.vertical, vertical)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule().fill((tint ?? VicePalette.violet).opacity(tint == nil ? 0.05 : 0.12))
                    }
            }
            .overlay {
                Capsule().strokeBorder(
                    LinearGradient(colors: [Color.white.opacity(0.28),
                                            (tint ?? VicePalette.violet).opacity(0.20)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.5
                )
            }
    }
}

extension View {
    func glassPill(tint: Color? = nil) -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule().fill((tint ?? VicePalette.violet).opacity(tint == nil ? 0.05 : 0.12))
                    }
            }
            .overlay {
                Capsule().strokeBorder(
                    LinearGradient(colors: [Color.white.opacity(0.28),
                                            (tint ?? VicePalette.violet).opacity(0.20)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.5
                )
            }
    }
}

/// Die ganze Seite inklusive Kulisse — und ohne eigenen Hintergrund
/// von ScrollViews, damit das Licht durchscheint.
struct GlassPage<Content: View>: View {
    var theme: GlacierTheme = .electricVice
    var accent: Color = VicePalette.magenta
    var light: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            AmbientBackdrop(theme: theme, accent: accent, light: light)
            content
        }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Buttons

/// Primär: volle Akzentfarbe, Lichtkante, ein einziger weicher Schatten.
struct PrimaryGlassButtonStyle: ButtonStyle {
    var tint: Color = VicePalette.magenta

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .tracking(0.2)
            .foregroundStyle(Color(red: 0.04, green: 0.03, blue: 0.06))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(LinearGradient(colors: [tint, tint.opacity(0.78)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay {
                        Capsule().fill(LinearGradient(colors: [Color.white.opacity(0.34), .clear],
                                                      startPoint: .top, endPoint: .center))
                    }
                    .overlay {
                        Capsule().strokeBorder(Color.white.opacity(0.45), lineWidth: 0.5)
                    }
                    .shadow(color: tint.opacity(configuration.isPressed ? 0.28 : 0.46),
                            radius: configuration.isPressed ? 6 : 14, y: 4)
            }
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct SecondaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.white.opacity(configuration.isPressed ? 0.7 : 0.94))
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay { Capsule().fill(Color.white.opacity(0.04)) }
            }
            .overlay {
                Capsule().strokeBorder(
                    LinearGradient(colors: [Color.white.opacity(0.30), Color.white.opacity(0.05)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.5
                )
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct PressableGlass<Content: View>: View {
    var action: () -> Void
    var radius: CGFloat
    @ViewBuilder var content: Content
    @State private var pressed = false

    init(radius: CGFloat = 24, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        Button(action: action) { content }
            .buttonStyle(.plain)
            .scaleEffect(pressed ? 0.978 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded { _ in pressed = false }
            )
    }
}

// MARK: - Haptics

enum Haptics {
    static var enabled: Bool {
        UserDefaults.standard.object(forKey: "tandem.haptics") as? Bool ?? true
    }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func soft() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func selection() {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Small building blocks

/// Kapitel-Überschrift: schmale Marke, weite gesperrte Kleinbuchstaben.
struct SectionHeader: View {
    var title: String
    var subtitle: String?
    var icon: String?
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(VicePalette.spectrum)
                .frame(width: 2, height: 11)
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(VicePalette.cyan.opacity(0.85))
            }
            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .heavy))
                .fontWidth(.expanded)
                .tracking(2.0)
                .foregroundStyle(Color.white.opacity(0.58))
            Spacer(minLength: 0)
            if let trailing {
                Text(trailing.uppercased())
                    .font(.system(size: 9.5, weight: .semibold))
                    .fontWidth(.condensed)
                    .tracking(1.1)
                    .foregroundStyle(Color.white.opacity(0.34))
            }
        }
        .padding(.horizontal, 4)
    }
}

/// Knappes Status-Badge: Material, farbiger Text, keine Leuchtreklame.
struct StatusBadge: View {
    var text: String
    var tint: Color
    var icon: String?

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.system(size: 8, weight: .bold))
            }
            Text(text.uppercased())
                .font(.system(size: 9, weight: .heavy))
                .fontWidth(.condensed)
                .tracking(0.9)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay { Capsule().fill(tint.opacity(0.12)) }
        }
        .overlay {
            Capsule().strokeBorder(tint.opacity(0.34), lineWidth: 0.5)
        }
    }
}

/// Die Marke des Agenten: „AUTONOMOUS AGENT“, „CLEARANCE“ & Co.
struct Insignia: View {
    var text: String
    var tint: Color = VicePalette.magenta
    var icon: String = "circle.hexagongrid.fill"

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 8, weight: .bold))
            Text(text.uppercased())
                .font(.system(size: 8.5, weight: .heavy))
                .fontWidth(.expanded)
                .tracking(1.5)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay { Capsule().fill(tint.opacity(0.10)) }
        }
        .overlay {
            Capsule().strokeBorder(
                LinearGradient(colors: [tint.opacity(0.55), Color.white.opacity(0.08)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 0.5
            )
        }
    }
}

/// Dünne Trennlinie, die von Akzent zu Akzent verläuft.
struct NeonDivider: View {
    var body: some View {
        LinearGradient(colors: [Color.white.opacity(0.0),
                                Color.white.opacity(0.14),
                                Color.white.opacity(0.0)],
                       startPoint: .leading, endPoint: .trailing)
            .frame(height: 0.5)
    }
}

/// Ein Laufband mit echter Agenten-Telemetrie statt Kulissen-Schlagzeilen.
struct SignalTicker: View {
    var items: [String]
    var tint: Color = VicePalette.cyan

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var textWidth: CGFloat = 0

    private var line: String {
        items.joined(separator: "     ·     ")
    }

    private let gap: CGFloat = 40

    var body: some View {
        HStack(spacing: 9) {
            HStack(spacing: 4) {
                PulseDot(color: tint)
                Text("LIVE")
                    .font(.system(size: 8, weight: .heavy))
                    .fontWidth(.expanded)
                    .tracking(1.2)
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule().fill(.ultraThinMaterial).overlay { Capsule().fill(tint.opacity(0.10)) }
            }
            .overlay { Capsule().strokeBorder(tint.opacity(0.30), lineWidth: 0.5) }

            GeometryReader { proxy in
                let viewWidth = proxy.size.width
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
                    let period = max(1, textWidth + gap)
                    let offset = reduceMotion
                        ? 0
                        : CGFloat((timeline.date.timeIntervalSinceReferenceDate * 34.0)
                            .truncatingRemainder(dividingBy: Double(period)))
                    HStack(spacing: gap) {
                        headline
                        headline
                    }
                    .offset(x: -offset)
                    .frame(width: viewWidth, alignment: .leading)
                    .clipped()
                }
            }
            .frame(height: 14)
            .mask(
                LinearGradient(stops: [
                    .init(color: .clear, location: 0.00),
                    .init(color: .black, location: 0.04),
                    .init(color: .black, location: 0.94),
                    .init(color: .clear, location: 1.00),
                ], startPoint: .leading, endPoint: .trailing)
            )
        }
    }

    private var headline: some View {
        Text(line)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .tracking(0.3)
            .foregroundStyle(Color.white.opacity(0.48))
            .lineLimit(1)
            .fixedSize()
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(key: TickerWidthKey.self, value: proxy.size.width)
                }
            }
            .onPreferenceChange(TickerWidthKey.self) { width in
                if width > 0 { textWidth = width }
            }
    }
}

private struct TickerWidthKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Das Emblem: zwei Leucht-Ringe, sechs Knoten, ein Kern — reine
/// Geometrie, kein Motiv aus einem Spiel.
struct AgentEmblem: View {
    var tint: Color = VicePalette.magenta
    var rim: Color = VicePalette.cyan
    var animated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var angle: Double = 0

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let node = max(4, size * 0.052)

            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [tint.opacity(0.26), .clear],
                                         center: .center, startRadius: 0, endRadius: size * 0.5))
                    .blur(radius: size * 0.02)

                Circle()
                    .strokeBorder(
                        LinearGradient(colors: [rim.opacity(0.85), Color.white.opacity(0.10), tint.opacity(0.75)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: max(1, size * 0.005)
                    )
                    .padding(size * 0.055)

                Circle()
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: max(0.5, size * 0.002))
                    .padding(size * 0.165)

                Circle()
                    .trim(from: 0.06, to: 0.40)
                    .stroke(rim.opacity(0.9),
                            style: StrokeStyle(lineWidth: max(1, size * 0.009), lineCap: .round))
                    .padding(size * 0.115)
                    .rotationEffect(.degrees(angle * 0.55))

                Circle()
                    .trim(from: 0.54, to: 0.92)
                    .stroke(tint.opacity(0.85),
                            style: StrokeStyle(lineWidth: max(1, size * 0.009), lineCap: .round))
                    .padding(size * 0.115)
                    .rotationEffect(.degrees(-angle * 0.42))

                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(index % 2 == 0 ? tint : rim)
                        .frame(width: index % 3 == 0 ? node : node * 0.72,
                               height: index % 3 == 0 ? node : node * 0.72)
                        .shadow(color: (index % 2 == 0 ? tint : rim).opacity(0.9), radius: size * 0.02)
                        .offset(y: -size * 0.245)
                        .rotationEffect(.degrees(Double(index) * 60 + angle))
                }

                Circle()
                    .fill(LinearGradient(colors: [Color.white.opacity(0.95), rim],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: size * 0.16, height: size * 0.16)
                    .overlay {
                        Circle().strokeBorder(Color.white.opacity(0.55), lineWidth: 0.6)
                    }
                    .shadow(color: rim.opacity(0.8), radius: size * 0.06)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            guard animated, !reduceMotion else { return }
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                angle = 360
            }
        }
    }
}

struct ProgressRing: View {
    var progress: Double
    var tint: Color
    var size: CGFloat = 44
    var lineWidth: CGFloat = 3

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.02, min(1, progress)))
                .stroke(LinearGradient(colors: [tint, tint.opacity(0.55)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.45), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.24, weight: .semibold))
                .fontWidth(.condensed)
                .monospacedDigit()
                .foregroundStyle(Color.white.opacity(0.78))
        }
        .frame(width: size, height: size)
    }
}

/// Ein Punkt, der bei einem laufenden Schritt ruhig pulsiert.
struct PulseDot: View {
    var color: Color
    var active: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        ZStack {
            if active && !reduceMotion {
                Circle()
                    .fill(color.opacity(0.35))
                    .frame(width: 12, height: 12)
                    .scaleEffect(animate ? 1.5 : 0.5)
                    .opacity(animate ? 0 : 0.9)
            }
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
        }
        .frame(width: 12, height: 12)
        .onAppear {
            guard active, !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.3).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}

/// Ein schmaler Balken für Fortschritt innerhalb einer Zeile.
struct MeterBar: View {
    var progress: Double
    var tint: Color
    var height: CGFloat = 3

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.07))
                Capsule()
                    .fill(LinearGradient(colors: [tint, tint.opacity(0.55)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(2, proxy.size.width * min(1, max(0, progress))))
            }
        }
        .frame(height: height)
    }
}

/// Deutscher Zeitabstand: „gerade eben", „vor 4 Min.", „vor 2 Std.".
enum RelativeTime {
    static func string(from date: Date, now: Date = Date()) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        if seconds < 45 { return "gerade eben" }
        if seconds < 3600 { return "vor \(Int(seconds / 60)) Min." }
        if seconds < 86_400 { return "vor \(Int(seconds / 3600)) Std." }
        let days = Int(seconds / 86_400)
        return days == 1 ? "gestern" : "vor \(days) Tagen"
    }

    static func clock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    static func weekdayLong(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: date)
    }
}
