import Foundation

/// Ein fertiger Plan: Absicht, Titel und Schritte, die jeweils an ein
/// Werkzeug gebunden sind. Der Planner entscheidet nichts Riskantes —
/// er legt nur fest, was der Agent der Reihe nach aufruft.
struct AgentPlan {
    var title: String
    var intent: AgentIntent
    var steps: [TaskStep]
    var opening: String
}

/// Zerlegt ein Ziel in sichtbare Schritte und wählt die Werkzeuge dazu.
/// Die Absicht wird aus mehreren Signalen bestimmt, nicht aus einem
/// einzelnen Stichwort — „prüf, ob die GTA-News-Seite noch läuft“ ist
/// ein Repo-Audit, keine News-Recherche.
enum TaskPlanner {
    // MARK: Absicht

    static func intent(for goal: String) -> AgentIntent {
        let text = goal.lowercased()
        func score(_ words: [String], weight: Int = 1) -> Int {
            words.reduce(0) { $0 + (text.contains($1) ? weight : 0) }
        }

        let scores: [(AgentIntent, Int)] = [
            (.mailTriage, score(["mail", "postfach", "posteingang", "inbox", "e-mail", "email", "antwort", "newsletter"], weight: 2)
                + score(["ungelesen", "triag", "absender"])),
            (.repoAudit, score(["github", "repo", "repository", "ci", "pipeline", "build", "commit", "pull request", "branch", "actions"], weight: 2)
                + score(["rot", "grün", "deploy", "release check", "workflow"])),
            (.newsScan, score(["news", "nachricht", "meldung", "schlagzeile", "newswire", "überwach", "monitor", "gta 6", "gta6", "rockstar"], weight: 2)
                + score(["web", "portal", "feed", "presse"])),
            (.briefing, score(["briefing", "morgen", "tagesplan", "starte den tag", "überblick", "zusammenfassung des tages", "was steht an"], weight: 2)),
            (.calendar, score(["kalender", "termin", "meeting", "block", "fokusblock", "verschieb", "einladung"], weight: 2)),
            (.memory, score(["gedächtnis", "gedaechtnis", "erinner", "memory", "was weißt du", "notier", "merken"], weight: 2)),
            (.research, score(["recherche", "recherchier", "such", "finde", "vergleich", "prüf nach", "schlag nach"], weight: 2)
                + score(["wie funktioniert", "welche"])),
        ]

        let best = scores.max { $0.1 < $1.1 }
        if let best, best.1 >= 2 { return best.0 }
        return .generic
    }

    // MARK: Plan

    static func plan(for goal: String) -> AgentPlan {
        let intent = intent(for: goal)
        return AgentPlan(title: title(for: goal, intent: intent),
                         intent: intent,
                         steps: steps(for: goal, intent: intent),
                         opening: opening(for: intent, goal: goal))
    }

    static func title(for goal: String, intent: AgentIntent) -> String {
        let trimmed = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        switch intent {
        case .newsScan: return "News-Lage: \(focusWord(trimmed))"
        case .repoAudit: return "Repo-Audit"
        case .mailTriage: return "Postfach sortieren"
        case .briefing: return "Tagesbriefing bauen"
        case .research: return "Recherche: \(focusWord(trimmed))"
        case .calendar: return "Kalender ordnen"
        case .memory: return "Gedächtnis prüfen"
        case .generic:
            if trimmed.count <= 42 { return trimmed }
            return String(trimmed.prefix(39)) + "…"
        }
    }

    private static func focusWord(_ text: String) -> String {
        let stop: Set<String> = ["überwache", "überwach", "monitor", "prüfe", "prüf", "check", "die", "den", "das",
                                 "der", "meine", "meinen", "für", "und", "auf", "bitte", "mal", "alle", "new"]
        let words = text.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        let useful = words.filter { $0.count > 2 && !stop.contains($0.lowercased()) }
        let picked = useful.prefix(2).map(String.init).joined(separator: " ")
        return picked.isEmpty ? "Auftrag" : picked
    }

