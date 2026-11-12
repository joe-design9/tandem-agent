import Foundation
import SwiftUI

/// Der Zustand, den der Agent bei jedem Werkzeugaufruf lesen darf.
/// Alles davon liegt lokal in der App — kein Werkzeug geht ins Netz.
struct AgentContext {
    var userName: String
    var city: String
    var role: String
    var today: String
    var weather: String
    var weatherDetail: String
    var temperature: String
    var agenda: [BriefingItem]
    var todos: [String]
    var pendingApprovals: [ApprovalRequest]
    var runningTasks: [AgentTask]
    var memoryHighlights: [String]
    var unreadMails: Int
    var repos: [String]
    var nightNote: String
    var recentScans: [CheckIn]
}

/// Ein Werkzeug, das der Agent aufrufen kann. Jedes hat einen festen
/// Namen (so erscheint es im Protokoll), ein Risiko und eine Farbe.
struct AgentTool: Identifiable, Hashable {
    var name: String
    var title: String
    var detail: String
    var icon: String
    var tint: Color
    var sensitive: Bool
    var risk: Risk

    var id: String { name }

    static let all: [AgentTool] = [
        AgentTool(name: "plan.build", title: "Plan bauen", detail: "Ziel in Schritte zerlegen",
                  icon: "point.3.connected.trianglepath.dotted", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "web.scan", title: "Web scannen", detail: "Quellen nach dem Ziel absuchen",
                  icon: "globe", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "web.read", title: "Quelle lesen", detail: "Treffer im Volltext prüfen",
                  icon: "doc.text.magnifyingglass", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "news.rank", title: "Meldungen gewichten", detail: "Relevanz, Duplikate, Alter",
                  icon: "line.3.horizontal.decrease", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "repo.check", title: "Repos prüfen", detail: "Branches, PRs, letzte Commits",
                  icon: "chevron.left.forwardslash.chevron.right", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "ci.inspect", title: "CI-Läufe prüfen", detail: "Rote Builds und Ursachen",
                  icon: "gearshape.2", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "mail.triage", title: "Postfach triagieren", detail: "Ungelesenes der letzten Tage",
                  icon: "envelope.badge", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "mail.rank", title: "Wichtigkeit einordnen", detail: "Absender, Fristen, offene Fragen",
                  icon: "flag", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "mail.draft", title: "Antwort entwerfen", detail: "Entwurf — Versand nur nach Freigabe",
                  icon: "pencil.line", tint: Palette.icon,
                  sensitive: true, risk: .medium),
        AgentTool(name: "mail.send", title: "Mail senden", detail: "Geht erst nach deinem Ja raus",
                  icon: "paperplane", tint: Palette.icon,
                  sensitive: true, risk: .medium),
        AgentTool(name: "calendar.read", title: "Kalender lesen", detail: "Termine, Kollisionen, freie Blöcke",
                  icon: "calendar", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "calendar.plan", title: "Blöcke rechnen", detail: "Zwei machbare Alternativen",
                  icon: "rectangle.split.3x1", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "calendar.create", title: "Termin eintragen", detail: "Schreibt erst nach Freigabe",
                  icon: "calendar.badge.plus", tint: Palette.icon,
                  sensitive: true, risk: .low),
        AgentTool(name: "memory.sync", title: "Gedächtnis abgleichen", detail: "Bekanntes Kontext zuordnen",
                  icon: "brain.head.profile", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "memory.write", title: "Gedächtnis ergänzen", detail: "Neue Fakten vormerken",
                  icon: "brain", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "weather.read", title: "Wetter lesen", detail: "Ort, Temperatur, Fenster",
                  icon: "cloud.sun", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "brief.compose", title: "Briefing formulieren", detail: "Ein Punkt, keine Liste",
                  icon: "text.alignleft", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "doc.write", title: "Entwurf schreiben", detail: "Kurz, konkret, auf Deutsch",
                  icon: "doc.text", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "pay.charge", title: "Zahlung auslösen", detail: "Betrag, Karte, Laufzeit",
                  icon: "creditcard", tint: Palette.icon,
                  sensitive: true, risk: .medium),
        AgentTool(name: "github.artifacts.delete", title: "Artefakte löschen", detail: "Nur abgelaufene Builds",
                  icon: "trash", tint: Palette.icon,
                  sensitive: true, risk: .low),
        AgentTool(name: "approval.queue", title: "Freigabe vorlegen", detail: "Auf den Tisch, nicht raus",
                  icon: "hand.raised", tint: Palette.icon,
                  sensitive: false, risk: .low),
        AgentTool(name: "result.synthesis", title: "Ergebnis synthetisieren", detail: "Gegen das Ziel abgleichen",
                  icon: "checkmark.seal", tint: Palette.icon,
                  sensitive: false, risk: .low),
    ]

    static func find(_ name: String) -> AgentTool? {
        all.first { $0.name == name }
    }

    static func title(for name: String) -> String {
        find(name)?.title ?? name
    }

    static func icon(for name: String) -> String {
        find(name)?.icon ?? "wrench.and.screwdriver.fill"
    }

