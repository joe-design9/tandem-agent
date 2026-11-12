import SwiftUI

/// Das Herz der Sicherheit: jede riskante Aktion liegt hier als Karte,
/// mit allem, was du zum Entscheiden brauchst — Empfänger, Betreff,
/// Text, Risiko und der Grund, warum Tandem sie vorschlägt.
struct ApprovalsView: View {
    @Environment(TandemStore.self) private var store
    @State private var editing: ApprovalRequest?
    @State private var rejectTarget: ApprovalRequest?
    @State private var expanded: Set<UUID> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ruleCard

                if store.pendingApprovals.isEmpty {
                    emptyState
                } else {
                    SectionHeader(title: "Offen", subtitle: nil, icon: "hand.raised.fill",
                                  trailing: "\(store.pendingApprovals.count) warten")
                    ForEach(store.pendingApprovals) { approval in
                        approvalCard(approval)
                    }
                }

                if !store.decidedApprovals.isEmpty {
                    SectionHeader(title: "Entschieden", subtitle: nil, icon: "checkmark.seal.fill",
                                  trailing: "\(store.decidedApprovals.count)")
                    GlassCard(tint: nil, glow: false, padding: 6) {
                        VStack(spacing: 0) {
                            ForEach(store.decidedApprovals) { approval in
                                decidedRow(approval)
                                if approval.id != store.decidedApprovals.last?.id {
                                    Rectangle().fill(Color.white.opacity(0.07))
                                        .frame(height: 0.7)
                                        .padding(.leading, 44)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
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
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        store.reject(target.id)
                    }
                }
                rejectTarget = nil
            }
            Button("Zurück", role: .cancel) { rejectTarget = nil }
        } message: {
            Text("Nichts wird ausgeführt. Tandem merkt sich die Ablehnung im Protokoll.")
        }
    }

