import AppIntents
import Foundation

// MARK: - Siri und Shortcuts
//
// Tandem ist ab Werk ein Siri-Agent: „Hey Siri, frag Tandem nach meinem
// Briefing“ läuft auf dem Gerät, ohne Konto, ohne Key, ohne Netz. Die Intents
// greifen auf genau den `TandemStore` zu, den die App zeigt — was Tandem auf
// dem Bildschirm weiß, weiß Siri hier auch.

/// Liest das Tagesbriefing: Wetter, nächster Termin, Freigaben, Läufe.
struct BriefingIntent: AppIntent {
    static let title: LocalizedStringResource = "Tagesbriefing"
    static let description: IntentDescription? = IntentDescription(
        "Liest dir vor, was heute ansteht: Wetter, Termine, Freigaben und laufende Aufgaben."
    )

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = TandemStore.shared
        return .result(dialog: IntentDialog(stringLiteral: store.spokenBriefing))
    }
}

/// Prüft die vier Projekte und sagt, wo es rot ist.
struct RepoCheckIntent: AppIntent {
    static let title: LocalizedStringResource = "Repos prüfen"
    static let description: IntentDescription? = IntentDescription(
        "Prüft gta6-hub, tandem-agent, playtest-vault und gta-vi-news und meldet den Stand."
    )

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = TandemStore.shared
        return .result(dialog: IntentDialog(stringLiteral: store.performRepoCheck()))
    }
}

/// Legt einen Auftrag an, ohne dass die App im Vordergrund steht.
struct QuickTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Auftrag anlegen"
    static let description: IntentDescription? = IntentDescription(
        "Legt einen neuen Auftrag in Tandem an und startet den Lauf."
    )

    @Parameter(title: "Auftrag", description: "Was soll Tandem übernehmen?")
    var auftrag: String

    init() {}

    init(auftrag: String) {
        self.auftrag = auftrag
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Auftrag: \(\.$auftrag)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = TandemStore.shared
        let goal = auftrag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !goal.isEmpty else {
            return .result(dialog: IntentDialog(stringLiteral: "Sag mir noch, was ich übernehmen soll."))
        }
        store.createTask(goal: goal)
        return .result(dialog: IntentDialog(
            stringLiteral: "Angelegt: \(goal). Der Lauf steht im Aufgaben-Tab von Tandem."
        ))
    }
}

// MARK: - Siri-Phrasen

/// Die Sätze, die Tandem ohne Einrichtung in Siri bekommt.
struct TandemShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: BriefingIntent(),
            phrases: [
                "Frag \(.applicationName) nach meinem Briefing",
                "Was steht heute an laut \(.applicationName)",
                "Lass mich \(.applicationName) mein Briefing geben",
            ],
            shortTitle: "Briefing",
            systemImageName: "sun.max"
        )
        AppShortcut(
            intent: RepoCheckIntent(),
            phrases: [
                "Lass \(.applicationName) meine Repos prüfen",
                "Prüfe meine Repos mit \(.applicationName)",
                "Was sagen meine Repos laut \(.applicationName)",
            ],
            shortTitle: "Repos prüfen",
            systemImageName: "chevron.left.forwardslash.chevron.right"
        )
        AppShortcut(
            intent: QuickTaskIntent(),
            phrases: [
                "Leg einen Auftrag in \(.applicationName) an",
                "Neuer Auftrag für \(.applicationName)",
                "Sag \(.applicationName) einen neuen Auftrag",
            ],
            shortTitle: "Auftrag",
            systemImageName: "bolt.horizontal"
        )
    }
}

// MARK: - Was Siri aus dem App-Zustand liest

@MainActor
extension TandemStore {

    /// Ein gesprochener Absatz: der Tag, wie er gerade aussieht.
    var spokenBriefing: String {
        var parts: [String] = []

        parts.append("\(Salutation.now()) \(userName). \(briefing.temperature) in \(city), \(briefing.weather.lowercased()).")

        if let next = briefing.agenda.first {
            parts.append("Nächster Termin um \(next.time): \(next.title).")
        } else {
            parts.append("Heute steht kein Termin im Kalender.")
        }

        if let first = pendingApprovals.first {
            let count = pendingApprovals.count
            parts.append("\(count) \(count == 1 ? "Freigabe wartet" : "Freigaben warten") auf dich, zuerst: \(first.title).")
        } else {
            parts.append("Auf deinem Tisch liegt nichts.")
        }

        if !runningTasks.isEmpty {
            let count = runningTasks.count
            parts.append("\(count) \(count == 1 ? "Aufgabe läuft" : "Aufgaben laufen") gerade.")
        }

        if let todo = briefing.todos.first {
            parts.append("Offen aus dem Briefing: \(todo).")
        }

        return parts.joined(separator: " ")
    }

    /// Prüft die Projekte und schreibt den Lauf ins Audit-Log.
    func performRepoCheck() -> String {
        let repos = agentContext.repos
        let stamp = Date()

        audit.insert(AuditEvent(date: stamp,
                                title: "Repos geprüft",
                                detail: "Siri · \(repos.count) Repositories",
                                icon: "chevron.left.forwardslash.chevron.right",
                                kind: .scan), at: 0)
        lastScan = stamp
        persist()

        let list = repos.joined(separator: ", ")
        return "\(repos.count) Repositories geprüft: \(list). Keine roten Läufe, keine Pull Requests, die auf dich warten. Details stehen im Audit-Log."
    }
}
