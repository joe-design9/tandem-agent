import SwiftUI
import UIKit

// MARK: - Palette

/// Eine ruhige, monochrome Palette. Farbe trägt hier Bedeutung, nicht
/// Dekoration: Weiß und Grau für alles Strukturelle, genau ein warmer
/// Akzent für aktive Zustände. Rot nur für Fehler und Löschen.
enum Palette {
    // Flächen
    static let background = Color(red: 0.05, green: 0.05, blue: 0.07)
    static let backgroundLift = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let surface = Color(white: 0.12)
    static let surfaceRaised = Color(white: 0.155)
    static let surfaceSunken = Color(white: 0.09)

    // Linien
    static let hairline = Color.white.opacity(0.08)
    static let hairlineStrong = Color.white.opacity(0.14)

    // Schrift
    static let textPrimary = Color.white.opacity(0.94)
    static let textSecondary = Color.white.opacity(0.56)
    static let textTertiary = Color.white.opacity(0.32)

    // Der eine Akzent: warmes Sand. Handgemacht, kein Neon.
    static let accent = Color(red: 0.84, green: 0.72, blue: 0.56)
    static let onAccent = Color(red: 0.09, green: 0.08, blue: 0.06)

    // Nur für Fehler, Warnungen und Löschen.
    static let danger = Color(red: 0.84, green: 0.46, blue: 0.44)

    // Icons sind grundsätzlich monochrom.
    static let icon = Color.white.opacity(0.60)
    static let iconStrong = Color.white.opacity(0.84)
}

// MARK: - Themes

/// Drei ruhige Bühnen. Sie unterscheiden sich nur in der Tiefe des
/// Schwarz — kein Licht, keine Animation, keine Effekte.
enum TandemTheme: String, CaseIterable, Identifiable, Codable {
    case obsidian
    case graphite
    case midnight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .obsidian: return "Obsidian"
        case .graphite: return "Graphit"
        case .midnight: return "Mitternacht"
        }
    }

    var subtitle: String {
        switch self {
        case .obsidian: return "Tiefes Schwarz, neutral"
        case .graphite: return "Etwas weicher, wärmer"
        case .midnight: return "Schwarz mit kühlem Blau"
        }
    }

    var top: Color {
        switch self {
        case .obsidian: return Color(red: 0.07, green: 0.07, blue: 0.085)
        case .graphite: return Color(red: 0.09, green: 0.085, blue: 0.08)
        case .midnight: return Color(red: 0.06, green: 0.07, blue: 0.10)
        }
    }

    var bottom: Color {
        switch self {
        case .obsidian: return Color(red: 0.04, green: 0.04, blue: 0.05)
        case .graphite: return Color(red: 0.05, green: 0.05, blue: 0.05)
        case .midnight: return Color(red: 0.035, green: 0.04, blue: 0.06)
        }
    }
}

enum AccentChoice: String, CaseIterable, Identifiable, Codable {
    case sand
    case clay
    case sage
    case sky
    case lilac
    case stone

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sand: return "Sand"
        case .clay: return "Ton"
        case .sage: return "Salbei"
        case .sky: return "Himmel"
        case .lilac: return "Flieder"
        case .stone: return "Stein"
        }
    }

    var color: Color {
        switch self {
        case .sand: return Color(red: 0.84, green: 0.72, blue: 0.56)
        case .clay: return Color(red: 0.82, green: 0.58, blue: 0.48)
        case .sage: return Color(red: 0.64, green: 0.76, blue: 0.64)
        case .sky: return Color(red: 0.60, green: 0.72, blue: 0.84)
        case .lilac: return Color(red: 0.72, green: 0.68, blue: 0.84)
        case .stone: return Color(red: 0.76, green: 0.76, blue: 0.74)
        }
    }

    /// Dunkle Variante für Flächen, die den Akzent tragen.
    var deep: Color { color.opacity(0.72) }

    var onAccent: Color { Palette.onAccent }
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

    /// Tandem ist bewusst eine dunkle App. Ein heller Modus würde die
    /// weiße Typografie auf den dunklen Flächen unlesbar machen.
    var colorScheme: ColorScheme? { .dark }
}