    private var ruleCard: some View {
        GlassCard(tint: VicePalette.magenta, glow: true, padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Insignia(text: "Human in the Loop", tint: VicePalette.magenta, icon: "shield.lefthalf.filled")
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [VicePalette.cyan, VicePalette.magenta],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 38, height: 38)
                            .shadow(color: VicePalette.cyan.opacity(0.6), radius: 10)
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(Color.black.opacity(0.8))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nichts geht ohne dein Ja raus")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Text("Tandem bereitet vor und wartet. E-Mails, Zahlungen, Kalenderänderungen und Löschungen laufen erst nach deiner Freigabe — jede Entscheidung landet im Protokoll.")
                            .font(.system(size: 11.5, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        GlassCard(tint: VicePalette.cyan, glow: true, padding: 22) {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(VicePalette.cyan)
                    .shadow(color: VicePalette.cyan.opacity(0.8), radius: 12)
                Text("Alles erledigt")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text("Keine offenen Freigaben. Tandem meldet sich, sobald etwas deine Entscheidung braucht.")
                    .font(.system(size: 11.5, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func approvalCard(_ approval: ApprovalRequest) -> some View {
        let isExpanded = expanded.contains(approval.id)
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Insignia(text: "Freigabe nötig", tint: approval.kind.tint, icon: "shield.lefthalf.filled")
                    Spacer(minLength: 0)
                    StatusBadge(text: approval.risk.title, tint: approval.risk.color,
                                icon: approval.risk == .high ? "exclamationmark.triangle.fill" : "shield.lefthalf.filled")
                }

                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(approval.kind.tint.opacity(0.20))
                            .frame(width: 34, height: 34)
                            .overlay {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .strokeBorder(approval.kind.tint.opacity(0.55), lineWidth: 0.8)
                            }
                        Image(systemName: approval.kind.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(approval.kind.tint)
                    }
                    .shadow(color: approval.kind.tint.opacity(0.45), radius: 8)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(approval.kind.title.uppercased())
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(approval.kind.tint)
                        Text(RelativeTime.string(from: approval.createdAt))
                            .font(.system(size: 9.5, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(approval.title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(approval.summary)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let amount = approval.amount {
                    HStack(spacing: 6) {
                        Image(systemName: "eurosign.circle.fill").font(.system(size: 12))
                        Text(amount)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                    .foregroundStyle(approval.risk.color)
                }

                if isExpanded {
                    previewBlock(approval)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                HStack(spacing: 6) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            if isExpanded { expanded.remove(approval.id) } else { expanded.insert(approval.id) }
                        }
                        Haptics.tap()
                    } label: {
                        HStack(spacing: 3) {
                            Text(isExpanded ? "Vorschau schließen" : "Vorschau ansehen")
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    if !approval.tool.isEmpty {
                        Text(approval.tool)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                }

                if let reason = approval.reason {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                            .foregroundStyle(store.accent)
                            .padding(.top, 2)
                        Text(reason)
                            .font(.system(size: 10.5, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                            store.approve(approval.id)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: approval.kind == .email ? "paperplane.fill" : "checkmark")
                                .font(.system(size: 10, weight: .bold))
                            Text(approval.kind == .email ? "Freigeben & Senden" : "Freigeben")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryGlassButtonStyle(tint: approval.kind.tint))

                    Button {
                        Haptics.tap()
                        editing = approval
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 13)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(SecondaryGlassButtonStyle())

                    Button {
                        Haptics.warning()
                        rejectTarget = approval
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                            Text("Ablehnen")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(VicePalette.coral.opacity(0.95))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(SecondaryGlassButtonStyle())
                }
            }
            .padding(16)
        }
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(approval.kind.tint.opacity(0.06))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [Color.white.opacity(0.28),
                                            approval.kind.tint.opacity(0.26),
                                            Color.white.opacity(0.03)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.5
                )
        }
        .shadow(color: Color.black.opacity(0.40), radius: 18, y: 9)
    }

    private func previewBlock(_ approval: ApprovalRequest) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let recipient = approval.recipient {
                HStack(spacing: 6) {
                    Text("An")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.tertiary)
                        .frame(width: 22, alignment: .leading)
                    Text(recipient)
                        .font(.system(size: 11.5, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
            if let subject = approval.subject {
                HStack(spacing: 6) {
                    Text("Betreff")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.tertiary)
                        .frame(width: 44, alignment: .leading)
                    Text(subject)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .lineLimit(2)
                }
            }
            if let body = approval.body {
                Text(body)
                    .font(.system(size: 11.5, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.90))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.black.opacity(0.28))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(VicePalette.cyan.opacity(0.25), lineWidth: 0.8)
                            }
                    }
            }
        }
    }

    private func decidedRow(_ approval: ApprovalRequest) -> some View {
        HStack(spacing: 10) {
            Image(systemName: approval.state == .executed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(approval.state == .executed
                                 ? Color(red: 0.40, green: 1.00, blue: 0.74)
                                 : VicePalette.hotPink)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(approval.title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .lineLimit(1)
                Text("\(approval.state.title) · \(approval.decidedAt.map { RelativeTime.clock($0) } ?? "—")")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
            Text(approval.kind.title)
                .font(.system(size: 9.5, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
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
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    GlassCard(tint: nil, glow: false) {
                        VStack(alignment: .leading, spacing: 12) {
                            if approval.recipient != nil {
                                editField(title: "An", text: Binding(
                                    get: { approval.recipient ?? "" },
                                    set: { approval.recipient = $0 }))
                            }
                            if approval.subject != nil {
                                editField(title: "Betreff", text: Binding(
                                    get: { approval.subject ?? "" },
                                    set: { approval.subject = $0 }))
                            }
                            if approval.body != nil {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("TEXT")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .tracking(1.2)
                                        .foregroundStyle(.tertiary)
                                    TextEditor(text: Binding(
                                        get: { approval.body ?? "" },
                                        set: { approval.body = $0 }))
                                        .font(.system(size: 13, design: .rounded))
                                        .scrollContentBackground(.hidden)
                                        .frame(minHeight: 180)
                                        .padding(8)
                                        .background {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.white.opacity(0.06))
                                        }
                                }
                            }
                        }
                    }
                    Text("Tandem behält deine Änderungen bei. Erst mit der Freigabe geht die Aktion raus.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                .padding(18)
            }
            .background(AmbientBackdrop(theme: store.themeChoice, accent: store.accent))
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

    private func editField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.tertiary)
            TextField(title, text: text)
                .font(.system(size: 13.5, design: .rounded))
                .padding(10)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                }
        }
    }
}
