import SwiftUI

/// Der Chat mit dem Agenten. Ruhig wie iMessage, sachlich wie Linear:
/// Ziel eingeben, Plan und Werkzeuge als eine einzige, aufklappbare Zeile,
/// darunter das Ergebnis als Text.
struct ChatView: View {
    @Environment(TandemStore.self) private var store
    @State private var draft = ""
    @State private var showApprovals = false
    @FocusState private var focused: Bool

    private let starters = [
        "Was steht heute an?",
        "Überwache die GTA-6-News",
        "Prüfe meine GitHub CI Pipelines",
        "Welche Freigaben warten?",
    ]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        if store.messages.isEmpty {
                            emptyState
                        } else {
                            ForEach(store.messages) { message in
                                messageView(message)
                                    .id(message.id)
                            }
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: store.messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
                }
                .onChange(of: store.messages.last?.text.count ?? 0) { _, _ in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { composer }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("Tandem")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Palette.textPrimary)
                        Text(store.isSimulator ? "Lokal" : store.engineLabel)
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.tap()
                        store.selectedTab = 0
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .accessibilityLabel("Zurück zu Heute")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            store.clearChat()
                        } label: {
                            Label("Verlauf leeren", systemImage: "trash")
                        }
                        Button {
                            store.selectedTab = 4
                        } label: {
                            Label("Modell wählen", systemImage: "cpu")
                        }
                        Button {
                            showApprovals = true
                        } label: {
                            Label("Freigaben", systemImage: "hand.raised")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16))
                    }
                }
            }
            .sheet(isPresented: $showApprovals) {
                NavigationStack { ApprovalsView() }
            }
            .toolbar(.hidden, for: .tabBar)
        }
    }

    // MARK: Nachrichten

    @ViewBuilder
    private func messageView(_ message: ChatMessage) -> some View {
        if message.role == .user {
            HStack {
                Spacer(minLength: 48)
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Palette.surfaceRaised)
                    }
                    .textSelection(.enabled)
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                if !message.tools.isEmpty {
                    ToolRunView(tools: message.tools)
                }

                if message.text.isEmpty {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("denkt nach")
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.textSecondary)
                    }
                } else {
                    RichText(markdown: message.text, accent: Palette.textSecondary)
                }

                if let card = message.card {
                    chatCard(card)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func chatCard(_ card: ChatCard) -> some View {
        Button {
            Haptics.tap()
            if card.kind == .approval {
                showApprovals = true
            } else {
                store.selectedTab = 1
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: card.icon)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.icon)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Palette.textPrimary)
                    Text(card.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                if let action = card.actionTitle {
                    Text(action)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.accent)
                }
            }
            .padding(13)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.surface)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Leerzustand

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Womit soll ich anfangen?")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                Text("Ein Ziel reicht. Ich plane die Schritte, führe die Werkzeuge aus und liefere das Ergebnis. Alles Riskante warte ich ab, bis du zustimmst.")
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 0) {
                flowRow(icon: "text.cursor", title: "Ziel eingeben", detail: "Ein Satz genügt")
                ThinDivider().padding(.leading, 38)
                flowRow(icon: "list.bullet.indent", title: "Plan ansehen", detail: "Schritte und Werkzeuge")
                ThinDivider().padding(.leading, 38)
                flowRow(icon: "checkmark.seal", title: "Ergebnis bekommen", detail: "Freigabe nur, wenn nötig")
            }
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Palette.surface)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Vorschläge")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.textTertiary)
                    .padding(.bottom, 4)
                ForEach(starters, id: \.self) { starter in
                    Button {
                        Haptics.tap()
                        store.send(starter)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.system(size: 12))
                                .foregroundStyle(Palette.textTertiary)
                            Text(starter)
                                .font(.system(size: 14))
                                .foregroundStyle(Palette.textPrimary)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    ThinDivider()
                }
            }
        }
        .padding(.top, 8)
    }

    private func flowRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Palette.icon)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.textPrimary)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: Eingabe

    private var composer: some View {
        VStack(spacing: 0) {
            if store.isThinking {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.mini)
                    Text("Agent arbeitet")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.textSecondary)
                    Spacer()
                    Button("Stopp") { store.stopStreaming() }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Palette.accent)
                        .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }

            HStack(alignment: .bottom, spacing: 9) {
                TextField("Ziel, Frage oder Auftrag", text: $draft, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1...5)
                    .focused($focused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Palette.surface)
                    }

                Button {
                    let text = draft
                    draft = ""
                    store.send(text)
                    Haptics.tap()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.onAccent)
                        .frame(width: 36, height: 36)
                        .background {
                            Circle().fill(Palette.accent)
                        }
                }
                .buttonStyle(.plain)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isThinking)
                .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(store.themeChoice.bottom.ignoresSafeArea(edges: .bottom))
    }
}

// MARK: - Werkzeug-Ausführung

/// Eine Zeile pro Agenten-Antwort: „3 Schritte ausgeführt". Tippen klappt
/// die Werkzeuge auf. Kein Neon, keine Karten — nur Text und Haken.
struct ToolRunView: View {
    var tools: [ToolCall]
    @State private var expanded = false

    private var running: Bool {
        tools.contains { $0.state == .running }
    }

    private var summary: String {
        if running {
            return "Arbeitet · \(tools.count) \(tools.count == 1 ? "Schritt" : "Schritte")"
        }
        let failed = tools.filter { $0.state == .failed }.count
        if failed > 0 {
            return "\(failed) von \(tools.count) fehlgeschlagen"
        }
        return "\(tools.count) \(tools.count == 1 ? "Schritt" : "Schritte") ausgeführt"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Haptics.tap()
                withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    if running {
                        ProgressView().controlSize(.mini)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Palette.accent)
                    }
                    Text(summary)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.textSecondary)
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Palette.textTertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(tools) { tool in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: statusIcon(tool.state))
                                .font(.system(size: 10))
                                .foregroundStyle(tool.state == .failed ? Palette.danger : Palette.textTertiary)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(tool.label)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Palette.textSecondary)
                                HStack(spacing: 6) {
                                    Text(tool.name)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(Palette.textTertiary)
                                    if let result = tool.result {
                                        Text("· \(result)")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Palette.textTertiary)
                                    }
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.leading, 2)
                .transition(.opacity)
            }
        }
    }

    private func statusIcon(_ state: ToolCall.State) -> String {
        switch state {
        case .running: return "circle.dotted"
        case .done: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }
}
