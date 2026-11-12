import SwiftUI

/// Autonome Läufe mit sichtbaren Schritten, dazu Verlauf und Protokoll.
struct TasksView: View {
    @Environment(TandemStore.self) private var store
    @State private var segment = 0
    @State private var newTask = false

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
            .navigationTitle("Aufgaben")
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
            VStack(alignment: .leading, spacing: 12) {
                ViceBadge(text: "Vice City Agent Protocol", tint: VicePalette.magenta, icon: "bolt.fill")
                HStack(spacing: 13) {
                    ZStack {
                        Circle().stroke(VicePalette.cyan.opacity(0.18), lineWidth: 4).frame(width: 52, height: 52)
                        Circle()
                            .trim(from: 0, to: runningProgress)
                            .stroke(LinearGradient(colors: [VicePalette.cyan, VicePalette.magenta],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 52, height: 52)
                            .shadow(color: VicePalette.cyan.opacity(0.6), radius: 6)
                        Text("\(store.runningTasks.count)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .monospacedDigit()
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.runningTasks.isEmpty ? "Alles abgearbeitet" : "\(store.runningTasks.count) Aufgaben laufen")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Text("Autonomie: \(store.defaultAutonomy.title) · riskante Schritte halten immer an")
                            .font(.system(size: 11, design: .rounded))
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
                .fill(.clear)
                .glassEffect(.regular.tint(VicePalette.violet.opacity(0.22)), in: Capsule())
                .overlay {
                    Capsule().strokeBorder(
                        LinearGradient(colors: [VicePalette.magenta.opacity(0.55), VicePalette.cyan.opacity(0.45)],
                                       startPoint: .leading, endPoint: .trailing),
                        lineWidth: 0.9
                    )
                }
        }
    }

    private func segmentButton(_ title: String, index: Int, count: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { segment = index }
            Haptics.selection()
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Text("\(count)")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .opacity(0.7)
            }
            .foregroundStyle(segment == index ? Color.black.opacity(0.88) : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background {
                if segment == index {
                    Capsule()
                        .fill(store.accent.gradient)
                        .shadow(color: store.accent.opacity(0.7), radius: 10)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Aktiv

    @ViewBuilder
    private var activeList: some View {
        if store.runningTasks.isEmpty {
            GlassCard(tint: VicePalette.cyan, glow: false, padding: 22) {
                VStack(spacing: 10) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(VicePalette.cyan)
                        .shadow(color: VicePalette.cyan.opacity(0.7), radius: 10)
                    Text("Keine laufenden Aufgaben")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text("Tippe auf + und gib ein Ziel an — Tandem zerlegt es in Schritte.")
                        .font(.system(size: 11.5, design: .rounded))
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
        GlassCard(tint: task.status.color, glow: task.status == .running, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    ProgressRing(progress: task.progress, tint: task.status.color, size: 42)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(task.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 5) {
                            StatusBadge(text: task.status.title.uppercased(), tint: task.status.color,
                                        icon: task.status == .running ? "bolt.fill" : "pause.fill")
                            Text(task.autonomy.title)
                                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer(minLength: 0)
                    Text(RelativeTime.string(from: task.createdAt))
                        .font(.system(size: 9.5, design: .rounded))
                        .foregroundStyle(.tertiary)
                }

                VStack(spacing: 7) {
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
                                .font(.system(size: 9, weight: .bold))
                            Text(task.status == .paused ? "Weiter" : "Pause")
                        }
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background { Capsule().fill(Color.white.opacity(0.10)) }
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            store.cancelTask(task.id)
                        }
                    } label: {
                        Text("Abbrechen")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 1.0, green: 0.52, blue: 0.58))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background { Capsule().fill(Color.white.opacity(0.06)) }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if let step = task.currentStep {
                        Text(step.title)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private func stepRow(_ step: TaskStep, index: Int) -> some View {
        HStack(alignment: .top, spacing: 9) {
            ZStack {
                Circle()
                    .fill(stepColor(step.state).opacity(0.16))
                    .frame(width: 18, height: 18)
                if step.state == .running {
                    ProgressView().controlSize(.mini).tint(stepColor(step.state))
                } else {
                    Image(systemName: stepIcon(step.state))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(stepColor(step.state))
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("\(index + 1). \(step.title)")
                    .font(.system(size: 11.5, weight: step.state == .running ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(step.state == .pending ? .secondary : .primary)
                if !step.detail.isEmpty {
                    Text(step.detail)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func stepColor(_ state: TaskStep.State) -> Color {
        switch state {
        case .done: return Color(red: 0.50, green: 0.92, blue: 0.74)
        case .running: return store.accent
        case .failed: return Color(red: 1.0, green: 0.50, blue: 0.55)
        case .pending: return .secondary
        }
    }

    private func stepIcon(_ state: TaskStep.State) -> String {
        switch state {
        case .done: return "checkmark"
        case .running: return "arrow.right"
        case .failed: return "xmark"
        case .pending: return "circle.fill"
        }
    }

    // MARK: Verlauf

    @ViewBuilder
    private var historyList: some View {
        if store.history.isEmpty {
            GlassCard(tint: nil, glow: false, padding: 22) {
                Text("Noch keine abgeschlossenen Aufgaben.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(spacing: 10) {
                ForEach(store.history) { task in
                    GlassCard(tint: nil, glow: false, padding: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: task.status == .done ? "checkmark.circle.fill" : "minus.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(task.status.color)
                                Text(task.title)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                Spacer(minLength: 0)
                                Text(task.finishedAt.map { RelativeTime.string(from: $0) } ?? "—")
                                    .font(.system(size: 9.5, design: .rounded))
                                    .foregroundStyle(.tertiary)
                            }
                            if let summary = task.summary {
                                Text(summary)
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            HStack(spacing: 6) {
                                Text("\(task.steps.count) Schritte")
                                Text("·")
                                Text(task.autonomy.title)
                                Text("·")
                                Text(task.status.title)
                            }
                            .font(.system(size: 9.5, design: .rounded))
                            .foregroundStyle(.tertiary)
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
                        ZStack {
                            Circle().fill(event.kind.color.opacity(0.15)).frame(width: 24, height: 24)
                            Image(systemName: event.icon)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(event.kind.color)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(event.title)
                                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                Spacer(minLength: 0)
                                Text(RelativeTime.string(from: event.date))
                                    .font(.system(size: 9, design: .rounded))
                                    .foregroundStyle(.tertiary)
                            }
                            Text(event.detail)
                                .font(.system(size: 10.5, design: .rounded))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    if event.id != store.audit.last?.id {
                        Rectangle().fill(Color.white.opacity(0.06))
                            .frame(height: 0.6)
                            .padding(.leading, 43)
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
    @FocusState private var focused: Bool

    private let examples = [
        "Fasse meine Mails von heute zusammen",
        "Prüfe alle Repos auf rote CI",
        "Schreibe den Changelog für Tandem v1.0.0",
        "Ordne meinen Kalender nächste Woche",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Was soll ich übernehmen?")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                        Text("Ein Ziel reicht. Ich zerlege es in Schritte und halte an, sobald etwas deine Freigabe braucht.")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    GlassCard(tint: store.accent, glow: true) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ZIEL")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(.tertiary)
                            TextField("z. B. Fasse meine Mails von heute zusammen", text: $goal, axis: .vertical)
                                .font(.system(size: 14, design: .rounded))
                                .lineLimit(3...6)
                                .focused($focused)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Autonomie", subtitle: nil, icon: "slider.horizontal.3", trailing: nil)
                        ForEach(AutonomyLevel.allCases) { level in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { autonomy = level }
                                Haptics.selection()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: level.icon)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(level.tint)
                                        .frame(width: 22)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(level.title)
                                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                        Text(level.detail)
                                            .font(.system(size: 10.5, design: .rounded))
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: autonomy == level ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(autonomy == level ? store.accent : Color.white.opacity(0.2))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(autonomy == level ? store.accent.opacity(0.10) : Color.white.opacity(0.03))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(autonomy == level ? store.accent.opacity(0.4) : Color.white.opacity(0.08),
                                                              lineWidth: 0.9)
                                        }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("BEISPIELE")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 4)
                        FlowChips(items: examples) { item in
                            goal = item
                            Haptics.tap()
                        }
                    }
                }
                .padding(18)
            }
            .background(AmbientBackdrop(theme: store.themeChoice, accent: store.accent))
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
                        .font(.system(size: 11.5, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.09), lineWidth: 0.8)
                                }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
