import Foundation

/// Der Offline-Simulator: antwortet ohne API-Key, damit Tandem direkt
/// nach dem Sideloading etwas kann. Er liest den echten App-Zustand
/// (Freigaben, Aufgaben, Briefing, Gedächtnis) und formuliert daraus
/// eine Antwort — plus Tool-Pills, damit die Chat-Oberfläche zeigt,
/// wie ein echter Lauf aussieht.
struct DemoContext {
    var userName: String
    var city: String
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
}

enum DemoBrain {
    struct Plan {
        var tools: [(name: String, label: String, result: String)]
        var text: String
        var card: ChatCard?
    }

    static func plan(for input: String, context: DemoContext) -> Plan {
        let text = input.lowercased()
        func has(_ words: String...) -> Bool { words.contains { text.contains($0) } }

        if has("hallo", "hi ", "hey", "moin", "servus") && text.count < 24 {
            return Plan(tools: [], text: greeting(context))
        }
        if has("wer bist du", "was bist du", "was kannst du", "hilfe", "how do you work") {
            return Plan(tools: [], text: capabilities(context))
        }
        if has("invite", "key", "einlad", "code", "zugang") {
            return Plan(tools: [("vault.read", "Vault prüfen", "Preview-Zugang aktiv")], text: inviteAnswer(context))
        }
        if has("wetter", "regen", "temperatur", "jacke", "schirm") {
            return Plan(tools: [("weather.lookup", "Wetter laden", context.temperature)],
                        text: weatherAnswer(context))
        }
        if has("mail", "e-mail", "email", "postfach", "posteingang", "inbox") {
            return Plan(tools: [("mail.search", "Postfach scannen", "\(context.unreadMails) ungelesen"),
                                ("mail.classify", "Wichtigkeit sortieren", "1 dringend")],
                        text: mailAnswer(context), card: mailCard(context))
        }
        if has("freigabe", "approval", "genehmig", "bestätig") {
            return Plan(tools: [("approvals.list", "Freigaben laden", "\(context.pendingApprovals.count) offen")],
                        text: approvalAnswer(context), card: approvalCard(context))
        }
        if has("aufgabe", "task", "delegier", "erledig", "hintergrund") {
            return Plan(tools: [("tasks.list", "Aufgaben lesen", "\(context.runningTasks.count) aktiv")],
                        text: taskAnswer(context))
        }
        if has("github", "repo", "commit", "ci", "pull request", "pipeline") {
            return Plan(tools: [("github.repos", "Repos scannen", "\(context.repos.count) Repos"),
                                ("github.runs", "CI prüfen", "alle grün")],
                        text: githubAnswer(context))
        }
        if has("termin", "kalender", "heute", "tag", "plan", "briefing", "morgen") {
            return Plan(tools: [("calendar.events", "Kalender lesen", "\(context.agenda.count) Termine"),
                                ("weather.lookup", "Wetter laden", context.temperature)],
                        text: dayAnswer(context))
        }
        if has("gedächtnis", "gedaechtnis", "erinner", "memory", "weißt du", "weisst du") {
            return Plan(tools: [("memory.search", "Gedächtnis durchsuchen", "\(context.memoryHighlights.count) Treffer")],
                        text: memoryAnswer(context))
        }
        if has("danke", "thanks", "top", "nice", "geil") {
            return Plan(tools: [], text: "Immer. Sag Bescheid, wenn ich den nächsten Schritt direkt vorbereiten soll — ich halte dir alles zur Freigabe hin. ✨")
        }
        return Plan(tools: [("memory.search", "Kontext laden", "Profil gefunden")],
                    text: fallbackAnswer(context, input: input))
    }

    // MARK: Antworten

    private static func greeting(_ c: DemoContext) -> String {
        """
        Hey \(c.userName) — ich bin **Tandem**, dein proaktiver Agent. Ich schaue im Hintergrund nach deinem Tag, deinen Mails und deinen Aufgaben und lege dir alles als fertige Entscheidung hin.

        Gerade im Blick:
        - **\(c.pendingApprovals.count) Freigaben** warten auf dich
        - **\(c.runningTasks.count) Aufgaben** laufen im Hintergrund
        - **\(c.unreadMails) ungelesene Mails**, davon eine, die heute raus sollte

        Frag mich nach dem Tag, deinen Mails oder „delegier das“ — ich bereite vor, du entscheidest.
        """
    }

