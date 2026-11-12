import SwiftUI

/// Der Kommandostand: was der Agent gerade tut, was auf dem Tisch liegt
/// und womit du ihn heute losschickst.
struct HomeView: View {
    @Environment(TandemStore.self) private var store
    @State private var doneTodos: Set<String> = []
    @State private var showApprovals = false
    @State private var appear = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    statusRow
                    approvalsStrip
                    briefingCard
                    liveFeed
                    launchpad
                    footer
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 28)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 10)
            }
            .scrollIndicators(.hidden)
            .navigationDestination(isPresented: $showApprovals) {
                ApprovalsView()
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                withAnimation(.easeOut(duration: 0.45)) { appear = true }
            }
        }
    }

    // MARK: Kopf

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Insignia(text: store.proactiveEnabled ? "Autonomous Agent" : "Agent Pausiert",
                         tint: store.proactiveEnabled ? store.accent : VicePalette.coral,
                         icon: store.proactiveEnabled ? "circle.hexagongrid.fill" : "pause.fill")
                Spacer(minLength: 0)
                if store.isFounder {
                    StatusBadge(text: "Founder", tint: VicePalette.gold, icon: "crown.fill")
                }
                Button {
                    Haptics.tap()
                    store.selectedTab = 3
                } label: {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(VicePalette.cyan)
                        .padding(8)
                        .glassPill(tint: VicePalette.cyan)
                }
                .buttonStyle(.plain)
            }

            SignalTicker(items: store.liveSignals, tint: store.accent)

            Text(greeting)
                .font(.system(size: 30, weight: .heavy))
                .fontWidth(.condensed)
                .tracking(0.2)
                .foregroundStyle(
                    LinearGradient(colors: [.white, Color.white.opacity(0.72)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.top, 4)

            HStack(spacing: 6) {
                Text(RelativeTime.weekdayLong(Date()).uppercased())
                Text("·")
                Text(store.engineLabel.uppercased())
                Text("·")
                Text("Letzter Scan \(RelativeTime.string(from: store.lastScan))")
            }
            .font(.system(size: 9.5, weight: .medium))
            .fontWidth(.condensed)
            .tracking(0.8)
            .foregroundStyle(Color.white.opacity(0.36))
        }
        .padding(.horizontal, 2)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "Guten Morgen, \(store.userName)."
        case 11..<15: return "Mahlzeit, \(store.userName)."
        case 15..<19: return "Guten Nachmittag, \(store.userName)."
        default: return "Guten Abend, \(store.userName)."
        }
    }

    private var statusRow: some View {
        HStack(spacing: 9) {
            statusChip(icon: "hand.raised.fill",
                       value: "\(store.pendingApprovals.count)",
                       label: "Freigaben",
                       tint: store.pendingApprovals.isEmpty ? VicePalette.cyan : VicePalette.gold) {
                showApprovals = true
            }
            statusChip(icon: "bolt.horizontal.fill",
                       value: "\(store.runningTasks.count)",
                       label: "Läufe",
                       tint: store.accent) {
                store.selectedTab = 1
            }
            statusChip(icon: "wrench.and.screwdriver.fill",
                       value: "\(store.audit.count)",
                       label: "Protokoll",
                       tint: VicePalette.mint) {
                store.selectedTab = 1
            }
        }
    }

    private func statusChip(icon: String, value: String, label: String, tint: Color,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint)
                Text(value)
                    .font(.system(size: 20, weight: .semibold))
                    .fontWidth(.condensed)
                    .monospacedDigit()
                    .foregroundStyle(Color.white.opacity(0.94))
                Text(label.uppercased())
                    .font(.system(size: 8.5, weight: .heavy))
                    .fontWidth(.expanded)
                    .tracking(1.1)
                    .foregroundStyle(Color.white.opacity(0.34))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(tint.opacity(0.07))
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [Color.white.opacity(0.26), tint.opacity(0.18), Color.white.opacity(0.03)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.5
                    )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Freigaben

    private var approvalsStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Wartet auf dich",
                          subtitle: nil,
                          icon: "hand.raised.fill",
                          trailing: "\(store.pendingApprovals.count) offen")

            if store.pendingApprovals.isEmpty {
                GlassCard(tint: VicePalette.cyan, glow: false, padding: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(VicePalette.cyan)
                        Text("Nichts offen. Der Agent meldet sich, sobald etwas deine Entscheidung braucht.")
                            .font(.system(size: 12.5))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(store.pendingApprovals.prefix(3)) { approval in
                            Button {
                                Haptics.tap()
                                showApprovals = true
                            } label: {
                                approvalChip(approval)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 1)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func approvalChip(_ approval: ApprovalRequest) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 6) {
                Image(systemName: approval.kind.icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(approval.kind.tint)
                Text(approval.kind.title.uppercased())
                    .font(.system(size: 8, weight: .heavy))
                    .fontWidth(.expanded)
                    .tracking(1.1)
                    .foregroundStyle(Color.white.opacity(0.38))
                Spacer(minLength: 4)
                Circle()
                    .fill(approval.risk.color)
                    .frame(width: 5, height: 5)
            }
            Text(approval.title)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.94))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            Text(approval.summary)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.42))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                Text("PRÜFEN")
                    .tracking(1.0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 8, weight: .bold))
            }
            .font(.system(size: 9, weight: .heavy))
            .fontWidth(.condensed)
            .foregroundStyle(approval.kind.tint)
        }
        .padding(13)
        .frame(width: 210, height: 136, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(approval.kind.tint.opacity(0.06))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [Color.white.opacity(0.26), approval.kind.tint.opacity(0.28)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.5
                )
        }
    }

    // MARK: Briefing

    private var briefingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                SectionHeader(title: "Tagesbriefing", subtitle: nil, icon: "sun.horizon.fill",
                              trailing: RelativeTime.string(from: store.briefing.generatedAt))
                Button {
                    store.regenerateBriefing()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(VicePalette.cyan)
                        .padding(6)
                        .glassPill(tint: VicePalette.cyan)
                }
                .buttonStyle(.plain)
            }

            GlassCard(tint: store.accent, glow: true, padding: 18) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FOKUS")
                                .font(.system(size: 8.5, weight: .heavy))
                                .fontWidth(.expanded)
                                .tracking(1.6)
                                .foregroundStyle(store.accent.opacity(0.9))
                            Text(store.briefing.focus)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.94))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                        if store.isRegeneratingBriefing {
                            ProgressView().controlSize(.mini).tint(.white)
                        }
                    }

                    weatherRow

                    NeonDivider()

                    VStack(spacing: 12) {
                        ForEach(store.briefing.agenda) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Text(item.time)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(item.highlight ? VicePalette.gold : Color.white.opacity(0.42))
                                    .frame(width: 40, alignment: .leading)
                                Rectangle()
                                    .fill(item.highlight ? VicePalette.gold : Color.white.opacity(0.14))
                                    .frame(width: 1.5, height: 26)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.system(size: 12.5, weight: item.highlight ? .semibold : .regular))
                                        .foregroundStyle(Color.white.opacity(item.highlight ? 0.96 : 0.82))
                                    Text(item.detail)
                                        .font(.system(size: 10.5))
                                        .foregroundStyle(Color.white.opacity(0.38))
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }

                    if !store.briefing.todos.isEmpty {
                        NeonDivider()
                        VStack(alignment: .leading, spacing: 9) {
                            Text("OFFEN")
                                .font(.system(size: 8.5, weight: .heavy))
                                .fontWidth(.expanded)
                                .tracking(1.6)
                                .foregroundStyle(Color.white.opacity(0.38))
                            ForEach(store.briefing.todos, id: \.self) { todo in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                        if doneTodos.contains(todo) { doneTodos.remove(todo) } else { doneTodos.insert(todo) }
                                    }
                                    Haptics.tap()
                                } label: {
                                    HStack(spacing: 9) {
                                        Image(systemName: doneTodos.contains(todo) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 12))
                                            .foregroundStyle(doneTodos.contains(todo) ? VicePalette.mint : Color.white.opacity(0.22))
                                        Text(todo)
                                            .font(.system(size: 12))
                                            .strikethrough(doneTodos.contains(todo), color: .secondary)
                                            .foregroundStyle(doneTodos.contains(todo) ? Color.white.opacity(0.38) : Color.white.opacity(0.86))
                                        Spacer(minLength: 0)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    HStack(alignment: .top, spacing: 7) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(VicePalette.violet.opacity(0.9))
                            .padding(.top, 1)
                        Text(store.briefing.nightNote)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.34))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var weatherRow: some View {
        HStack(spacing: 12) {
            Image(systemName: store.briefing.weatherIcon)
                .font(.system(size: 24, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.white.opacity(0.82))
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(store.briefing.temperature)
                        .font(.system(size: 18, weight: .semibold))
                        .fontWidth(.condensed)
                    Text(store.city.uppercased())
                        .font(.system(size: 9, weight: .heavy))
                        .fontWidth(.expanded)
                        .tracking(1.1)
                        .foregroundStyle(Color.white.opacity(0.32))
                }
                Text(store.briefing.weather)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.44))
            }
            Spacer(minLength: 0)
            Text(store.briefing.weatherDetail)
                .font(.system(size: 9.5))
                .foregroundStyle(Color.white.opacity(0.30))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 138, alignment: .trailing)
        }
    }

    // MARK: Agenten-Log

    private var liveFeed: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Agent-Log", subtitle: nil, icon: "dot.radiowaves.left.and.right",
                          trailing: "\(store.checkIns.count) Signale")
            GlassCard(tint: nil, glow: false, padding: 14) {
                VStack(spacing: 0) {
                    ForEach(Array(store.checkIns.prefix(5))) { checkIn in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(checkIn.tone.color)
                                .frame(width: 6, height: 6)
                                .shadow(color: checkIn.tone.color.opacity(0.8), radius: 4)
                                .padding(.top, 5)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(checkIn.title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color.white.opacity(0.88))
                                    Spacer(minLength: 0)
                                    Text(RelativeTime.string(from: checkIn.date))
                                        .font(.system(size: 9))
                                        .foregroundStyle(Color.white.opacity(0.26))
                                }
                                Text(checkIn.detail)
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(Color.white.opacity(0.40))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, 9)
                        if checkIn.id != store.checkIns.prefix(5).last?.id {
                            NeonDivider().padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }

    // MARK: Startrampe

    private var launchpad: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Ein Ziel genügt", subtitle: nil, icon: "bolt.horizontal.fill",
                          trailing: "Agent starten")
            VStack(spacing: 9) {
                launchCard(icon: "newspaper.fill",
                           tint: VicePalette.cyan,
                           title: "GTA-6-News überwachen",
                           detail: "web.scan → news.rank → brief.compose",
                           action: "Starten") {
                    store.createTask(goal: "Überwache die GTA-6-News und melde nur, was sich wirklich ändert")
                }
                launchCard(icon: "chevron.left.forwardslash.chevron.right",
                           tint: VicePalette.mint,
                           title: "GitHub CI prüfen",
                           detail: "repo.check → ci.inspect → Synthese",
                           action: "Starten") {
                    store.createTask(goal: "Prüfe meine GitHub CI Pipelines und sage mir, was rot ist")
                }
                launchCard(icon: "sun.horizon.fill",
                           tint: VicePalette.gold,
                           title: "Morgen-Briefing bauen",
                           detail: "calendar.read → mail.triage → brief.compose",
                           action: "Starten") {
                    store.createTask(goal: "Stelle mein Morgen-Briefing aus Kalender, Postfach und Wetter zusammen")
                }
            }
        }
    }

    private func launchCard(icon: String, tint: Color, title: String, detail: String,
                            action: String, perform: @escaping () -> Void) -> some View {
        GlassCard(tint: tint, glow: false, padding: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(tint.opacity(0.10))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(tint.opacity(0.22), lineWidth: 0.5)
                    }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                    Text(detail)
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.32))
                }
                Spacer(minLength: 0)
                Button(action: perform) {
                    Text(action.uppercased())
                        .font(.system(size: 9, weight: .heavy))
                        .fontWidth(.condensed)
                        .tracking(1.0)
                        .foregroundStyle(Color(red: 0.04, green: 0.03, blue: 0.06))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background { Capsule().fill(tint) }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            AgentEmblem(tint: VicePalette.magenta, rim: VicePalette.cyan)
                .frame(width: 40, height: 40)
                .opacity(0.8)
            Text("Der Agent plant, ruft Werkzeuge auf und hält bei allem Riskanten an. Ausgeführt wird nur, was du freigibst.")
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.28))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}
