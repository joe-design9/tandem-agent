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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ViceBadge(text: store.proactiveEnabled ? "Vice City Agent Protocol" : "Protocol Paused",
                          tint: store.proactiveEnabled ? VicePalette.magenta : VicePalette.coral,
                          icon: store.proactiveEnabled ? "bolt.fill" : "pause.fill")
                Spacer(minLength: 0)
                if store.isFounder {
                    StatusBadge(text: "VIP Founder", tint: VicePalette.gold, icon: "crown.fill")
                }
                Button {
                    Haptics.tap()
                    store.selectedTab = 3
                } label: {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(VicePalette.cyan)
                        .padding(8)
                        .glassPill(tint: VicePalette.cyan)
                }
                .buttonStyle(.plain)
            }

            WeazelTicker(items: ViceNews.headlines, tint: VicePalette.cyan)

            Text(greeting.uppercased())
                .font(.system(size: 27, weight: .black, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(
                    LinearGradient(colors: [.white,
                                            VicePalette.gold,
                                            VicePalette.coral,
                                            VicePalette.magenta],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: VicePalette.magenta.opacity(0.55), radius: 16)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.top, 2)

            HStack(spacing: 5) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 8.5))
                    .foregroundStyle(VicePalette.cyan)
                Text(RelativeTime.weekdayLong(Date()).uppercased())
                Text("·")
                Text("\(store.checkIns.count) Scans · letzter \(RelativeTime.string(from: store.lastScan))")
            }
            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
            .tracking(0.5)
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
                       tint: store.pendingApprovals.isEmpty ? VicePalette.cyan : VicePalette.gold) {
                showApprovals = true
            }
            statusChip(icon: "square.stack.3d.up.fill",
                       value: "\(store.runningTasks.count)",
                       label: "Aufgaben",
                       tint: VicePalette.magenta) {
                store.selectedTab = 1
            }
            statusChip(icon: "checkmark.seal.fill",
                       value: "\(store.audit.count)",
                       label: "Protokoll",
                       tint: VicePalette.coral) {
                store.selectedTab = 1
            }
        }
    }

    private func statusChip(icon: String, value: String, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(tint)
                    .shadow(color: tint.opacity(0.8), radius: 6)
                VStack(alignment: .leading, spacing: 0) {
                    Text(value)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text(label.uppercased())
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular.tint(tint.opacity(0.18)),
                                 in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                LinearGradient(colors: [tint.opacity(0.85), VicePalette.cyan.opacity(0.35)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: tint.opacity(0.35), radius: 12, y: 3)
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
                GlassCard(tint: VicePalette.cyan, glow: true, padding: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(VicePalette.cyan)
                            .shadow(color: VicePalette.cyan.opacity(0.8), radius: 8)
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
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(approval.kind.tint)
                    .shadow(color: approval.kind.tint.opacity(0.8), radius: 6)
                Text(approval.kind.title.uppercased())
                    .font(.system(size: 8.5, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Circle()
                    .fill(approval.risk.color)
                    .frame(width: 6, height: 6)
                    .shadow(color: approval.risk.color, radius: 5)
            }
            Text(approval.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            Text(approval.summary)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            HStack(spacing: 4) {
                Text("PRÜFEN")
                    .tracking(0.8)
                Image(systemName: "arrow.right")
                    .font(.system(size: 8, weight: .black))
            }
            .font(.system(size: 9.5, weight: .black, design: .rounded))
            .foregroundStyle(approval.kind.tint)
        }
        .padding(13)
        .frame(width: 208, height: 132, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular.tint(approval.kind.tint.opacity(0.16)),
                             in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [approval.kind.tint.opacity(0.75),
                                                    VicePalette.magenta.opacity(0.35),
                                                    VicePalette.cyan.opacity(0.55)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                }
                .shadow(color: approval.kind.tint.opacity(0.28), radius: 14, y: 4)
        }
    }

    // MARK: Briefing

    private var briefingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("LEONIDA MORNING DISPATCH")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.7)
                        .foregroundStyle(VicePalette.sunset)
                        .shadow(color: VicePalette.coral.opacity(0.55), radius: 10)
                    Text("Vice City Brief · \(RelativBriefing())")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .tracking(0.4)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                StatusBadge(text: "Live", tint: VicePalette.cyan, icon: "dot.radiowaves.left.and.right")
            }
            .padding(.horizontal, 4)

            GlassCard(tint: store.accent, glow: true, padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(store.briefing.focus)
                                .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 5) {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 8, weight: .bold))
                                Text("6 Quellen · Postfach, Kalender, GitHub, Gerät")
                                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                            }
                            .foregroundStyle(VicePalette.cyan.opacity(0.8))
                        }
                        Spacer(minLength: 0)
                        Button {
                            store.regenerateBriefing()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(VicePalette.cyan.opacity(0.14))
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        Circle().strokeBorder(VicePalette.cyan.opacity(0.55), lineWidth: 0.8)
                                    }
                                if store.isRegeneratingBriefing {
                                    ProgressView().controlSize(.mini).tint(.white)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(VicePalette.cyan)
                                }
                            }
                            .shadow(color: VicePalette.cyan.opacity(0.45), radius: 8)
                        }
                        .buttonStyle(.plain)
                    }

                    weatherRow

                    NeonDivider()

                    VStack(spacing: 10) {
                        ForEach(store.briefing.agenda) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Text(item.time)
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(item.highlight ? VicePalette.gold : .secondary)
                                    .frame(width: 38, alignment: .leading)
                                Image(systemName: item.icon)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(item.highlight ? VicePalette.coral : .secondary)
                                    .frame(width: 14)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.title)
                                        .font(.system(size: 12.5, weight: item.highlight ? .bold : .medium, design: .rounded))
                                    Text(item.detail)
                                        .font(.system(size: 10.5, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }

                    if !store.briefing.todos.isEmpty {
                        NeonDivider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("OFFEN")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .tracking(1.4)
                                .foregroundStyle(VicePalette.gold.opacity(0.85))
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
                                            .foregroundStyle(doneTodos.contains(todo) ? VicePalette.cyan : Color.white.opacity(0.3))
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
                            .foregroundStyle(VicePalette.violet)
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
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [VicePalette.gold.opacity(0.35), .clear],
                                         center: .center, startRadius: 2, endRadius: 30))
                    .frame(width: 46, height: 46)
                Image(systemName: store.briefing.weatherIcon)
                    .font(.system(size: 26, weight: .light))
                    .symbolRenderingMode(.multicolor)
            }
            .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text("LEONIDA WETTER")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(VicePalette.gold.opacity(0.9))
                }
                HStack(spacing: 6) {
                    Text(store.briefing.temperature)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                    Text(store.city)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.6)
                        .foregroundStyle(.secondary)
                }
                Text(store.briefing.weather)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(store.briefing.weatherDetail)
                .font(.system(size: 9.5, design: .rounded))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 132, alignment: .trailing)
        }
    }

    // MARK: Proaktive Check-ins

    private var tickerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "ViceNet Monitor", subtitle: nil, icon: "dot.radiowaves.left.and.right",
                          trailing: "Leonida Dispatch · 15 Min.")
            GlassCard(tint: VicePalette.magenta, glow: true, padding: 16) {
                VStack(spacing: 0) {
                    ForEach(Array(store.checkIns.prefix(5))) { checkIn in
                        HStack(alignment: .top, spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(checkIn.tone.color.opacity(0.18))
                                    .frame(width: 26, height: 26)
                                Image(systemName: checkIn.icon)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(checkIn.tone.color)
                            }
                            .shadow(color: checkIn.tone.color.opacity(0.5), radius: 6)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(checkIn.title)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                    Spacer(minLength: 0)
                                    Text(RelativeTime.string(from: checkIn.date))
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
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
                            NeonDivider()
                                .padding(.leading, 36)
                                .opacity(0.6)
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
                               tint: VicePalette.cyan,
                               title: "Lisa antworten und Freitag zusagen",
                               detail: "Entwurf liegt fertig vor — 1 Freigabe, dann ist es raus.",
                               action: "Freigeben") {
                    showApprovals = true
                }
                suggestionCard(icon: "doc.badge.gearshape",
                               tint: VicePalette.magenta,
                               title: "Changelog für Tandem 1.1.0",
                               detail: "Commits seit v1.0.0 clustern und Release-Notes schreiben.",
                               action: "Delegieren") {
                    store.createTask(goal: "Sammle alle Commits seit v1.0.0 und schreibe den Changelog für Tandem 1.1.0")
                }
                suggestionCard(icon: "phone.badge.checkmark",
                               tint: VicePalette.gold,
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
                        .fill(tint.opacity(0.20))
                        .frame(width: 36, height: 36)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(tint.opacity(0.55), lineWidth: 0.8)
                        }
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(tint)
                }
                .shadow(color: tint.opacity(0.35), radius: 8)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text(detail)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button(action: perform) {
                    Text(action.uppercased())
                        .font(.system(size: 9.5, weight: .black, design: .rounded))
                        .tracking(0.6)
                        .foregroundStyle(Color.black.opacity(0.85))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background {
                            Capsule()
                                .fill(tint)
                                .shadow(color: tint.opacity(0.6), radius: 8)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            PalmGlyph(tint: VicePalette.violet, rim: VicePalette.cyan)
                .frame(width: 44, height: 44)
                .shadow(color: VicePalette.magenta.opacity(0.45), radius: 12)
            Text("Tandem hält die Stadt im Blick — riskante Aktionen stoppen immer bei dir.")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .tracking(0.3)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
}
