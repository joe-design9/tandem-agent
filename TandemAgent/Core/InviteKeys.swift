import Foundation

/// Invite-Key-Logik für die Research Preview.
///
/// Tandem ist bewusst eine geschlossene Preview: Ohne eingelösten Key
/// bleibt die App hinter dem Gatekeeper. Es gibt zwei Wege hinein —
/// die Founder-Keys unten oder einen Code, den Joel in den Einstellungen
/// selbst erzeugt und weitergibt.
enum InviteKeys {
    /// Founder-Zugänge. Diese Keys schalten zusätzlich das Founder-Badge frei.
    static let masterKeys: [String] = [
        "JOEL-VIP",
        "VICE-VIP",
        "LEONIDA-DEV",
        "OCEAN-DRIVE",
        "TANDEM-2026",
        "DUET-FOUNDER",
    ]

    /// Zeichen ohne Verwechslungsgefahr (kein O/0, kein I/1).
    private static let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func normalize(_ raw: String) -> String {
        raw
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isMaster(_ code: String) -> Bool {
        masterKeys.contains(normalize(code))
    }

    /// Erzeugt einen Code im Vice-Style: meist VICE-XXXX-XXXX,
    /// gelegentlich TNDM-XXXX-XXXX.
    static func generate() -> String {
        func block(_ length: Int) -> String {
            String((0..<length).map { _ in alphabet.randomElement() ?? "X" })
        }
        let prefix = Bool.random() ? "VICE" : "TNDM"
        return "\(prefix)-\(block(4))-\(block(4))"
    }

    /// Format, das im Feld angezeigt wird: TNDM-AB12-CD34.
    static func formatted(_ raw: String) -> String {
        let clean = normalize(raw).filter { $0.isLetter || $0.isNumber || $0 == "-" }
        return String(clean.prefix(14))
    }

    static var exampleKey: String { masterKeys[0] }

    static var masterHint: String { "Founder-Keys: JOEL-VIP · VICE-VIP · LEONIDA-DEV · OCEAN-DRIVE · TANDEM-2026" }
}
