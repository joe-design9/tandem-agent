import SwiftUI

/// Der Startbildschirm: Begrüßung, ein ruhiger Überblick, die Läufe von
/// heute und drei Wege, den Agenten direkt loszuschicken.
struct HomeView: View {
    @Environment(TandemStore.self) private var store
    @State private var showNewTask = false
    @State private var showApprovals = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 26) {
                    dateLine
                    overview
                    approvalsSection
                    tasksSection
                    quickStart
                    recentSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .navigationTitle(greetingLine)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showNewTask = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .accessibilityLabel("Neue Aufgabe")
                }
            }
            .sheet(isPresented: $showNewTask) {
                NewTaskView()
            }
            .navigationDestination(isPresented: $showApprovals) {
                ApprovalsView()
            }
        }
    }

    // MARK: Begrüßung

    private var dateLine: some View {
        Text("\(RelativeTime.weekdayLong(Date())) · \(store.isSimulator ? "Lokal" : store.provider.title)")
            .font(.system(size: 13))
            .foregroundStyle(Palette.textSecondary)
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "Guten Morgen, \(store.userName)"
        case 11..<18: return "Guten Tag, \(store.userName)"
        default: return "Guten Abend, \(store.userName)"
        }
    }

    // MARK: Überblick

    private var overview: some View {
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Heute im Fokus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Palette.textTertiary)
                    Text(store.briefing.focus)
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ThinDivider()

                HStack(alignment: .top, spacing: 0) {
                    metric(value: "\(store.pendingApprovals.count)", label: "Freigaben")
                    metricDivider
                    metric(value: "\(store.runningTasks.count)", label: "Läufe")
                    metricDivider
                    metric(value: "\(store.audit.count)", label: "Ereignisse")
                }

                ThinDivider()

                HStack(spacing: 10) {
                    Image(systemName: store.briefing.weatherIcon)
                        .font(.system(size: 17, weight: .regular))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Palette.icon)
                    Text(store.briefing.weather)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(store.city)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.textTertiary)
                }
            }
        }
    }

    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 21, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Palette.textPrimary)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(width: 0.5, height: 30)
            .padding(.horizontal, 12)
    }

    // MARK: Freigaben

    @ViewBuilder
    private var approvalsSection: some View {
        if !store.pendingApprovals.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionLabel(title: "Wartet auf dich")
                    Spacer()
                    Button("Alle ansehen") {
                        Haptics.tap()
                        showApprovals = true
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.accent)
                }

                Card(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(store.pendingApprovals.prefix(2)) { approval in
                            Button {
                                Haptics.tap()
                                showApprovals = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: approval.kind.icon)
                                        .font(.system(size: 15))
                                        .foregroundStyle(Palette.icon)
                                        .frame(width: 22)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(approval.title)
                                            .font(.system(size: 15))
                                            .foregroundStyle(Palette.textPrimary)
                                            .lineLimit(1)
                                        Text(approval.summary)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Palette.textSecondary)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Palette.textTertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if approval.id != store.pendingApprovals.prefix(2).last?.id {
                                ThinDivider().padding(.leading, 50)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Läufe

    @ViewBuilder
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel(title: "Läufe")
                Spacer()
                Button("Alle") {
                    Haptics.tap()
                    store.selectedTab = 1
                }
                .font(.system(size: 13))
                .foregroundStyle(Palette.accent)
            }

            if store.runningTasks.isEmpty {
                Card(padding: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.icon)
                            .frame(width: 22)
                        Text("Kein Lauf aktiv")
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 15)
                }
            } else {
                Card(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(store.runningTasks.prefix(3)) { task in
                            Button {
                                Haptics.tap()
                                store.selectedTab = 1
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: statusIcon(task.status))
                                        .font(.system(size: 15))
                                        .foregroundStyle(task.status == .running ? Palette.accent : Palette.icon)
                                        .frame(width: 22)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title)
                                            .font(.system(size: 15))
                                            .foregroundStyle(Palette.textPrimary)
                                            .lineLimit(1)
                                        Text("\(task.status.title) · \(RelativeTime.duration(from: task.createdAt))")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Palette.textSecondary)
                                    }
                                    Spacer(minLength: 0)
                                    Text("\(Int(task.progress * 100)) %")
                                        .font(.system(size: 13))
                                        .monospacedDigit()
                                        .foregroundStyle(Palette.textTertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if task.id != store.runningTasks.prefix(3).last?.id {
                                ThinDivider().padding(.leading, 50)
                            }
                        }
                    }
                }
            }
        }
    }

    private func statusIcon(_ status: AgentTask.Status) -> String {
        switch status {
        case .running: return "circle.dotted"
        case .paused: return "pause.circle"
        case .queued: return "clock"
        case .done: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }

    // MARK: Schnell starten

    private var quickStart: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: "Schnell starten")

            Card(padding: 0) {
                VStack(spacing: 0) {
                    quickStartRow(icon: "newspaper",
                                  title: "GTA-6-News prüfen",
                                  detail: "Nur melden, was sich wirklich ändert") {
                        store.createTask(goal: "Überwache die GTA-6-News und melde nur, was sich wirklich ändert")
                    }
                    ThinDivider().padding(.leading, 50)
                    quickStartRow(icon: "chevron.left.forwardslash.chevron.right",
                                  title: "GitHub CI prüfen",
                                  detail: "Alle Repos, rote Läufe zuerst") {
                        store.createTask(goal: "Prüfe meine GitHub CI Pipelines und sage mir, was rot ist")
                    }
                    ThinDivider().padding(.leading, 50)
                    quickStartRow(icon: "sun.horizon",
                                  title: "Morgen-Briefing bauen",
                                  detail: "Kalender, Postfach und Wetter") {
                        store.createTask(goal: "Stelle mein Morgen-Briefing aus Kalender, Postfach und Wetter zusammen")
                    }
                }
            }
        }
    }

    private func quickStartRow(icon: String, title: String, detail: String,
                               perform: @escaping () -> Void) -> some View {
        Button {
            Haptics.soft()
            perform()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.icon)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.textPrimary)
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer(minLength: 8)
                Text("Starten")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Zuletzt geprüft

    /// Ältere Check-ins tragen ihre Zeit im Titel („News-Scan vor 6 Min.“) —
    /// die Zeile zeigt sie rechts, also hier abschneiden.
    private func checkInTitle(_ checkIn: CheckIn) -> String {
        if let range = checkIn.title.range(of: " vor ", options: .backwards) {
            return String(checkIn.title[..<range.lowerBound])
        }
        return checkIn.title
    }

    @ViewBuilder
    private var recentSection: some View {
        if !store.checkIns.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(title: "Zuletzt geprüft")

                Card(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(store.checkIns.prefix(3)) { checkIn in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: checkIn.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Palette.icon)
                                    .frame(width: 22)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(checkInTitle(checkIn))
                                        .font(.system(size: 14))
                                        .foregroundStyle(Palette.textPrimary)
                                    Text(checkIn.detail)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Palette.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 8)
                                Text(RelativeTime.string(from: checkIn.date))
                                    .font(.system(size: 11))
                                    .foregroundStyle(Palette.textTertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            if checkIn.id != store.checkIns.prefix(3).last?.id {
                                ThinDivider().padding(.leading, 50)
                            }
                        }
                    }
                }
            }
        }
    }
}
