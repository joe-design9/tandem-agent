import SwiftUI

/// Der Chat mit Streaming, Tool-Pills und Rich Cards. Antworten kommen
/// aus dem Simulator oder aus einem echten Modell — sichtbar wird nur,
/// was der Agent tut.
struct ChatView: View {
    @Environment(TandemStore.self) private var store
    @State private var draft = ""
    @State private var showApprovals = false
    @FocusState private var focused: Bool

    private let starters = [
        "Was steht heute an?",
        "Fasse meine Mails zusammen",
        "Welche Freigaben warten?",
        "Wie laufen meine Repos?",
        "Was weißt du über mich?",
    ]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
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
            .navigationTitle("Tandem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text("Tandem").font(.system(size: 14, weight: .bold, design: .rounded))
                        HStack(spacing: 4) {
                            Circle().fill(store.accent).frame(width: 5, height: 5)
                            Text(store.isSimulator ? "Simulator · offline" : store.engineLabel)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
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
                Spacer(minLength: 40)
                Text(message.text)
                    .font(.system(size: 13.5, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LinearGradient(colors: [store.accent.opacity(0.85), store.accentChoice.deep.opacity(0.85)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.8)
                            }
                    }
            }
        } else {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 6) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(store.accent)
                    Text("TANDEM")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(.secondary)
                    if let engine = message.engine {
                        Text(engine)
                            .font(.system(size: 8.5, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                }

                if !message.tools.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(message.tools) { tool in
                            toolPill(tool)
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
                    .fill(.clear)
                    .glassEffect(.regular.tint(VicePalette.violet.opacity(0.22)),
                                 in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                LinearGradient(colors: [VicePalette.magenta.opacity(0.55),
                                                        VicePalette.cyan.opacity(0.40)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 0.9
                            )
                    }
                    .shadow(color: VicePalette.magenta.opacity(0.22), radius: 14, y: 4)
            }
        }
    }

    private func toolPill(_ tool: ToolCall) -> some View {
        HStack(spacing: 6) {
            if tool.state == .running {
                ProgressView().controlSize(.mini).tint(store.accent)
            } else {
                Image(systemName: tool.state == .done ? "checkmark" : "xmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(tool.state == .done ? store.accent : Color(red: 1, green: 0.5, blue: 0.55))
            }
            Text(tool.name)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundStyle(VicePalette.cyan.opacity(0.95))
            if let result = tool.result {
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(result)
                    .font(.system(size: 9.5, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background {
            Capsule()
                .fill(VicePalette.cyan.opacity(0.12))
                .overlay { Capsule().strokeBorder(VicePalette.cyan.opacity(0.30), lineWidth: 0.7) }
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(store.accent.opacity(0.55))
                    .frame(width: 5, height: 5)
                    .opacity(store.isThinking ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.15),
                               value: store.isThinking)
            }
        }
        .padding(.vertical, 4)
    }

    private func chatCard(_ card: ChatCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: card.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(store.accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text(card.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                    Text(card.subtitle)
                        .font(.system(size: 10, design: .rounded))
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
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(store.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(store.accent.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(store.accent.opacity(0.22), lineWidth: 0.8)
                }
        }
    }

    // MARK: Leerzustand

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 7) {
                Text("FRAG MICH IRGENDWAS.")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(LinearGradient(colors: [.white, VicePalette.gold, VicePalette.magenta],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: VicePalette.magenta.opacity(0.5), radius: 14)
                Text(store.isSimulator
                     ? "Der Simulator antwortet offline und liest dabei dein Briefing, deine Freigaben und dein Gedächtnis. Für echte Modelle: Einstellungen → Backbone."
                     : "Verbunden mit \(store.engineLabel). Antworten nutzen Briefing, Freigaben und Gedächtnis als Kontext.")
                    .font(.system(size: 12.5, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            GlassCard(tint: store.accent, glow: true, padding: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 11))
                            .foregroundStyle(store.accent)
                        Text("Das kann der Agent")
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    }
                    Text("Frag nach dem Tag, nach Mails, nach deinen Repos. Wenn eine Antwort eine Aktion braucht, legt Tandem sie als Freigabe hin — gesendet wird nichts ohne dich.")
                        .font(.system(size: 11.5, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("VORSCHLÄGE")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.tertiary)
                ForEach(starters, id: \.self) { starter in
                    Button {
                        Haptics.tap()
                        store.send(starter)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(store.accent.opacity(0.8))
                            Text(starter)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(.primary.opacity(0.9))
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 11)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.09), lineWidth: 0.8)
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
                    Text("Tandem arbeitet…")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Stopp") { store.stopStreaming() }
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
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
                        .foregroundStyle(store.accent.opacity(0.8))
                        .padding(.bottom, 9)
                    TextField("Nachricht an Tandem…", text: $draft, axis: .vertical)
                        .font(.system(size: 13.5, design: .rounded))
                        .lineLimit(1...5)
                        .focused($focused)
                        .padding(.vertical, 9)
                }
                .padding(.horizontal, 13)
                .background {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.clear)
                        .glassEffect(.regular.tint(VicePalette.violet.opacity(0.28)),
                                     in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(colors: [VicePalette.cyan.opacity(0.55),
                                                            VicePalette.magenta.opacity(0.45)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 0.9
                                )
                        }
                }

                Button {
                    let text = draft
                    draft = ""
                    store.send(text)
                    Haptics.tap()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.85))
                        .frame(width: 42, height: 42)
                        .background {
                            Circle()
                                .fill(store.accent.gradient)
                                .shadow(color: store.accent.opacity(0.45), radius: 10, y: 3)
                        }
                }
                .buttonStyle(.plain)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isThinking)
                .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 6)
        }
        .background {
            Rectangle()
                .fill(.clear)
                .glassEffect(.regular.tint(Color.black.opacity(0.15)), in: Rectangle())
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
