import Foundation
import SwiftUI

// MARK: - Autonomie

/// Wie viel Tandem ohne Rückfrage tun darf. Der Standard ist „Vorschlagen":
/// Tandem bereitet alles vor, ausgeführt wird erst nach Freigabe.
enum AutonomyLevel: String, Codable, CaseIterable, Identifiable {
    case ask
    case suggest
    case act

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ask: return "Nur fragen"
        case .suggest: return "Vorschlagen"
        case .act: return "Handeln"
        }
    }

    var detail: String {
        switch self {
        case .ask: return "Tandem recherchiert und fragt vor jedem Schritt."
        case .suggest: return "Tandem bereitet alles vor, du gibst frei."
        case .act: return "Unkritische Schritte laufen durch, Riskantes braucht Freigabe."
        }
    }

    var icon: String {
        switch self {
        case .ask: return "hand.raised.fill"
        case .suggest: return "wand.and.stars"
        case .act: return "bolt.fill"
        }
    }

    var tint: Color {
        switch self {
        case .ask: return Color(red: 0.42, green: 0.80, blue: 1.00)
        case .suggest: return VicePalette.cyan
        case .act: return VicePalette.gold
        }
    }
}

// MARK: - Freigaben

enum Risk: String, Codable, CaseIterable {
    case low
    case medium
    case high

    var title: String {
        switch self {
        case .low: return "Geringes Risiko"
        case .medium: return "Mittleres Risiko"
        case .high: return "Hohes Risiko"
        }
    }

    var color: Color {
        switch self {
        case .low: return Color(red: 0.35, green: 1.00, blue: 0.74)
        case .medium: return VicePalette.gold
        case .high: return VicePalette.hotPink
        }
    }
}

/// Eine Aktion, die Tandem vorbereitet hat und die ohne Freigabe nie
/// ausgeführt wird: E-Mail, Zahlung, Kalender, Löschung, Nachricht.
struct ApprovalRequest: Identifiable, Codable, Hashable {
    enum Kind: String, Codable, CaseIterable {
        case email
        case payment
        case calendar
        case deletion
        case message

        var title: String {
            switch self {
            case .email: return "E-Mail"
            case .payment: return "Zahlung"
            case .calendar: return "Kalender"
            case .deletion: return "Löschung"
            case .message: return "Nachricht"
            }
        }

        var icon: String {
            switch self {
            case .email: return "envelope.fill"
            case .payment: return "creditcard.fill"
            case .calendar: return "calendar.badge.clock"
            case .deletion: return "trash.fill"
            case .message: return "bubble.left.and.bubble.right.fill"
            }
        }

        var tint: Color {
            switch self {
            case .email: return VicePalette.cyan
            case .payment: return VicePalette.gold
            case .calendar: return VicePalette.coral
            case .deletion: return VicePalette.hotPink
            case .message: return Color(red: 0.72, green: 0.60, blue: 1.00)
            }
        }
    }

    enum State: String, Codable {
        case pending
        case executed
        case rejected

        var title: String {
            switch self {
            case .pending: return "Wartet auf dich"
            case .executed: return "Ausgeführt"
            case .rejected: return "Abgelehnt"
            }
        }
    }

    var id: UUID = UUID()
    var kind: Kind
    var title: String
    var summary: String
    var recipient: String?
    var subject: String?
    var body: String?
    var amount: String?
    var risk: Risk
    var tool: String
    var createdAt: Date = Date()
    var state: State = .pending
    var decidedAt: Date?
    var reason: String?
    var note: String?

    var isPending: Bool { state == .pending }
}

// MARK: - Aufgaben

struct TaskStep: Identifiable, Codable, Hashable {
    enum State: String, Codable {
        case pending
        case running
        case done
        case failed
    }

    var id: UUID = UUID()
    var title: String
    var detail: String
    var state: State = .pending
}

struct AgentTask: Identifiable, Codable, Hashable {
    enum Status: String, Codable {
        case queued
        case running
        case paused
        case done
        case cancelled

        var title: String {
            switch self {
            case .queued: return "In der Warteschlange"
            case .running: return "Läuft"
            case .paused: return "Pausiert"
            case .done: return "Erledigt"
            case .cancelled: return "Abgebrochen"
            }
        }

        var color: Color {
            switch self {
            case .queued: return Color(red: 0.62, green: 0.62, blue: 1.00)
            case .running: return VicePalette.cyan
            case .paused: return VicePalette.gold
            case .done: return Color(red: 0.40, green: 1.00, blue: 0.74)
            case .cancelled: return VicePalette.hotPink
            }
        }
    }

    var id: UUID = UUID()
    var title: String
    var goal: String
    var autonomy: AutonomyLevel
    var status: Status = .queued
    var steps: [TaskStep] = []
    var createdAt: Date = Date()
    var finishedAt: Date?
    var summary: String?
    var source: String?

