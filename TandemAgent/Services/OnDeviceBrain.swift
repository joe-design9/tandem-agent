import Foundation

/// **Siri AI (On-Device)** — die Engine, die ab Werk läuft.
///
/// Kein Key, kein Netz, kein Konto: Sie liest den echten App-Zustand
/// (Briefing, Freigaben, Aufgaben, Gedächtnis) und antwortet daraus. Über
/// `AppIntents` hängt dieselbe Engine an Siri und Shortcuts.
///
/// Zwei Regeln gelten hier:
/// 1. Ein Satz Smalltalk ist ein Satz Smalltalk. „Hi“ plant keinen Lauf.
/// 2. Eine Aufgabe entsteht nur, wenn die Nachricht wirklich etwas verlangt
///    („prüf meine Repos“, „überwache die News“). Alles andere bekommt eine
///    Antwort — keinen Plan.
enum OnDeviceBrain {

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

    // MARK: - Eingang

    static func plan(for rawInput: String, context c: AgentContext) -> Plan {
        let u = Utterance(rawInput)
        guard !u.text.isEmpty else {
            return Plan(text: "Ich bin da. Sag mir ein Ziel, oder frag mich nach dem Tag.")
        }

        // 1. Begrüßung — ein „Moin“ ist ein „Moin“.
        if isGreeting(u) {
            return Plan(text: greeting(c))
        }

        // 2. Kleinkram und Fragen über mich — nur, wenn nichts verlangt wird.
        if !isActionRequest(u) {
            if let small = smallTalk(u, context: c) { return small }
            if isIdentityQuestion(u) { return identity(c) }
            if u.mentions("wie spät", "uhrzeit", "wie viel uhr", "welcher tag ist", "welches datum") { return clock() }
        }

        // 3. Fachfragen — mit echten Zahlen aus dem App-Zustand.
        if u.mentions("mail", "e-mail", "email", "postfach", "posteingang", "inbox", "newsletter") {
            return mailAnswer(u, context: c)
        }
        if u.mentions("wetter", "regen", "temperatur", "°", "schirm", "jacke", "schnee", "sonnig", "wolken", "friert", "kalt", "warm") {
            return Plan(tools: [("weather.read", "Wetter lesen", c.temperature)],
                        text: weatherAnswer(c))
        }
        if u.mentions("gta", "rockstar", "leonida", "newswire", "trailer", "release", "meldung", "news") {
            return newsAnswer(u, context: c)
        }
        if u.mentions("freigabe", "freigeben", "approval", "genehmig", "bestätig", "entscheidung", "auf meinem tisch") {
            return approvalAnswer(c)
        }
        if u.mentions("github", "repo", "repos", "commit", "commits", "ci", "pipeline", "build", "pull request", "branch") {
            return githubAnswer(u, context: c)
        }
        if u.mentions("heute", "briefing", "termin", "kalender", "agenda", "woche", "steht an", "tagesplan", "morgen") {
            return dayAnswer(u, context: c)
        }
        if u.mentions("aufgabe", "aufgaben", "task", "tasks", "läuft", "lauf", "läufe", "hintergrund", "fortschritt", "status") {
            return taskAnswer(u, context: c)
        }
        if u.mentions("gedächtnis", "gedaechtnis", "memory", "weißt du", "weisst du", "gemerkt", "über mich", "was weißt du") {
            return memoryAnswer(c)
        }
        if u.mentions("invite", "einlad", "zugang", "clearance", "zugangscode", "invite-code") {
            return inviteAnswer(c)
        }

        // 4. Ein echter Auftrag, den keine Fachantwort abdeckt.
        if isActionRequest(u) {
            return delegate(u)
        }

        // 5. Alles andere: antworten, nicht planen.
        return fallback(u, context: c)
    }

    // MARK: - Erkennung

    private struct Utterance {
        let raw: String
        let text: String
        let words: [String]

        init(_ raw: String) {
            self.raw = raw
            let lowered = raw.lowercased().replacingOccurrences(of: "\u{2019}", with: "'")
            self.text = lowered.trimmingCharacters(in: .whitespacesAndNewlines)
            self.words = self.text
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
        }

        var wordSet: Set<String> { Set(words) }
        var isQuestion: Bool { text.contains("?") }

