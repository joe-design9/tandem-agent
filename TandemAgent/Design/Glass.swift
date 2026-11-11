import SwiftUI
import UIKit

// MARK: - Themes

/// Drei Kulissen für die App. Jede färbt das Liquid Glass anders:
/// Deep Aurora (kühl, violett-grün), Neon Vice (warm, magenta-gold),
/// Dark Titanium (graphit, silbern).
enum GlacierTheme: String, CaseIterable, Identifiable, Codable {
    case aurora
    case neonVice
    case titanium

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aurora: return "Deep Aurora"
        case .neonVice: return "Neon Vice"
        case .titanium: return "Dark Titanium"
        }
    }

    var subtitle: String {
        switch self {
        case .aurora: return "Polarlicht, Indigo und Mint"
        case .neonVice: return "Magenta-Sonne über dem Grid"
        case .titanium: return "Gebürstetes Metall, kühles Silber"
        }
    }

    var icon: String {
        switch self {
        case .aurora: return "sparkles"
        case .neonVice: return "sun.horizon.fill"
        case .titanium: return "circle.hexagongrid.fill"
        }
    }
}

enum AccentChoice: String, CaseIterable, Identifiable, Codable {
    case mint
    case violet
    case ice
    case amber

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mint: return "Mint"
        case .violet: return "Violet"
        case .ice: return "Ice"
        case .amber: return "Amber"
        }
    }

    var color: Color {
        switch self {
        case .mint: return Color(red: 0.42, green: 0.96, blue: 0.80)
        case .violet: return Color(red: 0.66, green: 0.55, blue: 1.00)
        case .ice: return Color(red: 0.42, green: 0.80, blue: 1.00)
        case .amber: return Color(red: 1.00, green: 0.78, blue: 0.42)
        }
    }

    var deep: Color {
        switch self {
        case .mint: return Color(red: 0.08, green: 0.62, blue: 0.52)
        case .violet: return Color(red: 0.38, green: 0.26, blue: 0.92)
        case .ice: return Color(red: 0.12, green: 0.48, blue: 0.92)
        case .amber: return Color(red: 0.92, green: 0.52, blue: 0.12)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: [color, deep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
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

    var colorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}

// MARK: - Backdrop

/// Die Kulisse hinter allen Glasflächen. Wird pro Seite eingesetzt
/// (TabView malt sonst seinen eigenen Hintergrund darüber).
struct AmbientBackdrop: View {
    var theme: GlacierTheme = .aurora
    var accent: Color = AccentChoice.mint.color
    var light: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    var body: some View {
        ZStack {
            switch theme {
            case .aurora:
                auroraBody
            case .neonVice:
                neonBody
            case .titanium:
                titaniumBody
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }

    // MARK: Deep Aurora

    private var auroraBase: LinearGradient {
        light
            ? LinearGradient(stops: [
                .init(color: Color(red: 0.94, green: 0.96, blue: 1.00), location: 0.0),
                .init(color: Color(red: 0.88, green: 0.93, blue: 0.99), location: 0.45),
                .init(color: Color(red: 0.95, green: 0.94, blue: 1.00), location: 1.0),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(stops: [
                .init(color: Color(red: 0.04, green: 0.05, blue: 0.13), location: 0.0),
                .init(color: Color(red: 0.09, green: 0.07, blue: 0.28), location: 0.38),
                .init(color: Color(red: 0.06, green: 0.13, blue: 0.26), location: 0.72),
                .init(color: Color(red: 0.02, green: 0.03, blue: 0.07), location: 1.0),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var auroraBody: some View {
        ZStack {
            auroraBase
            Canvas { context, size in
                let w = size.width
                let h = size.height

                // Sternenfeld (im hellen Modus weggelassen).
                if !light {
                    var seed: UInt64 = 20261202
                    func rnd() -> Double {
                        seed = seed &* 6364136223846793005 &+ 1442695040888963407
                        return Double((seed >> 33) & 0xFFFFFF) / Double(0x1000000)
                    }
                    for _ in 0..<110 {
                        let x = rnd() * w
                        let y = rnd() * h * 0.75
                        let r = 0.5 + rnd() * 1.3
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                                     with: .color(.white.opacity(0.12 + rnd() * 0.35)))
                    }
                }

                // Polarlicht-Bänder: drei weiche, durchscheinende Bögen.
                drawRibbon(&context, size: size, center: CGPoint(x: w * 0.18, y: h * 0.20),
                           width: w * 0.90, height: h * 0.42, angle: -22,
                           color: light ? Color(red: 0.55, green: 0.90, blue: 0.85).opacity(0.55)
                                        : Color(red: 0.25, green: 0.95, blue: 0.78).opacity(0.32))
                drawRibbon(&context, size: size, center: CGPoint(x: w * 0.82, y: h * 0.42),
                           width: w * 1.00, height: h * 0.34, angle: 16,
                           color: light ? Color(red: 0.62, green: 0.58, blue: 1.00).opacity(0.42)
                                        : Color(red: 0.52, green: 0.36, blue: 1.00).opacity(0.30))
                drawRibbon(&context, size: size, center: CGPoint(x: w * 0.45, y: h * 0.86),
                           width: w * 1.10, height: h * 0.30, angle: -8,
                           color: light ? Color(red: 0.45, green: 0.75, blue: 1.00).opacity(0.35)
                                        : Color(red: 0.20, green: 0.55, blue: 1.00).opacity(0.22))

                // Akzent-Glow unten, damit das Glas Farbe bricht.
                let glowRect = CGRect(x: w * 0.5 - w * 0.7, y: h * 0.55, width: w * 1.4, height: h * 0.9)
                context.fill(Path(ellipseIn: glowRect), with: .radialGradient(
                    Gradient(colors: [accent.opacity(light ? 0.16 : 0.22), .clear]),
                    center: CGPoint(x: w * 0.5, y: h * 0.95), startRadius: 10, endRadius: w * 0.85))

                // Abdunklung oben für die Statusleiste.
                if !light {
                    context.fill(Path(CGRect(x: 0, y: 0, width: w, height: h * 0.14)),
                                 with: .linearGradient(Gradient(colors: [Color.black.opacity(0.28), .clear]),
                                                       startPoint: CGPoint(x: 0, y: 0),
                                                       endPoint: CGPoint(x: 0, y: h * 0.14)))
                }
            }

            if !reduceMotion {
                RadialGradient(colors: [accent.opacity(light ? 0.10 : 0.16), .clear],
                               center: UnitPoint(x: 0.72, y: 0.24), startRadius: 8, endRadius: 280)
                    .opacity(breathe ? 1 : 0.45)
                    .blendMode(.plusLighter)
            }
        }
    }

    // MARK: Neon Vice

    private var neonBase: LinearGradient {
        light
            ? LinearGradient(stops: [
                .init(color: Color(red: 1.00, green: 0.95, blue: 0.96), location: 0.0),
                .init(color: Color(red: 1.00, green: 0.90, blue: 0.92), location: 0.45),
                .init(color: Color(red: 0.96, green: 0.92, blue: 1.00), location: 1.0),
            ], startPoint: .top, endPoint: .bottom)
            : LinearGradient(stops: [
                .init(color: Color(red: 0.06, green: 0.02, blue: 0.16), location: 0.0),
                .init(color: Color(red: 0.22, green: 0.03, blue: 0.34), location: 0.28),
                .init(color: Color(red: 0.55, green: 0.05, blue: 0.38), location: 0.52),
                .init(color: Color(red: 0.16, green: 0.02, blue: 0.22), location: 0.78),
                .init(color: Color(red: 0.04, green: 0.01, blue: 0.10), location: 1.0),
            ], startPoint: .top, endPoint: .bottom)
    }

    private var neonBody: some View {
        ZStack {
            neonBase
            Canvas { context, size in
                let w = size.width
                let h = size.height
                let horizon = h * 0.70

                // Sonnenscheibe mit Retrostreifen.
                let center = CGPoint(x: w * 0.5, y: horizon - h * 0.10)
                let radius = w * 0.22
                context.fill(Path(ellipseIn: CGRect(x: center.x - w * 0.55, y: center.y - w * 0.55,
                                                    width: w * 1.1, height: w * 1.1)),
                             with: .radialGradient(
                                Gradient(colors: [Color(red: 1.0, green: 0.35, blue: 0.55).opacity(light ? 0.24 : 0.42), .clear]),
                                center: center, startRadius: 6, endRadius: w * 0.55))
                let sunRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                context.drawLayer { layer in
                    layer.clip(to: Path(ellipseIn: sunRect))
                    layer.fill(Path(sunRect), with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 1.00, green: 0.86, blue: 0.58),
                            Color(red: 1.00, green: 0.52, blue: 0.42),
                            Color(red: 1.00, green: 0.24, blue: 0.62),
                        ]),
                        startPoint: CGPoint(x: center.x, y: sunRect.minY),
                        endPoint: CGPoint(x: center.x, y: sunRect.maxY)))
                    var y = center.y
                    var gap: CGFloat = radius * 0.10
                    while y < sunRect.maxY {
                        layer.fill(Path(CGRect(x: sunRect.minX, y: y, width: sunRect.width, height: gap * 0.55)),
                                   with: .color(light ? Color.white.opacity(0.55)
                                                      : Color(red: 0.12, green: 0.01, blue: 0.18).opacity(0.85)))
                        y += gap
                        gap *= 1.28
                    }
                }

                // Horizontlinie.
                context.fill(Path(CGRect(x: 0, y: horizon - 1, width: w, height: 2)),
                             with: .color(Color(red: 0.45, green: 0.95, blue: 1.0).opacity(light ? 0.35 : 0.55)))

                // Perspektiv-Grid.
                var offset: CGFloat = 2
                var spacing: CGFloat = 2
                while horizon + offset < h {
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: horizon + offset))
                    line.addLine(to: CGPoint(x: w, y: horizon + offset))
                    context.stroke(line, with: .color(Color(red: 0.55, green: 0.85, blue: 1.0).opacity(light ? 0.18 : 0.14)),
                                   lineWidth: 0.8)
                    offset += spacing
                    spacing *= 1.34
                }
                for index in -8...8 {
                    var ray = Path()
                    ray.move(to: CGPoint(x: w * 0.5, y: horizon))
                    ray.addLine(to: CGPoint(x: w * 0.5 + CGFloat(index) * w * 0.16, y: h))
                    context.stroke(ray, with: .color(Color(red: 0.55, green: 0.85, blue: 1.0).opacity(light ? 0.14 : 0.11)),
                                   lineWidth: 0.8)
                }

                if !light {
                    // Silhouette einer Palme links als Markenzeichen.
                    drawPalm(&context, base: CGPoint(x: w * 0.08, y: h * 1.02),
                             height: h * 0.46, lean: w * 0.04,
                             color: Color(red: 0.05, green: 0.01, blue: 0.10).opacity(0.92))
                    context.fill(Path(CGRect(x: 0, y: 0, width: w, height: h * 0.14)),
                                 with: .linearGradient(Gradient(colors: [Color.black.opacity(0.25), .clear]),
                                                       startPoint: CGPoint(x: 0, y: 0),
                                                       endPoint: CGPoint(x: 0, y: h * 0.14)))
                }
            }
        }
    }

    // MARK: Dark Titanium

    private var titaniumBase: LinearGradient {
        light
            ? LinearGradient(stops: [
                .init(color: Color(red: 0.96, green: 0.96, blue: 0.97), location: 0.0),
                .init(color: Color(red: 0.89, green: 0.90, blue: 0.92), location: 0.5),
                .init(color: Color(red: 0.97, green: 0.97, blue: 0.98), location: 1.0),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(stops: [
                .init(color: Color(red: 0.13, green: 0.14, blue: 0.16), location: 0.0),
                .init(color: Color(red: 0.07, green: 0.08, blue: 0.09), location: 0.45),
                .init(color: Color(red: 0.11, green: 0.12, blue: 0.14), location: 0.80),
                .init(color: Color(red: 0.04, green: 0.04, blue: 0.05), location: 1.0),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var titaniumBody: some View {
        ZStack {
            titaniumBase
            Canvas { context, size in
                let w = size.width
                let h = size.height

                // Gebürstete Metallstreifen, leicht schräg.
                var y: CGFloat = -h * 0.2
                var index = 0
                while y < h * 1.2 {
                    let alpha = (index % 3 == 0) ? 0.10 : 0.05
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y))
                    line.addLine(to: CGPoint(x: w, y: y + h * 0.10))
                    context.stroke(line, with: .color(light ? Color.white.opacity(alpha * 2.2)
                                                            : Color.white.opacity(alpha * 0.6)),
                                   lineWidth: 1 + CGFloat(index % 4))
                    y += h * 0.014
                    index += 1
                }

                // Weicher Silber-Schimmer oben rechts.
                context.fill(Path(ellipseIn: CGRect(x: w * 0.45, y: -h * 0.25, width: w * 0.9, height: h * 0.8)),
                             with: .radialGradient(
                                Gradient(colors: [Color.white.opacity(light ? 0.55 : 0.14), .clear]),
                                center: CGPoint(x: w * 0.85, y: h * 0.10), startRadius: 4, endRadius: w * 0.6))

                // Akzentkante am unteren Rand.
                context.fill(Path(CGRect(x: 0, y: h * 0.92, width: w, height: h * 0.08)),
                             with: .linearGradient(Gradient(colors: [.clear, accent.opacity(light ? 0.10 : 0.20)]),
                                                   startPoint: CGPoint(x: 0, y: h * 0.92),
                                                   endPoint: CGPoint(x: 0, y: h)))
            }
        }
    }

    // MARK: Helpers

    private func drawRibbon(_ context: inout GraphicsContext, size: CGSize,
                            center: CGPoint, width: CGFloat, height: CGFloat,
                            angle: Double, color: Color) {
        context.drawLayer { layer in
            layer.translateBy(x: center.x, y: center.y)
            layer.rotate(by: .degrees(angle))
            let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
            layer.fill(Path(ellipseIn: rect), with: .radialGradient(
                Gradient(colors: [color, color.opacity(0.35), .clear]),
                center: .zero, startRadius: 4, endRadius: width / 2))
        }
    }

    private func drawPalm(_ context: inout GraphicsContext, base: CGPoint,
                          height: CGFloat, lean: CGFloat, color: Color) {
        let crown = CGPoint(x: base.x + lean, y: base.y - height)
        let baseHalf = max(4, height * 0.018)
        var trunk = Path()
        trunk.move(to: CGPoint(x: base.x - baseHalf, y: base.y))
        trunk.addQuadCurve(to: CGPoint(x: crown.x - baseHalf * 0.45, y: crown.y + 2),
                           control: CGPoint(x: base.x - baseHalf + lean * 0.3, y: base.y - height * 0.55))
        trunk.addLine(to: CGPoint(x: crown.x + baseHalf * 0.45, y: crown.y + 2))
        trunk.addQuadCurve(to: CGPoint(x: base.x + baseHalf, y: base.y),
                           control: CGPoint(x: base.x + baseHalf + lean * 0.3, y: base.y - height * 0.55))
        trunk.closeSubpath()
        context.fill(trunk, with: .color(color))

        for i in 0..<7 {
            let theta = (-165.0 + Double(i) * 25.0) * Double.pi / 180.0
            let edge = abs(abs(Double(i) - 3.0) / 3.0)
            let len = height * CGFloat(0.36 - 0.08 * edge)
            let tip = CGPoint(x: crown.x + CGFloat(cos(theta)) * len,
                              y: crown.y + CGFloat(sin(theta)) * len + len * 0.36)
            let mid = CGPoint(x: (crown.x + tip.x) / 2, y: (crown.y + tip.y) / 2 - len * 0.15)
            let chord = CGPoint(x: tip.x - crown.x, y: tip.y - crown.y)
            let chordLen = max(1, hypot(chord.x, chord.y))
            let halfWidth = len * 0.05 + 1.2
            let normal = CGPoint(x: -chord.y / chordLen * halfWidth, y: chord.x / chordLen * halfWidth)
            var frond = Path()
            frond.move(to: crown)
            frond.addQuadCurve(to: tip, control: CGPoint(x: mid.x + normal.x, y: mid.y + normal.y))
            frond.addQuadCurve(to: crown, control: CGPoint(x: mid.x - normal.x, y: mid.y - normal.y))
            frond.closeSubpath()
            context.fill(frond, with: .color(color))
        }
    }
}

// MARK: - Glass surfaces

/// Liquid-Glass-Karte: frostige Fläche, Akzent-Tint, Lichtkante und
/// optional ein weicher Glow, der langsam atmet.
struct GlassCard<Content: View>: View {
    var radius: CGFloat
    var tint: Color?
    var glow: Bool
    var padding: CGFloat
    var content: Content

    @AppStorage("tandem.glow") private var glowEnabled = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    init(radius: CGFloat = 26,
         tint: Color? = nil,
         glow: Bool = true,
         padding: CGFloat = 18,
         @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.tint = tint
        self.glow = glow
        self.padding = padding
        self.content = content()
    }

    private var showsGlow: Bool { glow && glowEnabled }

    private var glassTint: Color {
        if let tint {
            return tint.opacity(showsGlow ? (pulsing ? 0.18 : 0.10) : 0.10)
        }
        return Color.white.opacity(0.06)
    }

    private var glowShadow: Color {
        guard showsGlow, let tint else { return .clear }
        return tint.opacity(pulsing ? 0.30 : 0.12)
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular.tint(glassTint),
                                 in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(colors: [Color.white.opacity(0.34), Color.white.opacity(0.04)],
                                               startPoint: .top, endPoint: .bottom),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: glowShadow, radius: showsGlow ? 16 : 0)
            }
            .onAppear {
                guard showsGlow, !reduceMotion, tint != nil else { return }
                withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
            .onDisappear { pulsing = false }
    }
}

/// Eine Glas-Pille für kleine Elemente: Chips, Badges, Eingabefelder.
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
                    .fill(.clear)
                    .glassEffect(.regular.tint(tint?.opacity(0.16) ?? Color.white.opacity(0.08)), in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                LinearGradient(colors: [Color.white.opacity(0.32), Color.white.opacity(0.04)],
                                               startPoint: .top, endPoint: .bottom),
                                lineWidth: 1
                            )
                    }
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
                    .fill(.clear)
                    .glassEffect(.regular.tint(tint?.opacity(0.18) ?? Color.white.opacity(0.08)), in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                LinearGradient(colors: [Color.white.opacity(0.32), Color.white.opacity(0.04)],
                                               startPoint: .top, endPoint: .bottom),
                                lineWidth: 1
                            )
                    }
            }
    }
}