    var progress: Double {
        guard !steps.isEmpty else { return 0 }
        let done = steps.filter { $0.state == .done || $0.state == .failed }.count
        return Double(done) / Double(steps.count)
    }

    var currentStep: TaskStep? {
        steps.first { $0.state == .running } ?? steps.first { $0.state == .pending }
    }
}

// MARK: - Audit

struct AuditEvent: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var title: String
    var detail: String
    var icon: String
    var kind: Kind

    enum Kind: String, Codable {
        case approval
        case task
        case scan
        case system
        case memory

        var color: Color {
            switch self {
            case .approval: return VicePalette.gold
            case .task: return VicePalette.cyan
            case .scan: return Color(red: 0.55, green: 0.75, blue: 1.00)
            case .system: return Color(red: 0.70, green: 0.72, blue: 0.80)
            case .memory: return Color(red: 0.72, green: 0.60, blue: 1.00)
            }
        }
    }
}

// MARK: - Proaktive Check-ins

struct CheckIn: Identifiable, Codable, Hashable {
    enum Tone: String, Codable {
        case neutral
        case good
        case warn

        var color: Color {
            switch self {
            case .neutral: return VicePalette.cyan
            case .good: return Color(red: 0.40, green: 1.00, blue: 0.74)
            case .warn: return VicePalette.coral
            }
        }
    }

    var id: UUID = UUID()
    var icon: String
    var title: String
    var detail: String
    var date: Date
    var tone: Tone = .neutral
}

// MARK: - Briefing

struct BriefingItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var time: String
    var title: String
    var detail: String
    var icon: String
    var highlight: Bool = false
}

struct MorningBriefing: Codable, Hashable {
    var generatedAt: Date = Date()
    var greeting: String = "Guten Morgen"
    var focus: String = ""
    var weather: String = ""
    var weatherDetail: String = ""
    var weatherIcon: String = "cloud.sun.fill"
    var temperature: String = ""
    var agenda: [BriefingItem] = []
    var todos: [String] = []
    var nightNote: String = ""
}

// MARK: - Gedächtnis

struct MemoryTopic: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var emoji: String
    var title: String
    var facts: [String]
    var updatedAt: Date = Date()
    var pinned: Bool = false
}

struct ConnectedService: Identifiable, Codable, Hashable {
    enum Status: String, Codable {
        case connected
        case pending
        case off

        var title: String {
            switch self {
            case .connected: return "Verbunden"
            case .pending: return "Wartet"
            case .off: return "Nicht verbunden"
            }
        }

        var color: Color {
            switch self {
            case .connected: return Color(red: 0.40, green: 1.00, blue: 0.74)
            case .pending: return VicePalette.gold
            case .off: return Color(red: 0.62, green: 0.66, blue: 0.75)
            }
        }
    }

    var id: String
    var name: String
    var icon: String
    var tintKey: String
    var detail: String
    var status: Status
    var scopes: [String]

    var tint: Color { ServiceTint.color(tintKey) }
}

enum ServiceTint {
    static func color(_ key: String) -> Color {
        switch key {
        case "mail": return VicePalette.cyan
        case "calendar": return VicePalette.coral
        case "github": return Color(red: 0.85, green: 0.88, blue: 0.98)
        case "x": return Color(red: 0.92, green: 0.92, blue: 0.97)
        case "device": return VicePalette.cyan
        case "music": return VicePalette.magenta
        default: return Color(red: 0.70, green: 0.76, blue: 0.90)
        }
    }
}

// MARK: - Chat

struct ToolCall: Identifiable, Codable, Hashable {
    enum State: String, Codable {
        case running
        case done
        case failed
    }

    var id: UUID = UUID()
    var name: String
    var label: String
    var state: State = .running
    /// Kleinigkeit, die der Tool-Aufruf zurückgegeben hat („3 Treffer").
    var result: String?
}

struct ChatCard: Identifiable, Codable, Hashable {
    enum Kind: String, Codable {
        case approval
        case task
        case info
    }

    var id: UUID = UUID()
    var kind: Kind
    var title: String
    var subtitle: String
    var icon: String
    var actionTitle: String?
    var approvalID: UUID?
    var taskID: UUID?
}

struct ChatMessage: Identifiable, Codable, Hashable {
    enum Role: String, Codable {
        case user
        case agent
        case system
    }

    var id: UUID = UUID()
    var role: Role
    var text: String
    var date: Date = Date()
    var tools: [ToolCall] = []
    var card: ChatCard?
    var engine: String?
}

// MARK: - Invite Keys

struct InviteKey: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var code: String
    var createdAt: Date = Date()
    var redeemed: Bool = false
    var redeemedAt: Date?
}

// MARK: - Provider

