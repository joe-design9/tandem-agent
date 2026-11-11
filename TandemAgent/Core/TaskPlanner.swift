import Foundation

/// Zerlegt ein Ziel in sichtbare Schritte. Der Simulator nutzt dieselbe
/// Logik, damit Aufgaben im Aufgaben-Tab ehrlich aussehen: jeder Schritt
/// ist etwas, das ein Agent wirklich tun würde.
enum TaskPlanner {
    static func title(for goal: String) -> String {
        let text = goal.lowercased()
        if text.contains("mail") || text.contains("postfach") { return "Postfach aufräumen" }
        if text.contains("changelog") || text.contains("release") { return "Release vorbereiten" }
        if text.contains("repo") || text.contains("github") || text.contains("ci") { return "Repos prüfen" }
        if text.contains("woche") || text.contains("rückblick") { return "Wochenrückblick" }
        if text.contains("termin") || text.contains("kalender") { return "Kalender ordnen" }
        if text.contains("recherche") || text.contains("such") { return "Recherche" }

        let trimmed = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 42 { return trimmed }
        return String(trimmed.prefix(39)) + "…"
    }

    static func steps(for goal: String) -> [TaskStep] {
        let text = goal.lowercased()

        if text.contains("mail") || text.contains("postfach") || text.contains("e-mail") {
            return [
                TaskStep(title: "Postfach scannen", detail: "Ungelesene Mails der letzten 48 Stunden"),
                TaskStep(title: "Wichtigkeit einordnen", detail: "Absender, Fristen, offene Fragen"),
                TaskStep(title: "Antworten entwerfen", detail: "Nur Entwürfe — Versand erst nach Freigabe"),
                TaskStep(title: "Freigabe vorbereiten", detail: "Alles landet bei dir auf dem Tisch"),
            ]
        }
        if text.contains("changelog") || text.contains("release") || text.contains("version") {
            return [
                TaskStep(title: "Commits seit dem letzten Tag sammeln", detail: "git log, Pull Requests, Issues"),
                TaskStep(title: "Änderungen clustern", detail: "Features, Fixes, Interna"),
                TaskStep(title: "Changelog formulieren", detail: "Kurz, konkret, auf Deutsch"),
                TaskStep(title: "Release-Entwurf anlegen", detail: "Veröffentlichen erst nach deinem Ja"),
            ]
        }
        if text.contains("repo") || text.contains("github") || text.contains("ci") {
            return [
                TaskStep(title: "Repos scannen", detail: "Branches, offene PRs, letzte Läufe"),
                TaskStep(title: "CI-Läufe prüfen", detail: "Rote Builds und Ursachen"),
                TaskStep(title: "Zusammenfassung schreiben", detail: "Was ist grün, was braucht dich"),
            ]
        }
        if text.contains("woche") || text.contains("rückblick") || text.contains("zusammenfass") {
            return [
                TaskStep(title: "Aktivität sammeln", detail: "Commits, Termine, erledigte Aufgaben"),
                TaskStep(title: "Highlights auswählen", detail: "Was diese Woche wirklich zählt"),
                TaskStep(title: "Entwurf schreiben", detail: "Drei Absätze, kein Marketing"),
            ]
        }
        if text.contains("termin") || text.contains("kalender") {
            return [
                TaskStep(title: "Kalender lesen", detail: "Kollisionen und freie Blöcke"),
                TaskStep(title: "Vorschlag rechnen", detail: "Zwei Alternativen, beide machbar"),
                TaskStep(title: "Änderung vorbereiten", detail: "Eintragen erst nach Freigabe"),
            ]
        }

        return [
            TaskStep(title: "Ziel zerlegen", detail: "Was ist das fertige Ergebnis?"),
            TaskStep(title: "Kontext laden", detail: "Gedächtnis, Kalender, Postfach"),
            TaskStep(title: "Schritte ausführen", detail: "Ein Schritt nach dem anderen"),
            TaskStep(title: "Ergebnis prüfen", detail: "Gegen das Ziel abgleichen"),
        ]
    }

    static func duration(for index: Int) -> Int {
        // Feste, leicht variierende Schrittzeiten — lang genug, dass man
        // den Fortschritt sieht, kurz genug für einen Screenshot.
        let base = [2200, 2600, 2400, 2000]
        return base[index % base.count] + (index % 2 == 0 ? 200 : 0)
    }

    static func summary(for goal: String) -> String {
        let text = goal.lowercased()
        if text.contains("mail") || text.contains("postfach") {
            return "Postfach sortiert. Antwortentwürfe liegen als Freigabe bereit — nichts wurde gesendet."
        }
        if text.contains("changelog") || text.contains("release") {
            return "Changelog steht. Der Release-Entwurf wartet auf deine Freigabe."
        }
        if text.contains("repo") || text.contains("github") || text.contains("ci") {
            return "Alle Repos geprüft. Keine roten Läufe, zwei kleine Updates vorgemerkt."
        }
        return "Durchgelaufen. Ergebnis liegt im Verlauf, riskante Schritte warten auf Freigabe."
    }
}