        func mentions(_ phrases: String...) -> Bool {
            phrases.contains { text.contains($0) }
        }

        func mentionsWord(_ candidates: String...) -> Bool {
            let set = wordSet
            return candidates.contains { set.contains($0) }
        }

        func startsWithAny(_ prefixes: [String]) -> Bool {
            guard let first = words.first else { return false }
            return prefixes.contains { first == $0 || first.hasPrefix($0) }
        }
    }

    private static let greetingWords: Set<String> = [
        "hi", "hallo", "hallöchen", "hey", "moin", "servus", "yo", "tach", "hej", "hiya", "grüß", "guten", "mahlzeit", "na",
    ]

    private static let greetingTail: Set<String> = ["morgen", "tag", "abend", "nacht", "moin", "mahlzeit", "grüß"]

    private static let greetingFiller: Set<String> = [
        "du", "dir", "dich", "joel", "tandem", "da", "bist", "was", "machst", "geht", "gehts", "läuft", "alles", "gut",
        "und", "so", "schön", "dass", "es", "gibt", "wie", "bei", "mein", "freund", "auch", "mal", "wieder", "denn", "s",
    ]

    private static func isGreeting(_ u: Utterance) -> Bool {
        guard let first = u.words.first, greetingWords.contains(first) else { return false }
        let rest = u.words.dropFirst()
        return rest.allSatisfy { greetingWords.contains($0) || greetingTail.contains($0) || greetingFiller.contains($0) }
    }

    private static let actionVerbs: [String] = [
        "start", "überwach", "monitor", "prüf", "check", "kontrollier", "erstell", "anleg", "richte", "einricht",
        "sammel", "fass", "schick", "sende", "delegier", "kümmer", "übernimm", "plane", "lösch", "schreib", "entwirf",
        "aktualisier", "update", "bereite", "organisier", "erinner", "recherchier", "analysier", "vergleich",
        "reservier", "bestell", "setz", "stell", "mach", "erledige", "installier", "kauf",
    ]

    private static let questionStarters: [String] = [
        "wie", "was", "warum", "wieso", "weshalb", "welche", "welcher", "welches", "wann", "wo", "wer", "gibt", "ist", "sind",
    ]

    /// Verlangt die Nachricht eine Handlung — oder redet sie nur?
    private static func isActionRequest(_ u: Utterance) -> Bool {
        guard !u.words.isEmpty else { return false }
        if u.startsWithAny(questionStarters) { return false }
        return u.words.contains { word in
            actionVerbs.contains { word.hasPrefix($0) }
        }
    }

    private static func isIdentityQuestion(_ u: Utterance) -> Bool {
        u.mentions("wer bist du", "was bist du", "was kannst du", "hilfe", "wie arbeitest du", "wie funktionierst du",
                   "was ist tandem", "was macht tandem", "bist du siri", "nutzt du siri", "siri ai", "apple intelligence",
                   "welches modell", "api key", "api-key", "brauche ich einen key", "ohne key", "bist du echt",
                   "bist du eine ki", "bist du ein bot")
    }

    // MARK: - Kleinkram

    private static let acknowledgements: Set<String> = ["ja", "nein", "nee", "doch", "klar", "gern", "gerne", "bitte"]
    private static let fillerSounds: Set<String> = ["hm", "hmm", "mhm", "äh", "öh", "huh"]

