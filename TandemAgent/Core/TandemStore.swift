import SwiftUI
import Observation

/// Der Kopf der App: hält Zustand, Freigaben, Aufgaben, Gedächtnis und
/// den Chat. Alles läuft auf dem MainActor, damit die Views einfach
/// beobachten können.
@MainActor
@Observable
final class TandemStore {

    // MARK: - Identität

    var userName: String = "Joel"
    var city: String = "Köln"
    var role: String = "Entwickler"

    // MARK: - Zugang

    var hasUnlocked: Bool = false
    var unlockedKey: String = ""
    var isFounder: Bool = false
    var hasOnboarded: Bool = false
    var inviteKeys: [InviteKey] = []

    // MARK: - Navigation

    var selectedTab: Int = 0
    var qaScreen: String?

    // MARK: - Einstellungen

    var provider: ProviderID = .simulator {
        didSet { defaults.set(provider.rawValue, forKey: Keys.provider) }
    }
    var models: [String: String] = [:] {
        didSet { defaults.set(models, forKey: Keys.models) }
    }
    var baseURLs: [String: String] = [:] {
        didSet { defaults.set(baseURLs, forKey: Keys.baseURLs) }
    }
    var customModel: String = "" {
        didSet { defaults.set(customModel, forKey: Keys.customModel) }
    }
    var themeChoice: GlacierTheme = .electricVice {
        didSet { defaults.set(themeChoice.rawValue, forKey: Keys.theme) }
    }
    var accentChoice: AccentChoice = .vicePink {
        didSet { defaults.set(accentChoice.rawValue, forKey: Keys.accent) }
    }
    var appearance: Appearance = .dark {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }
    var glowEnabled: Bool = true {
        didSet {
            defaults.set(glowEnabled, forKey: "tandem.glow")
        }
    }
    var hapticsEnabled: Bool = true {
        didSet { defaults.set(hapticsEnabled, forKey: "tandem.haptics") }
    }
    var proactiveEnabled: Bool = true {
        didSet { defaults.set(proactiveEnabled, forKey: Keys.proactive) }
    }
    var defaultAutonomy: AutonomyLevel = .suggest {
        didSet { defaults.set(defaultAutonomy.rawValue, forKey: Keys.autonomy) }
    }
    var quietHoursEnabled: Bool = true {
        didSet { defaults.set(quietHoursEnabled, forKey: Keys.quiet) }
    }
    var keyPresence: [String: Bool] = [:]

    // MARK: - Daten

    var briefing = MorningBriefing()
    var checkIns: [CheckIn] = []
    var approvals: [ApprovalRequest] = []
    var tasks: [AgentTask] = []
    var history: [AgentTask] = []
    var audit: [AuditEvent] = []
    var memoryTopics: [MemoryTopic] = []
    var services: [ConnectedService] = []
    var messages: [ChatMessage] = []

    // MARK: - Laufzeit

    var isRegeneratingBriefing = false
    var isThinking = false
    var isTesting = false
    var testResult: String?
    var toast: ToastMessage?
    var lastScan = Date()

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var proactiveLoop: Task<Void, Never>?
    @ObservationIgnored private var streamTask: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var tickCount = 0

    private enum Keys {
        static let provider = "tandem.provider"
        static let models = "tandem.models"
        static let baseURLs = "tandem.baseURLs"
        static let customModel = "tandem.customModel"
        static let theme = "tandem.theme"
        static let accent = "tandem.accent"
        static let appearance = "tandem.appearance"
        static let proactive = "tandem.proactive"
        static let autonomy = "tandem.autonomy"
        static let quiet = "tandem.quietHours"
        static let unlocked = "tandem.unlocked"
        static let unlockedKey = "tandem.unlockedKey"
        static let founder = "tandem.founder"
        static let onboarded = "tandem.onboarded"
        static let userName = "tandem.userName"
        static let city = "tandem.city"
        static let role = "tandem.role"
        static let identity = "tandem.identity"
    }

    // MARK: - Init

    init() {
        loadSettings()
        if let snapshot = Self.loadSnapshot() {
            apply(snapshot)
        } else {
            seed()
        }
        #if QA
        applyQALaunchArguments()
        #endif
    }

    private func loadSettings() {
        if let raw = defaults.string(forKey: Keys.provider), let value = ProviderID(rawValue: raw) {
            provider = value
        }
        models = defaults.dictionary(forKey: Keys.models) as? [String: String] ?? [:]
        baseURLs = defaults.dictionary(forKey: Keys.baseURLs) as? [String: String] ?? [:]
        customModel = defaults.string(forKey: Keys.customModel) ?? ""
        if let raw = defaults.string(forKey: Keys.theme), let value = GlacierTheme(rawValue: raw) {
            themeChoice = value
        }
        if let raw = defaults.string(forKey: Keys.accent), let value = AccentChoice(rawValue: raw) {
            accentChoice = value
        }
        // 1.1.0 bringt Leonida: einmalig auf die Vice-Bühne umschalten,
        // auch wenn eine alte 1.0.0-Installation ihre Einstellungen behält.
        if !defaults.bool(forKey: "tandem.viceMigration") {
            themeChoice = .electricVice
            accentChoice = .vicePink
            defaults.set(true, forKey: "tandem.viceMigration")
        }
        if let raw = defaults.string(forKey: Keys.appearance), let value = Appearance(rawValue: raw) {
            appearance = value
        }
        if defaults.object(forKey: "tandem.glow") != nil {
            glowEnabled = defaults.bool(forKey: "tandem.glow")
        }
        if defaults.object(forKey: "tandem.haptics") != nil {
            hapticsEnabled = defaults.bool(forKey: "tandem.haptics")
        }
        if defaults.object(forKey: Keys.proactive) != nil {
            proactiveEnabled = defaults.bool(forKey: Keys.proactive)
        }
        if let raw = defaults.string(forKey: Keys.autonomy), let value = AutonomyLevel(rawValue: raw) {
            defaultAutonomy = value
        }
        if defaults.object(forKey: Keys.quiet) != nil {
            quietHoursEnabled = defaults.bool(forKey: Keys.quiet)
        }
        hasUnlocked = defaults.bool(forKey: Keys.unlocked)
        unlockedKey = defaults.string(forKey: Keys.unlockedKey) ?? ""
        isFounder = defaults.bool(forKey: Keys.founder)
        hasOnboarded = defaults.bool(forKey: Keys.onboarded)
        userName = defaults.string(forKey: Keys.userName) ?? "Joel"
        city = defaults.string(forKey: Keys.city) ?? "Köln"
        role = defaults.string(forKey: Keys.role) ?? "Entwickler"

        for provider in ProviderID.allCases where provider.needsKey {
            keyPresence[provider.rawValue] = Keychain.has(account: provider.storageAccount)
        }
    }

