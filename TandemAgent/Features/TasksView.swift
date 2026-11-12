import SwiftUI

/// Autonome Läufe: Status-Pille, Schritte mit Werkzeugnamen, aufklappbares
/// Ausführungsprotokoll dazu. Verlauf und Protokoll liegen daneben.
struct TasksView: View {
    @Environment(TandemStore.self) private var store
    @State private var segment = 0
    @State private var newTask = false
    @State private var expandedLogs: Set<UUID> = []

    init(showNewTask: Bool = false) {
        _newTask = State(initialValue: showNewTask)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    segmentPicker

                    switch segment {
                    case 0:
                        activeList
                    case 1:
                        historyList
                    default:
                        auditList
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Läufe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        newTask = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
            }
            .sheet(isPresented: $newTask) {
                NewTaskView()
            }
        }
    }

    private var header: some View {
        GlassCard(tint: store.accent, glow: true, padding: 16) {
            VStack(alignment: .leading, spacing: 13) {
                Insignia(text: "Agent Engine", tint: store.accent, icon: "point.3.connected.trianglepath.dotted")
                HStack(spacing: 13) {
                    ProgressRing(progress: runningProgress, tint: store.accent, size: 48, lineWidth: 3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.runningTasks.isEmpty ? "Alles abgearbeitet" : "\(store.runningTasks.count) Läufe aktiv")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Autonomie: \(store.defaultAutonomy.title) · riskante Schritte halten immer an")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var runningProgress: Double {
        guard !store.runningTasks.isEmpty else { return 0 }
        let total = store.runningTasks.reduce(0.0) { $0 + $1.progress }
        return total / Double(store.runningTasks.count)
    }

    private var segmentPicker: some View {
        HStack(spacing: 4) {
            segmentButton("Aktiv", index: 0, count: store.runningTasks.count)
            segmentButton("Verlauf", index: 1, count: store.history.count)
            segmentButton("Protokoll", index: 2, count: store.audit.count)
        }
        .padding(4)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay { Capsule().fill(Color.white.opacity(0.03)) }
        }
        .overlay {
            Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
        }
    }

    private func segmentButton(_ title: String, index: Int, count: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) { segment = index }
            Haptics.selection()
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Text("\(count)")
                    .font(.system(size: 9.5, weight: .semibold))
                    .monospacedDigit()
                    .opacity(0.6)
            }
            .foregroundStyle(segment == index ? Color(red: 0.04, green: 0.03, blue: 0.06) : Color.white.opacity(0.55))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background {
                if segment == index {
                    Capsule().fill(store.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Aktiv

    @ViewBuilder
    private var activeList: some View {
        if store.runningTasks.isEmpty {
            GlassCard(tint: nil, glow: false, padding: 24) {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(VicePalette.mint)
                    Text("Kein Lauf aktiv")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Tippe auf + und gib ein Ziel an — der Agent zerlegt es und ruft die Werkzeuge selbst auf.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            ForEach(store.runningTasks) { task in
                taskCard(task)
            }
        }
    }

    private func taskCard(_ task: AgentTask) -> some View {
        let tint = task.status.color
        let logOpen = expandedLogs.contains(task.id)
        return GlassCard(tint: tint, glow: task.status == .running, padding: 16) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(task.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.95))
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 6) {
                            statusPill(task)
                            Text(task.intent.title.uppercased())
                                .font(.system(size: 8.5, weight: .heavy))
                                .fontWidth(.condensed)
                                .tracking(1.0)
                                .foregroundStyle(Color.white.opacity(0.30))
                        }
                    }
                    Spacer(minLength: 0)
                    Text(RelativeTime.string(from: task.createdAt))
                        .font(.system(size: 9.5))
                        .foregroundStyle(Color.white.opacity(0.28))
                }

                MeterBar(progress: task.progress, tint: tint, height: 3)

                VStack(spacing: 8) {
                    ForEach(task.steps.indices, id: \.self) { index in
                        stepRow(task.steps[index], index: index)
                    }
                }

                HStack(spacing: 8) {
                    Button {
                        store.togglePause(task.id)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: task.status == .paused ? "play.fill" : "pause.fill")
                                .font(.system(size: 8, weight: .bold))
                            Text(task.status == .paused ? "Weiter" : "Pause")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.80))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background { Capsule().fill(Color.white.opacity(0.06)) }
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                            store.cancelTask(task.id)
                        }
                    } label: {
                        Text("Abbrechen")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(VicePalette.coral.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background { Capsule().fill(Color.white.opacity(0.04)) }
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            if logOpen { expandedLogs.remove(task.id) } else { expandedLogs.insert(task.id) }
                        }
                        Haptics.tap()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 9, weight: .semibold))
                            Text("Protokoll")
                                .font(.system(size: 10.5, weight: .medium))
                            Image(systemName: logOpen ? "chevron.up" : "chevron.down")
                                .font(.system(size: 7, weight: .bold))
                        }
                        .foregroundStyle(Color.white.opacity(0.50))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background { Capsule().fill(Color.white.opacity(0.05)) }
                    }
                    .buttonStyle(.plain)
                }

                if logOpen {
                    auditLog(task)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private func statusPill(_ task: AgentTask) -> some View {
        HStack(spacing: 3) {
            PulseDot(color: task.status.color, active: task.status == .running)
            Text(task.status.shortTitle.uppercased())
                .font(.system(size: 8.5, weight: .heavy))
                .fontWidth(.condensed)
                .tracking(1.0)
        }
        .foregroundStyle(task.status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule().fill(task.status.color.opacity(0.10))
        }
        .overlay {
            Capsule().strokeBorder(task.status.color.opacity(0.28), lineWidth: 0.5)
        }
        .animation(.easeInOut(duration: 0.5), value: task.status)
    }

    private func stepRow(_ step: TaskStep, index: Int) -> some View {
        HStack(alignment: .top, spacing: 9) {
            ZStack {
                Circle()
                    .stroke(stepColor(step.state).opacity(step.state == .pending ? 0.20 : 0.55), lineWidth: 1)
                    .frame(width: 16, height: 16)
                if step.state == .running {
                    ProgressView().controlSize(.mini).tint(stepColor(step.state))
                } else if step.state == .done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(stepColor(step.state))
                } else if step.state == .failed {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(stepColor(step.state))
                }
            }
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(step.title)
                        .font(.system(size: 11.5, weight: step.state == .running ? .semibold : .regular))
                        .foregroundStyle(step.state == .pending ? Color.white.opacity(0.34) : Color.white.opacity(0.86))
                    if let tool = step.tool {
                        Text(tool)
                            .font(.system(size: 8.5, design: .monospaced))
                            .foregroundStyle(AgentTool.tint(for: tool).opacity(0.75))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background { Capsule().fill(AgentTool.tint(for: tool).opacity(0.08)) }
                    }
                    Spacer(minLength: 0)
                }
                Text(step.result ?? step.detail)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(step.result == nil ? 0.26 : 0.40))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func stepColor(_ state: TaskStep.State) -> Color {
        switch state {
        case .done: return VicePalette.mint
        case .running: return store.accent
        case .failed: return VicePalette.coral
        case .pending: return Color.white.opacity(0.30)
        }
    }

    private func auditLog(_ task: AgentTask) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                Text("AUDIT LOG")
                    .font(.system(size: 8.5, weight: .heavy))
                    .fontWidth(.expanded)
                    .tracking(1.6)
                Spacer()
                Text("\(task.log.count) Einträge · \(task.completedCount)/\(task.steps.count) Schritte")
                    .font(.system(size: 8.5))
            }
            .foregroundStyle(Color.white.opacity(0.28))
            .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 7) {
                ForEach(task.log.suffix(14)) { entry in
                    HStack(alignment: .top, spacing: 7) {
                        Text(RelativeTime.clock(entry.date))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.24))
                            .frame(width: 34, alignment: .leading)
                        Image(systemName: entry.level.icon)
                            .font(.system(size: 6.5))
                            .foregroundStyle(entry.level.tint)
                            .padding(.top, 3)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.text)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.white.opacity(0.62))
                                .fixedSize(horizontal: false, vertical: true)
                            if let tool = entry.tool {
                                Text(tool)
                                    .font(.system(size: 8.5, design: .monospaced))
                                    .foregroundStyle(AgentTool.tint(for: tool).opacity(0.55))
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(11)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.22))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
        }
    }

    // MARK: Verlauf

    @ViewBuilder
    private var historyList: some View {
        if store.history.isEmpty {
            GlassCard(tint: nil, glow: false, padding: 22) {
                Text("Noch keine abgeschlossenen Läufe.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(spacing: 9) {
                ForEach(store.history) { task in
                    GlassCard(tint: nil, glow: false, padding: 14) {
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(spacing: 8) {
                                Image(systemName: task.status == .done ? "checkmark.circle.fill" : "minus.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(task.status.color)
                                Text(task.title)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.88))
                                Spacer(minLength: 0)
                                Text(task.finishedAt.map { RelativeTime.string(from: $0) } ?? "—")
                                    .font(.system(size: 9.5))
                                    .foregroundStyle(Color.white.opacity(0.26))
                            }
                            if let summary = task.summary {
                                Text(summary)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.white.opacity(0.44))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            HStack(spacing: 6) {
                                Text("\(task.steps.count) Schritte")
                                Text("·")
                                Text(task.intent.title)
                                Text("·")
                                Text(task.status.shortTitle)
                            }
                            .font(.system(size: 9.5))
                            .foregroundStyle(Color.white.opacity(0.26))
                        }
                    }
                }
            }
        }
    }

    // MARK: Protokoll

    private var auditList: some View {
        GlassCard(tint: nil, glow: false, padding: 8) {
            VStack(spacing: 0) {
                ForEach(store.audit) { event in
                    HStack(alignment: .top, spacing: 11) {
                        Image(systemName: event.icon)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(event.kind.color)
                            .frame(width: 22, height: 22)
                            .background {
                                Circle().fill(event.kind.color.opacity(0.10))
                            }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(event.title)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.82))
                                Spacer(minLength: 0)
                                Text(RelativeTime.string(from: event.date))
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.white.opacity(0.24))
                            }
                            Text(event.detail)
                                .font(.system(size: 10.5))
                                .foregroundStyle(Color.white.opacity(0.40))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 9)
                    if event.id != store.audit.last?.id {
                        Rectangle().fill(Color.white.opacity(0.05))
                            .frame(height: 0.5)
                            .padding(.leading, 41)
                    }
                }
            }
        }
    }
}