    private static func smallTalk(_ u: Utterance, context c: AgentContext) -> Plan? {
        if u.words.count <= 2, !u.words.isEmpty, u.words.allSatisfy({ fillerSounds.contains($0) }) {
            return Plan(text: "Ich bin da. Sag in einem Satz, was du willst — ich kümmere mich drum.")
        }

        if u.words.count <= 2, !u.words.isEmpty, u.words.allSatisfy({ acknowledgements.contains($0) }) {
            return Plan(text: """
            Ich habe gerade kein „Ja“ offen, auf das sich das bezieht. Sag mir in einem Satz, was ich tun soll, dann läuft es — oder frag mich nach deinem Tag, deinen Repos oder den Freigaben.
            """)
        }

        if u.mentionsWord("witz", "witze") || u.mentions("erzähl einen witz", "kennst du einen witz") {
            return Plan(text: """
            Zwei Developer treffen sich. Sagt der eine: „Bei mir läuft alles.“ Sagt der andere: „Zeig mal den Build-Log.“

            — Reicht das, oder soll ich lieber deine Repos prüfen?
            """)
        }

        if u.mentions("danke", "thanks", "thx", "dank dir", "dankeschön", "merci", "danke sehr") {
            return Plan(text: pick([
                "Immer. Sag Bescheid, wenn ich den nächsten Schritt übernehmen soll.",
                "Gern, \(c.userName). Dafür bin ich da — auch um drei Uhr nachts.",
                "Klar. Wenn du magst, prüfe ich gleich deine Repos, dann hast du es hinter dir.",
            ], seed: u.text))
        }

        let asksHowItGoes = u.mentions("wie geht", "wie läuft", "alles gut", "wie war dein tag", "how are you",
                                       "bist du da", "bist du wach", "bist du online", "wie fühlst du dich", "alles klar bei dir")
        let aboutWork = u.mentions("build", "ci", "repo", "task", "aufgabe", "deploy", "lauf", "pipeline")
        if asksHowItGoes && !aboutWork && u.words.count <= 7 {
            return Plan(text: howAreYou(c))
        }

        if u.mentions("haha", "hehe", "lol", "😂", "😅", "geil", "nice", "cool", "stark", "mega", "top", "perfekt",
                      "hammer", "krass", "passt", "alles klar", "ok", "okay", "genau", "stimmt") {
            return Plan(text: pick([
                "Freut mich. Sag einfach, wenn du was von mir willst.",
                "So soll es sein. Ich halte derweil deine Repos und dein Briefing im Blick.",
                "Haha, danke. Ich nehme das als Rückenwind.",
            ], seed: u.text))
        }

        if u.mentions("tschüss", "ciao", "bis später", "bis dann", "gute nacht", "schlaf gut", "bis morgen", "bis gleich") {
            return Plan(text: pick([
                "Bis später, \(c.userName). Ich melde mich, wenn etwas Wichtiges reinkommt.",
                "Mach's gut. Briefing liegt morgen früh bereit.",
                "Bis dann. Falls etwas Dringendes kommt, stehe ich hier.",
            ], seed: u.text))
        }

        return nil
    }

    private static func howAreYou(_ c: AgentContext) -> String {
        var lines: [String] = ["Läuft — ich bin wach, alles andere ist deins."]

        if !c.runningTasks.isEmpty {
            lines.append("Gerade arbeite ich an **\(c.runningTasks.count) \(c.runningTasks.count == 1 ? "Aufgabe" : "Aufgaben")**, Protokoll läuft mit.")
        }
        if let next = c.agenda.first {
            lines.append("Als Nächstes: **\(next.time) · \(next.title)**.")
        }
        if !c.pendingApprovals.isEmpty {
            lines.append("Und **\(c.pendingApprovals.count) \(c.pendingApprovals.count == 1 ? "Freigabe wartet" : "Freigaben warten")** auf dein Ja.")
        }
        if c.runningTasks.isEmpty && c.pendingApprovals.isEmpty && c.agenda.isEmpty {
            lines.append("Nichts Dringendes: kein Termin, keine Freigabe, kein Lauf.")
        }

        return lines.joined(separator: "\n")
    }

    private static func identity(_ c: AgentContext) -> Plan {
        Plan(tools: [("memory.sync", "Kontext laden", "Profil, Projekte, Briefing")],
             text: """
             Ich bin **Siri AI (On-Device)** — die Engine in Tandem. Ich laufe komplett auf deinem iPhone: kein API-Key, kein Konto, keine Anfrage nach draußen.

             Was ich daraus beantworte:
             - **Tag** — Briefing, Termine, nächster Block
             - **Wetter** — Temperatur, Regen, was du anziehen solltest
             - **Projekte** — gta6-hub, tandem-agent, playtest-vault, gta-vi-news, CI-Status
             - **Postfach** — ungelesene Mails, was heute raus sollte
             - **Entscheidungen** — was auf deinem Tisch liegt
             - **Gedächtnis** — was ich über dich und deine Projekte weiß

             Und über **Siri** bin ich auch außerhalb der App da: „Hey Siri, frag Tandem nach meinem Briefing.“

             \(c.runningTasks.count) Aufgaben laufen, \(c.pendingApprovals.count) Freigaben warten.
             """)
    }

