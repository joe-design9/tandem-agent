import SwiftUI
import UIKit

// MARK: - Vice City Palette

/// Leonida in fünf Farben: Electric Cyan, Neon Magenta, Sunset Coral,
/// Vice Gold — und darunter das tiefe Mitternachtsviolett, auf dem
/// alles sitzt. Jede Fläche in Tandem zieht aus diesem Kasten.
enum VicePalette {
    static let cyan = Color(red: 0.00, green: 0.94, blue: 1.00)      // #00F0FF
    static let magenta = Color(red: 1.00, green: 0.16, blue: 0.52)   // #FF2A85
    static let hotPink = Color(red: 1.00, green: 0.08, blue: 0.58)   // #FF1493
    static let coral = Color(red: 1.00, green: 0.42, blue: 0.21)     // #FF6B35
    static let gold = Color(red: 1.00, green: 0.84, blue: 0.00)      // #FFD700
    static let midnight = Color(red: 0.06, green: 0.03, blue: 0.13)  // #0E0720
    static let violet = Color(red: 0.32, green: 0.05, blue: 0.44)
    static let ink = Color(red: 0.03, green: 0.01, blue: 0.07)
    static let mint = Color(red: 0.42, green: 0.96, blue: 0.80)

    /// Neon-Kante für Karten: Magenta links oben, Cyan rechts, Gold unten.
    static var edge: LinearGradient {
        LinearGradient(colors: [magenta.opacity(0.80), cyan.opacity(0.70), gold.opacity(0.45)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Der Sonnenuntergang als Verlauf — für Titel und Badges.
    static var sunset: LinearGradient {
        LinearGradient(colors: [gold, coral, magenta],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Magenta → Violett → Cyan: die Signatur von Vice City.
    static var vice: LinearGradient {
        LinearGradient(colors: [hotPink, Color(red: 0.55, green: 0.10, blue: 0.78), cyan],
                       startPoint: .leading, endPoint: .trailing)
    }
}

/// Die Schlagzeilen des Weazel-News-Bands. Kulisse, keine echte Quelle.
enum ViceNews {
    static let headlines: [String] = [
        "Weazel News: Sonnenuntergang über Vice Beach — Grid glüht bis Mitternacht",
        "VCPR Traffic: Ocean Drive frei, Leonida Keys dicht",
        "Leonida Dispatch: 3 neue Mails, 1 davon dringend",
        "Vice City PD: Keine Vorfälle, alles ruhig in Little Havana",
        "Weazel Wetter: 24 °C, Palmenwind, später Neon-Regen",
    ]
}

// MARK: - Themes

/// Vier Kulissen für die App. Electric Vice ist die Standardbühne:
/// Sonnenuntergang, Perspektiv-Grid, Palmen, Partikelglühen.
enum GlacierTheme: String, CaseIterable, Identifiable, Codable {
    case electricVice
    case neonVice
    case aurora
    case titanium

    var id: String { rawValue }

    var title: String {
        switch self {
        case .electricVice: return "Electric Vice"
        case .neonVice: return "Neon Vice"
        case .aurora: return "Deep Aurora"
        case .titanium: return "Titanium"
        }
    }

    var subtitle: String {
        switch self {
        case .electricVice: return "Sunset über Leonida, Neon-Grid, Palmen"
        case .neonVice: return "Magenta-Sonne über dem Grid"
        case .aurora: return "Polarlicht, Indigo und Mint"
        case .titanium: return "Gebürstetes Metall, kühles Silber"
        }
    }

    var icon: String {
        switch self {
        case .electricVice: return "sunset.fill"
        case .neonVice: return "sun.horizon.fill"
        case .aurora: return "sparkles"
        case .titanium: return "circle.hexagongrid.fill"
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
        case .viceGold: return "Vice Gold"
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
        case .violet: return Color(red: 0.66, green: 0.55, blue: 1.00)
        case .ice: return Color(red: 0.42, green: 0.80, blue: 1.00)
        case .amber: return Color(red: 1.00, green: 0.78, blue: 0.42)
        }
    }

    var deep: Color {
        switch self {
        case .vicePink: return Color(red: 0.72, green: 0.02, blue: 0.36)
        case .viceCyan: return Color(red: 0.00, green: 0.42, blue: 0.62)
        case .sunset: return Color(red: 0.78, green: 0.10, blue: 0.34)
        case .viceGold: return Color(red: 1.00, green: 0.46, blue: 0.00)
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
    var theme: GlacierTheme = .electricVice
    var accent: Color = VicePalette.magenta
    var light: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    var body: some View {
        ZStack {
            switch theme {
            case .electricVice:
                electricBody
            case .neonVice:
                neonBody
            case .aurora:
                auroraBody
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

    // MARK: Electric Vice

    private var electricBase: LinearGradient {
        light
            ? LinearGradient(stops: [
                .init(color: Color(red: 1.00, green: 0.95, blue: 0.92), location: 0.0),
                .init(color: Color(red: 1.00, green: 0.82, blue: 0.84), location: 0.34),
                .init(color: Color(red: 1.00, green: 0.72, blue: 0.66), location: 0.58),
                .init(color: Color(red: 0.98, green: 0.80, blue: 0.76), location: 0.62),
                .init(color: Color(red: 0.94, green: 0.86, blue: 0.92), location: 1.0),
            ], startPoint: .top, endPoint: .bottom)
            : LinearGradient(stops: [
                .init(color: Color(red: 0.03, green: 0.01, blue: 0.09), location: 0.0),
                .init(color: Color(red: 0.13, green: 0.02, blue: 0.30), location: 0.22),
                .init(color: Color(red: 0.34, green: 0.03, blue: 0.45), location: 0.40),
                .init(color: Color(red: 0.72, green: 0.05, blue: 0.48), location: 0.54),
                .init(color: Color(red: 0.14, green: 0.02, blue: 0.22), location: 0.62),
                .init(color: Color(red: 0.03, green: 0.01, blue: 0.07), location: 1.0),
            ], startPoint: .top, endPoint: .bottom)
    }

    private var electricBody: some View {
        ZStack {
            electricBase

            TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion)) { timeline in
                Canvas { context, size in
                    ViceScene.draw(&context,
                                   size: size,
                                   time: timeline.date.timeIntervalSinceReferenceDate,
                                   light: light,
                                   accent: accent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if !reduceMotion {
                RadialGradient(colors: [VicePalette.hotPink.opacity(light ? 0.12 : 0.24), .clear],
                               center: UnitPoint(x: 0.5, y: 0.55), startRadius: 10, endRadius: 250)
                    .opacity(breathe ? 1 : 0.45)
                    .blendMode(.plusLighter)
                RadialGradient(colors: [VicePalette.cyan.opacity(light ? 0.06 : 0.15), .clear],
                               center: UnitPoint(x: 0.12, y: 0.88), startRadius: 6, endRadius: 210)
                    .opacity(breathe ? 0.45 : 1)
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
                    drawVicePalm(&context, base: CGPoint(x: w * 0.08, y: h * 1.02),
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

    // MARK: Titanium

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
}

// MARK: - The Electric Vice scene

/// Die lebendige Kulisse: Sonnenuntergang, Perspektiv-Grid, Skyline,
/// Palmen, Sternenstaub und treibende Neon-Partikel. Alles zeitgetrieben,
/// damit die Stadt atmet statt zu stehen.
enum ViceScene {
    static func draw(_ context: inout GraphicsContext, size: CGSize,
                     time: Double, light: Bool, accent: Color) {
        let w = size.width
        let h = size.height
        guard w > 8, h > 8 else { return }

        let horizon = h * 0.60
        let t = CGFloat(time)

        // Himmel
        let skyStops: [Gradient.Stop] = light
            ? [
                .init(color: Color(red: 1.00, green: 0.95, blue: 0.92), location: 0.00),
                .init(color: Color(red: 1.00, green: 0.86, blue: 0.86), location: 0.22),
                .init(color: Color(red: 1.00, green: 0.74, blue: 0.78), location: 0.42),
                .init(color: Color(red: 1.00, green: 0.66, blue: 0.62), location: 0.54),
                .init(color: Color(red: 1.00, green: 0.80, blue: 0.55), location: 0.60),
            ]
            : [
                .init(color: Color(red: 0.03, green: 0.01, blue: 0.09), location: 0.00),
                .init(color: Color(red: 0.12, green: 0.02, blue: 0.30), location: 0.20),
                .init(color: Color(red: 0.33, green: 0.03, blue: 0.46), location: 0.38),
                .init(color: Color(red: 0.72, green: 0.05, blue: 0.48), location: 0.50),
                .init(color: Color(red: 1.00, green: 0.25, blue: 0.42), location: 0.56),
                .init(color: Color(red: 1.00, green: 0.56, blue: 0.22), location: 0.60),
            ]
        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: horizon)),
                     with: .linearGradient(Gradient(stops: skyStops),
                                           startPoint: CGPoint(x: 0, y: 0),
                                           endPoint: CGPoint(x: 0, y: horizon)))

        // Sterne über der Stadt.
        if !light {
            var seed: UInt64 = 0x9E3779B97F4A7C15
            func rnd() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double((seed >> 33) & 0xFFFFFF) / Double(0x1000000)
            }
            for _ in 0..<80 {
                let x = CGFloat(rnd()) * w
                let y = CGFloat(rnd()) * horizon * 0.70
                let r = 0.4 + CGFloat(rnd()) * 1.2
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                             with: .color(Color.white.opacity(0.14 + rnd() * 0.5)))
            }
        }

        // Wanderndes Farbband: der Himmel lebt.
        let bandY = horizon - h * 0.24 + CGFloat(sin(time * 0.22)) * h * 0.035
        context.fill(Path(CGRect(x: 0, y: bandY - h * 0.11, width: w, height: h * 0.22)),
                     with: .linearGradient(
                        Gradient(colors: [.clear,
                                          VicePalette.hotPink.opacity(light ? 0.10 : 0.18),
                                          VicePalette.coral.opacity(light ? 0.08 : 0.12),
                                          .clear]),
                        startPoint: CGPoint(x: 0, y: bandY - h * 0.11),
                        endPoint: CGPoint(x: 0, y: bandY + h * 0.11)))

        // Sonnenuntergang: Glow, Scheibe, Retrostreifen.
        let sunCenter = CGPoint(x: w * 0.5, y: horizon - h * 0.02)
        let sunRadius = w * 0.235
        context.fill(Path(ellipseIn: CGRect(x: sunCenter.x - w * 0.9, y: sunCenter.y - w * 0.9,
                                            width: w * 1.8, height: w * 1.8)),
                     with: .radialGradient(
                        Gradient(colors: [(light ? VicePalette.coral : VicePalette.hotPink).opacity(light ? 0.28 : 0.52),
                                          VicePalette.coral.opacity(light ? 0.12 : 0.24),
                                          .clear]),
                        center: sunCenter, startRadius: 4, endRadius: w * 0.9))

        let sunRect = CGRect(x: sunCenter.x - sunRadius, y: sunCenter.y - sunRadius,
                             width: sunRadius * 2, height: sunRadius * 2)
        context.drawLayer { layer in
            layer.clip(to: Path(ellipseIn: sunRect))
            layer.fill(Path(sunRect), with: .linearGradient(
                Gradient(colors: [VicePalette.gold,
                                  Color(red: 1.00, green: 0.64, blue: 0.24),
                                  VicePalette.coral,
                                  VicePalette.magenta]),
                startPoint: CGPoint(x: sunCenter.x, y: sunRect.minY),
                endPoint: CGPoint(x: sunCenter.x, y: sunRect.maxY)))
            var y = sunCenter.y - sunRadius * 0.15
            var gap = sunRadius * 0.10
            while y < sunRect.maxY {
                layer.fill(Path(CGRect(x: sunRect.minX, y: y, width: sunRect.width, height: gap * 0.55)),
                           with: .color(Color(red: 0.09, green: 0.02, blue: 0.15).opacity(light ? 0.40 : 0.80)))
                y += gap * 1.85
                gap *= 1.18
            }
        }
        context.stroke(Path(ellipseIn: sunRect),
                       with: .color(VicePalette.gold.opacity(light ? 0.45 : 0.80)),
                       lineWidth: 1.4)

        // Meer
        let seaStops: [Gradient.Stop] = light
            ? [
                .init(color: Color(red: 0.98, green: 0.74, blue: 0.72), location: 0.0),
                .init(color: Color(red: 0.94, green: 0.78, blue: 0.86), location: 0.30),
                .init(color: Color(red: 0.82, green: 0.80, blue: 0.94), location: 1.0),
            ]
            : [
                .init(color: Color(red: 0.42, green: 0.06, blue: 0.38), location: 0.0),
                .init(color: Color(red: 0.16, green: 0.02, blue: 0.26), location: 0.34),
                .init(color: Color(red: 0.03, green: 0.01, blue: 0.07), location: 1.0),
            ]
        context.fill(Path(CGRect(x: 0, y: horizon, width: w, height: h - horizon)),
                     with: .linearGradient(Gradient(stops: seaStops),
                                           startPoint: CGPoint(x: 0, y: horizon),
                                           endPoint: CGPoint(x: 0, y: h)))

        // Neon-Horizont
        context.fill(Path(CGRect(x: 0, y: horizon - 1, width: w, height: 2)),
                     with: .linearGradient(
                        Gradient(colors: [VicePalette.magenta.opacity(0.5),
                                          VicePalette.gold,
                                          VicePalette.cyan,
                                          VicePalette.magenta.opacity(0.5)]),
                        startPoint: CGPoint(x: 0, y: horizon),
                        endPoint: CGPoint(x: w, y: horizon)))

        // Perspektiv-Grid, das auf dich zuläuft.
        let rows = 16
        for index in 0..<rows {
            let base = Double(index) / Double(rows)
            let phase = (base + time * 0.055).truncatingRemainder(dividingBy: 1.0)
            let eased = pow(phase, 1.9)
            let y = horizon + CGFloat(eased) * (h - horizon)
            let fade = 1.0 - phase
            let alpha = (light ? 0.22 : 0.40) * fade
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y))
            line.addLine(to: CGPoint(x: w, y: y))
            context.stroke(line, with: .color(VicePalette.cyan.opacity(alpha)), lineWidth: 0.9)
        }
        for index in -9...9 {
            var ray = Path()
            ray.move(to: CGPoint(x: w * 0.5, y: horizon + 1))
            ray.addLine(to: CGPoint(x: w * 0.5 + CGFloat(index) * w * 0.19, y: h))
            context.stroke(ray, with: .color(VicePalette.magenta.opacity(light ? 0.14 : 0.24)),
                           lineWidth: 0.9)
        }

        // Sonnenreflex im Wasser.
        for index in 0..<12 {
            let position = (Double(index) + time * 1.3).truncatingRemainder(dividingBy: 12.0) / 12.0
            let y = horizon + CGFloat(position) * (h - horizon) * 0.85
            let shimmer = 0.6 + 0.4 * CGFloat(sin(position * 7.0 + time * 1.9))
            let width = w * (0.05 + 0.14 * CGFloat(position)) * shimmer
            let alpha = (1.0 - position) * 0.32
            let rect = CGRect(x: w * 0.5 - width, y: y, width: width * 2, height: 2.2)
            context.fill(Path(roundedRect: rect, cornerRadius: 1.1),
                         with: .color(Color(red: 1.0, green: 0.58, blue: 0.36).opacity(alpha)))
        }

        // Skyline von Vice City mit Neon-Kante.
        let skyline: [(CGFloat, CGFloat, CGFloat)] = [
            (0.00, 0.13, 0.10), (0.11, 0.09, 0.16), (0.19, 0.12, 0.08),
            (0.30, 0.08, 0.13), (0.62, 0.10, 0.11), (0.71, 0.09, 0.17),
            (0.80, 0.12, 0.09), (0.90, 0.11, 0.14),
        ]
        for building in skyline {
            let rect = CGRect(x: building.0 * w,
                              y: horizon - building.2 * h,
                              width: building.1 * w,
                              height: building.2 * h + 2)
            context.fill(Path(rect),
                         with: .color(Color(red: 0.05, green: 0.01, blue: 0.11).opacity(light ? 0.75 : 0.92)))
            var roof = Path()
            roof.move(to: CGPoint(x: rect.minX, y: rect.minY))
            roof.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            context.stroke(roof, with: .color(VicePalette.magenta.opacity(light ? 0.35 : 0.65)),
                           lineWidth: 1.1)
            var windows = Path()
            let columns = max(1, Int(rect.width / 12))
            for column in 0..<columns {
                let x = rect.minX + 4 + CGFloat(column) * 12
                if x + 3 > rect.maxX - 3 { continue }
                let y = rect.minY + 8 + CGFloat((column * 5) % max(1, Int(rect.height * 0.5)))
                windows.addRect(CGRect(x: x, y: y, width: 3, height: 4))
            }
            context.fill(windows, with: .color(VicePalette.gold.opacity(light ? 0.25 : 0.55)))
        }

        // Zwei Palmen als Markenzeichen, mit Neon-Rim.
        drawVicePalm(&context, base: CGPoint(x: w * 0.09, y: h * 1.03), height: h * 0.44,
                     lean: w * 0.035, color: Color(red: 0.04, green: 0.01, blue: 0.10).opacity(light ? 0.70 : 0.96))
        drawVicePalm(&context, base: CGPoint(x: w * 0.93, y: h * 1.05), height: h * 0.35,
                     lean: -w * 0.030, color: Color(red: 0.04, green: 0.01, blue: 0.10).opacity(light ? 0.70 : 0.96))

        // Treibende Neon-Partikel.
        let motes = 14
        for index in 0..<motes {
            let seed = Double(index) * 12.9898
            let spread = sin(seed) * 0.5 + 0.5
            let speed = 0.010 + (cos(seed) * 0.5 + 0.5) * 0.020
            let travel = (time * speed + Double(index) * 0.137).truncatingRemainder(dividingBy: 1.0)
            let y = h * (1.05 - CGFloat(travel) * 1.10)
            let x = w * CGFloat(spread) + CGFloat(sin(time * 0.8 + Double(index))) * 14
            let radius = 1.0 + CGFloat(cos(seed * 2) * 0.5 + 0.5) * 2.0
            let color = index % 3 == 0 ? VicePalette.cyan
                : (index % 3 == 1 ? VicePalette.magenta : VicePalette.gold)
            context.fill(Path(ellipseIn: CGRect(x: x - radius * 3, y: y - radius * 3,
                                                width: radius * 6, height: radius * 6)),
                         with: .radialGradient(Gradient(colors: [color.opacity(0.22), .clear]),
                                               center: CGPoint(x: x, y: y),
                                               startRadius: 0, endRadius: radius * 3))
            context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius,
                                                width: radius * 2, height: radius * 2)),
                         with: .color(color.opacity(0.55)))
        }

        // Vignette, damit oben und unten Ruhe ins Bild kommt.
        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)),
                     with: .radialGradient(
                        Gradient(colors: [.clear, Color.black.opacity(light ? 0.04 : 0.32)]),
                        center: CGPoint(x: w * 0.5, y: h * 0.45),
                        startRadius: w * 0.32, endRadius: w * 0.98))

        // Akzentblüte, die mit der Stimmung atmet.
        context.fill(Path(ellipseIn: CGRect(x: w * 0.5 - w * 0.55, y: horizon - w * 0.55,
                                            width: w * 1.1, height: w * 1.1)),
                     with: .radialGradient(Gradient(colors: [accent.opacity(light ? 0.05 : 0.10), .clear]),
                                           center: sunCenter, startRadius: 4, endRadius: w * 0.55))
    }

    /// Eine Palme als gefüllte Silhouette: Stamm plus sieben Wedel.
    static func drawPalm(_ context: inout GraphicsContext, base: CGPoint,
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

        for index in 0..<7 {
            let theta = (-165.0 + Double(index) * 25.0) * Double.pi / 180.0
            let edge = abs(abs(Double(index) - 3.0) / 3.0)
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

/// Freie Funktion, damit Kulisse, Emblem und Badges dieselbe Palme zeichnen.
func drawVicePalm(_ context: inout GraphicsContext, base: CGPoint,
                  height: CGFloat, lean: CGFloat, color: Color) {
    ViceScene.drawPalm(&context, base: base, height: height, lean: lean, color: color)
}

// MARK: - Glass surfaces

/// Liquid-Glass-Karte im Vice-Look: frostige Fläche mit Neon-Tint,
/// Magenta-Cyan-Kante und einem Glow, der langsam atmet.
struct GlassCard<Content: View>: View {
    var radius: CGFloat
    var tint: Color?
    var glow: Bool
    var padding: CGFloat
    var neon: Bool
    var content: Content

    @AppStorage("tandem.glow") private var glowEnabled = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    init(radius: CGFloat = 26,
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

    private var showsGlow: Bool { glow && glowEnabled }

    private var baseTint: Color { tint ?? VicePalette.violet }

    private var glassTint: Color {
        baseTint.opacity(showsGlow ? (pulsing ? 0.22 : 0.13) : (tint == nil ? 0.08 : 0.12))
    }

    private var glowShadow: Color {
        guard showsGlow else { return .clear }
        return baseTint.opacity(pulsing ? 0.42 : 0.20)
    }

    private var edgeStyle: AnyShapeStyle {
        neon ? AnyShapeStyle(VicePalette.edge)
             : AnyShapeStyle(LinearGradient(colors: [Color.white.opacity(0.34), Color.white.opacity(0.06)],
                                            startPoint: .top, endPoint: .bottom))
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
                            .fill(LinearGradient(colors: [Color.white.opacity(0.10), .clear, Color.white.opacity(0.03)],
                                                 startPoint: .top, endPoint: .bottom))
                            .blendMode(.plusLighter)
                            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(edgeStyle, lineWidth: neon ? 1.2 : 1)
                    }
                    .shadow(color: glowShadow, radius: showsGlow ? 22 : 0, y: 6)
            }
            .onAppear {
                guard showsGlow, !reduceMotion else { return }
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
                    .glassEffect(.regular.tint(tint?.opacity(0.22) ?? VicePalette.violet.opacity(0.16)), in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                LinearGradient(colors: [VicePalette.magenta.opacity(0.55),
                                                        VicePalette.cyan.opacity(0.45)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 0.9
                            )
                    }
                    .shadow(color: (tint ?? VicePalette.magenta).opacity(0.30), radius: 8)
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
                    .glassEffect(.regular.tint(tint?.opacity(0.22) ?? VicePalette.violet.opacity(0.18)), in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                LinearGradient(colors: [VicePalette.magenta.opacity(0.55),
                                                        VicePalette.cyan.opacity(0.45)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 0.9
                            )
                    }
            }
    }
}

/// Die ganze Seite inklusive Kulisse — und ohne den eigenen Hintergrund
/// von ScrollViews, damit die Farben durchscheinen.
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

/// Der Neon-Button: kräftige Füllung, weiße Lichtkante, Glow in der
/// Akzentfarbe — „Freigeben & Senden“ soll nach Stadt bei Nacht aussehen.
struct PrimaryGlassButtonStyle: ButtonStyle {
    var tint: Color = VicePalette.magenta

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.heavy))
            .tracking(0.3)
            .foregroundStyle(Color.black.opacity(0.88))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(LinearGradient(colors: [tint, tint.opacity(0.72)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay {
                        Capsule()
                            .fill(LinearGradient(colors: [Color.white.opacity(0.45), .clear],
                                                 startPoint: .top, endPoint: .center))
                    }
                    .overlay {
                        Capsule().strokeBorder(Color.white.opacity(0.55), lineWidth: 0.8)
                    }
                    .shadow(color: tint.opacity(configuration.isPressed ? 0.45 : 0.85),
                            radius: configuration.isPressed ? 6 : 18, y: 3)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(Color.white.opacity(0.92))
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular.tint(VicePalette.magenta.opacity(0.16)), in: Capsule())
                    .overlay {
                        Capsule().strokeBorder(
                            LinearGradient(colors: [VicePalette.cyan.opacity(0.55),
                                                    VicePalette.magenta.opacity(0.55)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                    }
                    .shadow(color: VicePalette.magenta.opacity(0.25), radius: 10)
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

/// Kapitel-Überschrift mit Neon-Kante und Sonnenuntergangs-Verlauf.
struct SectionHeader: View {
    var title: String
    var subtitle: String?
    var icon: String?
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(VicePalette.sunset)
                .frame(width: 3, height: 12)
                .shadow(color: VicePalette.magenta.opacity(0.8), radius: 5)
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(VicePalette.cyan)
            }
            Text(title.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(LinearGradient(colors: [Color.white.opacity(0.96),
                                                         VicePalette.cyan.opacity(0.85)],
                                                startPoint: .leading, endPoint: .trailing))
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(VicePalette.gold.opacity(0.85))
            }
        }
        .padding(.horizontal, 4)
    }
}

/// Knackscharfes Neon-Badge mit Glow.
struct StatusBadge: View {
    var text: String
    var tint: Color
    var icon: String?

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.system(size: 8.5, weight: .black))
            }
            Text(text.uppercased())
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .tracking(0.7)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(LinearGradient(colors: [tint.opacity(0.95), tint.opacity(0.45)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay { Capsule().strokeBorder(Color.white.opacity(0.42), lineWidth: 0.7) }
                .shadow(color: tint.opacity(0.65), radius: 8, y: 1)
        }
    }
}

/// Das GTA-Badge: „VICE CITY AGENT PROTOCOL“ und Verwandte.
struct ViceBadge: View {
    var text: String
    var tint: Color = VicePalette.magenta
    var icon: String = "bolt.fill"

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 8, weight: .black))
            Text(text.uppercased())
                .font(.system(size: 8.5, weight: .black, design: .rounded))
                .tracking(1.1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background {
            Capsule()
                .fill(LinearGradient(colors: [tint, tint.opacity(0.55)],
                                     startPoint: .leading, endPoint: .trailing))
                .overlay { Capsule().strokeBorder(Color.white.opacity(0.38), lineWidth: 0.6) }
                .shadow(color: tint.opacity(0.70), radius: 11, y: 2)
        }
    }
}

/// Dünne Neon-Trennlinie mit Vice-Verlauf.
struct NeonDivider: View {
    var body: some View {
        LinearGradient(colors: [VicePalette.magenta.opacity(0.0),
                                VicePalette.magenta.opacity(0.55),
                                VicePalette.cyan.opacity(0.55),
                                VicePalette.cyan.opacity(0.0)],
                       startPoint: .leading, endPoint: .trailing)
            .frame(height: 1)
    }
}

/// Laufband im Stil von Weazel News: bunte Schlagzeilen, die durchziehen.
struct WeazelTicker: View {
    var items: [String]
    var tint: Color = VicePalette.cyan

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var textWidth: CGFloat = 0

    private var line: String {
        items.joined(separator: "    \u{25C6}    ")
    }

    private let gap: CGFloat = 44

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 8, weight: .black))
                Text("WEAZEL NEWS")
                    .font(.system(size: 8.5, weight: .black, design: .rounded))
                    .tracking(1.1)
            }
            .foregroundStyle(Color.black.opacity(0.85))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(LinearGradient(colors: [VicePalette.gold, VicePalette.coral],
                                         startPoint: .leading, endPoint: .trailing))
                    .shadow(color: VicePalette.coral.opacity(0.65), radius: 10, y: 1)
            }

