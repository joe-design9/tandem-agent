import SwiftUI

/// Der Chat mit dem Agenten: Werkzeug-Karten statt Textwüste. Man sieht,
/// was geplant, welches Werkzeug aufgerufen und welches Ergebnis
/// synthetisiert wurde.
struct ChatView: View {
    @Environment(TandemStore.self) private var store
    @State private var draft = ""
    @State private var showApprovals = false
    @FocusState private var focused: Bool

    private let starters = [
        "Überwache die GTA-6-News",
        "Prüfe meine GitHub CI Pipelines",
        "Was steht heute an?",
        "Welche Freigaben warten?",
        "Was weißt du über mich?",
    ]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
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
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: store.messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("bottom", anchor: .bottom) }
                }
                .onChange(of: store.messages.last?.text.count ?? 0) { _, _ in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { composer }
            .navigationTitle("Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("TANDEM")
                            .font(.system(size: 11, weight: .heavy))
                            .fontWidth(.expanded)
                            .tracking(2.4)
                        HStack(spacing: 4) {
                            Circle().fill(store.accent).frame(width: 4, height: 4)
                            Text(store.isSimulator ? "Simulator · offline" : store.engineLabel)
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
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
                            Label("Modell wechseln", systemImage: "cpu")
                        }
                        Button {
                            showApprovals = true
                        } label: {
                            Label("Freigaben", systemImage: "hand.raised")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 15))
                    }
                }
            }
            .sheet(isPresented: $showApprovals) {
                NavigationStack { ApprovalsView() }
            }
        }
    }

    // MARK: Nachrichten

    @ViewBuilder
    private func messageView(_ message: ChatMessage) -> some View {
        if message.role == .user {
            HStack {
                Spacer(minLength: 44)
                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.96))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LinearGradient(colors: [store.accent.opacity(0.62),
                                                          store.accentChoice.deep.opacity(0.85)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.160), lineWidth: 0.5)
                            }
                    }
            }
        } else {
            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(store.accent)
                        .frame(width: 5, height: 5)
                        .shadow(color: store.accent.opacity(0.9), radius: 4)
                    Text("AGENT")
                        .font(.system(size: 8.5, weight: .heavy))
                        .fontWidth(.expanded)
                        .tracking(2.0)
                        .foregroundStyle(Color.white.opacity(0.42))
                    if let engine = message.engine {
                        Text(engine)
                            .font(.system(size: 8.5))
                            .foregroundStyle(Color.white.opacity(0.24))
                    }
                    Spacer(minLength: 0)
                }

                if !message.tools.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(message.tools) { tool in
                            toolCard(tool)
                        }
                    }
                }

                if message.text.isEmpty {
                    typingIndicator
                } else {
                    RichText(markdown: message.text, accent: store.accent)
                }

                if let card = message.card {
                    chatCard(card)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.02))
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [Color.white.opacity(0.22), Color.white.opacity(0.04)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.5
                    )
            }
        }
    }

    /// Eine Werkzeug-Karte: `[Planung aktiv…]` → `[Tool: repo.check]` → Ergebnis.
    private func toolCard(_ tool: ToolCall) -> some View {
        let tint = AgentTool.tint(for: tool.name)
        return HStack(spacing: 9) {
            Group {
                if tool.state == .running {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(tint)
                } else {
                    Image(systemName: tool.state == .done ? AgentTool.icon(for: tool.name) : "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(tool.state == .done ? tint : VicePalette.coral)
                }
            }
            .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(tool.name)
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(tint.opacity(0.92))
                Text(tool.label)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            if let result = tool.result {
                Text(result)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.40))
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background {
                        Capsule().fill(Color.white.opacity(0.05))
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
            } else if tool.state == .running {
                Text("läuft")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.32))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.035))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(tint.opacity(tool.state == .running ? 0.30 : 0.12), lineWidth: 0.5)
        }
        .animation(.easeInOut(duration: 0.25), value: tool.state)
    }

    private var typingIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(store.accent.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .opacity(store.isThinking ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.55).repeatForever().delay(Double(index) * 0.14),
                               value: store.isThinking)
            }
            Text("denkt nach")
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.34))
                .padding(.leading, 2)
        }
        .padding(.vertical, 4)
    }

    private func chatCard(_ card: ChatCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: card.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(store.accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text(card.title)
                        .font(.system(size: 12, weight: .semibold))
                    Text(card.subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            if let action = card.actionTitle {
                Button {
                    Haptics.tap()
                    if card.kind == .approval {
                        showApprovals = true
                    } else {
                        store.selectedTab = 1
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(action)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(store.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(store.accent.opacity(0.07))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(store.accent.opacity(0.20), lineWidth: 0.5)
                }
        }
    }

    // MARK: Leerzustand

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("GIB MIR EIN ZIEL.")
                    .font(.system(size: 26, weight: .heavy))
                    .fontWidth(.condensed)
                    .tracking(0.4)
                    .foregroundStyle(LinearGradient(colors: [.white, Color.white.opacity(0.6)],
                                                   startPoint: .top, endPoint: .bottom))
                Text(store.isSimulator
                     ? "Der Simulator plant und ruft Werkzeuge auf, liest dabei Briefing, Freigaben und Gedächtnis. Für echte Modelle: Mehr → KI-Provider."
                     : "Verbunden mit \(store.engineLabel). Antworten nutzen Briefing, Freigaben und Gedächtnis als Kontext.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            GlassCard(tint: store.accent, glow: true, padding: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "point.3.connected.trianglepath.dotted")
                            .font(.system(size: 11))
                            .foregroundStyle(store.accent)
                        Text("So arbeitet der Agent")
                            .font(.system(size: 11.5, weight: .semibold))
                    }
                    Text("Ziel lesen → Schritte planen → Werkzeug aufrufen → Ergebnis synthetisieren. Alles Riskante wird zur Freigabe, bevor es rausgeht.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("VORSCHLÄGE")
                    .font(.system(size: 9, weight: .heavy))
                    .fontWidth(.expanded)
                    .tracking(1.5)
                    .foregroundStyle(Color.white.opacity(0.28))
                ForEach(starters, id: \.self) { starter in
                    Button {
                        Haptics.tap()
                        store.send(starter)
                    } label: {
                        HStack(spacing: 9) {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(store.accent.opacity(0.8))
                            Text(starter)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.84))
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 11)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.035))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 12)
    }

    // MARK: Eingabe

    private var composer: some View {
        VStack(spacing: 0) {
            if store.isThinking {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.mini).tint(store.accent)
                    Text("Agent arbeitet…")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Stopp") { store.stopStreaming() }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(store.accent)
                        .buttonStyle(.plain)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 6)
                .transition(.opacity)
            }

            HStack(alignment: .bottom, spacing: 9) {
                HStack(alignment: .bottom, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(store.accent.opacity(0.7))
                        .padding(.bottom, 9)
                    TextField("Ziel, Frage oder Auftrag…", text: $draft, axis: .vertical)
                        .font(.system(size: 13.5))
                        .lineLimit(1...5)
                        .focused($focused)
                        .padding(.vertical, 9)
                }
                .padding(.horizontal, 13)
                .background {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white.opacity(0.03))
                        }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
                }

                Button {
                    let text = draft
                    draft = ""
                    store.send(text)
                    Haptics.tap()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0.04, green: 0.03, blue: 0.06))
                        .frame(width: 40, height: 40)
                        .background {
                            Circle()
                                .fill(store.accent)
                                .shadow(color: store.accent.opacity(0.36), radius: 8, y: 3)
                        }
                }
                .buttonStyle(.plain)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isThinking)
                .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 6)
        }
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
