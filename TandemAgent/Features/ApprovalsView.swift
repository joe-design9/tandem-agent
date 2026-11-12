import SwiftUI

/// Freigaben: alles, was der Agent vorbereitet hat und nicht ohne dein Ja
/// ausführt. Lesbar, knapp, mit vollständiger Vorschau.
struct ApprovalsView: View {
    @Environment(TandemStore.self) private var store
    @State private var editing: ApprovalRequest?
    @State private var rejectTarget: ApprovalRequest?
    @State private var expanded: Set<UUID> = []

    var body: some View {
        List {
            if store.pendingApprovals.isEmpty {
                Section {
                    EmptyState(icon: "checkmark.circle",
                               title: "Nichts offen",
                               message: "Sobald etwas deine Entscheidung braucht, liegt es hier.")
                } footer: {
                    Text("E-Mails, Zahlungen, Kalenderänderungen und Löschungen laufen erst nach deiner Freigabe.")
                }
            } else {
                Section {
                    ForEach(store.pendingApprovals) { approval in
                        approvalRow(approval)
                    }
                } header: {
                    Text("Offen")
                } footer: {
                    Text("Nichts geht ohne dein Ja raus. Jede Entscheidung landet im Protokoll.")
                }
            }

            if !store.decidedApprovals.isEmpty {
                Section("Entschieden") {
                    ForEach(store.decidedApprovals) { approval in
                        decidedRow(approval)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppBackground(theme: store.themeChoice, accent: store.accent))
        .navigationTitle("Freigaben")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { approval in
            ApprovalEditView(approval: approval) { updated in
                store.updateApproval(updated)
                editing = nil
            }
        }
        .confirmationDialog("Freigabe ablehnen?",
                            isPresented: Binding(get: { rejectTarget != nil },
                                                 set: { if !$0 { rejectTarget = nil } }),
                            titleVisibility: .visible) {
            Button("Ablehnen", role: .destructive) {
                if let target = rejectTarget {
                    store.reject(target.id)
                }
                rejectTarget = nil
            }
            Button("Zurück", role: .cancel) { rejectTarget = nil }
        } message: {
            Text("Nichts wird ausgeführt. Die Ablehnung steht danach im Protokoll.")
        }
    }

    // MARK: Karte

    private func approvalRow(_ approval: ApprovalRequest) -> some View {
        let isExpanded = expanded.contains(approval.id)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: approval.kind.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.icon)
                Text(approval.kind.title)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textSecondary)
                Spacer(minLength: 6)
                Text(approval.risk.title)
                    .font(.system(size: 11))
                    .foregroundStyle(approval.risk == .high ? Palette.danger : Palette.textTertiary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(approval.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(approval.summary)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let amount = approval.amount {
                Text(amount)
                    .font(.system(size: 16, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(Palette.textPrimary)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if let recipient = approval.recipient {
                        previewLine(label: "An", value: recipient)
                    }
                    if let subject = approval.subject {
                        previewLine(label: "Betreff", value: subject)
                    }
                    if let body = approval.body {
                        Text(body)
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(11)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Palette.surfaceSunken)
                            }
                    }
                }
            }

            HStack(spacing: 8) {
                Button(isExpanded ? "Vorschau schließen" : "Vorschau ansehen") {
                    Haptics.tap()
                    withAnimation(.easeInOut(duration: 0.18)) {
                        if isExpanded { expanded.remove(approval.id) } else { expanded.insert(approval.id) }
                    }
                }
                .font(.system(size: 13))
                .foregroundStyle(Palette.textSecondary)
                .buttonStyle(.plain)

                Spacer(minLength: 6)

                Text(approval.tool)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Palette.textTertiary)
            }

            if let reason = approval.reason {
                HStack(alignment: .top, spacing: 7) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.textTertiary)
                        .padding(.top, 1)
                    Text(reason)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                Button {
                    Haptics.success()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.approve(approval.id)
                    }
                } label: {
                    Text(approval.kind == .email ? "Freigeben & senden" : "Freigeben")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    Haptics.tap()
                    editing = approval
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.textPrimary)
                        .frame(width: 38, height: 38)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Palette.surfaceRaised)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Bearbeiten")

                Button {
                    Haptics.warning()
                    rejectTarget = approval
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.danger)
                        .frame(width: 38, height: 38)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Palette.surfaceRaised)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ablehnen")
            }
        }
        .padding(.vertical, 6)
        .listRowBackground(Palette.surface)
    }

    private func previewLine(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Palette.textTertiary)
                .frame(width: 48, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func decidedRow(_ approval: ApprovalRequest) -> some View {
        HStack(spacing: 10) {
            Image(systemName: approval.state == .executed ? "checkmark.circle" : "xmark.circle")
                .font(.system(size: 14))
                .foregroundStyle(approval.state == .executed ? Palette.accent : Palette.danger)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(approval.title)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                Text("\(approval.state.title) · \(approval.decidedAt.map { RelativeTime.clock($0) } ?? "")")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .listRowBackground(Palette.surface)
    }
}

// MARK: - Bearbeiten

struct ApprovalEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TandemStore.self) private var store

    @State var approval: ApprovalRequest
    var onSave: (ApprovalRequest) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if approval.recipient != nil {
                        TextField("An", text: Binding(
                            get: { approval.recipient ?? "" },
                            set: { approval.recipient = $0 }))
                    }
                    if approval.subject != nil {
                        TextField("Betreff", text: Binding(
                            get: { approval.subject ?? "" },
                            set: { approval.subject = $0 }))
                    }
                }

                if approval.body != nil {
                    Section("Text") {
                        TextEditor(text: Binding(
                            get: { approval.body ?? "" },
                            set: { approval.body = $0 }))
                            .font(.system(size: 14))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 220)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground(theme: store.themeChoice, accent: store.accent))
            .navigationTitle("Bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Haptics.success()
                        var updated = approval
                        updated.note = "Von dir bearbeitet"
                        onSave(updated)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }
}