// MARK: - Neue Aufgabe

struct NewTaskView: View {
    @Environment(TandemStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var goal = ""
    @State private var autonomy: AutonomyLevel = .suggest
    @State private var preview: AgentPlan?
    @FocusState private var focused: Bool

    private let examples = [
        "Überwache die GTA-6-News und melde nur Änderungen",
        "Prüfe alle Repos auf rote CI",
        "Fasse mein Postfach zusammen und entwerfe Antworten",
        "Stelle mein Morgen-Briefing zusammen",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Was soll der Agent übernehmen?")
                            .font(.system(size: 21, weight: .semibold))
                        Text("Ein Ziel reicht. Der Agent wählt die Werkzeuge und hält an, sobald etwas deine Freigabe braucht.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    GlassCard(tint: store.accent, glow: true) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ZIEL")
                                .font(.system(size: 9, weight: .heavy))
                                .fontWidth(.expanded)
                                .tracking(1.5)
                                .foregroundStyle(Color.white.opacity(0.32))
                            TextField("z. B. Überwache die GTA-6-News", text: $goal, axis: .vertical)
                                .font(.system(size: 14))
                                .lineLimit(3...6)
                                .focused($focused)
                                .onChange(of: goal) { _, newValue in
                                    let cleaned = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                    preview = cleaned.count > 3 ? TaskPlanner.plan(for: cleaned) : nil
                                }
                        }
                    }