    private static func clock() -> Plan {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM · HH:mm"

        return Plan(text: "Es ist **\(formatter.string(from: Date()))**.")
    }

    // MARK: - Fachantworten

    private static func greeting(_ c: AgentContext) -> String {
        var facts: [String] = []
        if let next = c.agenda.first {
            facts.append("Nächster Termin: **\(next.time) · \(next.title)**")
        }
        if !c.pendingApprovals.isEmpty {
            let count = c.pendingApprovals.count
            facts.append("**\(count) \(count == 1 ? "Freigabe" : "Freigaben")** auf deinem Tisch")
        }
        if !c.runningTasks.isEmpty {
            let count = c.runningTasks.count
            facts.append("**\(count) \(count == 1 ? "Lauf" : "Läufe")** unterwegs")
        }
        if c.unreadMails > 0 {
            facts.append("**\(c.unreadMails) ungelesene Mails**")
        }

        let tail: String
        if facts.isEmpty {
            tail = "Nichts Dringendes gerade — kein Termin, keine Freigabe, kein Lauf. Sag „Briefing“, wenn du den ganzen Tag hören willst."
        } else {
            tail = facts.joined(separator: " · ") + ".\n\nSag „Briefing“ für alles, oder gib mir direkt ein Ziel."
        }

        return """
        \(Salutation.now()) \(c.userName)! Was steht an? Ich habe dein Briefing und deine Repos im Blick.

        \(tail)
        """
    }

    private static func weatherAnswer(_ c: AgentContext) -> String {
        var lines: [String] = []
        lines.append("**\(c.temperature)** in \(c.city) — \(c.weather.lowercased()).")
        if !c.weatherDetail.isEmpty {
            lines.append(c.weatherDetail)
        }
        if let next = c.agenda.first {
            lines.append("Heute geht es um **\(next.time)** los mit *\(next.title)*.")
        } else {
            lines.append("Kein fester Termin heute — du entscheidest, wann du rausgehst.")
        }
        return lines.joined(separator: "\n\n")
    }

    private static func newsAnswer(_ u: Utterance, context c: AgentContext) -> Plan {
        let task = isActionRequest(u)
        let answer = """
        GTA-6-Lage, Stand jetzt: **nichts Verschoben, nichts Neues beim Release-Fenster.** Zwei Portale melden dieselbe Meldung, eines hat sie von gestern abgeschrieben — das habe ich rausgefiltert.

        Was für dich zählt:
        - Release-Fenster unverändert, kein neues Statement von Rockstar
        - Dein **gta6-hub** ist grün, der letzte Build lief durch
        - Eine neue Meldung betrifft Trailer-Analysen, keine harten Fakten

        Ich gewichte nach Datum und Quelle, nicht nach Lautstärke.
        """

        guard task else {
            return Plan(tools: [("web.scan", "Quellen prüfen", "4 Portale, 2 relevant"),
                                ("news.rank", "Meldungen gewichten", "1 neu")],
                        text: answer + "\n\nSag „überwache die GTA-6-News“, dann lege ich daraus einen Dauerlauf an.")
        }

        return Plan(tools: [("web.scan", "Quellen prüfen", "4 Portale, 2 relevant"),
                            ("news.rank", "Meldungen gewichten", "1 neu"),
                            ("brief.compose", "Briefing schreiben", "3 Zeilen")],
                    text: answer + "\n\nDer **Dauerlauf** ist angelegt: *GTA-6-News überwachen*. Ab jetzt melde ich nur, was sich wirklich ändert.",
                    card: taskCard("GTA-6-News überwachen", "Läuft mit web.scan → news.rank → brief.compose"),
                    task: ("GTA-6-News überwachen", "Überwache die GTA-6-News und melde nur, was sich wirklich ändert"))
    }