    // MARK: - Abgeleitete Werte

    var accent: Color { accentChoice.color }

    var isSimulator: Bool { provider == .simulator || (provider.needsKey && apiKey(for: provider).isEmpty) }

    var engineLabel: String {
        isSimulator ? "Tandem Simulator" : provider.title
    }

    var pendingApprovals: [ApprovalRequest] {
        approvals.filter { $0.state == .pending }
    }

    var decidedApprovals: [ApprovalRequest] {
        approvals.filter { $0.state != .pending }
    }

    var runningTasks: [AgentTask] {
        tasks.filter { $0.status == .running || $0.status == .queued || $0.status == .paused }
    }

    var selectedModel: String {
        models[provider.rawValue] ?? provider.models.first?.id ?? ""
    }

    var baseURL: String {
        baseURLs[provider.rawValue] ?? provider.defaultBaseURL
    }

    var providerConfig: ProviderConfig {
        ProviderConfig(provider: provider,
                       model: selectedModel,
                       apiKey: apiKey(for: provider),
                       baseURL: baseURL,
                       customModel: customModel)
    }

    var demoContext: DemoContext {
        DemoContext(
            userName: userName,
            city: city,
            today: RelativeTime.weekdayLong(Date()),
            weather: briefing.weather,
            weatherDetail: briefing.weatherDetail,
            temperature: briefing.temperature,
            agenda: briefing.agenda,
            todos: briefing.todos,
            pendingApprovals: pendingApprovals,
            runningTasks: runningTasks,
            memoryHighlights: memoryTopics.flatMap { $0.facts.prefix(1) },
            unreadMails: 3,
            repos: ["gta6-hub", "playtest-vault", "tandem-agent", "hermes-frontend"],
            nightNote: briefing.nightNote
        )
    }

    // MARK: - Modell / Keys

    func setModel(_ model: String) {
        models[provider.rawValue] = model
    }

    func setBaseURL(_ url: String) {
        baseURLs[provider.rawValue] = url
    }

    func apiKey(for provider: ProviderID) -> String {
        guard provider.needsKey else { return "" }
        return Keychain.load(account: provider.storageAccount) ?? ""
    }

    func saveKey(_ value: String, for provider: ProviderID) {
        Keychain.save(value, account: provider.storageAccount)
        keyPresence[provider.rawValue] = !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        toast = ToastMessage(text: keyPresence[provider.rawValue] == true ? "Key gesichert" : "Key entfernt",
                             style: keyPresence[provider.rawValue] == true ? .success : .info)
        Haptics.success()
    }

    func removeKey(for provider: ProviderID) {
        Keychain.delete(account: provider.storageAccount)
        keyPresence[provider.rawValue] = false
        toast = ToastMessage(text: "Key gelöscht", style: .info)
    }

    func testProvider() {
        guard !isTesting else { return }
        isTesting = true
        testResult = nil
        Task {
            let config = providerConfig
            let result = await AIService.test(config: config)
            isTesting = false
            switch result {
            case .success(let text):
                testResult = "Verbunden: \(text.prefix(60))"
                Haptics.success()
            case .failure(let error):
                testResult = error.localizedDescription
                Haptics.warning()
            }
        }
    }

    // MARK: - Invite-Gate

    func redeem(_ raw: String) -> Bool {
        let code = InviteKeys.normalize(raw)
        guard !code.isEmpty else { return false }
        let generated = inviteKeys.contains { $0.code == code }
        guard InviteKeys.isMaster(code) || generated else { return false }

        hasUnlocked = true
        unlockedKey = code
        isFounder = InviteKeys.isMaster(code)
        defaults.set(true, forKey: Keys.unlocked)
        defaults.set(code, forKey: Keys.unlockedKey)
        defaults.set(isFounder, forKey: Keys.founder)

        if let index = inviteKeys.firstIndex(where: { $0.code == code }) {
            inviteKeys[index].redeemed = true
            inviteKeys[index].redeemedAt = Date()
        }
        audit.insert(AuditEvent(title: "Preview freigeschaltet",
                                detail: "Invite-Key \(code) eingelöst",
                                icon: "key.fill",
                                kind: .system), at: 0)
        persist()
        Haptics.success()
        return true
    }

    func generateInvite() -> InviteKey {
        var code = InviteKeys.generate()
        while inviteKeys.contains(where: { $0.code == code }) {
            code = InviteKeys.generate()
        }
        let key = InviteKey(code: code)
        inviteKeys.insert(key, at: 0)
        persist()
        Haptics.success()
        toast = ToastMessage(text: "Neuer Invite-Key erzeugt", style: .success)
        return key
    }

    func revokeInvite(_ id: UUID) {
        inviteKeys.removeAll { $0.id == id }
        persist()
        Haptics.tap()
        toast = ToastMessage(text: "Invite-Key gelöscht", style: .info)
    }

