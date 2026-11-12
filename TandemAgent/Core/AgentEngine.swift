import Foundation

/// Führt einen Plan aus. Die Engine ruft Schritt für Schritt ein Werkzeug
/// auf, schreibt jeden Aufruf ins Protokoll und legt alles Riskante als
/// Freigabe auf den Tisch, statt es selbst zu tun.
@MainActor
final class AgentEngine {
    private weak var store: TandemStore?
    private var runners: [UUID: Task<Void, Never>] = [:]

    init(store: TandemStore) {
        self.store = store
    }

    var runningIDs: [UUID] { Array(runners.keys) }

    func isRunning(_ id: UUID) -> Bool { runners[id] != nil }

    func launch(taskID: UUID) {
        guard runners[taskID] == nil else { return }
        runners[taskID] = Task { [weak self] in
            await self?.execute(taskID)
            self?.runners[taskID] = nil
        }
    }

    func cancel(taskID: UUID) {
        runners[taskID]?.cancel()
        runners[taskID] = nil
    }

    // MARK: Lauf

    private func execute(_ id: UUID) async {
        guard let store else { return }
        guard let task = store.tasks.first(where: { $0.id == id }) else { return }

        store.mutateTask(id) { value in
            value.status = .running
            if value.log.isEmpty {
                value.log.append(AgentLogEntry(level: .info, text: value.goal))
            }
        }
        store.appendLog(id, level: .info, text: "Ziel analysiert · Absicht: \(task.intent.title)")
        store.appendLog(id, level: .tool, text: "Plan gebaut · \(task.steps.count) Schritte", tool: "plan.build")

        var insights: [String] = []
        var approvals = 0

        var index = 0
        while index < (store.tasks.first(where: { $0.id == id })?.steps.count ?? 0) {
            if Task.isCancelled { return }

            // Pause respektieren, ohne den Lauf zu verlieren.
            while let current = store.tasks.first(where: { $0.id == id }), current.status == .paused {
                if Task.isCancelled { return }
                try? await Task.sleep(for: .milliseconds(420))
            }
            guard let current = store.tasks.first(where: { $0.id == id }),
                  current.status == .running else { return }

            let step = current.steps[index]
            store.mutateTask(id) { value in
                guard value.steps.indices.contains(index) else { return }
                value.steps[index].state = .running
            }
            store.appendLog(id, level: .tool,
                            text: step.title + " · " + (step.tool ?? "agent.step"),
                            tool: step.tool)

            try? await Task.sleep(for: .milliseconds(TaskPlanner.duration(for: step, index: index)))
            if Task.isCancelled { return }
            guard let stillRunning = store.tasks.first(where: { $0.id == id }),
                  stillRunning.status == .running else { return }

            let outcome = ToolRunner.run(step.tool ?? "", goal: current.goal,
                                         context: store.agentContext, step: index)
            store.mutateTask(id) { value in
                guard value.steps.indices.contains(index) else { return }
                value.steps[index].state = .done
                value.steps[index].result = outcome.summary
            }
            store.appendLog(id, level: .result, text: outcome.summary, tool: step.tool)
            for note in outcome.notes {
                store.appendLog(id, level: .info, text: note, tool: step.tool)
            }
            if let insight = outcome.insight {
                insights.append(insight)
            }
            if let approval = outcome.approval {
                if store.queue(approval, from: id) {
                    approvals += 1
                    store.appendLog(id, level: .approval,
                                    text: "Freigabe vorbereitet: \(approval.title)",
                                    tool: "approval.queue")
                }
            }

            index += 1
        }

        guard let finished = store.tasks.first(where: { $0.id == id }),
              finished.status == .running else { return }

        let summary = TaskPlanner.summary(for: finished.intent, insights: insights, approvals: approvals)
        store.appendLog(id, level: .result, text: summary, tool: "result.synthesis")
        store.finishTask(id, summary: summary)
    }
}
