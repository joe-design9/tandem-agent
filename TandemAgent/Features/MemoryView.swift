import SwiftUI

/// Was Tandem über Joel weiß — sichtbar, änderbar, löschbar.
struct MemoryView: View {
    @Environment(TandemStore.self) private var store
    @State private var addFactTo: MemoryTopic?
    @State private var confirmWipe = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    profileCard
                    topicsSection
                    servicesSection
                    privacyCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Gedächtnis")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $addFactTo) { topic in
                AddFactView(topic: topic) { fact in
                    store.addFact(fact, to: topic.id)
                }
            }
            .confirmationDialog("Gedächtnis wirklich leeren?",
                                isPresented: $confirmWipe,
                                titleVisibility: .visible) {
                Button("Alles löschen", role: .destructive) {
                    store.wipeMemory()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Alle Themen und der Chatverlauf werden entfernt. Freigaben und Aufgaben bleiben erhalten.")
            }
        }
    }

    // MARK: Profil

    private var profileCard: some View {
        GlassCard(tint: store.accent, glow: true, padding: 18) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [store.accent, store.accentChoice.deep],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 58, height: 58)
                    Text(initials)
                        .font(.system(size: 21, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.75))
                }
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(store.userName)
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                        if store.isFounder {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(store.accent)
                        }
                    }
                    Text("\(store.city) · \(store.role)")
                        .font(.system(size: 11.5, design: .rounded))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 5) {
                        if store.isFounder {
                            StatusBadge(text: "VIP ACCESS", tint: store.accent, icon: "sparkles")
                        }
                        StatusBadge(text: store.hasUnlocked ? "PREVIEW AKTIV" : "GESPERRT",
                                    tint: store.hasUnlocked ? Color(red: 0.50, green: 0.92, blue: 0.74) : .secondary,
                                    icon: "lock.fill")
                    }
                    .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var initials: String {
        let parts = store.userName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "J" : String(letters).uppercased()
    }

    // MARK: Themen

    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Was ich über dich weiß",
                          subtitle: nil,
                          icon: "brain.head.profile",
                          trailing: "\(store.memoryTopics.reduce(0) { $0 + $1.facts.count }) Fakten")

            if store.memoryTopics.isEmpty {
                GlassCard(tint: nil, glow: false, padding: 18) {
                    Text("Noch nichts gespeichert. Tandem lernt nur aus Gesprächen und aus dem, was du hier einträgst.")
                        .font(.system(size: 11.5, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(store.memoryTopics) { topic in
                GlassCard(tint: nil, glow: false, padding: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 9) {
                            Text(topic.emoji).font(.system(size: 17))
                            Text(topic.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                            if topic.pinned {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(store.accent)
                            }
                            Spacer()
                            Text(RelativeTime.string(from: topic.updatedAt))
                                .font(.system(size: 9, design: .rounded))
                                .foregroundStyle(.tertiary)
                            Button {
                                Haptics.tap()
                                addFactTo = topic
                            } label: {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 13))
                                    .foregroundStyle(store.accent)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 15)
                        .padding(.top, 14)
                        .padding(.bottom, 8)

                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(topic.facts, id: \.self) { fact in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(store.accent.opacity(0.55))
                                        .frame(width: 4, height: 4)
                                        .padding(.top, 6)
                                    Text(fact)
                                        .font(.system(size: 11.5, design: .rounded))
                                        .foregroundStyle(.primary.opacity(0.88))
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                    Button {
                                        withAnimation { store.removeFact(fact, from: topic.id) }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 17)
                                .padding(.vertical, 5)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
        }
    }

    // MARK: Dienste

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Verbundene Dienste", subtitle: nil, icon: "link",
                          trailing: "\(store.services.filter { $0.status == .connected }.count) aktiv")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(store.services) { service in
                    Button {
                        store.toggleService(service.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            HStack {
                                Image(systemName: service.icon)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(service.status == .off ? Color.secondary : service.tint)
                                Spacer()
                                Circle()
                                    .fill(service.status.color)
                                    .frame(width: 6, height: 6)
                            }
                            Text(service.name)
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            Text(service.detail)
                                .font(.system(size: 9.5, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.clear)
                                .glassEffect(.regular.tint(Color.white.opacity(0.05)),
                                             in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.8)
                                }
                        }
                        .opacity(service.status == .off ? 0.6 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Datenschutz

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Kontrolle", subtitle: nil, icon: "lock.shield.fill", trailing: nil)
            GlassCard(tint: nil, glow: false, padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 9) {
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 13))
                            .foregroundStyle(store.accent)
                        Text("Gedächtnis liegt lokal auf diesem iPhone. Kein Tandem-Server, kein Konto.")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    HStack(spacing: 8) {
                        Button {
                            confirmWipe = true
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "trash")
                                Text("Gedächtnis leeren")
                            }
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 1.0, green: 0.52, blue: 0.58))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background { Capsule().fill(Color.white.opacity(0.06)) }
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.lockApp()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "lock.fill")
                                Text("App sperren")
                            }
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background { Capsule().fill(Color.white.opacity(0.06)) }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct AddFactView: View {
    @Environment(\.dismiss) private var dismiss
    var topic: MemoryTopic
    var onSave: (String) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Neuer Fakt für „\(topic.title)“")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                TextField("z. B. mag keine Meetings vor 10 Uhr", text: $text, axis: .vertical)
                    .font(.system(size: 13.5, design: .rounded))
                    .lineLimit(2...5)
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    }
                    .focused($focused)
                Spacer()
            }
            .padding(18)
            .navigationTitle("Fakt hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        onSave(text)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}