    private static func capabilities(_ c: DemoContext) -> String {
        """
        Ich bin ein **Agent**, kein Chatfenster: Ich arbeite in Runden aus Beobachten → Vorbereiten → Freigeben.

        | Fähigkeit | Was das heißt |
        | --- | --- |
        | Briefing | Wetter, Termine, Todos und Nachtaktivität in einer Karte |
        | Hintergrund-Scans | Postfach, Kalender, GitHub, Gerät — alle 15 Minuten |
        | Freigaben | E-Mails, Zahlungen, Kalendereinträge: erst nach deinem Ja |
        | Aufgaben | Mehrstufige Läufe mit Protokoll und Fortschritt |
        | Gedächtnis | Was ich über dich weiß, jederzeit lesbar und löschbar |

        \(c.pendingApprovals.isEmpty ? "Aktuell liegt nichts auf dem Tisch." : "Auf dem Tisch liegen gerade \(c.pendingApprovals.count) Freigaben — die würde ich zuerst anschauen.")
        """
    }

    private static func inviteAnswer(_ c: DemoContext) -> String {
        """
        Tandem läuft als **Research Preview** — der Zugang hängt an einem Invite-Key, nicht an einem App-Store-Account. Dein Key ist eingelöst, deshalb bist du drin.

        Wenn du jemanden einladen willst: **Einstellungen → Invite Keys teilen**. Dort erzeugst du mit einem Tipp einen Code wie `TNDM-4K7Q-9WZ2`. Jeder Code schaltet genau eine Installation frei, du siehst im selben Screen, welche schon eingelöst sind.

        Deine Founder-Keys bleiben dauerhaft gültig.
        """
    }

    private static func weatherAnswer(_ c: DemoContext) -> String {
        """
        \(c.temperature) in \(c.city) — \(c.weather.lowercased()).

        \(c.weatherDetail)

        Für deinen Tag: \(c.agenda.first.map { "gegen \($0.time) geht es los mit *\($0.title)*." } ?? "kein fester Termin, der Rest ist frei.")
        """
    }

    private static func mailAnswer(_ c: DemoContext) -> String {
        let urgent = c.pendingApprovals.first { $0.kind == .email }
        let lead = urgent.map { "Ich habe **\(c.unreadMails) ungelesene Mails** durchgesehen. Eine ist wichtig: *\($0.subject ?? $0.title)*." }
            ?? "Ich habe **\(c.unreadMails) ungelesene Mails** durchgesehen — nichts, was heute brennt."
        return """
        \(lead)

        | Absender | Thema | Einschätzung |
        | --- | --- | --- |
        | \(urgent?.recipient ?? "newsletter@…") | \(urgent?.subject ?? "Wochenrückblick") | dringend, Antwort heute |
        | team@playtest-vault.dev | Review angefragt | heute erledigen |
        | notifications@github.com | 3 CI-Läufe | automatisch abgehakt |

        \(urgent == nil ? "Soll ich die Mails in einer Aufgabe zusammenfassen?" : "Den Antwortentwurf habe ich fertig — er liegt als Freigabe bei dir, du musst nur noch ja sagen.")
        """
    }

    private static func mailCard(_ c: DemoContext) -> ChatCard? {
        guard let approval = c.pendingApprovals.first(where: { $0.kind == .email }) else { return nil }
        return ChatCard(kind: .approval,
                        title: "Antwort an \(approval.recipient ?? "den Absender")",
                        subtitle: approval.subject ?? approval.title,
                        icon: "envelope.fill",
                        actionTitle: "Freigabe ansehen",
                        approvalID: approval.id)
    }

