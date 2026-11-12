import Foundation

/// Der Offline-Agent: antwortet ohne API-Key, damit Tandem direkt nach
/// dem Sideloading etwas kann. Er liest den echten App-Zustand und baut
/// daraus einen Lauf mit Werkzeugen — plus Antwort, die den Kontext
/// kennt (Köln, Entwickler, GTA-6-Hub, Playtests).
enum DemoBrain {
    struct Plan {
        var tools: [(name: String, label: String, result: String)]
        var text: String
        var card: ChatCard?
        var task: (title: String, goal: String)?

        init(tools: [(name: String, label: String, result: String)] = [],
             text: String,
             card: ChatCard? = nil,
             task: (title: String, goal: String)? = nil) {
            self.tools = tools
            self.text = text
            self.card = card
            self.task = task
        }
    }

    static func plan(for input: String, context: AgentContext) -> Plan {
        let text = input.lowercased()
        func has(_ words: String...) -> Bool { words.contains { text.contains($0) } }

        if has("hallo", "hi ", "hey", "moin", "servus", "guten morgen") && text.count < 26 {
            return Plan(text: greeting(context))
        }
        if has("wer bist du", "was bist du", "was kannst du", "hilfe", "wie arbeitest du", "how do you work") {
            return Plan(tools: [("memory.sync", "Kontext laden", "Profil gefunden")],
                        text: capabilities(context))
        }
        if has("invite", "key", "einlad", "zugang", "clearance") {
            return Plan(tools: [("memory.sync", "Zugang prüfen", "Zugang aktiv")],
                        text: inviteAnswer(context))
        }
        if has("wetter", "regen", "temperatur", "jacke", "schirm") {
            return Plan(tools: [("weather.read", "Wetter lesen", context.temperature)],
                        text: weatherAnswer(context))
        }
        if has("gta", "rockstar", "leonida", "news", "newswire", "meldung") {
            return newsAnswer(input, context: context)
        }
        if has("mail", "e-mail", "email", "postfach", "posteingang", "inbox") {
            return mailAnswer(input, context: context)
        }
        if has("freigabe", "approval", "genehmig", "bestätig", "warten") {
            return approvalAnswer(context)
        }
        if has("aufgabe", "task", "delegier", "hintergrund", "agenten", "läuft") {
            return taskAnswer(input, context: context)
        }
        if has("github", "repo", "commit", "ci", "pull request", "pipeline", "build") {
            return githubAnswer(input, context: context)
        }
        if has("termin", "kalender", "heute", "tag", "plan", "briefing", "morgen", "woche") {
            return dayAnswer(input, context: context)
        }
        if has("gedächtnis", "gedaechtnis", "erinner", "memory", "weißt du", "weisst du") {
            return memoryAnswer(context)
        }
        if has("danke", "thanks", "top", "nice", "geil", "stark", "mega") {
            return Plan(text: "Immer. Wenn du willst, starte ich den nächsten Schritt direkt — ich halte dir alles zur Freigabe hin. ✨")
        }
        return fallback(input, context: context)
    }

    // MARK: - Delegation

    private static func createsTask(_ text: String) -> Bool {
        ["überwach", "überwache", "monitor", "kümmere", "kümmer", "delegier", "starte", "richte ein",
         "prüf mal", "prüf meine", "schick", "erstelle", "sammel", "fass zusammen", "übernimm"].contains {
            text.contains($0)
        }
    }

    private static func taskCard(_ title: String, _ subtitle: String) -> ChatCard {
        ChatCard(kind: .task, title: title, subtitle: subtitle, icon: "bolt.horizontal",
                 actionTitle: "Im Aufgaben-Tab ansehen", approvalID: nil, taskID: nil)
    }

    // MARK: - Antworten

    private static func greeting(_ c: AgentContext) -> String {
        """
        Hey \(c.userName) — Tandem ist wach. Ich bin kein Chatfenster, ich arbeite in Runden: **beobachten → planen → Werkzeug aufrufen → dir vorlegen**.

        Gerade im Blick:
        - **\(c.pendingApprovals.count) Freigaben** liegen auf deinem Tisch
        - **\(c.runningTasks.count) Aufgaben** laufen mit Protokoll
        - **\(c.unreadMails) ungelesene Mails**, eine davon sollte heute raus

        Sag mir ein Ziel — „überwache die GTA-6-News“ reicht — und ich starte einen Lauf.
        """
    }