    static func tint(for name: String) -> Color {
        find(name)?.tint ?? Palette.icon
    }
}

/// Was ein Werkzeug zurückgibt: eine Kurzzeile für die Status-Pille,
/// Protokollzeilen und — bei sensiblen Schritten — eine vorbereitete
/// Freigabe, die auf Joels Ja wartet.
struct ToolOutcome {
    var summary: String
    var notes: [String] = []
    var insight: String?
    var approval: ApprovalRequest?
}

enum ToolRunner {
    /// Simuliert den Aufruf gegen den echten App-Zustand. Deterministisch
    /// genug, um glaubwürdig zu sein, variabel genug, um nicht wie eine
    /// Tabelle zu wirken.
    static func run(_ name: String, goal: String, context: AgentContext, step: Int) -> ToolOutcome {
        let text = goal.lowercased()
        let noisy = (abs(goal.hashValue &+ step &* 31) % 3) + 1

        switch name {
        case "plan.build":
            return ToolOutcome(summary: "Absicht erkannt",
                               notes: ["Ziel gelesen: „\(goal.prefix(64))“",
                                       "Werkzeuge gewählt: \(noisy + 2) Schritte, kein Netz nötig"])

        case "web.scan":
            let target = newsTarget(text)
            return ToolOutcome(summary: "\(noisy + 3) Quellen geprüft",
                               notes: ["Gescannt: \(target.scanline)",
                                       "Streuung: \(noisy) neue Meldungen seit dem letzten Lauf"],
                               insight: target.insight)

        case "web.read":
            return ToolOutcome(summary: "2 Quellen gelesen",
                               notes: ["Volltext geprüft, Dubletten zusammengelegt",
                                       "Primärquelle statt Aggregator bevorzugt"])

        case "news.rank":
            return ToolOutcome(summary: "\(noisy + 1) relevant",
                               notes: ["Gewichtet nach Datum, Quelle und Bezug zu deinen Projekten",
                                       "1 Meldung ist ein Duplikat von gestern"],
                               insight: "Relevant bleibt vor allem, was Release-Termine oder deinen Hub betrifft.")

        case "repo.check":
            let repos = context.repos.prefix(4).joined(separator: ", ")
            return ToolOutcome(summary: "\(context.repos.count) Repos grün",
                               notes: ["Gelesen: \(repos)",
                                       "Keine offenen PRs älter als 3 Tage"],
                               insight: "Alle Repos sind grün — nichts, was heute deine Hand braucht.")

        case "ci.inspect":
            return ToolOutcome(summary: "12 Läufe, 0 rot",
                               notes: ["3 Läufe heute, alle erfolgreich",
                                       "Längster Lauf: 1 min 12 s (iOS Release)"],
                               insight: "Die Pipelines laufen durch.")

        case "mail.triage":
            return ToolOutcome(summary: "\(context.unreadMails) ungelesen",
                               notes: ["Absender und Fristen geprüft",
                                       "1 Mail ist heute relevant, 2 können warten"],
                               insight: "Eine Mail sollte heute raus, der Rest hat Zeit bis morgen.")

        case "mail.rank":
            let urgent = context.pendingApprovals.first { $0.kind == .email }
            return ToolOutcome(summary: urgent == nil ? "nichts Dringendes" : "1 dringend",
                               notes: [urgent.map { "Wichtig: \($0.title)" } ?? "Keine Frist in den nächsten 24 Stunden",
                                       "Newsletter und Benachrichtigungen aussortiert"])

        case "mail.draft":
            return ToolOutcome(summary: "Entwurf steht",
                               notes: ["Ton: kurz, direkt, ohne Floskeln", "Versand ist gesperrt, bis du zustimmst"],
                               insight: "Der Entwurf liegt als Freigabe bereit.",
                               approval: draftApproval(goal: goal, context: context))

        case "mail.send":
            return ToolOutcome(summary: "wartet auf Freigabe",
                               notes: ["Kein Versand ohne dein Ja"],
                               approval: draftApproval(goal: goal, context: context))

        case "calendar.read":
            return ToolOutcome(summary: "\(context.agenda.count) Termine",
                               notes: ["Heute: \(context.agenda.first.map { "\($0.time) \($0.title)" } ?? "nichts eingetragen")",
                                       "Morgen ist der Vormittag frei"],
                               insight: "Zwei Blöcke sind noch unverplant.")

        case "calendar.plan":
            return ToolOutcome(summary: "2 Alternativen",
                               notes: ["Variante A: 09:30–11:00", "Variante B: 15:00–16:30"],
                               insight: "Beide passen ohne Kollision.")

        case "calendar.create":
            return ToolOutcome(summary: "wartet auf Freigabe",
                               notes: ["Termin ist vorbereitet, nicht eingetragen"],
                               approval: calendarApproval(goal: goal))

        case "memory.sync":
            return ToolOutcome(summary: "\(max(1, context.memoryHighlights.count)) Treffer",
                               notes: ["Profil, Projekte und Arbeitsrhythmus abgeglichen",
                                       "Kein Widerspruch zu dem, was ich schon weiß"])

        case "memory.write":
            return ToolOutcome(summary: "2 Fakten vorgemerkt",
                               notes: ["Übernehme nur, was im Gespräch wirklich vorkam"])

        case "weather.read":
            return ToolOutcome(summary: "\(context.temperature) in \(context.city)",
                               notes: ["\(context.weather)",
                                       "Fenster für draußen: heute Nachmittag"])

        case "brief.compose":
            let top = context.agenda.first?.title ?? "Fokusblock"
            return ToolOutcome(summary: "\(max(2, context.agenda.count)) Punkte",
                               notes: ["Erster Punkt: \(top)", "Todos aus dem Briefing übernommen"],
                               insight: "Heute zählt ein Ding, der Rest ist Beiwerk.")

        case "doc.write":
            return ToolOutcome(summary: "Entwurf, 310 Wörter",
                               notes: ["Drei Absätze, kein Marketing", "Auf Deutsch, mit konkreten Zahlen"])

        case "pay.charge":
            return ToolOutcome(summary: "wartet auf Freigabe",
                               notes: ["Betrag und Karte geprüft", "Nichts abgebucht"],
                               approval: paymentApproval())

        case "github.artifacts.delete":
            return ToolOutcome(summary: "wartet auf Freigabe",
                               notes: ["Nur abgelaufene Artefakte, kein Branch, kein Release"],
                               approval: artifactApproval())

        case "approval.queue":
            return ToolOutcome(summary: "\(context.pendingApprovals.count + 1) auf dem Tisch",
                               notes: ["Alles liegt bei dir, nichts ist gelaufen"])

        case "result.synthesis":
            return ToolOutcome(summary: "Ergebnis steht",
                               notes: ["Gegen das Ziel abgeglichen", "Keine offenen Fehler"])

        default:
            return ToolOutcome(summary: "erledigt",
                               notes: ["Schritt abgeschlossen"])
        }
    }