    private static func approvalAnswer(_ c: DemoContext) -> String {
        guard !c.pendingApprovals.isEmpty else {
            return "Aktuell liegt **nichts** auf deinem Tisch. Alle vorbereiteten Aktionen sind erledigt oder abgelehnt — ich melde mich, sobald etwas Neues dazukommt."
        }
        let rows = c.pendingApprovals.map { approval in
            "| \(approval.kind.title) | \(approval.title) | \(approval.risk.title) |"
        }.joined(separator: "\n")
        return """
        **\(c.pendingApprovals.count) Aktionen** sind vorbereitet und warten auf dein Ja. Nichts davon ist rausgegangen.

        | Art | Aktion | Risiko |
        | --- | --- | --- |
        \(rows)

        Der wichtigste Punkt: *\(c.pendingApprovals[0].title)*. Sag „freigeben“, dann schicke ich es raus — oder „ablehnen“, dann bleibt es liegen.
        """
    }

    private static func approvalCard(_ c: DemoContext) -> ChatCard? {
        guard let first = c.pendingApprovals.first else { return nil }
        return ChatCard(kind: .approval,
                        title: first.title,
                        subtitle: first.summary,
                        icon: first.kind.icon,
                        actionTitle: "Freigaben öffnen",
                        approvalID: first.id)
    }

    private static func taskAnswer(_ c: DemoContext) -> String {
        guard !c.runningTasks.isEmpty else {
            return "Im Moment läuft keine Hintergrundaufgabe. Sag mir ein Ziel — *„prüf meine Repos auf rote CI“* — und ich zerlege es in Schritte, die du im Aufgaben-Tab live siehst."
        }
        let rows = c.runningTasks.map { task in
            "| \(task.title) | \(task.status.title) | \(Int(task.progress * 100)) % |"
        }.joined(separator: "\n")
        return """
        **\(c.runningTasks.count) Aufgaben** sind unterwegs:

        | Aufgabe | Status | Fortschritt |
        | --- | --- | --- |
        \(rows)

        Der laufende Schritt steht im Aufgaben-Tab unter der jeweiligen Karte. Sobald etwas deine Freigabe braucht, halte ich an und frage — Autonomie endet bei riskanten Aktionen.
        """
    }

    private static func githubAnswer(_ c: DemoContext) -> String {
        let rows = c.repos.map { "| \($0) | grün | 0 offen |" }.joined(separator: "\n")
        return """
        Ich habe deine Repos gescannt — nichts Rotes:

        | Repo | CI | Offene Issues |
        | --- | --- | --- |
        \(rows)

        Bei **gta6-hub** ist der letzte Release-Build durchgelaufen. Wenn du willst, schreibe ich für das nächste Release schon die Changelog-Zeilen aus den Commits und lege sie dir als Freigabe hin.
        """
    }

    private static func dayAnswer(_ c: DemoContext) -> String {
        let lines = c.agenda.map { "- **\($0.time)** — \($0.title)\($0.detail.isEmpty ? "" : " · \($0.detail)")" }.joined(separator: "\n")
        let todos = c.todos.prefix(3).map { "- \($0)" }.joined(separator: "\n")
        return """
        **\(c.today)**

        \(c.temperature) · \(c.weather)

        \(lines.isEmpty ? "- Keine festen Termine — ein ruhiger Tag." : lines)

        Offen aus dem Briefing:
        \(todos)

        \(c.nightNote)
        """
    }

    private static func memoryAnswer(_ c: DemoContext) -> String {
        let facts = c.memoryHighlights.map { "- \($0)" }.joined(separator: "\n")
        return """
        Das habe ich über dich gespeichert — und du kannst jeden Punkt im Gedächtnis-Tab ändern oder löschen:

        \(facts)

        Neue Fakten übernehme ich nur, wenn sie im Gespräch auftauchen oder du sie bestätigst. Nichts davon geht an Dritte.
        """
    }

    private static func fallbackAnswer(_ c: DemoContext, input: String) -> String {
        let firstWord = input.split(separator: " ").first.map(String.init) ?? "das"
        return """
        Verstanden — ich habe **„\(input.trimmingCharacters(in: .whitespacesAndNewlines))“** im Kontext deines Tages gelesen.

        Mein Vorschlag: Ich zerlege das in eine Aufgabe mit klaren Schritten, sammle die nötigen Infos aus Postfach, Kalender und Gedächtnis und lege dir am Ende genau eine Entscheidung hin. Wenn dabei etwas rausgeht — Mail, Zahlung, Kalender — stoppe ich vorher.

        Soll ich das als Aufgabe starten? Dann steht „\(firstWord) …“ gleich im Aufgaben-Tab.
        """
    }
}