    private static func capabilities(_ c: AgentContext) -> String {
        """
        So arbeite ich, in drei Lagen:

        | Lage | Was passiert |
        | --- | --- |
        | **Absicht** | Ich lese dein Ziel und bestimme, worum es wirklich geht — Mail, Repo, News, Kalender, Recherche. |
        | **Plan** | Ich zerlege es in Schritte und binde jeden an ein Werkzeug: `web.scan`, `repo.check`, `mail.triage`, `memory.sync`. |
        | **Ausführung** | Ich rufe die Werkzeuge der Reihe nach auf und schreibe alles ins Protokoll. Riskantes landet als Freigabe bei dir. |

        Aktuell: \(c.runningTasks.count) Aufgaben laufen, \(c.pendingApprovals.count) Freigaben warten. Ein Ziel genügt, ich übernehme den Rest.
        """
    }

    private static func inviteAnswer(_ c: AgentContext) -> String {
        """
        Tandem läuft als **Research Preview** — der Zugang hängt an einem Einladungscode, nicht an einem App-Store-Account. Dein Zugang ist aktiv.

        Für Freunde: **Mehr → Invite-Codes**. Ein Tipp erzeugt einen Code wie `TNDM-4K7Q-9WZ2`; jeder Code schaltet genau eine Installation frei. Die festen Codes (`JOEL-VIP`, `VICE-VIP`, `LEONIDA-DEV`, `OCEAN-DRIVE`) bleiben dauerhaft gültig.
        """
    }

    private static func weatherAnswer(_ c: AgentContext) -> String {
        """
        \(c.temperature) in \(c.city) — \(c.weather.lowercased()).

        \(c.weatherDetail)

        Für deinen Tag: \(c.agenda.first.map { "gegen \($0.time) geht es los mit *\($0.title)*." } ?? "kein fester Termin, der Rest ist frei.")
        """
    }

    private static func newsAnswer(_ input: String, context c: AgentContext) -> Plan {
        let task = createsTask(input.lowercased())
        let tools: [(name: String, label: String, result: String)] = [
            ("web.scan", "Newswire, Portale, Hub", "4 Quellen geprüft"),
            ("news.rank", "Relevanz gewichten", "2 relevant"),
            ("brief.compose", "Kurzbriefing", "3 Zeilen"),
        ]
        var answer = """
        GTA-6-Lage, Stand jetzt: **nichts Verschoben, nichts Neuertes beim Release-Fenster**. Zwei Portale melden dieselbe Meldung, eines hat sie von gestern abgeschrieben — das habe ich rausgefiltert.

        Was für dich zählt:
        - Release-Fenster unverändert, kein neues Statement von Rockstar
        - Dein gta6-hub ist grün, der letzte Build lief durch
        - Eine neue Meldung betrifft Trailer-Analysen, keine harten Fakten

        Ich habe die Meldungen nach Datum und Quelle gewichtet, nicht nach Lautstärke.
        """
        if task {
            answer += "\n\nIch habe das als **Dauerlauf** angelegt: *GTA-6-News überwachen*. Ab jetzt melde ich nur, was sich wirklich ändert — Protokoll siehst du im Aufgaben-Tab."
        }
        return Plan(tools: tools,
                    text: answer,
                    card: task ? taskCard("GTA-6-News überwachen", "Läuft mit web.scan → news.rank → brief.compose") : nil,
                    task: task ? ("GTA-6-News überwachen", "Überwache die GTA-6-News und melde nur, was sich wirklich ändert") : nil)
    }

    private static func mailAnswer(_ input: String, context c: AgentContext) -> Plan {
        let urgent = c.pendingApprovals.first { $0.kind == .email }
        let task = createsTask(input.lowercased())
        let lead = urgent.map { "Ich habe **\(c.unreadMails) ungelesene Mails** durchgesehen. Eine ist wichtig: *\($0.subject ?? $0.title)*." }
            ?? "Ich habe **\(c.unreadMails) ungelesene Mails** durchgesehen — nichts, was heute brennt."

        var answer = """
        \(lead)

        | Absender | Thema | Einschätzung |
        | --- | --- | --- |
        | \(urgent?.recipient ?? "newsletter@…") | \(urgent?.subject ?? "Wochenrückblick") | dringend, Antwort heute |
        | team@playtest-vault.dev | Review angefragt | heute erledigen |
        | notifications@github.com | 3 CI-Läufe | automatisch abgehakt |

        \(urgent == nil ? "Soll ich die Mails als Aufgabe zusammenfassen?" : "Den Antwortentwurf habe ich fertig — er liegt als Freigabe bei dir, gesendet wird nichts ohne dein Ja.")
        """
        if task {
            answer += "\n\nDer **Mail-Triage-Lauf** ist gestartet: scannen → einordnen → Entwurf → Freigabe."
        }
        return Plan(tools: [("mail.triage", "Postfach scannen", "\(c.unreadMails) ungelesen"),
                            ("mail.rank", "Wichtigkeit sortieren", "1 dringend"),
                            ("mail.draft", "Antwort entwerfen", "Entwurf steht")],
                    text: answer,
                    card: urgent.map { urgentCard($0) } ?? (task ? taskCard("Postfach sortieren", "Triage mit Entwürfen, Versand nur nach Freigabe") : nil),
                    task: task ? ("Postfach sortieren", "Sortiere mein Postfach und entwerfe Antworten für alles Dringende") : nil)
    }