                    if let preview {
                        GlassCard(tint: VicePalette.cyan, glow: false, padding: 14) {
                            VStack(alignment: .leading, spacing: 9) {
                                HStack(spacing: 6) {
                                    Image(systemName: preview.intent.icon)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(VicePalette.cyan)
                                    Text("ERKANNTE ABSICHT")
                                        .font(.system(size: 8.5, weight: .heavy))
                                        .fontWidth(.expanded)
                                        .tracking(1.4)
                                        .foregroundStyle(Color.white.opacity(0.32))
                                    Spacer()
                                    Text(preview.intent.title)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(VicePalette.cyan)
                                }
                                ForEach(preview.steps.indices, id: \.self) { index in
                                    HStack(alignment: .top, spacing: 7) {
                                        Text("\(index + 1)")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundStyle(Color.white.opacity(0.28))
                                            .frame(width: 12, alignment: .leading)
                                        Text(preview.steps[index].title)
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.white.opacity(0.72))
                                        Spacer(minLength: 0)
                                        if let tool = preview.steps[index].tool {
                                            Text(tool)
                                                .font(.system(size: 8.5, design: .monospaced))
                                                .foregroundStyle(AgentTool.tint(for: tool).opacity(0.8))
                                        }
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Autonomie", subtitle: nil, icon: "slider.horizontal.3", trailing: nil)
                        ForEach(AutonomyLevel.allCases) { level in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) { autonomy = level }
                                Haptics.selection()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: level.icon)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(level.tint)
                                        .frame(width: 20)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(level.title)
                                            .font(.system(size: 12.5, weight: .medium))
                                        Text(level.detail)
                                            .font(.system(size: 10.5))
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: autonomy == level ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 13))
                                        .foregroundStyle(autonomy == level ? store.accent : Color.white.opacity(0.18))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(autonomy == level ? store.accent.opacity(0.08) : Color.white.opacity(0.02))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(autonomy == level ? store.accent.opacity(0.32) : Color.white.opacity(0.06),
                                                              lineWidth: 0.5)
                                        }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("BEISPIELE")
                            .font(.system(size: 9, weight: .heavy))
                            .fontWidth(.expanded)
                            .tracking(1.5)
                            .foregroundStyle(Color.white.opacity(0.28))
                            .padding(.horizontal, 4)
                        FlowChips(items: examples) { item in
                            goal = item
                            preview = TaskPlanner.plan(for: item)
                            Haptics.tap()
                        }
                    }
                }
                .padding(18)
            }
            .background(AmbientBackdrop(theme: store.themeChoice, accent: store.accent))
            .navigationTitle("Neuer Lauf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Starten") {
                        store.createTask(goal: goal, autonomy: autonomy)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                autonomy = store.defaultAutonomy
                focused = true
            }
        }
        .presentationDetents([.large])
    }
}

/// Einfache Chip-Reihe mit Umbruch.
struct FlowChips: View {
    var items: [String]
    var onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button {
                    onSelect(item)
                } label: {
                    Text(item)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color.white.opacity(0.80))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.035))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
                                }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