enum ProviderID: String, Codable, CaseIterable, Identifiable, Hashable {
    case simulator
    case anthropic
    case openai
    case deepseek
    case openrouter
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .simulator: return "Tandem Simulator"
        case .anthropic: return "Anthropic Claude"
        case .openai: return "OpenAI"
        case .deepseek: return "DeepSeek"
        case .openrouter: return "OpenRouter"
        case .custom: return "Eigener Endpoint"
        }
    }

    var subtitle: String {
        switch self {
        case .simulator: return "Läuft offline, ohne API-Key"
        case .anthropic: return "Claude Opus, Sonnet, Haiku"
        case .openai: return "GPT-4o, GPT-4.1, o-Reihe"
        case .deepseek: return "DeepSeek Chat und Reasoner"
        case .openrouter: return "Ein Key, viele Modelle"
        case .custom: return "OpenAI-kompatible API"
        }
    }

    var icon: String {
        switch self {
        case .simulator: return "sparkles.rectangle.stack.fill"
        case .anthropic: return "a.circle.fill"
        case .openai: return "o.circle.fill"
        case .deepseek: return "d.circle.fill"
        case .openrouter: return "r.circle.fill"
        case .custom: return "slider.horizontal.3"
        }
    }

    var tint: Color {
        switch self {
        case .simulator: return VicePalette.magenta
        case .anthropic: return VicePalette.coral
        case .openai: return Color(red: 0.55, green: 0.96, blue: 0.86)
        case .deepseek: return Color(red: 0.52, green: 0.62, blue: 1.00)
        case .openrouter: return Color(red: 0.78, green: 0.60, blue: 1.00)
        case .custom: return Color(red: 0.80, green: 0.84, blue: 0.92)
        }
    }

    var needsKey: Bool { self != .simulator }

    var keyHint: String {
        switch self {
        case .simulator: return "Kein Key nötig"
        case .anthropic: return "sk-ant-…"
        case .openai: return "sk-…"
        case .deepseek: return "sk-…"
        case .openrouter: return "sk-or-…"
        case .custom: return "Beliebig, falls dein Server keinen braucht"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .simulator: return ""
        case .anthropic: return "https://api.anthropic.com"
        case .openai: return "https://api.openai.com"
        case .deepseek: return "https://api.deepseek.com"
        case .openrouter: return "https://openrouter.ai/api"
        case .custom: return "https://"
        }
    }

    var models: [ModelOption] {
        switch self {
        case .simulator:
            return [ModelOption(id: "tandem-local-1", name: "Tandem Local 1", note: "Regelbasierter Simulator")]
        case .anthropic:
            return [
                ModelOption(id: "claude-opus-4-5", name: "Claude Opus 4.5", note: "Stärkstes Reasoning"),
                ModelOption(id: "claude-sonnet-4-5", name: "Claude Sonnet 4.5", note: "Bester Allrounder"),
                ModelOption(id: "claude-haiku-4-5", name: "Claude Haiku 4.5", note: "Schnell und günstig"),
            ]
        case .openai:
            return [
                ModelOption(id: "gpt-4o", name: "GPT-4o", note: "Multimodal, schnell"),
                ModelOption(id: "gpt-4.1", name: "GPT-4.1", note: "Langer Kontext"),
                ModelOption(id: "o4-mini", name: "o4-mini", note: "Reasoning, günstig"),
            ]
        case .deepseek:
            return [
                ModelOption(id: "deepseek-chat", name: "DeepSeek Chat", note: "Allgemein"),
                ModelOption(id: "deepseek-reasoner", name: "DeepSeek Reasoner", note: "Denkt nach"),
            ]
        case .openrouter:
            return [
                ModelOption(id: "anthropic/claude-sonnet-4.5", name: "Claude Sonnet 4.5", note: "Über OpenRouter"),
                ModelOption(id: "openai/gpt-4o", name: "GPT-4o", note: "Über OpenRouter"),
                ModelOption(id: "google/gemini-2.5-pro", name: "Gemini 2.5 Pro", note: "Über OpenRouter"),
                ModelOption(id: "meta-llama/llama-3.3-70b-instruct", name: "Llama 3.3 70B", note: "Offen"),
            ]
        case .custom:
            return [ModelOption(id: "custom-model", name: "Eigenes Modell", note: "Name unten eintragen")]
        }
    }
}

struct ModelOption: Identifiable, Hashable {
    var id: String
    var name: String
    var note: String
}

// MARK: - Toast

struct ToastMessage: Identifiable, Equatable {
    enum Style {
        case success
        case info
        case warning

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .info: return "sparkles"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return Color(red: 0.40, green: 1.00, blue: 0.74)
            case .info: return VicePalette.cyan
            case .warning: return VicePalette.gold
            }
        }
    }

    var id: UUID = UUID()
    var text: String
    var style: Style = .success
}