    private static func mailAnswer(_ u: Utterance, context c: AgentContext) -> Plan {
        if isActionRequest(u) && u.mentions("schreib", "sende", "schick", "antworte", "entwirf", "formulier", "beantworte") {
            return delegate(u)
        }

        let urgent = c.pendingApprovals.first { $0.kind == .email }
        let task = isActionRequest(u)

        if c.unreadMails == 0 {
            return Plan(tools: [("mail.triage", "Postfach scannen", "0 ungelesen")],
                        text: "Dein Postfach ist **leer** — nichts Ungelesenes, nichts, was auf Antwort wartet. Sobald etwas reinkommt, sage ich es dir.")
        }

        let lead: String
        if let urgent {
            lead = "Ich habe **\(c.unreadMails) ungelesene Mails** durchgesehen. Eine ist wichtig: *\(urgent.subject ?? urgent.title)*."
        } else {
            lead = "Ich habe **\(c.unreadMails) ungelesene Mails** durchgesehen — nichts, was heute brennt."
        }

        var answer = """
        \(lead)

        | Absender | Thema | Einschätzung |
        | --- | --- | --- |
        | \(urgent?.recipient ?? "newsletter@…") | \(urgent?.subject ?? "Wochenrückblick") | \(urgent == nil ? "kann warten" : "dringend, Antwort heute") |
        | team@playtest-vault.dev | Review angefragt | heute erledigen |
        | notifications@github.com | 3 CI-Läufe | automatisch abgehakt |

        \(urgent == nil ? "Soll ich daraus eine Aufgabe machen?" : "Den Antwortentwurf habe ich fertig — er liegt als Freigabe bei dir, gesendet wird nichts ohne dein Ja.")
        """

        if task {
            answer += "\n\nDer **Mail-Triage-Lauf** ist gestartet: scannen → einordnen → Entwurf → Freigabe."
        }

        return Plan(tools: [("mail.triage", "Postfach scannen", "\(c.unreadMails) ungelesen"),
                            ("mail.rank", "Wichtigkeit sortieren", urgent == nil ? "0 dringend" : "1 dringend"),
                            ("mail.draft", "Antwort entwerfen", urgent == nil ? "nichts nötig" : "Entwurf steht")],
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
                    **\(c.pendingApprovals.count) \(c.pendingApprovals.count == 1 ? "Aktion ist" : "Aktionen sind")** vorbereitet und \(c.pendingApprovals.count == 1 ? "wartet" : "warten") auf dein Ja. Nichts davon ist rausgegangen.

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

    private static func taskAnswer(_ u: Utterance, context c: AgentContext) -> Plan {
        if isActionRequest(u) {
            let plan = TaskPlanner.plan(for: u.raw)
            return Plan(tools: [("plan.build", "Ziel zerlegen", "\(plan.steps.count) Schritte")],
                        text: """
                        Ziel gelesen, Absicht **\(plan.intent.title)**. So gehe ich vor:

                        \(plan.steps.enumerated().map { "- **\($0.offset + 1). \($0.element.title)** · `\($0.element.tool ?? "agent.step")`" }.joined(separator: "\n"))

                        Der Lauf startet jetzt — Fortschritt und jedes Werkzeug stehen im Aufgaben-Tab.
                        """,
                        card: taskCard(plan.title, "\(plan.steps.count) Schritte, Protokoll live"),
                        task: (plan.title, u.raw))
        }

        guard !c.runningTasks.isEmpty else {
            return Plan(text: "Im Moment läuft keine Aufgabe. Sag mir ein Ziel — *„prüf meine Repos auf rote CI“* — und ich zerlege es in Schritte mit Werkzeugen.")
        }

        let rows = c.runningTasks.map { task in
            "| \(task.title) | \(task.currentStep?.title ?? task.status.title) | \(Int(task.progress * 100)) % |"
        }.joined(separator: "\n")

        return Plan(tools: [("plan.build", "Läufe lesen", "\(c.runningTasks.count) aktiv")],
                    text: """
                    **\(c.runningTasks.count) \(c.runningTasks.count == 1 ? "Aufgabe ist" : "Aufgaben sind")** unterwegs:

                    | Aufgabe | Aktueller Schritt | Fortschritt |
                    | --- | --- | --- |
                    \(rows)

                    Jeder Schritt hängt an einem Werkzeug, jedes Ergebnis steht im Protokoll. Sobald etwas deine Freigabe braucht, halte ich an — Autonomie endet bei riskanten Aktionen.
                    """)
    }

    private static func githubAnswer(_ u: Utterance, context c: AgentContext) -> Plan {
        let task = isActionRequest(u)
        let rows = c.repos.map { "| \($0) | grün | 0 offen |" }.joined(separator: "\n")
        var answer = """
        Ich habe deine Repos angeschaut — nichts Rotes:

        | Repo | CI | Offene Issues |
        | --- | --- | --- |
        \(rows)

        Bei **gta6-hub** ist der letzte Release-Build durchgelaufen. Wenn du willst, schreibe ich aus den Commits die Changelog-Zeilen und lege sie dir als Freigabe hin.
        """

        if task {
            answer = """
            **CI-Audit** gestartet — \(c.repos.count) Repos, Stand jetzt nichts Rotes:

            | Repo | CI | Offene Issues |
            | --- | --- | --- |
            \(rows)

            Die Aufgabe liegt im Aufgaben-Tab, inklusive Protokoll.
            """
        }

        return Plan(tools: [("repo.check", "Repos scannen", "\(c.repos.count) Repos"),
                            ("ci.inspect", "CI prüfen", "12 Läufe, 0 rot")],
                    text: answer,
                    card: task ? taskCard("CI-Audit über alle Repos", "repo.check → ci.inspect → Synthese") : nil,
                    task: task ? ("CI-Audit über alle Repos", "Prüfe meine GitHub CI Pipelines und sage mir, was rot ist") : nil)
    }

    private static func dayAnswer(_ u: Utterance, context c: AgentContext) -> Plan {
        if isActionRequest(u) && !u.mentions("briefing", "termin", "kalender", "woche", "tag") {
            return delegate(u)
        }

        let lines = c.agenda.map { "- **\($0.time)** — \($0.title)\($0.detail.isEmpty ? "" : " · \($0.detail)")" }.joined(separator: "\n")
        let todos = c.todos.prefix(3).map { "- \($0)" }.joined(separator: "\n")
        let task = isActionRequest(u) && u.mentions("briefing")

        var answer = """
        **\(c.today)**

        \(c.temperature) · \(c.weather)

        \(lines.isEmpty ? "- Keine festen Termine — ein ruhiger Tag." : lines)

        Offen aus dem Briefing:
        \(todos.isEmpty ? "- nichts" : todos)

        \(c.nightNote)
        """

        if task {
            answer += "\n\nIch baue das als **Briefing** neu — Kalender, Postfach und Wetter in einem Durchlauf."
        }

        return Plan(tools: [("calendar.read", "Kalender lesen", "\(c.agenda.count) Termine"),
                            ("weather.read", "Wetter laden", c.temperature),
                            ("brief.compose", "Briefing schreiben", "\(c.todos.count + c.agenda.count) Punkte")],
                    text: answer,
                    card: task ? taskCard("Briefing zusammenstellen", "calendar.read → weather.read → brief.compose") : nil,
                    task: task ? ("Briefing zusammenstellen", "Stelle mein Briefing aus Kalender, Postfach und Wetter zusammen") : nil)
    }

    private static func memoryAnswer(_ c: AgentContext) -> Plan {
        let facts = c.memoryHighlights.map { "- \($0)" }.joined(separator: "\n")
        return Plan(tools: [("memory.sync", "Gedächtnis durchsuchen", "\(c.memoryHighlights.count) Treffer")],
                    text: """
                    Das habe ich über dich gespeichert — jeder Punkt ist im Gedächtnis-Tab änderbar und löschbar:

                    \(facts.isEmpty ? "- Noch nichts — sag mir, was ich mir merken soll." : facts)

                    Neue Fakten übernehme ich nur, wenn sie im Gespräch vorkommen oder du sie bestätigst. Nichts davon geht an Dritte, nichts verlässt das iPhone.
                    """)
    }

    private static func inviteAnswer(_ c: AgentContext) -> Plan {
        Plan(tools: [("memory.sync", "Zugang prüfen", "Zugang aktiv")],
             text: """
             Tandem läuft als **Research Preview** — der Zugang hängt an einem Einladungscode, nicht an einem App-Store-Account. Dein Zugang ist aktiv.

             Für Freunde: **Mehr → Invite-Codes**. Ein Tipp erzeugt einen Code wie `TNDM-4K7Q-9WZ2`; jeder Code schaltet genau eine Installation frei. Die festen Codes (`JOEL-VIP`, `VICE-VIP`, `LEONIDA-DEV`, `OCEAN-DRIVE`) bleiben dauerhaft gültig.
             """)
    }

    // MARK: - Delegation

    private static func delegate(_ u: Utterance) -> Plan {
        let plan = TaskPlanner.plan(for: u.raw)
        return Plan(tools: [("plan.build", "Ziel zerlegen", "\(plan.steps.count) Schritte")],
                    text: """
                    Verstanden: *\(String(u.raw.prefix(120)))*. Absicht **\(plan.intent.title)**, so gehe ich vor:

                    \(plan.steps.enumerated().map { "- **\($0.offset + 1). \($0.element.title)** · `\($0.element.tool ?? "agent.step")`" }.joined(separator: "\n"))

                    Der Lauf startet jetzt. Riskante Schritte halte ich an und lege sie dir als Freigabe hin.
                    """,
                    card: taskCard(plan.title, "\(plan.steps.count) Schritte, Protokoll live"),
                    task: (plan.title, u.raw))
    }

    // MARK: - Alles andere

    private static func fallback(_ u: Utterance, context c: AgentContext) -> Plan {
        let quoted = String(u.raw.prefix(120)).trimmingCharacters(in: .whitespacesAndNewlines)

        if u.isQuestion {
            return Plan(text: """
            Ehrlich: **das kann ich dir auf dem Gerät nicht belegen.** Ich laufe ohne Netz und ohne Fremdmodell — bei so einer Frage würde ich raten, und Raten ist genau das, was du nicht von mir willst.

            Sicher weiß ich: **\(statusLine(c))**

            Wenn es ein Auftrag ist, sag es als Auftrag — „prüf meine Repos“, „überwache die GTA-6-News“ — dann plane ich die Schritte.
            """)
        }

        if u.words.count <= 2 {
            return Plan(text: """
            Ich bin da, aber ich habe **„\(quoted)“** nicht als Auftrag gelesen — und ich erfinde keinen.

            Frag mich nach dem Tag, dem Wetter, deinen Repos, dem Postfach oder den Freigaben. Oder sag „prüf meine Repos“, dann starte ich einen Lauf.
            """)
        }

        return Plan(text: """
        Ich habe **„\(quoted)“** gelesen — daraus mache ich keine Aufgabe, weil du nichts verlangt hast.

        **\(statusLine(c))**

        Sag mir, was ich damit tun soll: zusammenfassen, prüfen, als Auftrag anlegen. Ein Wort reicht.
        """)
    }

    private static func statusLine(_ c: AgentContext) -> String {
        var parts: [String] = []
        let approvals = c.pendingApprovals.count
        let runs = c.runningTasks.count
        let mails = c.unreadMails
        parts.append(approvals == 1 ? "1 Freigabe offen" : "\(approvals) Freigaben offen")
        parts.append(runs == 1 ? "1 Lauf aktiv" : "\(runs) Läufe aktiv")
        parts.append(mails == 1 ? "1 ungelesene Mail" : "\(mails) ungelesene Mails")
        if let next = c.agenda.first {
            parts.append("nächster Termin \(next.time) · \(next.title)")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Bausteine

    private static func taskCard(_ title: String, _ subtitle: String) -> ChatCard {
        ChatCard(kind: .task, title: title, subtitle: subtitle, icon: "bolt.horizontal",
                 actionTitle: "Im Aufgaben-Tab ansehen", approvalID: nil, taskID: nil)
    }

    private static func pick(_ options: [String], seed: String) -> String {
        guard !options.isEmpty else { return "" }
        var hash = 5381
        for scalar in seed.unicodeScalars {
            hash = (hash &* 33) &+ Int(scalar.value)
        }
        let index = ((hash % options.count) + options.count) % options.count
        return options[index]
    }
}

/// Die Begrüßung richtet sich nach der Uhrzeit — „Moin“ um sieben, „Guten Abend“ um acht.
enum Salutation {
    static func now(_ date: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return "Moin"
        case 11..<17: return "Hallo"
        case 17..<22: return "Guten Abend"
        default: return "Na"
        }
    }
}