/// Die ganze Seite inklusive Kulisse — und ohne den eigenen Hintergrund
/// von ScrollViews, damit die Farben durchscheinen.
struct GlassPage<Content: View>: View {
    var theme: GlacierTheme = .aurora
    var accent: Color = AccentChoice.mint.color
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

struct PrimaryGlassButtonStyle: ButtonStyle {
    var tint: Color = AccentChoice.mint.color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(Color.black.opacity(0.85))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(tint.gradient)
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
                    }
                    .shadow(color: tint.opacity(0.45), radius: configuration.isPressed ? 4 : 14, y: 4)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular.tint(Color.white.opacity(0.10)), in: Capsule())
                    .overlay {
                        Capsule().strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                    }
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
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
            .scaleEffect(pressed ? 0.975 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: pressed)
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

struct SectionHeader: View {
    var title: String
    var subtitle: String?
    var icon: String?
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.secondary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct StatusBadge: View {
    var text: String
    var tint: Color
    var icon: String?

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.system(size: 9, weight: .bold))
            }
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(0.4)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule().fill(tint.opacity(0.16))
                .overlay { Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 0.8) }
        }
    }
}

struct ProgressRing: View {
    var progress: Double
    var tint: Color
    var size: CGFloat = 44
    var lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.02, min(1, progress)))
                .stroke(tint.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.26, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .frame(width: size, height: size)
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