    // MARK: Vorlagen

    private struct NewsTarget {
        var scanline: String
        var insight: String
    }

    private static func newsTarget(_ text: String) -> NewsTarget {
        if text.contains("gta") || text.contains("rockstar") || text.contains("leonida") {
            return NewsTarget(scanline: "Rockstar Newswire, GTANet, r/GTA6, dein gta6-hub",
                              insight: "Beim GTA-6-Release-Fenster hat sich nichts verschoben; zwei Portale melden dasselbe, eines hat es von gestern abgeschrieben.")
        }
        if text.contains("swift") || text.contains("ios") || text.contains("xcode") {
            return NewsTarget(scanline: "Apple Developer News, Swift.org, WWDC-Sessions",
                              insight: "Zwei neue SwiftUI-APIs sind für dein Liquid-Glass-Layout relevant.")
        }
        return NewsTarget(scanline: "Nachrichtenquellen, Fach-Feeds, deine Repos",
                          insight: "Die Lage ist ruhig; eine Meldung betrifft dein Projekt direkt.")
    }

    private static func draftApproval(goal: String, context: AgentContext) -> ApprovalRequest {
        let existing = context.pendingApprovals.first { $0.kind == .email }
        let recipient = existing?.recipient ?? "team@playtest-vault.dev"
        let subject = existing?.subject ?? "Re: \(goal.prefix(48))"
        let body = existing?.body ?? """
        Hey zusammen,

        kurz zum Stand: Ich habe die offenen Punkte durchgesehen und würde heute nachziehen. Details bringe ich mit.

        Viele Grüße
        \(context.userName)
        """
        return ApprovalRequest(kind: .email,
                               title: existing?.title ?? "Antwort auf deinen Auftrag",
                               summary: "Entwurf fertig — Versand erst nach Freigabe",
                               recipient: recipient,
                               subject: subject,
                               body: body,
                               risk: .medium,
                               tool: "mail.send",
                               reason: "Der Agent hat den Entwurf aus deinem Ziel und dem Postfach gebaut.")
    }

    private static func calendarApproval(goal: String) -> ApprovalRequest {
        ApprovalRequest(kind: .calendar,
                        title: "Fokusblock eintragen",
                        summary: "90 Minuten, kollisionsfrei",
                        risk: .low,
                        tool: "calendar.create",
                        reason: "Der Block ist frei; eingetragen wird erst nach deinem Ja.")
    }

    private static func paymentApproval() -> ApprovalRequest {
        ApprovalRequest(kind: .payment,
                        title: "Abo verlängern",
                        summary: "Monatsbetrag, Karte endet auf 4417",
                        amount: "10,00 €",
                        risk: .medium,
                        tool: "pay.charge",
                        reason: "Läuft in zwei Tagen aus. Nichts wurde abgebucht.")
    }

    private static func artifactApproval() -> ApprovalRequest {
        ApprovalRequest(kind: .deletion,
                        title: "Alte Build-Artefakte löschen",
                        summary: "12,4 GB, älter als 30 Tage",
                        risk: .low,
                        tool: "github.artifacts.delete",
                        reason: "Betrifft nur abgelaufene Artefakte — keine Branches, keine Releases.")
    }
}