    static func steps(for goal: String, intent: AgentIntent) -> [TaskStep] {
        switch intent {
        case .newsScan:
            return [
                TaskStep(title: "Quellen scannen", detail: "Newswire, Portale, dein Hub — seit dem letzten Lauf", tool: "web.scan"),
                TaskStep(title: "Meldungen prüfen", detail: "Volltext lesen, Dubletten zusammenlegen", tool: "web.read"),
                TaskStep(title: "Relevanz gewichten", detail: "Datum, Quelle, Bezug zu GTA 6 und deinen Projekten", tool: "news.rank"),
                TaskStep(title: "Kurzbriefing formulieren", detail: "Drei Zeilen, kein Presse-Sprech", tool: "brief.compose"),
            ]
        case .repoAudit:
            return [
                TaskStep(title: "Repos prüfen", detail: "Branches, offene PRs, letzte Commits", tool: "repo.check"),
                TaskStep(title: "CI-Läufe prüfen", detail: "Rote Builds, Laufzeiten, Ursachen", tool: "ci.inspect"),
                TaskStep(title: "Kontext abgleichen", detail: "Gedächtnis und letzte Scans gegenlesen", tool: "memory.sync"),
                TaskStep(title: "Ergebnis synthetisieren", detail: "Was grün ist, was dich braucht", tool: "result.synthesis"),
            ]
        case .mailTriage:
            return [
                TaskStep(title: "Postfach scannen", detail: "Ungelesenes der letzten 48 Stunden", tool: "mail.triage"),
                TaskStep(title: "Wichtigkeit einordnen", detail: "Absender, Fristen, offene Fragen", tool: "mail.rank"),
                TaskStep(title: "Antwort entwerfen", detail: "Nur Entwurf — Versand erst nach Freigabe", tool: "mail.draft"),
                TaskStep(title: "Freigabe vorlegen", detail: "Alles landet auf deinem Tisch", tool: "approval.queue"),
            ]
        case .briefing:
            return [
                TaskStep(title: "Kalender lesen", detail: "Termine, Kollisionen, freie Blöcke", tool: "calendar.read"),
                TaskStep(title: "Postfach überfliegen", detail: "Was heute eine Antwort braucht", tool: "mail.triage"),
                TaskStep(title: "Wetter und Fenster", detail: "Temperatur, Regen, Zeit für draußen", tool: "weather.read"),
                TaskStep(title: "Briefing schreiben", detail: "Ein Fokus, drei Punkte, keine Liste", tool: "brief.compose"),
            ]
        case .research:
            return [
                TaskStep(title: "Ziel zerlegen", detail: "Welche Frage muss beantwortet werden", tool: "plan.build"),
                TaskStep(title: "Quellen suchen", detail: "Web, Repos, Gedächtnis", tool: "web.scan"),
                TaskStep(title: "Quellen lesen", detail: "Primärquellen vor Aggregatoren", tool: "web.read"),
                TaskStep(title: "Antwort schreiben", detail: "Kurz, mit Belegen, ohne Floskeln", tool: "doc.write"),
            ]
        case .calendar:
            return [
                TaskStep(title: "Kalender lesen", detail: "Was steht, was kollidiert", tool: "calendar.read"),
                TaskStep(title: "Blöcke rechnen", detail: "Zwei machbare Alternativen", tool: "calendar.plan"),
                TaskStep(title: "Änderung vorbereiten", detail: "Eintragen erst nach Freigabe", tool: "calendar.create"),
            ]
        case .memory:
            return [
                TaskStep(title: "Gedächtnis durchsuchen", detail: "Was ich über dich und das Thema weiß", tool: "memory.sync"),
                TaskStep(title: "Lücken benennen", detail: "Was fehlt, um wirklich zu helfen", tool: "result.synthesis"),
                TaskStep(title: "Neues vormerken", detail: "Nur Fakten aus dem Gespräch", tool: "memory.write"),
            ]
        case .generic:
            return [
                TaskStep(title: "Ziel zerlegen", detail: "Was ist das fertige Ergebnis?", tool: "plan.build"),
                TaskStep(title: "Kontext laden", detail: "Gedächtnis, Kalender, Postfach, Repos", tool: "memory.sync"),
                TaskStep(title: "Schritte ausführen", detail: "Ein Werkzeug nach dem anderen", tool: "web.scan"),
                TaskStep(title: "Ergebnis prüfen", detail: "Gegen das Ziel abgleichen", tool: "result.synthesis"),
            ]
        }
    }

    private static func opening(for intent: AgentIntent, goal: String) -> String {
        switch intent {
        case .newsScan:
            return "Absicht erkannt: News-Lage beobachten. Ich scanne die Quellen und filtere alles weg, was gestern schon da war."
        case .repoAudit:
            return "Absicht erkannt: Repo-Audit. Ich lese Branches und CI-Läufe und sage dir nur, was rot ist."
        case .mailTriage:
            return "Absicht erkannt: Postfach. Ich sortiere und entwerfe — gesendet wird nichts ohne dich."
        case .briefing:
            return "Absicht erkannt: Tagesbriefing. Kalender, Postfach und Wetter, verdichtet auf einen Fokus."
        case .research:
            return "Absicht erkannt: Recherche. Ich zerlege die Frage und lese die Quellen selbst, statt dir zehn Links zu geben."
        case .calendar:
            return "Absicht erkannt: Kalender. Ich suche Blöcke, die wirklich frei sind."
        case .memory:
            return "Absicht erkannt: Gedächtnis. Ich prüfe, was ich sicher über dich weiß — und was ich offen sage."
        case .generic:
            return "Absicht erkannt: Auftrag. Ich zerlege „\(String(goal.prefix(48)))“ und arbeite die Schritte ab."
        }
    }

    // MARK: Laufzeit

    static func duration(for step: TaskStep, index: Int) -> Int {
        switch step.tool {
        case "web.scan", "web.read", "repo.check": return 2600
        case "ci.inspect", "mail.triage": return 2400
        case "mail.draft", "brief.compose", "doc.write": return 2200
        case "memory.sync", "result.synthesis": return 1900
        default: return 1800
        }
    }

    static func summary(for intent: AgentIntent, insights: [String], approvals: Int) -> String {
        let base: String
        switch intent {
        case .newsScan:
            base = "Quellen gescannt, Meldungen gewichtet. Die Lage steht im Verlauf."
        case .repoAudit:
            base = "Alle Repos geprüft — kein roter Lauf, keine offenen PRs, die hängen."
        case .mailTriage:
            base = "Postfach sortiert. Antwortentwürfe liegen bereit, nichts wurde gesendet."
        case .briefing:
            base = "Briefing steht: ein Fokus, drei Punkte, Wetterfenster für draußen."
        case .research:
            base = "Recherche abgeschlossen. Ergebnis mit Quellen liegt im Verlauf."
        case .calendar:
            base = "Kalender geprüft, zwei Alternativen gerechnet."
        case .memory:
            base = "Gedächtnis geprüft. Bekanntes und Lücken sind getrennt."
        case .generic:
            base = "Durchgelaufen. Ergebnis liegt im Verlauf."
        }
        let tail: String
        if approvals > 0 {
            tail = approvals == 1
                ? " Ein Schritt wartet als Freigabe auf dich."
                : " \(approvals) Schritte warten als Freigabe auf dich."
        } else {
            tail = " Nichts Riskantes war dabei."
        }
        let extra = insights.first.map { " " + $0 } ?? ""
        return base + tail + extra
    }
}
