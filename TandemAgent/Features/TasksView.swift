import SwiftUI

/// Die Läufe des Agenten: was gerade läuft, was fertig ist und was im
/// Protokoll steht. Eine ruhige Liste, Details nur auf Wunsch.
struct TasksView: View {
    @Environment(TandemStore.self) private var store
    @State private var segment = 0
    @State private var showNewTask = false
    @State private var expanded: Set<UUID> = []

    init(showNewTask: Bool = false) {
        _showNewTask = State(initialValue: showNewTask)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Ansicht", selection: $segment) {
                        Text("Aktiv").tag(0)
                        Text("Verlauf").tag(1)
                        Text("Protokoll").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                }

                switch segment {
                case 0:
                    activeSection
                case 1:
                    historySection
                default:
                    auditSection
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppBackground(theme: store.themeChoice, accent: store.accent))
            .navigationTitle("Aufgaben")
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
        }
    }

    // MARK: Aktiv

    @ViewBuilder
    private var activeSection: some View {
        if store.runningTasks.isEmpty {
            Section {
                EmptyState(icon: "checkmark.circle",
                           title: "Kein Lauf aktiv",
                           message: "Tippe auf + und beschreibe ein Ziel. Ich plane die Schritte und arbeite sie ab.")
            }
        } else {
            Section {
                ForEach(store.runningTasks) { task in
                    taskRow(task)
                }
            } header: {
                Text("Aktiv")
            }
        }
    }

    private func taskRow(_ task: AgentTask) -> some View {
        DisclosureGroup(isExpanded: binding(for: task.id)) {
            taskDetail(task)
                .padding(.top, 10)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(task.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 6)
                    Text("\(Int(task.progress * 100)) %")
                        .font(.system(size: 13))
                        .monospacedDigit()
                        .foregroundStyle(Palette.textSecondary)
                }
                HStack(spacing: 8) {
                    StatusTag(task.status.shortTitle, tone: task.status.tone)
                    Text("\(task.intent.title) · \(RelativeTime.duration(from: task.createdAt))")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.textTertiary)
                }
            }
            .padding(.vertical, 4)
        }
        .tint(Palette.textSecondary)
        .listRowBackground(Palette.surface)
    }

    private func taskDetail(_ task: AgentTask) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 9) {
                ForEach(task.steps) { step in
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: stepIcon(step.state))
                            .font(.system(size: 12))
                            .foregroundStyle(step.state == .running ? Palette.accent : Palette.textTertiary)
                            .frame(width: 16)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(step.title)
                                .font(.system(size: 13))
                                .foregroundStyle(step.state == .pending ? Palette.textTertiary : Palette.textPrimary)
                            Text(step.result ?? step.detail)
                                .font(.system(size: 12))
                                .foregroundStyle(Palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            if let tool = step.tool {
                                Text(tool)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Palette.textTertiary)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
            }

            ThinDivider()

            HStack(spacing: 8) {
                Button {
                    Haptics.tap()
                    store.togglePause(task.id)
                } label: {
                    Label(task.status == .paused ? "Weiter" : "Pause",
                          systemImage: task.status == .paused ? "play" : "pause")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Palette.textPrimary)

                Button {
                    Haptics.tap()
                    store.cancelTask(task.id)
                } label: {
                    Label("Abbrechen", systemImage: "xmark")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Palette.danger)

                Spacer(minLength: 0)
            }

            if !task.log.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Protokoll")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Palette.textTertiary)
                    ForEach(task.log.suffix(6)) { entry in
                        HStack(alignment: .top, spacing: 8) {
                            Text(RelativeTime.clock(entry.date))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Palette.textTertiary)
                                .frame(width: 36, alignment: .leading)
                            Text(entry.text)
                                .font(.system(size: 12))
                                .foregroundStyle(Palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    private func binding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { expanded.contains(id) },
            set: { newValue in
                if newValue { expanded.insert(id) } else { expanded.remove(id) }
            }
        )
    }

    private func stepIcon(_ state: TaskStep.State) -> String {
        switch state {
        case .pending: return "circle"
        case .running: return "circle.dotted"
        case .done: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }

    // MARK: Verlauf

    @ViewBuilder
    private var historySection: some View {
        if store.history.isEmpty {
            Section {
                EmptyState(icon: "clock",
                           title: "Noch nichts abgeschlossen",
                           message: "Fertige Läufe erscheinen hier mit ihrer Zusammenfassung.")
            }
        } else {
            Section("Verlauf") {
                ForEach(store.history) { task in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(task.title)
                                .font(.system(size: 15))
                                .foregroundStyle(Palette.textPrimary)
                            Spacer(minLength: 6)
                            Text(task.finishedAt.map { RelativeTime.string(from: $0) } ?? "")
                                .font(.system(size: 12))
                                .foregroundStyle(Palette.textTertiary)
                        }
                        if let summary = task.summary {
                            Text(summary)
                                .font(.system(size: 13))
                                .foregroundStyle(Palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Text("\(task.status.title) · \(task.steps.count) Schritte · \(RelativeTime.duration(from: task.createdAt, to: task.finishedAt))")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.textTertiary)
                    }
                    .padding(.vertical, 3)
                    .listRowBackground(Palette.surface)
                }
            }
        }
    }

    // MARK: Protokoll

    @ViewBuilder
    private var auditSection: some View {
        if store.audit.isEmpty {
            Section {
                EmptyState(icon: "list.bullet.rectangle",
                           title: "Noch keine Ereignisse",
                           message: "Jede Freigabe und jeder Werkzeugaufruf landet hier.")
            }
        } else {
            Section("Protokoll") {
                ForEach(store.audit) { event in
                    HStack(alignment: .top, spacing: 11) {
                        Image(systemName: event.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.icon)
                            .frame(width: 20)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(event.title)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Palette.textPrimary)
                                Spacer(minLength: 6)
                                Text(RelativeTime.string(from: event.date))
                                    .font(.system(size: 11))
                                    .foregroundStyle(Palette.textTertiary)
                            }
                            Text(event.detail)
                                .font(.system(size: 12))
                                .foregroundStyle(Palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 2)
                    .listRowBackground(Palette.surface)
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
            Form {
                Section {
                    TextField("Was soll ich übernehmen?", text: $goal, axis: .vertical)
                        .font(.system(size: 15))
                        .lineLimit(3...6)
                        .focused($focused)
                        .onChange(of: goal) { _, newValue in
                            let cleaned = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            preview = cleaned.count > 3 ? TaskPlanner.plan(for: cleaned) : nil
                        }
                } header: {
                    Text("Ziel")
                } footer: {
                    Text("Ein Satz reicht. Ich wähle die Werkzeuge selbst und halte an, sobald etwas deine Freigabe braucht.")
                }

                if let preview {
                    Section("Geplanter Ablauf") {
                        ForEach(preview.steps.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(Palette.textTertiary)
                                    .frame(width: 16, alignment: .leading)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(preview.steps[index].title)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Palette.textPrimary)
                                    if let tool = preview.steps[index].tool {
                                        Text(tool)
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundStyle(Palette.textTertiary)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }

                Section("Autonomie") {
                    ForEach(AutonomyLevel.allCases) { level in
                        Button {
                            Haptics.selection()
                            autonomy = level
                        } label: {
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.title)
                                        .font(.system(size: 15))
                                        .foregroundStyle(Palette.textPrimary)
                                    Text(level.detail)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Palette.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 8)
                                if autonomy == level {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Palette.accent)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Beispiele") {
                    ForEach(examples, id: \.self) { example in
                        Button {
                            Haptics.tap()
                            goal = example
                            preview = TaskPlanner.plan(for: example)
                        } label: {
                            Text(example)
                                .font(.system(size: 14))
                                .foregroundStyle(Palette.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground(theme: store.themeChoice, accent: store.accent))
            .navigationTitle("Neue Aufgabe")
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
