import SwiftUI
import Observation

/// Der Kopf der App: hält Zustand, Freigaben, Aufgaben, Gedächtnis und
/// den Chat. Die Ausführung von Aufgaben liegt in `AgentEngine`; hier
/// stehen nur die Daten und die Entscheidungen, die Joel trifft.
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
    var themeChoice: TandemTheme = .obsidian {
        didSet { defaults.set(themeChoice.rawValue, forKey: Keys.theme) }
    }
    var accentChoice: AccentChoice = .sand {
        didSet { defaults.set(accentChoice.rawValue, forKey: Keys.accent) }
    }
    var appearance: Appearance = .dark {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
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
    var testProviderID: String?
    var toast: ToastMessage?
    var lastScan = Date()

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var proactiveLoop: Task<Void, Never>?
    @ObservationIgnored private var streamTask: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var tickCount = 0
    @ObservationIgnored private lazy var engine = AgentEngine(store: self)

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
            resumeInterruptedTasks()
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
        if let raw = defaults.string(forKey: Keys.theme), let value = TandemTheme(rawValue: raw) {
            themeChoice = value
        }
        if let raw = defaults.string(forKey: Keys.accent), let value = AccentChoice(rawValue: raw) {
            accentChoice = value
        }
        // 1.3.0: ruhige, monochrome Bühne — einmalig auch für Bestandsinstallationen.
        if !defaults.bool(forKey: "tandem.calmMigration") {
            themeChoice = .obsidian
            accentChoice = .sand
            defaults.set(true, forKey: "tandem.calmMigration")
        }
        if let raw = defaults.string(forKey: Keys.appearance), let value = Appearance(rawValue: raw) {
            appearance = value
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
        isSimulator ? "Tandem Agent · Simulator" : provider.title
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

    var activeTaskCount: Int { runningTasks.count }

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

    func config(for provider: ProviderID) -> ProviderConfig {
        ProviderConfig(provider: provider,
                       model: models[provider.rawValue] ?? provider.models.first?.id ?? "",
                       apiKey: apiKey(for: provider),
                       baseURL: baseURLs[provider.rawValue] ?? provider.defaultBaseURL,
                       customModel: customModel)
    }

    var agentContext: AgentContext {
        AgentContext(
            userName: userName,
            city: city,
            role: role,
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
            nightNote: briefing.nightNote,
            recentScans: checkIns
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
        testProvider(provider)
    }

    func testProvider(_ target: ProviderID) {
        guard !isTesting else { return }
        guard target != .simulator else {
            testResult = "Simulator bereit — kein Key nötig."
            testProviderID = target.rawValue
            return
        }
        isTesting = true
        testResult = nil
        testProviderID = target.rawValue
        Task {
            let result = await AIService.test(config: config(for: target))
            isTesting = false
            switch result {
            case .success(let text):
                testResult = "Verbunden: \(text.prefix(48))"
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
        audit.insert(AuditEvent(title: "Zugang freigeschaltet",
                                detail: "Einladungscode \(code) eingelöst",
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

    /// Nimmt eine vom Agenten vorbereitete Freigabe an — höchstens eine
    /// pro Werkzeug und Titel, damit der Tisch nicht überläuft.
    @discardableResult
    func queue(_ approval: ApprovalRequest, from taskID: UUID?) -> Bool {
        let duplicate = approvals.contains {
            $0.state == .pending && $0.tool == approval.tool && $0.title == approval.title
        }
        guard !duplicate, pendingApprovals.count < 4 else { return false }
        var value = approval
        value.note = "Vom Agenten vorbereitet"
        approvals.insert(value, at: 0)
        audit.insert(AuditEvent(title: "Freigabe vorbereitet",
                                detail: value.title,
                                icon: "hand.raised.fill",
                                kind: .approval), at: 0)
        Haptics.soft()
        persist()
        return true
    }

    // MARK: - Aufgaben

    func createTask(title: String? = nil, goal: String, autonomy: AutonomyLevel? = nil) {
        let cleaned = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        let plan = TaskPlanner.plan(for: cleaned)
        var task = AgentTask(title: title ?? plan.title,
                             goal: cleaned,
                             autonomy: autonomy ?? defaultAutonomy,
                             intent: plan.intent,
                             status: .queued,
                             steps: plan.steps)
        task.source = "Chat"
        task.log = [AgentLogEntry(level: .info, text: plan.opening)]
        tasks.insert(task, at: 0)
        audit.insert(AuditEvent(title: "Aufgabe gestartet",
                                detail: task.title,
                                icon: "play.circle.fill",
                                kind: .task), at: 0)
        showToast("Agent läuft — Protokoll im Aufgaben-Tab", style: .info)
        Haptics.soft()
        persist()
        engine.launch(taskID: task.id)
    }

    func togglePause(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        if tasks[index].status == .paused {
            tasks[index].status = .running
            engine.launch(taskID: id)
            Haptics.tap()
            showToast("Agent läuft weiter", style: .info)
        } else if tasks[index].status == .running {
            tasks[index].status = .paused
            appendLog(id, level: .info, text: "Pausiert von dir")
            Haptics.tap()
            showToast("Agent pausiert", style: .info)
        }
        persist()
    }

    func cancelTask(_ id: UUID) {
        engine.cancel(taskID: id)
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].status = .cancelled
        tasks[index].finishedAt = Date()
        tasks[index].summary = "Von dir abgebrochen."
        tasks[index].log.append(AgentLogEntry(level: .warning, text: "Lauf abgebrochen"))
        let cancelled = tasks.remove(at: index)
        history.insert(cancelled, at: 0)
        audit.insert(AuditEvent(title: "Aufgabe abgebrochen",
                                detail: cancelled.title,
                                icon: "stop.circle.fill",
                                kind: .task), at: 0)
        Haptics.tap()
        persist()
    }

    // MARK: - Aufgaben-Laufzeit (von der Engine genutzt)

    func mutateTask(_ id: UUID, _ change: (inout AgentTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        change(&tasks[index])
        persist()
    }

    func appendLog(_ id: UUID, level: AgentLogEntry.Level, text: String, tool: String? = nil) {
        mutateTask(id) { value in
            value.log.append(AgentLogEntry(level: level, text: text, tool: tool))
            if value.log.count > 80 { value.log.removeFirst(value.log.count - 80) }
        }
    }

    func finishTask(_ id: UUID, summary: String) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].status = .done
        tasks[index].finishedAt = Date()
        tasks[index].summary = summary
        for stepIndex in tasks[index].steps.indices where tasks[index].steps[stepIndex].state == .pending {
            tasks[index].steps[stepIndex].state = .done
        }
        let finished = tasks.remove(at: index)
        history.insert(finished, at: 0)
        audit.insert(AuditEvent(title: "Aufgabe abgeschlossen",
                                detail: finished.title,
                                icon: "checkmark.circle.fill",
                                kind: .task), at: 0)
        for tool in Set(finished.steps.compactMap { $0.tool }) {
            audit.insert(AuditEvent(title: "Werkzeug ausgeführt",
                                    detail: tool,
                                    icon: AgentTool.icon(for: tool),
                                    kind: .tool), at: 0)
        }
        checkIns.insert(CheckIn(icon: "checkmark.circle.fill",
                                title: "Agent fertig",
                                detail: finished.title,
                                date: Date(),
                                tone: .good), at: 0)
        showToast("Fertig: \(finished.title)", style: .success)
        Haptics.success()
        persist()
    }

    /// Nach einem Neustart laufen angefangene Aufgaben weiter — sonst
    /// blieben sie für immer bei 40 % stehen.
    private func resumeInterruptedTasks() {
        let resumable = tasks.filter { $0.status == .running || $0.status == .queued }
        for task in resumable {
            engine.launch(taskID: task.id)
        }
    }

    // MARK: - Briefing

    func regenerateBriefing() {
        guard !isRegeneratingBriefing else { return }
        isRegeneratingBriefing = true
        Haptics.soft()
        Task {
            try? await Task.sleep(for: .milliseconds(1400))
            briefing.generatedAt = Date()
            briefing.focus = Self.focusIdeas.randomElement() ?? briefing.focus
            isRegeneratingBriefing = false
            checkIns.insert(CheckIn(icon: "sun.horizon.fill",
                                    title: "Briefing neu gebaut",
                                    detail: "6 Quellen geprüft, 1 neuer Hinweis",
                                    date: Date(),
                                    tone: .good), at: 0)
            audit.insert(AuditEvent(title: "Briefing gebaut",
                                    detail: "Kalender, Postfach, Wetter, Repos",
                                    icon: "sun.horizon.fill",
                                    kind: .scan), at: 0)
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
        if checkIns.count > 12 { checkIns.removeLast(checkIns.count - 12) }

        if tickCount % 4 == 0, pendingApprovals.count < 3,
           let proposal = Self.proposalRotation.randomElement() {
            queue(proposal, from: nil)
            showToast("Neue Freigabe vorbereitet", style: .info)
        }
        persist()
    }

    private static let focusIdeas: [String] = [
        "Heute zählt ein Ding: den GTA-6-News-Lauf scharf stellen, danach ist der Kopf frei für Reviews.",
        "Drei Termine, ein langer Fokusblock — ich habe die Mails schon vorsortiert.",
        "Ruhiger Tag in Köln. Perfekt, um das Playtest-Vault-Release zu schneiden.",
        "Vor dem Mittagessen ist dein Kalender voll, ab 13 Uhr kannst du durchziehen.",
    ]

    private static let scanRotation: [(icon: String, title: String, detail: String, tone: CheckIn.Tone)] = [
        ("envelope.badge", "Postfach-Scan", "0 neue dringende Mails", .good),
        ("chevron.left.forwardslash.chevron.right", "Repo-Scan", "Alle Repos grün, keine roten Läufe", .good),
        ("calendar", "Kalender-Scan", "Nächster Termin in 42 Minuten", .neutral),
        ("cloud.sun.rain", "Wetter", "Regenfenster ab 16 Uhr bestätigt", .warn),
        ("bolt.batteryblock", "Gerätestatus", "Akku 74 %, Backup um 03:12 gelaufen", .good),
        ("brain.head.profile", "Gedächtnis", "2 neue Fakten aus dem Chat übernommen", .neutral),
        ("newspaper", "News-Scan", "GTA-6-Lage unverändert, 1 neue Meldung", .neutral),
        ("doc.text.magnifyingglass", "Dokumente", "Keine neuen Verträge oder Rechnungen", .good),
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
                            tool: "pay.charge",
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
        var message = ChatMessage(role: .agent, text: "", engine: simulator ? "Tandem Agent" : provider.title)
        message.id = messageID
        messages.append(message)

        if simulator {
            let plan = DemoBrain.plan(for: text, context: agentContext)
            if !plan.tools.isEmpty {
                let calls = plan.tools.map { ToolCall(name: $0.name, label: $0.label) }
                updateMessage(messageID) { $0.tools = calls }
                for (index, tool) in plan.tools.enumerated() {
                    try? await Task.sleep(for: .milliseconds(430))
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
                try? await Task.sleep(for: .milliseconds(16))
            }
            if let card = plan.card {
                updateMessage(messageID) { $0.card = card }
            }
            if let task = plan.task, let card = plan.card, card.kind == .task {
                createTask(title: task.title, goal: task.goal)
            }
        } else {
            updateMessage(messageID) { message in
                message.tools = [ToolCall(name: "context.build",
                                          label: "Kontext: Gedächtnis, Freigaben, Briefing",
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
                    $0.text = "**Verbindung fehlgeschlagen.** \(error.localizedDescription)\n\nTipp: In den Einstellungen den Key prüfen oder auf den Tandem-Simulator umschalten — der läuft immer."
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
        let tasks = store.runningTasks.map { "- \($0.title) (\(Int($0.progress * 100)) %)" }.joined(separator: "\n")
        return """
        Du bist Tandem, ein autonomer persönlicher Agent in der Tandem-App.
        Der Nutzer heißt \(store.userName), wohnt in \(store.city) und arbeitet als \(store.role).

        Deine Regeln:
        - Antworte auf Deutsch, knapp und konkret. Markdown ist erlaubt (Überschriften, Listen, Tabellen).
        - Du handelst nie ohne Freigabe bei E-Mails, Zahlungen, Kalenderänderungen und Löschungen. Bereite vor und frage.
        - Erfinde keine Fakten über den Nutzer. Unbekanntes sagst du offen.
        - Nenne am Ende eines Vorschlags immer den nächsten konkreten Schritt.

        Heute: \(RelativeTime.weekdayLong(Date())), \(store.briefing.temperature) \(store.briefing.weather.lowercased()).

        Laufende Aufgaben:
        \(tasks.isEmpty ? "- keine" : tasks)

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
        return directory.appendingPathComponent("tandem-state-v3.json")
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
        let url = directory.appendingPathComponent("tandem-state-v3.json")
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
            focus: "Heute zählt ein Ding: Der GTA-6-News-Lauf soll von allein laufen — danach ist der Kopf frei für Reviews.",
            weather: "Bewölkt, 9 °C, leichter Wind aus West",
            weatherDetail: "Ab 16 Uhr Regen, gegen 19 Uhr trocken. Gute Stunde für die Laufrunde am Rhein.",
            weatherIcon: "cloud.sun.fill",
            temperature: "9 °C",
            agenda: [
                BriefingItem(time: "09:30", title: "Standup mit dem Team", detail: "15 Minuten, danach Fokusblock", icon: "person.2.fill"),
                BriefingItem(time: "11:00", title: "Fokusblock: Tandem 1.3.0", detail: "Ruhiges Design, Build, IPA, Release", icon: "hammer.fill", highlight: true),
                BriefingItem(time: "14:00", title: "Review: Playtest Vault", detail: "3 Pull Requests warten", icon: "chevron.left.forwardslash.chevron.right"),
                BriefingItem(time: "18:30", title: "Laufrunde am Rhein", detail: "6 km, ab 18 Uhr trocken", icon: "figure.run"),
            ],
            todos: ["Omas iPhone-Backup prüfen", "PR #12 in playtest-vault reviewen", "Release-Notes für Tandem 1.3.0 schreiben"],
            nightNote: "Nachtaktivität: Mail-Scan um 02:14 (0 dringend), GitHub durchgehend grün, iPhone-Backup um 03:12 gesichert."
        )

        checkIns = [
            CheckIn(icon: "newspaper", title: "News-Scan vor 6 Min.", detail: "GTA-6-Lage unverändert, 1 neue Meldung", date: now.addingTimeInterval(-360), tone: .neutral),
            CheckIn(icon: "envelope.badge", title: "Postfach-Scan vor 15 Min.", detail: "3 neue Mails, 1 davon dringend", date: now.addingTimeInterval(-900), tone: .warn),
            CheckIn(icon: "chevron.left.forwardslash.chevron.right", title: "Repo-Scan vor 32 Min.", detail: "Alle 4 Repos grün, keine roten CI-Läufe", date: now.addingTimeInterval(-1920), tone: .good),
            CheckIn(icon: "calendar", title: "Kalender-Scan vor 48 Min.", detail: "Nächster Termin 11:00 — Fokusblock Tandem", date: now.addingTimeInterval(-2880), tone: .neutral),
            CheckIn(icon: "cloud.sun.rain", title: "Wetter vor 1 Std.", detail: "Regen ab 16:00 erkannt", date: now.addingTimeInterval(-3600), tone: .neutral),
            CheckIn(icon: "brain.head.profile", title: "Gedächtnis vor 2 Std.", detail: "Neuer Fakt: Tandem-Projekt (Release 1.3.0)", date: now.addingTimeInterval(-7200), tone: .good),
            CheckIn(icon: "bolt.batteryblock", title: "Gerät vor 3 Std.", detail: "Akku 74 %, Backup um 03:12 gelaufen", date: now.addingTimeInterval(-10800), tone: .good),
            CheckIn(icon: "key.fill", title: "Zugang vor 5 Std.", detail: "Einladungscode eingelöst", date: now.addingTimeInterval(-18000), tone: .good),
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
                            tool: "pay.charge",
                            createdAt: now.addingTimeInterval(-5400),
                            reason: "Die hinterlegte Karte endet auf 4417. Vorbereitet, aber nicht ausgelöst."),
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
                            reason: "Der Agent hatte den Rückblick am Freitag vorbereitet."),
        ]

        var newsTask = AgentTask(title: "GTA-6-News-Lage",
                                 goal: "Überwache die GTA-6-News und melde nur, was sich wirklich ändert",
                                 autonomy: .suggest,
                                 intent: .newsScan,
                                 status: .running,
                                 steps: [
                                    TaskStep(title: "Quellen scannen", detail: "Newswire, Portale, dein Hub", tool: "web.scan", state: .done, result: "4 Quellen geprüft"),
                                    TaskStep(title: "Meldungen prüfen", detail: "Volltext, Dubletten, Alter", tool: "web.read", state: .done, result: "2 Quellen gelesen"),
                                    TaskStep(title: "Relevanz gewichten", detail: "Bezug zu GTA 6 und deinen Projekten", tool: "news.rank", state: .running),
                                    TaskStep(title: "Kurzbriefing formulieren", detail: "Drei Zeilen, kein Presse-Sprech", tool: "brief.compose"),
                                 ],
                                 createdAt: now.addingTimeInterval(-1500))
        newsTask.log = [
            AgentLogEntry(date: now.addingTimeInterval(-1500), level: .info, text: "Ziel analysiert · Absicht: News-Überwachung"),
            AgentLogEntry(date: now.addingTimeInterval(-1490), level: .tool, text: "Plan gebaut · 4 Schritte", tool: "plan.build"),
            AgentLogEntry(date: now.addingTimeInterval(-1480), level: .tool, text: "Quellen scannen · web.scan", tool: "web.scan"),
            AgentLogEntry(date: now.addingTimeInterval(-1460), level: .result, text: "4 Quellen geprüft", tool: "web.scan"),
            AgentLogEntry(date: now.addingTimeInterval(-1450), level: .info, text: "Gescannt: Rockstar Newswire, GTANet, r/GTA6, dein gta6-hub", tool: "web.scan"),
            AgentLogEntry(date: now.addingTimeInterval(-1440), level: .tool, text: "Meldungen prüfen · web.read", tool: "web.read"),
            AgentLogEntry(date: now.addingTimeInterval(-1430), level: .result, text: "2 Quellen gelesen", tool: "web.read"),
        ]

        var repotask = AgentTask(title: "CI-Audit über alle Repos",
                                 goal: "Prüfe meine GitHub CI Pipelines und sage mir, was rot ist",
                                 autonomy: .act,
                                 intent: .repoAudit,
                                 status: .running,
                                 steps: [
                                    TaskStep(title: "Repos prüfen", detail: "Branches, offene PRs, letzte Commits", tool: "repo.check", state: .done, result: "4 Repos grün"),
                                    TaskStep(title: "CI-Läufe prüfen", detail: "Rote Builds, Laufzeiten, Ursachen", tool: "ci.inspect", state: .running),
                                    TaskStep(title: "Kontext abgleichen", detail: "Gedächtnis und letzte Scans", tool: "memory.sync"),
                                    TaskStep(title: "Ergebnis synthetisieren", detail: "Was grün ist, was dich braucht", tool: "result.synthesis"),
                                 ],
                                 createdAt: now.addingTimeInterval(-600))
        repotask.log = [
            AgentLogEntry(date: now.addingTimeInterval(-600), level: .info, text: "Ziel analysiert · Absicht: Repo-Audit"),
            AgentLogEntry(date: now.addingTimeInterval(-590), level: .tool, text: "Plan gebaut · 4 Schritte", tool: "plan.build"),
            AgentLogEntry(date: now.addingTimeInterval(-580), level: .tool, text: "Repos prüfen · repo.check", tool: "repo.check"),
            AgentLogEntry(date: now.addingTimeInterval(-560), level: .result, text: "4 Repos grün", tool: "repo.check"),
        ]

        tasks = [newsTask, repotask]

        history = [
            AgentTask(title: "Mail-Triage Montag",
                      goal: "Sortiere das Wochenend-Postfach und markiere alles Dringende",
                      autonomy: .suggest,
                      intent: .mailTriage,
                      status: .done,
                      steps: [
                        TaskStep(title: "Postfach scannen", detail: "24 Mails", tool: "mail.triage", state: .done, result: "24 ungelesen"),
                        TaskStep(title: "Wichtigkeit einordnen", detail: "3 dringend", tool: "mail.rank", state: .done, result: "3 dringend"),
                        TaskStep(title: "Antworten vorbereiten", detail: "2 Entwürfe", tool: "mail.draft", state: .done, result: "2 Entwürfe"),
                      ],
                      createdAt: now.addingTimeInterval(-90000),
                      finishedAt: now.addingTimeInterval(-89000),
                      summary: "24 Mails sortiert, 2 Antwortentwürfe liegen als Freigabe bereit. Nichts wurde gesendet."),
            AgentTask(title: "Repo-Gesundheit prüfen",
                      goal: "Prüfe alle Repos auf rote CI und offene Dependabot-Warnungen",
                      autonomy: .act,
                      intent: .repoAudit,
                      status: .done,
                      steps: [
                        TaskStep(title: "CI-Läufe abrufen", detail: "12 Läufe", tool: "ci.inspect", state: .done, result: "12 Läufe"),
                        TaskStep(title: "Warnungen sammeln", detail: "0 kritisch", tool: "repo.check", state: .done, result: "0 kritisch"),
                      ],
                      createdAt: now.addingTimeInterval(-180000),
                      finishedAt: now.addingTimeInterval(-179000),
                      summary: "Alles grün. Zwei minor Updates vorgemerkt."),
        ]

        audit = [
            AuditEvent(date: now.addingTimeInterval(-360), title: "News-Scan abgeschlossen", detail: "4 Quellen, 1 neue Meldung", icon: "newspaper", kind: .scan),
            AuditEvent(date: now.addingTimeInterval(-600), title: "GitHub-Scan abgeschlossen", detail: "4 Repos, 0 Fehler", icon: "chevron.left.forwardslash.chevron.right", kind: .scan),
            AuditEvent(date: now.addingTimeInterval(-1500), title: "Aufgabe gestartet", detail: "GTA-6-News-Lage", icon: "play.circle.fill", kind: .task),
            AuditEvent(date: now.addingTimeInterval(-2400), title: "Freigabe vorbereitet", detail: "Antwort an Lisa Breuer", icon: "envelope.badge", kind: .approval),
            AuditEvent(date: now.addingTimeInterval(-7200), title: "Freigabe vorbereitet", detail: "Alte Build-Artefakte löschen", icon: "trash.fill", kind: .approval),
            AuditEvent(date: now.addingTimeInterval(-18000), title: "Zugang freigeschaltet", detail: "Einladungscode JOEL-VIP eingelöst", icon: "key.fill", kind: .system),
            AuditEvent(date: now.addingTimeInterval(-86400), title: "Gedächtnis ergänzt", detail: "Projekt Tandem mit Release-Plan", icon: "brain.head.profile", kind: .memory),
        ]

        memoryTopics = [
            MemoryTopic(emoji: "👤", title: "Profil",
                        facts: ["Joel, Köln", "Entwickler — baut unter anderem GTA-6-Hub und Playtest Vault", "Spricht Deutsch, mag trockenen Humor"],
                        updatedAt: now, pinned: true),
            MemoryTopic(emoji: "🛠️", title: "Projekte",
                        facts: ["gta6-hub: SwiftUI-News-Portal, v2.0.0", "playtest-vault: Testmanagement, v0.9 in Arbeit", "tandem-agent: dieser Agent, 1.3.0 Handcrafted"],
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
            ConnectedService(id: "mail", name: "Mail", icon: "envelope", tintKey: "mail",
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
            InviteKey(code: "OCEAN-DRIVE", createdAt: now.addingTimeInterval(-190000)),
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
            unlockedKey = "JOEL-VIP"
            isFounder = true
            return
        }
        hasUnlocked = true
        hasOnboarded = true
        unlockedKey = "JOEL-VIP"
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
            ChatMessage(role: .agent, text: DemoBrain.plan(for: "heute", context: agentContext).text, date: Date().addingTimeInterval(-170), engine: "Tandem Agent"),
        ]
    }
    #endif
}

extension ProviderID {
    var storageAccount: String { "key." + rawValue }
}