    private static func urgentCard(_ approval: ApprovalRequest) -> ChatCard {
        ChatCard(kind: .approval,
                 title: "Antwort an \(approval.recipient ?? "den Absender")",
                 subtitle: approval.subject ?? approval.title,
                 icon: "envelope",
                 actionTitle: "Freigabe ansehen",
                 approvalID: approval.id,
                 taskID: nil)
    }

    private static func approvalAnswer(_ c: AgentContext) -> Plan {
        guard !c.pendingApprovals.isEmpty else {
            return Plan(tools: [("approval.queue", "Tisch prüfen", "nichts offen")],
                        text: "Aktuell liegt **nichts** auf deinem Tisch. Alle vorbereiteten Aktionen sind entschieden — ich melde mich, sobald etwas Neues dazukommt.")
        }
        let rows = c.pendingApprovals.map { approval in
            "| \(approval.kind.title) | \(approval.title) | \(approval.risk.title) |"
        }.joined(separator: "\n")
        return Plan(tools: [("approval.queue", "Freigaben laden", "\(c.pendingApprovals.count) offen")],
                    text: """
                    **\(c.pendingApprovals.count) Aktionen** sind vorbereitet und warten auf dein Ja. Nichts davon ist rausgegangen.

                    | Art | Aktion | Risiko |
                    | --- | --- | --- |
                    \(rows)

                    Der wichtigste Punkt: *\(c.pendingApprovals[0].title)*. Sag „freigeben“, dann geht es raus — oder „ablehnen“, dann bleibt es liegen.
                    """,
                    card: ChatCard(kind: .approval,
                                   title: c.pendingApprovals[0].title,
                                   subtitle: c.pendingApprovals[0].summary,
                                   icon: c.pendingApprovals[0].kind.icon,
                                   actionTitle: "Freigaben öffnen",
                                   approvalID: c.pendingApprovals[0].id,
                                   taskID: nil))
    }

    private static func taskAnswer(_ input: String, context c: AgentContext) -> Plan {
        if createsTask(input.lowercased()) && !c.runningTasks.contains(where: { $0.goal.localizedCaseInsensitiveContains(input) }) {
            // Ein neues Ziel — der Planner übernimmt, der Chat legt es an.
            let plan = TaskPlanner.plan(for: input)
            return Plan(tools: [("plan.build", "Ziel zerlegen", "\(plan.steps.count) Schritte")],
                        text: """
                        Ziel gelesen, Absicht **\(plan.intent.title)**. Ich würde so vorgehen:

                        \(plan.steps.enumerated().map { "- **\($0.offset + 1). \($0.element.title)** · `\($0.element.tool ?? "agent.step")`" }.joined(separator: "\n"))

                        Ich starte den Lauf — Fortschritt und jedes Werkzeug stehen im Aufgaben-Tab.
                        """,
                        card: taskCard(plan.title, "\(plan.steps.count) Schritte, Protokoll live"),
                        task: (plan.title, input))
        }

        guard !c.runningTasks.isEmpty else {
            return Plan(text: "Im Moment läuft keine Aufgabe. Sag mir ein Ziel — *„prüf meine Repos auf rote CI“* — und ich zerlege es in Schritte mit Werkzeugen.")
        }
        let rows = c.runningTasks.map { task in
            "| \(task.title) | \(task.currentStep?.title ?? task.status.title) | \(Int(task.progress * 100)) % |"
        }.joined(separator: "\n")
        return Plan(tools: [("plan.build", "Läufe lesen", "\(c.runningTasks.count) aktiv")],
                    text: """
                    **\(c.runningTasks.count) Aufgaben** sind unterwegs:

                    | Aufgabe | Aktueller Schritt | Fortschritt |
                    | --- | --- | --- |
                    \(rows)

                    Jeder Schritt hängt an einem Werkzeug, jedes Ergebnis steht im Protokoll. Sobald etwas deine Freigabe braucht, halte ich an — Autonomie endet bei riskanten Aktionen.
                    """
        )
    }