// MARK: - Background

/// Die Bühne: ein einziger, statischer Verlauf. Keine Blurs, keine
/// Animationen, kein Canvas — der Metal-Renderer hat hier nichts zu tun.
struct AppBackground: View {
    var theme: TandemTheme = .obsidian
    var accent: Color = Palette.accent

    var body: some View {
        LinearGradient(colors: [theme.top, theme.bottom],
                       startPoint: .top,
                       endPoint: .bottom)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

// MARK: - Surfaces

/// Eine schlichte, dunkle Karte: eine Fläche, eine 0.5-pt Kante, ein
/// leiser Schatten. Nichts, was beim Scrollen nachgerechnet werden muss.
struct Card<Content: View>: View {
    var radius: CGFloat
    var padding: CGFloat
    var content: Content

    init(radius: CGFloat = 18, padding: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Palette.surface)
            }
            .shadow(color: Color.black.opacity(0.20), radius: 8, y: 4)
    }
}

/// Eine Zeile in einer Liste: Icon links, Text, optionaler Wert, Chevron.
/// Wird überall dort benutzt, wo eine native Liste zu eng wäre.
struct RowLabel: View {
    var icon: String
    var title: String
    var detail: String?
    var value: String?
    var showsChevron: Bool

    init(icon: String,
         title: String,
         detail: String? = nil,
         value: String? = nil,
         showsChevron: Bool = false) {
        self.icon = icon
        self.title = title
        self.detail = detail
        self.value = value
        self.showsChevron = showsChevron
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Palette.icon)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textPrimary)
                if let detail {
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            if let value {
                Text(value)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textTertiary)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Controls

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Palette.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Palette.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.82 : 1))
            }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Palette.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background {
                Capsule().fill(Palette.surfaceRaised)
            }
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

// MARK: - Small pieces

/// Kapitel-Überschrift: eine Zeile, leise, in normaler Schrift.
struct SectionLabel: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Palette.textSecondary)
            .padding(.horizontal, 2)
    }
}

/// Status-Chip: Text, ein Punkt, kein Neon. Farbe nur, wenn sie etwas sagt.
struct StatusTag: View {
    enum Tone {
        case neutral
        case active
        case danger
    }

    var text: String
    var tone: Tone

    init(_ text: String, tone: Tone = .neutral) {
        self.text = text
        self.tone = tone
    }

    private var color: Color {
        switch tone {
        case .neutral: return Palette.textSecondary
        case .active: return Palette.accent
        case .danger: return Palette.danger
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background {
            Capsule().fill(color.opacity(0.10))
        }
    }
}

struct ThinDivider: View {
    var body: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(height: 0.5)
    }
}

/// Ein ruhiger Leerzustand: Icon, zwei Zeilen, fertig.
struct EmptyState: View {
    var icon: String
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Palette.textTertiary)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
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

// MARK: - Formatting

/// Deutsche Zeitangaben: „gerade eben", „vor 4 Min.", „vor 2 Std.".
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

    /// Dauer eines Laufs: „45 Sek.", „3 Min.", „1 Std. 12 Min."
    static func duration(from start: Date, to end: Date? = nil) -> String {
        let seconds = max(0, (end ?? Date()).timeIntervalSince(start))
        if seconds < 60 { return "\(Int(seconds)) Sek." }
        if seconds < 3600 { return "\(Int(seconds / 60)) Min." }
        let hours = Int(seconds / 3600)
        let minutes = Int(seconds.truncatingRemainder(dividingBy: 3600) / 60)
        return minutes == 0 ? "\(hours) Std." : "\(hours) Std. \(minutes) Min."
    }
}