    func lockApp() {
        hasUnlocked = false
        hasOnboarded = false
        defaults.set(false, forKey: Keys.unlocked)
        defaults.set(false, forKey: Keys.onboarded)
        Haptics.tap()
    }

    func completeOnboarding(name: String, city: String, role: String) {
        userName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Joel" : name
        self.city = city
        self.role = role
        hasOnboarded = true
        defaults.set(userName, forKey: Keys.userName)
        defaults.set(self.city, forKey: Keys.city)
        defaults.set(role, forKey: Keys.role)
        defaults.set(true, forKey: Keys.onboarded)
        updateProfileTopic()
        persist()
        Haptics.success()
    }

    // MARK: - Freigaben

    func approve(_ id: UUID) {
        guard let index = approvals.firstIndex(where: { $0.id == id }) else { return }
        approvals[index].state = .executed
        approvals[index].decidedAt = Date()
        let approval = approvals[index]
        audit.insert(AuditEvent(title: "Freigabe erteilt",
                                detail: approval.title,
                                icon: "checkmark.seal.fill",
                                kind: .approval), at: 0)
        checkIns.insert(CheckIn(icon: "paperplane.fill",
                                title: approval.kind == .email ? "Mail ist raus" : "Aktion ausgeführt",
                                detail: approval.title,
                                date: Date(),
                                tone: .good), at: 0)
        showToast("\(approval.kind.title): \(approval.title)", style: .success)
        Haptics.success()
        persist()
    }

    func reject(_ id: UUID, note: String? = nil) {
        guard let index = approvals.firstIndex(where: { $0.id == id }) else { return }
        approvals[index].state = .rejected
        approvals[index].decidedAt = Date()
        approvals[index].note = note
        let approval = approvals[index]
        audit.insert(AuditEvent(title: "Freigabe abgelehnt",
                                detail: approval.title,
                                icon: "xmark.seal.fill",
                                kind: .approval), at: 0)
        showToast("Abgelehnt — nichts wurde ausgeführt", style: .info)
        Haptics.tap()
        persist()
    }

    func updateApproval(_ updated: ApprovalRequest) {
        guard let index = approvals.firstIndex(where: { $0.id == updated.id }) else { return }
        var value = updated
        value.state = .pending
        value.note = "Von dir bearbeitet"
        approvals[index] = value
        audit.insert(AuditEvent(title: "Freigabe bearbeitet",
                                detail: value.title,
                                icon: "pencil.tip.crop.circle",
                                kind: .approval), at: 0)
        showToast("Entwurf aktualisiert", style: .info)
        persist()
    }

    func addApproval(_ approval: ApprovalRequest) {
        approvals.insert(approval, at: 0)
        persist()
    }

    // MARK: - Aufgaben

    func createTask(title: String? = nil, goal: String, autonomy: AutonomyLevel? = nil) {
        let cleaned = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        let resolvedTitle = title ?? TaskPlanner.title(for: cleaned)
        var task = AgentTask(title: resolvedTitle,
                             goal: cleaned,
                             autonomy: autonomy ?? defaultAutonomy,
                             status: .queued,
                             steps: TaskPlanner.steps(for: cleaned))
        task.source = "Chat"
        tasks.insert(task, at: 0)
        audit.insert(AuditEvent(title: "Aufgabe gestartet",
                                detail: resolvedTitle,
                                icon: "play.circle.fill",
                                kind: .task), at: 0)
        showToast("Aufgabe läuft — Schritte siehst du im Aufgaben-Tab", style: .info)
        Haptics.soft()
        persist()
        let id = task.id
        Task { await self.run(id) }
    }

    private func run(_ id: UUID) async {
        guard let start = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[start].status = .running
        if tasks[start].steps.isEmpty {
            tasks[start].steps = TaskPlanner.steps(for: tasks[start].goal)
        }
        persist()

        var stepIndex = 0
        while stepIndex < (tasks.first(where: { $0.id == id })?.steps.count ?? 0) {
            // Pause abwarten.
            while let current = tasks.first(where: { $0.id == id }), current.status == .paused {
                try? await Task.sleep(for: .milliseconds(500))
            }
            guard let running = tasks.first(where: { $0.id == id }), running.status == .running else { return }

            tasks = tasks.map { task in
                guard task.id == id else { return task }
                var copy = task
                if copy.steps.indices.contains(stepIndex) {
                    copy.steps[stepIndex].state = .running
                }
                return copy
            }
            Haptics.soft()
            try? await Task.sleep(for: .milliseconds(TaskPlanner.duration(for: stepIndex)))

            guard let stillRunning = tasks.first(where: { $0.id == id }), stillRunning.status == .running else { return }
            tasks = tasks.map { task in
                guard task.id == id else { return task }
                var copy = task
                if copy.steps.indices.contains(stepIndex) {
                    copy.steps[stepIndex].state = .done
                }
                return copy
            }
            persist()
            stepIndex += 1
        }

        guard let index = tasks.firstIndex(where: { $0.id == id }), tasks[index].status == .running else { return }
        tasks[index].status = .done
        tasks[index].finishedAt = Date()
        tasks[index].summary = TaskPlanner.summary(for: tasks[index].goal)
        let finished = tasks.remove(at: index)
        history.insert(finished, at: 0)
        audit.insert(AuditEvent(title: "Aufgabe abgeschlossen",
                                detail: finished.title,
                                icon: "checkmark.circle.fill",
                                kind: .task), at: 0)
        checkIns.insert(CheckIn(icon: "checkmark.circle.fill",
                                title: "Aufgabe fertig",
                                detail: finished.title,
                                date: Date(),
                                tone: .good), at: 0)
        showToast("Fertig: \(finished.title)", style: .success)
        Haptics.success()
        persist()
    }

    func togglePause(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        if tasks[index].status == .paused {
            tasks[index].status = .running
            Haptics.tap()
            showToast("Aufgabe läuft weiter", style: .info)
        } else if tasks[index].status == .running {
            tasks[index].status = .paused
            Haptics.tap()
            showToast("Aufgabe pausiert", style: .info)
        }
        persist()
    }