    private static func githubAnswer(_ input: String, context c: AgentContext) -> Plan {
        let task = createsTask(input.lowercased())
        let rows = c.repos.map { "| \($0) | grün | 0 offen |" }.joined(separator: "\n")
        var answer = """
        Ich habe deine Repos gescannt — nichts Rotes:

        | Repo | CI | Offene Issues |
        | --- | --- | --- |
        \(rows)

        Bei **gta6-hub** ist der letzte Release-Build durchgelaufen, `tandem-agent` baut in 1 min 12 s. Wenn du willst, schreibe ich aus den Commits schon die Changelog-Zeilen und lege sie dir als Freigabe hin.
        """
        if task {
            answer += "\n\nDer **CI-Audit** läuft jetzt als Aufgabe über alle vier Repos."
        }
        return Plan(tools: [("repo.check", "Repos scannen", "\(c.repos.count) Repos"),
                            ("ci.inspect", "CI prüfen", "12 Läufe, 0 rot"),
                            ("result.synthesis", "Ergebnis prüfen", "alles grün")],
                    text: answer,
                    card: task ? taskCard("CI-Audit über alle Repos", "repo.check → ci.inspect → Synthese") : nil,
                    task: task ? ("CI-Audit über alle Repos", "Prüfe meine GitHub CI Pipelines und sage mir, was rot ist") : nil)
    }

    private static func dayAnswer(_ input: String, context c: AgentContext) -> Plan {
        let lines = c.agenda.map { "- **\($0.time)** — \($0.title)\($0.detail.isEmpty ? "" : " · \($0.detail)")" }.joined(separator: "\n")
        let todos = c.todos.prefix(3).map { "- \($0)" }.joined(separator: "\n")
        let task = createsTask(input.lowercased()) && input.lowercased().contains("briefing")
        var answer = """
        **\(c.today)**

        \(c.temperature) · \(c.weather)

        \(lines.isEmpty ? "- Keine festen Termine — ein ruhiger Tag." : lines)

        Offen aus dem Briefing:
        \(todos)

        \(c.nightNote)
        """
        if task {
            answer += "\n\nIch baue das gerade als **Morgen-Briefing** neu — Kalender, Postfach und Wetter in einem Durchlauf."
        }
        return Plan(tools: [("calendar.read", "Kalender lesen", "\(c.agenda.count) Termine"),
                            ("weather.read", "Wetter laden", c.temperature),
                            ("brief.compose", "Briefing schreiben", "4 Punkte")],
                    text: answer,
                    task: task ? ("Morgen-Briefing zusammenstellen", "Stelle mein Morgen-Briefing aus Kalender, Postfach und Wetter zusammen") : nil)
    }

    private static func memoryAnswer(_ c: AgentContext) -> Plan {
        let facts = c.memoryHighlights.map { "- \($0)" }.joined(separator: "\n")
        return Plan(tools: [("memory.sync", "Gedächtnis durchsuchen", "\(c.memoryHighlights.count) Treffer")],
                    text: """
                    Das habe ich über dich gespeichert — jeder Punkt ist im Gedächtnis-Tab änderbar und löschbar:

                    \(facts)

                    Neue Fakten übernehme ich nur, wenn sie im Gespräch vorkommen oder du sie bestätigst. Nichts davon geht an Dritte.
                    """)
    }

    private static func fallback(_ input: String, context c: AgentContext) -> Plan {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let plan = TaskPlanner.plan(for: trimmed.isEmpty ? "Auftrag" : trimmed)
        return Plan(tools: [("plan.build", "Ziel analysieren", "Absicht: \(plan.intent.title)"),
                            ("memory.sync", "Kontext laden", "Profil, Projekte, Kalender")],
                    text: """
                    Verstanden — ich habe **„\(String(trimmed.prefix(90)))“** gelesen und als Absicht **\(plan.intent.title)** eingeordnet.

                    Mein Vorschlag: Ich lege das als Aufgabe an, arbeite die Schritte mit echten Werkzeugen ab und lege dir am Ende genau eine Entscheidung hin. Wenn dabei etwas rausgeht — Mail, Zahlung, Kalender — stoppe ich vorher.

                    \(plan.steps.enumerated().map { "- **\($0.offset + 1). \($0.element.title)** · `\($0.element.tool ?? "agent.step")`" }.joined(separator: "\n"))

                    Sag „starte das“, dann läuft es im Aufgaben-Tab.
                    """,
                    card: nil,
                    task: nil)
    }
}
