import SwiftUI

/// Was Tandem über dich weiß — sichtbar, ergänzbar, löschbar. Eine
/// schlichte Liste, kein Dashboard.
struct MemoryView: View {
    @Environment(TandemStore.self) private var store
    @State private var addFactTo: MemoryTopic?
    @State private var confirmWipe = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Palette.surfaceRaised)
                                .frame(width: 48, height: 48)
                            Text(initials)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Palette.textPrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.userName)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Palette.textPrimary)
                            Text("\(store.city) · \(store.role)")
                                .font(.system(size: 13))
                                .foregroundStyle(Palette.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4)
                }

                if store.memoryTopics.isEmpty {
                    Section {
                        EmptyState(icon: "brain",
                                   title: "Noch nichts gespeichert",
                                   message: "Ich merke mir nur, was im Gespräch vorkommt oder was du hier ergänzt.")
                    }
                } else {
                    ForEach(store.memoryTopics) { topic in
                        Section {
                            ForEach(topic.facts, id: \.self) { fact in
                                Text(fact)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Palette.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            Haptics.tap()
                                            store.removeFact(fact, from: topic.id)
                                        } label: {
                                            Label("Löschen", systemImage: "trash")
                                        }
                                    }
                            }

                            Button {
                                Haptics.tap()
                                addFactTo = topic
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Palette.textSecondary)
                                    Text("Fakt hinzufügen")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Palette.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        } header: {
                            HStack {
                                Text(topic.title)
                                Spacer()
                                Text(RelativeTime.string(from: topic.updatedAt))
                                    .font(.system(size: 11))
                                    .foregroundStyle(Palette.textTertiary)
                            }
                        }
                    }
                }

                Section {
                    ForEach(store.services) { service in
                        HStack(spacing: 12) {
                            Image(systemName: service.icon)
                                .font(.system(size: 15))
                                .foregroundStyle(Palette.icon)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(service.name)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Palette.textPrimary)
                                Text(service.detail)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Palette.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 8)
                            Toggle("", isOn: Binding(
                                get: { service.status != .off },
                                set: { _ in store.toggleService(service.id) }
                            ))
                            .labelsHidden()
                        }
                    }
                } header: {
                    Text("Verbundene Dienste")
                } footer: {
                    Text("Nur verbundene Dienste darf der Agent lesen. Schreibende Aktionen brauchen immer eine Freigabe.")
                }

                Section {
                    Button("Gedächtnis leeren", role: .destructive) {
                        Haptics.warning()
                        confirmWipe = true
                    }
                    Button("App sperren") {
                        Haptics.tap()
                        store.lockApp()
                    }
                } header: {
                    Text("Kontrolle")
                } footer: {
                    Text("Gedächtnis und Chat liegen lokal auf diesem iPhone. Kein Tandem-Server, kein Konto.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground(theme: store.themeChoice, accent: store.accent))
            .navigationTitle("Gedächtnis")
            .navigationBarTitleDisplayMode(.large)
            .tint(store.accent)
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

    private var initials: String {
        let parts = store.userName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "J" : String(letters).uppercased()
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
            Form {
                Section {
                    TextField("Was soll ich mir merken?", text: $text, axis: .vertical)
                        .font(.system(size: 15))
                        .lineLimit(2...5)
                        .focused($focused)
                } header: {
                    Text(topic.title)
                } footer: {
                    Text("Kurz und konkret. Du kannst den Fakt jederzeit wieder löschen.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
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
