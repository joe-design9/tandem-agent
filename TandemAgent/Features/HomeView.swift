import SwiftUI

struct HomeView: View {
    @Environment(TandemStore.self) private var store
    @State private var doneTodos: Set<String> = []
    @State private var showApprovals = false
    @State private var appear = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    statusRow
                    approvalsStrip
                    briefingCard
                    tickerCard
                    suggestions
                    footer
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 28)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 12)
            }
            .scrollIndicators(.hidden)
            .navigationDestination(isPresented: $showApprovals) {
                ApprovalsView()
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) { appear = true }
            }
        }
    }

    // MARK: Kopf

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(store.proactiveEnabled ? store.accent : Color.orange)
                        .frame(width: 6, height: 6)
                        .shadow(color: store.accent, radius: 6)
                    Text(store.proactiveEnabled ? "PROAKTIV AKTIV" : "SCANS PAUSIERT")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1.3)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if store.isFounder {
                    StatusBadge(text: "FOUNDER", tint: store.accent, icon: "crown.fill")
                }
                Button {
                    Haptics.tap()
                    store.selectedTab = 3
                } label: {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .glassPill()
                }
                .buttonStyle(.plain)
            }

            Text(greeting)
                .font(.system(size: 31, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.white, .white.opacity(0.72)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .padding(.top, 6)

            HStack(spacing: 5) {
                Text(RelativeTime.weekdayLong(Date()))
                Text("·")
                Text("\(store.checkIns.count) Scans, letzter \(RelativeTime.string(from: store.lastScan).lowercased())")
            }
            .font(.system(size: 11.5, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 2)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "Guten Morgen, \(store.userName)"
        case 11..<15: return "Mahlzeit, \(store.userName)"
        case 15..<19: return "Guten Nachmittag, \(store.userName)"
        default: return "Guten Abend, \(store.userName)"
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            statusChip(icon: "hand.raised.fill",
                       value: "\(store.pendingApprovals.count)",
                       label: "Freigaben",
                       tint: store.pendingApprovals.isEmpty ? store.accent : Color(red: 1.0, green: 0.78, blue: 0.42)) {
                showApprovals = true
            }
            statusChip(icon: "square.stack.3d.up.fill",
                       value: "\(store.runningTasks.count)",
                       label: "Aufgaben",
                       tint: store.accent) {
                store.selectedTab = 1
            }
            statusChip(icon: "checkmark.seal.fill",
                       value: "\(store.audit.count)",
                       label: "Protokoll",
                       tint: Color(red: 0.72, green: 0.80, blue: 0.95)) {
                store.selectedTab = 1
            }
        }
    }

    private func statusChip(icon: String, value: String, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 0) {
                    Text(value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(label)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular.tint(tint.opacity(0.10)), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
                    }
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
                GlassCard(tint: nil, glow: false, padding: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(store.accent)
                        Text("Nichts offen. Tandem meldet sich, sobald etwas deine Entscheidung braucht.")
                            .font(.system(size: 12.5, design: .rounded))
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: approval.kind.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(approval.kind.tint)
                Text(approval.kind.title.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Circle().fill(approval.risk.color).frame(width: 6, height: 6)
            }
            Text(approval.title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            Text(approval.summary)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            HStack(spacing: 4) {
                Text("Prüfen")
                Image(systemName: "arrow.right")
                    .font(.system(size: 8, weight: .bold))
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(approval.kind.tint)
        }
        .padding(13)
        .frame(width: 208, height: 132, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular.tint(approval.kind.tint.opacity(0.12)),
                             in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [Color.white.opacity(0.28), Color.white.opacity(0.04)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                }
        }
    }

    // MARK: Briefing

    private var briefingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Morgen-Briefing", subtitle: nil, icon: "sun.horizon.fill",
                          trailing: RelativBriefing())

            GlassCard(tint: store.accent, glow: true, padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(store.briefing.focus)
                                .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("6 Quellen · Postfach, Kalender, GitHub, Gerät")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.tertiary)
                        }
                        Spacer(minLength: 0)
                        Button {
                            store.regenerateBriefing()
                        } label: {
                            ZStack {
                                Circle().fill(Color.white.opacity(0.10)).frame(width: 30, height: 30)
                                if store.isRegeneratingBriefing {
                                    ProgressView().controlSize(.mini).tint(.white)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(store.accent)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    weatherRow

                    Rectangle().fill(Color.white.opacity(0.10)).frame(height: 0.8)

                    VStack(spacing: 10) {
                        ForEach(store.briefing.agenda) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Text(item.time)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(item.highlight ? store.accent : .secondary)
                                    .frame(width: 38, alignment: .leading)
                                Image(systemName: item.icon)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(item.highlight ? store.accent : .secondary)
                                    .frame(width: 14)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.title)
                                        .font(.system(size: 12.5, weight: item.highlight ? .semibold : .medium, design: .rounded))
                                    Text(item.detail)
                                        .font(.system(size: 10.5, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }

                    if !store.briefing.todos.isEmpty {
                        Rectangle().fill(Color.white.opacity(0.10)).frame(height: 0.8)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("OFFEN")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(.tertiary)
                            ForEach(store.briefing.todos, id: \.self) { todo in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        if doneTodos.contains(todo) { doneTodos.remove(todo) } else { doneTodos.insert(todo) }
                                    }
                                    Haptics.tap()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: doneTodos.contains(todo) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 12))
                                            .foregroundStyle(doneTodos.contains(todo) ? store.accent : Color.white.opacity(0.3))
                                        Text(todo)
                                            .font(.system(size: 12, design: .rounded))
                                            .strikethrough(doneTodos.contains(todo), color: .secondary)
                                            .foregroundStyle(doneTodos.contains(todo) ? .secondary : .primary)
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
                            .foregroundStyle(.secondary)
                            .padding(.top, 1)
                        Text(store.briefing.nightNote)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func RelativBriefing() -> String {
        RelativeTime.string(from: store.briefing.generatedAt)
    }

    private var weatherRow: some View {
        HStack(spacing: 12) {
            Image(systemName: store.briefing.weatherIcon)
                .font(.system(size: 26, weight: .light))
                .symbolRenderingMode(.multicolor)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(store.briefing.temperature)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text(store.city)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Text(store.briefing.weather)
                    .font(.system(size: 11.5, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(store.briefing.weatherDetail)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 140, alignment: .trailing)
        }
    }

    // MARK: Proaktive Check-ins

    private var tickerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Hintergrund-Scans", subtitle: nil, icon: "dot.radiowaves.left.and.right",
                          trailing: "alle 15 Min.")
            GlassCard(tint: nil, glow: false, padding: 16) {
                VStack(spacing: 0) {
                    ForEach(Array(store.checkIns.prefix(5))) { checkIn in
                        HStack(alignment: .top, spacing: 10) {
                            ZStack {
                                Circle().fill(checkIn.tone.color.opacity(0.16)).frame(width: 26, height: 26)
                                Image(systemName: checkIn.icon)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(checkIn.tone.color)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(checkIn.title)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    Spacer(minLength: 0)
                                    Text(RelativeTime.string(from: checkIn.date))
                                        .font(.system(size: 9.5, design: .rounded))
                                        .foregroundStyle(.tertiary)
                                }
                                Text(checkIn.detail)
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, 8)
                        if checkIn.id != store.checkIns.prefix(5).last?.id {
                            Rectangle().fill(Color.white.opacity(0.07))
                                .frame(height: 0.7)
                                .padding(.leading, 36)
                        }
                    }
                }
            }
        }
    }

    // MARK: Vorschläge

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Dringende Vorschläge", subtitle: nil, icon: "sparkles", trailing: "1-Klick-Delegation")
            VStack(spacing: 10) {
                suggestionCard(icon: "envelope.fill",
                               tint: Color(red: 0.45, green: 0.72, blue: 1.0),
                               title: "Lisa antworten und Freitag zusagen",
                               detail: "Entwurf liegt fertig vor — 1 Freigabe, dann ist es raus.",
                               action: "Freigeben") {
                    showApprovals = true
                }
                suggestionCard(icon: "doc.badge.gearshape",
                               tint: store.accent,
                               title: "Changelog für Tandem v1.0.0",
                               detail: "Commits seit v0.9 clustern und Release-Notes schreiben.",
                               action: "Delegieren") {
                    store.createTask(goal: "Sammle alle Commits seit v0.9 und schreibe den Changelog für Tandem v1.0.0")
                }
                suggestionCard(icon: "phone.badge.checkmark",
                               tint: Color(red: 1.0, green: 0.78, blue: 0.42),
                               title: "Oma anrufen — Arzttermin Donnerstag",
                               detail: "Der Termin steht im Kalender, sie hat zuletzt gefragt.",
                               action: "Erinnern") {
                    store.createTask(title: "Erinnerung: Oma anrufen",
                                     goal: "Erinnere mich heute Abend daran, Oma wegen des Arzttermins am Donnerstag anzurufen")
                }
            }
        }
    }

    private func suggestionCard(icon: String, tint: Color, title: String, detail: String,
                                action: String, perform: @escaping () -> Void) -> some View {
        GlassCard(tint: tint, glow: false, padding: 15) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(tint)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Text(detail)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button(action: perform) {
                    Text(action)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background { Capsule().fill(tint.opacity(0.16)) }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
            Text("Tandem arbeitet im Hintergrund weiter — riskante Aktionen stoppen immer bei dir.")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
}