            GeometryReader { proxy in
                let viewWidth = proxy.size.width
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
                    let period = max(1, textWidth + gap)
                    let offset = reduceMotion
                        ? 0
                        : CGFloat((timeline.date.timeIntervalSinceReferenceDate * 42.0)
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
            .frame(height: 18)
            .mask(
                LinearGradient(stops: [
                    .init(color: .clear, location: 0.00),
                    .init(color: .black, location: 0.05),
                    .init(color: .black, location: 0.94),
                    .init(color: .clear, location: 1.00),
                ], startPoint: .leading, endPoint: .trailing)
            )
        }
    }

    private var headline: some View {
        Text(line)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .tracking(0.4)
            .foregroundStyle(tint.opacity(0.95))
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

/// Die Palme als eigenständiges Zeichen — für Emblem, Badges, Footer.
struct PalmGlyph: View {
    var tint: Color = VicePalette.magenta
    var rim: Color? = VicePalette.cyan

    var body: some View {
        Canvas { context, size in
            let base = CGPoint(x: size.width * 0.5, y: size.height * 1.02)
            let height = size.height * 0.94
            let lean = size.width * 0.06
            if let rim {
                drawVicePalm(&context, base: CGPoint(x: base.x + 1.2, y: base.y - 1.2),
                             height: height, lean: lean, color: rim.opacity(0.7))
            }
            drawVicePalm(&context, base: base, height: height, lean: lean, color: tint)
        }
    }
}

/// Das Gatekeeper-Emblem: Vice-Sonne, Neonschein, zwei Ringe, Palme,
/// Horizon-Grid. Reine Zeichnung, skaliert mit dem Rahmen.
struct ViceEmblem: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let center = CGPoint(x: w * 0.5, y: h * 0.50)

            // Glow
            context.fill(Path(ellipseIn: CGRect(x: center.x - w * 0.5, y: center.y - w * 0.5,
                                                width: w, height: w)),
                         with: .radialGradient(
                            Gradient(colors: [VicePalette.hotPink.opacity(0.45),
                                              VicePalette.violet.opacity(0.22),
                                              .clear]),
                            center: center, startRadius: 6, endRadius: w * 0.5))

            // Ringe
            context.stroke(Path(ellipseIn: CGRect(x: w * 0.06, y: h * 0.06,
                                                  width: w * 0.88, height: w * 0.88)),
                           with: .color(VicePalette.cyan.opacity(0.55)), lineWidth: 1.3)
            context.stroke(Path(ellipseIn: CGRect(x: w * 0.13, y: h * 0.13,
                                                  width: w * 0.74, height: w * 0.74)),
                           with: .color(VicePalette.magenta.opacity(0.55)), lineWidth: 0.9)

            // Sonne
            let radius = w * 0.23
            let sunRect = CGRect(x: center.x - radius, y: center.y - radius,
                                 width: radius * 2, height: radius * 2)
            context.drawLayer { layer in
                layer.clip(to: Path(ellipseIn: sunRect))
                layer.fill(Path(sunRect), with: .linearGradient(
                    Gradient(colors: [VicePalette.gold, VicePalette.coral, VicePalette.magenta]),
                    startPoint: CGPoint(x: center.x, y: sunRect.minY),
                    endPoint: CGPoint(x: center.x, y: sunRect.maxY)))
                var y = sunRect.midY
                var gap = radius * 0.16
                while y < sunRect.maxY {
                    layer.fill(Path(CGRect(x: sunRect.minX, y: y, width: sunRect.width, height: gap * 0.5)),
                               with: .color(Color(red: 0.06, green: 0.02, blue: 0.12).opacity(0.85)))
                    y += gap
                    gap *= 1.32
                }
            }
            context.stroke(Path(ellipseIn: sunRect), with: .color(VicePalette.gold.opacity(0.85)), lineWidth: 1.2)

            // Horizon-Grid
            for index in 0..<5 {
                let y = h * 0.74 + CGFloat(index) * h * 0.028
                var line = Path()
                line.move(to: CGPoint(x: w * 0.16, y: y))
                line.addLine(to: CGPoint(x: w * 0.84, y: y))
                context.stroke(line, with: .color(VicePalette.cyan.opacity(0.30)), lineWidth: 0.7)
            }
            for index in -4...4 {
                var ray = Path()
                ray.move(to: CGPoint(x: w * 0.5, y: h * 0.74))
                ray.addLine(to: CGPoint(x: w * 0.5 + CGFloat(index) * w * 0.10, y: h * 0.90))
                context.stroke(ray, with: .color(VicePalette.magenta.opacity(0.22)), lineWidth: 0.7)
            }

            // Palme davor
            drawVicePalm(&context, base: CGPoint(x: w * 0.5, y: h * 0.92),
                         height: h * 0.66, lean: w * 0.02,
                         color: Color(red: 0.03, green: 0.01, blue: 0.06))
        }
    }
}

/// CRT-Feeling über dem ganzen Bild: Vignette plus feine Scanlines.
struct ViceOverlay: View {
    var strength: Double = 1

    var body: some View {
        ZStack {
            LinearGradient(stops: [
                .init(color: Color.black.opacity(0.30 * strength), location: 0.00),
                .init(color: .clear, location: 0.18),
                .init(color: .clear, location: 0.80),
                .init(color: Color.black.opacity(0.36 * strength), location: 1.00),
            ], startPoint: .top, endPoint: .bottom)

            Canvas { context, size in
                var y: CGFloat = 0
                while y < size.height {
                    context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 0.7)),
                                 with: .color(Color.black.opacity(0.07 * strength)))
                    y += 3
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
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
                .stroke(LinearGradient(colors: [tint, VicePalette.cyan],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.7), radius: 6)
                .animation(.easeInOut(duration: 0.5), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.26, weight: .heavy, design: .rounded))
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