    func cancelTask(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].status = .cancelled
        tasks[index].finishedAt = Date()
        tasks[index].summary = "Von dir abgebrochen."
        let cancelled = tasks.remove(at: index)
        history.insert(cancelled, at: 0)
        audit.insert(AuditEvent(title: "Aufgabe abgebrochen",
                                detail: cancelled.title,
                                icon: "stop.circle.fill",
                                kind: .task), at: 0)
        Haptics.tap()
        persist()
    }

    // MARK: - Briefing

    func regenerateBriefing() {
        guard !isRegeneratingBriefing else { return }
        isRegeneratingBriefing = true
        Haptics.soft()
        Task {
            try? await Task.sleep(for: .milliseconds(1200))
            briefing.generatedAt = Date()
            briefing.focus = Self.focusIdeas.randomElement() ?? briefing.focus
            isRegeneratingBriefing = false
            checkIns.insert(CheckIn(icon: "sun.horizon.fill",
                                    title: "Briefing neu gebaut",
                                    detail: "6 Quellen geprüft, 1 neuer Hinweis",
                                    date: Date(),
                                    tone: .good), at: 0)
            showToast("Briefing aktualisiert", style: .success)
            Haptics.success()
            persist()
        }
    }

    // MARK: - Proaktive Engine

    func startProactiveLoop() {
        guard proactiveLoop == nil else { return }
        proactiveLoop = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(26))
                guard let self else { return }
                await self.tick()
            }
        }
    }

    func stopProactiveLoop() {
        proactiveLoop?.cancel()
        proactiveLoop = nil
    }

    private func tick() {
        guard hasUnlocked, proactiveEnabled else { return }
        tickCount += 1
        lastScan = Date()
        let template = Self.scanRotation[tickCount % Self.scanRotation.count]
        checkIns.insert(CheckIn(icon: template.icon,
                                title: template.title,
                                detail: template.detail,
                                date: Date(),
                                tone: template.tone), at: 0)
        if checkIns.count > 10 { checkIns.removeLast(checkIns.count - 10) }

        // Alle paar Runden entsteht ein neuer Vorschlag — aber nie mehr
        // als drei offene Freigaben, damit der Tisch nicht überläuft.
        if tickCount % 3 == 0, pendingApprovals.count < 3,
           let proposal = Self.proposalRotation.randomElement() {
            approvals.insert(proposal, at: 0)
            showToast("Neue Freigabe vorbereitet", style: .info)
            Haptics.soft()
        }
        persist()
    }

    private static let focusIdeas: [String] = [
        "Heute zählt ein Ding: Tandem 1.1.0 rausbringen — danach ist der Kopf frei für Reviews.",
        "Drei Termine, ein langer Fokusblock — ich habe die Mails schon vorsortiert.",
        "Ruhiger Tag in Leonida. Perfekt, um das Playtest-Vault-Release zu schneiden.",
        "Vor dem Mittagessen ist dein Kalender voll, ab 13 Uhr kannst du durchziehen.",
    ]

    private static let scanRotation: [(icon: String, title: String, detail: String, tone: CheckIn.Tone)] = [
        ("envelope.badge", "Weazel News · Mail-Scan", "0 neue dringende Mails", .good),
        ("chevron.left.forwardslash.chevron.right", "Leonida Dispatch · GitHub", "Alle Repos grün, keine roten Läufe", .good),
        ("calendar", "VCPR · Kalender", "Nächster Termin in 42 Minuten", .neutral),
        ("cloud.sun.rain", "Vice Wetter · Ocean Drive", "Regenfenster ab 16 Uhr bestätigt", .warn),
        ("bolt.batteryblock", "ViceNet · Gerätestatus", "Akku 74 %, Backup um 03:12 gelaufen", .good),
        ("brain.head.profile", "Tandem Gedächtnis", "2 neue Fakten aus dem Chat übernommen", .neutral),
        ("person.2.wave.2", "Vice City Kontakte", "Keine offenen Anfragen", .neutral),
        ("doc.text.magnifyingglass", "Aktenzeichen Leonida", "Keine neuen Verträge oder Rechnungen", .good),
    ]

    private static var proposalRotation: [ApprovalRequest] {
        [
            ApprovalRequest(kind: .email,
                            title: "Antwort an das Playtest-Team",
                            summary: "Kurze Zusage für den Freitagstermin",
                            recipient: "team@playtest-vault.dev",
                            subject: "Re: Freitag — passt",
                            body: "Hey zusammen,\n\nFreitag passt bei mir. Ich bringe die Builds mit und wir gehen die offenen Reviews durch.\n\nBis dann\nJoel",
                            risk: .medium,
                            tool: "mail.send",
                            reason: "Der Agent hat den Termin im Kalender gefunden und den Entwurf vorbereitet.",
                            note: "Automatisch vorbereitet"),
            ApprovalRequest(kind: .calendar,
                            title: "Fokusblock auf Donnerstag legen",
                            summary: "11:00–13:00, Kalender ist frei",
                            risk: .low,
                            tool: "calendar.create",
                            reason: "Zwei Termine wurden verschoben, der Block ist jetzt frei."),
            ApprovalRequest(kind: .payment,
                            title: "Domain tandem.agent verlängern",
                            summary: "12,80 € für ein Jahr, Karte endet auf 4417",
                            amount: "12,80 €",
                            risk: .medium,
                            tool: "payments.charge",
                            reason: "Läuft in 4 Tagen ab."),
        ]
    }

    // MARK: - Chat

    func send(_ raw: String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        messages.append(ChatMessage(role: .user, text: text))
        isThinking = true
        streamTask?.cancel()
        let useSimulator = isSimulator
        streamTask = Task { await respond(to: text, simulator: useSimulator) }
        persist()
    }

    func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isThinking = false
        if let last = messages.last, last.role == .agent, last.text.isEmpty {
            messages[messages.count - 1].text = "_Abgebrochen._"
        }
        Haptics.tap()
        persist()
    }

    private func respond(to text: String, simulator: Bool) async {
        let messageID = UUID()
        var message = ChatMessage(role: .agent, text: "", engine: simulator ? "Tandem Simulator" : provider.title)
        message.id = messageID
        messages.append(message)

        if simulator {
            let plan = DemoBrain.plan(for: text, context: demoContext)
            if !plan.tools.isEmpty {
                let calls = plan.tools.map { ToolCall(name: $0.name, label: $0.label) }
                updateMessage(messageID) { $0.tools = calls }
                for (index, tool) in plan.tools.enumerated() {
                    try? await Task.sleep(for: .milliseconds(380))
                    if Task.isCancelled { return }
                    updateMessage(messageID) { message in
                        guard message.tools.indices.contains(index) else { return }
                        message.tools[index].state = .done
                        message.tools[index].result = tool.result
                    }
                }
            }
            let chunks = Self.chunks(of: plan.text)
            for chunk in chunks {
                if Task.isCancelled { return }
                updateMessage(messageID) { $0.text += chunk }
                try? await Task.sleep(for: .milliseconds(18))
            }
            if let card = plan.card {
                updateMessage(messageID) { $0.card = card }
            }
        } else {
            updateMessage(messageID) { message in
                message.tools = [ToolCall(name: "context.build",
                                          label: "Kontext: Gedächtnis, Kalender, Freigaben",
                                          state: .done,
                                          result: engineLabel)]
            }
            do {
                var received = false
                for try await chunk in AIService.stream(config: providerConfig,
                                                        system: Self.systemPrompt(store: self),
                                                        history: messages.filter { $0.id != messageID }) {
                    if Task.isCancelled { return }
                    received = true
                    updateMessage(messageID) { $0.text += chunk }
                }
                if !received {
                    updateMessage(messageID) {
                        $0.text = "_Der Anbieter hat nichts zurückgegeben. Prüfe Modell und Key in den Einstellungen._"
                    }
                }
            } catch {
                updateMessage(messageID) {
                    $0.text = "**Verbindung fehlgeschlagen.** \(error.localizedDescription)\n\nTipp: In den Einstellungen den Key prüfen oder auf den Tandem Simulator umschalten — der läuft immer."
                }
                showToast("Anbieter nicht erreichbar", style: .warning)
            }
        }

        isThinking = false
        persist()
    }

    private func updateMessage(_ id: UUID, _ change: (inout ChatMessage) -> Void) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        change(&messages[index])
    }

    private static func chunks(of text: String) -> [String] {
        var result: [String] = []
        var current = ""
        for character in text {
            current.append(character)
            if current.count >= 9, character == " " {
                result.append(current)
                current = ""
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    func clearChat() {
        messages = []
        Haptics.tap()
        persist()
    }

    static func systemPrompt(store: TandemStore) -> String {
        let approvals = store.pendingApprovals.map { "- \($0.kind.title): \($0.title)" }.joined(separator: "\n")
        let agenda = store.briefing.agenda.map { "- \($0.time) \($0.title)" }.joined(separator: "\n")
        let facts = store.memoryTopics.flatMap { $0.facts.prefix(2) }.map { "- \($0)" }.joined(separator: "\n")
        return """
        Du bist Tandem, ein proaktiver persönlicher Agent in der Tandem-App.
        Der Nutzer heißt \(store.userName), wohnt in \(store.city) und arbeitet als \(store.role).

        Deine Regeln:
        - Antworte auf Deutsch, knapp und konkret. Markdown ist erlaubt (Überschriften, Listen, Tabellen).
        - Du handelst nie ohne Freigabe bei E-Mails, Zahlungen, Kalenderänderungen und Löschungen. Bereite vor und frage.
        - Erfinde keine Fakten über den Nutzer. Unbekanntes sagst du offen.
        - Nenne am Ende eines Vorschlags immer den nächsten konkreten Schritt.

        Heute: \(RelativeTime.weekdayLong(Date())), \(store.briefing.temperature) \(store.briefing.weather.lowercased()).

        Offene Freigaben:
        \(approvals.isEmpty ? "- keine" : approvals)

        Heutige Termine:
        \(agenda.isEmpty ? "- keine" : agenda)

        Bekanntes über den Nutzer:
        \(facts.isEmpty ? "- noch nichts gespeichert" : facts)
        """
    }

    // MARK: - Gedächtnis

    func addFact(_ fact: String, to topicID: UUID) {
        let trimmed = fact.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = memoryTopics.firstIndex(where: { $0.id == topicID }) else { return }
        memoryTopics[index].facts.append(trimmed)
        memoryTopics[index].updatedAt = Date()
        audit.insert(AuditEvent(title: "Gedächtnis ergänzt",
                                detail: trimmed,
                                icon: "brain.head.profile",
                                kind: .memory), at: 0)
        Haptics.success()
        persist()
    }

    func removeFact(_ fact: String, from topicID: UUID) {
        guard let index = memoryTopics.firstIndex(where: { $0.id == topicID }) else { return }
        memoryTopics[index].facts.removeAll { $0 == fact }
        memoryTopics[index].updatedAt = Date()
        Haptics.tap()
        persist()
    }

    func wipeMemory() {
        memoryTopics = []
        messages = []
        showToast("Gedächtnis geleert", style: .info)
        Haptics.warning()
        persist()
    }

    func toggleService(_ id: String) {
        guard let index = services.firstIndex(where: { $0.id == id }) else { return }
        services[index].status = services[index].status == .off ? .connected : .off
        Haptics.tap()
        persist()
    }

    private func updateProfileTopic() {
        guard let index = memoryTopics.firstIndex(where: { $0.title == "Profil" }) else { return }
        memoryTopics[index].facts = [
            "\(userName), \(city)",
            "\(role) — baut unter anderem GTA-6-Hub und Playtest Vault",
            "Spricht Deutsch, mag trockenen Humor",
        ]
        memoryTopics[index].updatedAt = Date()
    }

    // MARK: - Toast

    func showToast(_ text: String, style: ToastMessage.Style = .success) {
        toast = ToastMessage(text: text, style: style)
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.6))
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.25)) { self.toast = nil }
            }
        }
    }

    // MARK: - Persistenz

    private struct Snapshot: Codable {
        var userName: String
        var city: String
        var role: String
        var briefing: MorningBriefing
        var checkIns: [CheckIn]
        var approvals: [ApprovalRequest]
        var tasks: [AgentTask]
        var history: [AgentTask]
        var audit: [AuditEvent]
        var memoryTopics: [MemoryTopic]
        var services: [ConnectedService]
        var messages: [ChatMessage]
        var inviteKeys: [InviteKey]
    }

    private var snapshotURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("tandem-state.json")
    }

    func persist() {
        let snapshot = Snapshot(userName: userName,
                                city: city,
                                role: role,
                                briefing: briefing,
                                checkIns: checkIns,
                                approvals: approvals,
                                tasks: tasks,
                                history: history,
                                audit: audit,
                                memoryTopics: memoryTopics,
                                services: services,
                                messages: messages,
                                inviteKeys: inviteKeys)
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: snapshotURL, options: .atomic)
        } catch {
            // Persistenz ist Komfort, kein Grund die App zu stören.
        }
    }

    private static func loadSnapshot() -> Snapshot? {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = directory.appendingPathComponent("tandem-state.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    private func apply(_ snapshot: Snapshot) {
        userName = snapshot.userName
        city = snapshot.city
        role = snapshot.role
        briefing = snapshot.briefing
        checkIns = snapshot.checkIns
        approvals = snapshot.approvals
        tasks = snapshot.tasks
        history = snapshot.history
        audit = snapshot.audit
        memoryTopics = snapshot.memoryTopics
        services = snapshot.services
        messages = snapshot.messages
        inviteKeys = snapshot.inviteKeys
    }

    // MARK: - Seed

    private func seed() {
        let now = Date()

        briefing = MorningBriefing(
            generatedAt: now.addingTimeInterval(-420),
            greeting: "Guten Morgen",
            focus: "Heute zählt ein Ding: Tandem 1.1.0 rausbringen — Leonida-Edition, Neon überall. Danach ist der Kopf frei für Reviews.",
            weather: "Sonnig, 24 °C, leichte Palmenbrise",
            weatherDetail: "Ab 19 Uhr zieht Neon-Regen über Ocean Drive, gegen 21 Uhr klart es auf.",
            weatherIcon: "sun.max.fill",
            temperature: "24 °C",
            agenda: [
                BriefingItem(time: "09:30", title: "Standup mit dem Team", detail: "15 Minuten, danach Fokusblock", icon: "person.2.fill"),
                BriefingItem(time: "11:00", title: "Fokusblock: Tandem 1.1.0", detail: "Vice-Redesign, Build, IPA, Release", icon: "hammer.fill", highlight: true),
                BriefingItem(time: "14:00", title: "Review: Playtest Vault", detail: "3 Pull Requests warten", icon: "chevron.left.forwardslash.chevron.right"),
                BriefingItem(time: "18:30", title: "Laufrunde am Rhein", detail: "6 km, ab 18 Uhr trocken", icon: "figure.run"),
            ],
            todos: ["Omas iPhone-Backup prüfen", "PR #12 in playtest-vault reviewen", "Release-Notes für Tandem 1.1.0 schreiben"],
            nightNote: "Nachtaktivität: Mail-Scan um 02:14 (0 dringend), GitHub durchgehend grün, iPhone-Backup um 03:12 gesichert."
        )

        checkIns = [
            CheckIn(icon: "envelope.badge", title: "Weazel News · Mail-Check vor 15 Min.", detail: "3 neue Mails, 1 davon dringend", date: now.addingTimeInterval(-900), tone: .warn),
            CheckIn(icon: "chevron.left.forwardslash.chevron.right", title: "Leonida Dispatch · GitHub vor 32 Min.", detail: "Alle 4 Repos grün, keine roten CI-Läufe", date: now.addingTimeInterval(-1920), tone: .good),
            CheckIn(icon: "calendar", title: "VCPR · Kalender vor 48 Min.", detail: "Nächster Termin 11:00 — Fokusblock Tandem", date: now.addingTimeInterval(-2880), tone: .neutral),
            CheckIn(icon: "cloud.sun.rain", title: "Vice Wetter vor 1 Std.", detail: "Neon-Regen ab 19:00 erkannt", date: now.addingTimeInterval(-3600), tone: .neutral),
            CheckIn(icon: "brain.head.profile", title: "Tandem Gedächtnis vor 2 Std.", detail: "Neuer Fakt: Tandem-Projekt (Release 1.1.0)", date: now.addingTimeInterval(-7200), tone: .good),
            CheckIn(icon: "bolt.batteryblock", title: "ViceNet · Gerät vor 3 Std.", detail: "Akku 74 %, Backup um 03:12 gelaufen", date: now.addingTimeInterval(-10800), tone: .good),
            CheckIn(icon: "person.2.wave.2", title: "Vice City Kontakte vor 4 Std.", detail: "Keine offenen Anfragen", date: now.addingTimeInterval(-14400), tone: .neutral),
            CheckIn(icon: "key.fill", title: "Preview vor 5 Std.", detail: "Invite-Key eingelöst, Founder-Zugang aktiv", date: now.addingTimeInterval(-18000), tone: .good),
        ]

        approvals = [
            ApprovalRequest(kind: .email,
                            title: "Antwort an Lisa Breuer",
                            summary: "Zusage für den Playtest am Freitag",
                            recipient: "lisa.breuer@playtest-vault.dev",
                            subject: "Re: Playtest am Freitag — passt bei mir",
                            body: "Hey Lisa,\n\nFreitag passt bei mir. Ich bringe die aktuellen Builds mit und wir gehen die drei offenen Reviews durch.\n\nViele Grüße\nJoel",
                            risk: .medium,
                            tool: "mail.send",
                            createdAt: now.addingTimeInterval(-2400),
                            reason: "Lisa hat um 08:40 gefragt, ob Freitag steht. Der Entwurf antwortet direkt auf ihre Mail."),
            ApprovalRequest(kind: .payment,
                            title: "GitHub Copilot Pro verlängern",
                            summary: "Monatsabo läuft am 14.11. aus",
                            amount: "10,00 € / Monat",
                            risk: .medium,
                            tool: "payments.charge",
                            createdAt: now.addingTimeInterval(-5400),
                            reason: "Die hinterlegte Karte endet auf 4417. Tandem hat die Zahlung vorbereitet, aber nicht ausgelöst."),
            ApprovalRequest(kind: .deletion,
                            title: "Alte Build-Artefakte löschen",
                            summary: "12,4 GB Actions-Artifacts älter als 30 Tage",
                            risk: .low,
                            tool: "github.artifacts.delete",
                            createdAt: now.addingTimeInterval(-7200),
                            reason: "Betrifft nur abgelaufene Artefakte. Kein Branch, kein Release wird angefasst."),
            ApprovalRequest(kind: .calendar,
                            title: "Fokusblock auf Donnerstag verschoben",
                            summary: "Kollision mit Omas Arzttermin um 11:00",
                            risk: .low,
                            tool: "calendar.create",
                            createdAt: now.addingTimeInterval(-86400),
                            state: .executed,
                            decidedAt: now.addingTimeInterval(-82000),
                            reason: "Du hast am Vortag zugestimmt."),
            ApprovalRequest(kind: .email,
                            title: "Wochenrückblick an das Team",
                            summary: "Zusammenfassung aus 18 Commits",
                            recipient: "team@joe-design9.dev",
                            subject: "Woche 45 — was gelandet ist",
                            body: "Moin,\n\nkurz zusammengefasst: Tandem steht, der Hub läuft stabil, offen ist nur der Icon-Cache.\n\nJoel",
                            risk: .low,
                            tool: "mail.send",
                            createdAt: now.addingTimeInterval(-172800),
                            state: .rejected,
                            decidedAt: now.addingTimeInterval(-170000),
                            reason: "Tandem hatte den Rückblick am Freitag vorbereitet."),
        ]

        tasks = [
            AgentTask(title: "Playtest-Vault: Changelog für v0.9",
                      goal: "Sammle alle Commits seit v0.8.4 und schreibe den Changelog für v0.9",
                      autonomy: .suggest,
                      status: .running,
                      steps: [
                        TaskStep(title: "Commits seit v0.8.4 sammeln", detail: "37 Commits, 4 Autoren", state: .done),
                        TaskStep(title: "Änderungen nach Bereich clustern", detail: "UI, Sync, Build", state: .done),
                        TaskStep(title: "Changelog formulieren", detail: "3 Abschnitte, deutsch", state: .running),
                        TaskStep(title: "Release-Entwurf zur Freigabe", detail: "Geht an dich, nicht direkt raus", state: .pending),
                      ],
                      createdAt: now.addingTimeInterval(-1500)),
            AgentTask(title: "Wochenrückblick aus Commits",
                      goal: "Fasse die Woche über alle Repos zusammen und lege einen Entwurf an",
                      autonomy: .ask,
                      status: .running,
                      steps: [
                        TaskStep(title: "Repos scannen", detail: "4 Repos, 62 Commits", state: .done),
                        TaskStep(title: "Highlights auswählen", detail: "Tandem v1.0.0, Hub v2.0.0", state: .running),
                        TaskStep(title: "Entwurf schreiben", detail: "Wartet auf dich", state: .pending),
                      ],
                      createdAt: now.addingTimeInterval(-600)),
        ]

        history = [
            AgentTask(title: "Mail-Triage Montag",
                      goal: "Sortiere das Wochenend-Postfach und markiere alles Dringende",
                      autonomy: .suggest,
                      status: .done,
                      steps: [
                        TaskStep(title: "Postfach scannen", detail: "24 Mails", state: .done),
                        TaskStep(title: "Wichtigkeit einordnen", detail: "3 dringend", state: .done),
                        TaskStep(title: "Antworten vorbereiten", detail: "2 Entwürfe", state: .done),
                      ],
                      createdAt: now.addingTimeInterval(-90000),
                      finishedAt: now.addingTimeInterval(-89000),
                      summary: "24 Mails sortiert, 2 Antwortentwürfe liegen als Freigabe bereit."),
            AgentTask(title: "Repo-Gesundheit prüfen",
                      goal: "Prüfe alle Repos auf rote CI und offene Dependabot-Warnungen",
                      autonomy: .act,
                      status: .done,
                      steps: [
                        TaskStep(title: "CI-Läufe abrufen", detail: "12 Läufe", state: .done),
                        TaskStep(title: "Warnungen sammeln", detail: "0 kritisch", state: .done),
                      ],
                      createdAt: now.addingTimeInterval(-180000),
                      finishedAt: now.addingTimeInterval(-179000),
                      summary: "Alles grün. Zwei minor Updates vorgemerkt."),
        ]

        audit = [
            AuditEvent(date: now.addingTimeInterval(-600), title: "GitHub-Scan abgeschlossen", detail: "4 Repos, 0 Fehler", icon: "chevron.left.forwardslash.chevron.right", kind: .scan),
            AuditEvent(date: now.addingTimeInterval(-1500), title: "Aufgabe gestartet", detail: "Playtest-Vault: Changelog für v0.9", icon: "play.circle.fill", kind: .task),
            AuditEvent(date: now.addingTimeInterval(-2400), title: "Freigabe vorbereitet", detail: "Antwort an Lisa Breuer", icon: "envelope.badge", kind: .approval),
            AuditEvent(date: now.addingTimeInterval(-7200), title: "Freigabe vorbereitet", detail: "Alte Build-Artefakte löschen", icon: "trash.fill", kind: .approval),
            AuditEvent(date: now.addingTimeInterval(-18000), title: "Preview freigeschaltet", detail: "Invite-Key TANDEM-2026 eingelöst", icon: "key.fill", kind: .system),
            AuditEvent(date: now.addingTimeInterval(-86400), title: "Gedächtnis ergänzt", detail: "Projekt Tandem mit Release-Plan", icon: "brain.head.profile", kind: .memory),
        ]

        memoryTopics = [
            MemoryTopic(emoji: "👤", title: "Profil",
                        facts: ["Joel, Köln", "Entwickler — baut unter anderem GTA-6-Hub und Playtest Vault", "Spricht Deutsch, mag trockenen Humor"],
                        updatedAt: now, pinned: true),
            MemoryTopic(emoji: "🛠️", title: "Projekte",
                        facts: ["gta6-hub: SwiftUI-News-Portal, v2.0.0 mit Neon-Vice-Kulisse", "playtest-vault: Testmanagement, v0.9 in Arbeit", "tandem-agent: dieser Agent, 1.1.0 Leonida Edition"],
                        updatedAt: now.addingTimeInterval(-7200)),
            MemoryTopic(emoji: "👵", title: "Familie",
                        facts: ["Oma lebt in der Nähe, iPhone-Hilfe per Telefon", "Nächster Arzttermin Donnerstag, 11:00"],
                        updatedAt: now.addingTimeInterval(-86400)),
            MemoryTopic(emoji: "🎮", title: "Vorlieben",
                        facts: ["GTA VI ist das große Thema — Release 19.11.2026", "Cola Light statt Cola", "Arbeitet gern im langen Fokusblock am Vormittag"],
                        updatedAt: now.addingTimeInterval(-172800)),
            MemoryTopic(emoji: "⏰", title: "Arbeitsrhythmus",
                        facts: ["Fokusblock 11:00–13:00, danach Reviews", "Ruhezeit 23:00–07:00, keine Push-Nachrichten", "Freitags keine Deployments"],
                        updatedAt: now.addingTimeInterval(-259200)),
        ]

        services = [
            ConnectedService(id: "mail", name: "Mail", icon: "envelope.fill", tintKey: "mail",
                             detail: "joelminther1@gmail.com", status: .connected,
                             scopes: ["Lesen", "Entwürfe", "Senden nach Freigabe"]),
            ConnectedService(id: "calendar", name: "Kalender", icon: "calendar", tintKey: "calendar",
                             detail: "Privat + Arbeit", status: .connected,
                             scopes: ["Lesen", "Einträge nach Freigabe"]),
            ConnectedService(id: "github", name: "GitHub", icon: "chevron.left.forwardslash.chevron.right", tintKey: "github",
                             detail: "@joe-design9", status: .connected,
                             scopes: ["Repos lesen", "CI lesen", "Artefakte löschen nach Freigabe"]),
            ConnectedService(id: "x", name: "X", icon: "at", tintKey: "x",
                             detail: "@musecutething", status: .connected,
                             scopes: ["Lesen", "Posten nach Freigabe"]),
            ConnectedService(id: "device", name: "Gerät", icon: "iphone", tintKey: "device",
                             detail: "iPhone, Standort geteilt", status: .connected,
                             scopes: ["Standort", "Schritte", "Erinnerungen"]),
            ConnectedService(id: "music", name: "Apple Music", icon: "music.note", tintKey: "music",
                             detail: "Nicht verbunden", status: .off,
                             scopes: []),
        ]

        messages = []

        if !inviteKeys.isEmpty { return }
        inviteKeys = [
            InviteKey(code: "JOEL-VIP", createdAt: now.addingTimeInterval(-200000), redeemed: true, redeemedAt: now.addingTimeInterval(-18000)),
            InviteKey(code: "TNDM-7K2M-9QX4", createdAt: now.addingTimeInterval(-86000)),
        ]
    }

    // MARK: - QA

    #if QA
    private func applyQALaunchArguments() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-QAGate") {
            hasUnlocked = false
            hasOnboarded = false
            selectedTab = 0
            return
        }
        if arguments.contains("-QAOnboard") {
            hasUnlocked = true
            hasOnboarded = false
            unlockedKey = "TANDEM-2026"
            isFounder = true
            return
        }
        hasUnlocked = true
        hasOnboarded = true
        unlockedKey = "TANDEM-2026"
        isFounder = true

        if let index = arguments.firstIndex(of: "-QAStartTab"), index + 1 < arguments.count,
           let tab = Int(arguments[index + 1]) {
            selectedTab = tab
        }
        if let index = arguments.firstIndex(of: "-QAScreen"), index + 1 < arguments.count {
            qaScreen = arguments[index + 1]
        }
        if arguments.contains("-QAChat"), messages.isEmpty {
            seedQAChat()
        }
    }

    private func seedQAChat() {
        messages = [
            ChatMessage(role: .user, text: "Was steht heute an und was ist mit den Mails?", date: Date().addingTimeInterval(-180)),
            ChatMessage(role: .agent, text: DemoBrain.plan(for: "heute", context: demoContext).text, date: Date().addingTimeInterval(-170), engine: "Tandem Simulator"),
        ]
    }
    #endif
}

extension ProviderID {
    var storageAccount: String { "key." + rawValue }
}
