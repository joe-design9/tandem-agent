import Foundation

/// Verbindung zu einem echten Modell. Alle Anbieter sprechen entweder
/// die Anthropic-Messages-API oder die OpenAI-Chat-Completions-API —
/// damit deckt ein schlanker Client Claude, OpenAI, DeepSeek,
/// OpenRouter und jeden eigenen OpenAI-kompatiblen Endpoint ab.
struct ProviderConfig {
    var provider: ProviderID
    var model: String
    var apiKey: String
    var baseURL: String
    var customModel: String

    var effectiveModel: String {
        provider == .custom && !customModel.isEmpty ? customModel : model
    }
}

enum AIError: LocalizedError {
    case missingKey
    case badURL
    case server(Int, String)
    case empty

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "Für diesen Anbieter fehlt noch ein API-Key."
        case .badURL:
            return "Die Base-URL ist keine gültige Adresse."
        case .server(let code, let message):
            return "Der Anbieter antwortet mit \(code): \(message)"
        case .empty:
            return "Die Antwort kam leer zurück."
        }
    }
}

enum AIService {
    // MARK: Streaming

    static func stream(config: ProviderConfig, system: String, history: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let request = try makeRequest(config: config, system: system, history: history, streaming: true)
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw AIError.server(-1, "Keine HTTP-Antwort")
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        var body = ""
                        for try await line in bytes.lines {
                            body += line + "\n"
                            if body.count > 900 { break }
                        }
                        throw AIError.server(http.statusCode, friendly(body))
                    }

                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        guard line.hasPrefix("data:") else { continue }
                        let payload = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                        if payload.isEmpty { continue }
                        if payload == "[DONE]" { break }
                        if let chunk = textChunk(from: payload) {
                            continuation.yield(chunk)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: Verbindung testen

    static func test(config: ProviderConfig) async -> Result<String, Error> {
        do {
            var request = try makeRequest(config: config,
                                          system: "Antworte mit genau einem Wort: bereit.",
                                          history: [ChatMessage(role: .user, text: "Bist du da?")],
                                          streaming: false)
            request.timeoutInterval = 30
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failure(AIError.server(-1, "Keine HTTP-Antwort"))
            }
            let raw = String(data: data, encoding: .utf8) ?? ""
            guard (200..<300).contains(http.statusCode) else {
                return .failure(AIError.server(http.statusCode, friendly(raw)))
            }
            if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let content = object["content"] as? [[String: Any]],
                   let text = content.first?["text"] as? String {
                    return .success(text.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                if let choices = object["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let text = message["content"] as? String {
                    return .success(text.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
            return raw.isEmpty ? .failure(AIError.empty) : .success("Verbunden")
        } catch {
            return .failure(error)
        }
    }

    // MARK: Request

    private static func makeRequest(config: ProviderConfig,
                                    system: String,
                                    history: [ChatMessage],
                                    streaming: Bool) throws -> URLRequest {
        guard config.provider != .simulator else { throw AIError.missingKey }
        if config.provider.needsKey, config.apiKey.isEmpty { throw AIError.missingKey }
        guard let url = endpointURL(for: config) else { throw AIError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let turns = history.filter { $0.role != .system }
        let body: [String: Any]

        if config.provider == .anthropic {
            request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            var messages: [[String: Any]] = []
            for message in turns {
                let role = message.role == .user ? "user" : "assistant"
                let text = message.text.isEmpty ? "…" : message.text
                if var last = messages.last, (last["role"] as? String) == role,
                   var content = last["content"] as? String {
                    content += "\n\n" + text
                    last["content"] = content
                    messages[messages.count - 1] = last
                } else {
                    messages.append(["role": role, "content": text])
                }
            }
            if messages.isEmpty { messages = [["role": "user", "content": "Hallo"]] }
            body = [
                "model": config.effectiveModel,
                "max_tokens": 1600,
                "system": system,
                "messages": messages,
                "stream": streaming,
            ]
        } else {
            if !config.apiKey.isEmpty {
                request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
            }
            if config.provider == .openrouter {
                request.setValue("Tandem Agent", forHTTPHeaderField: "X-Title")
                request.setValue("https://github.com/joe-design9/tandem-agent", forHTTPHeaderField: "HTTP-Referer")
            }
            var messages: [[String: Any]] = [["role": "system", "content": system]]
            for message in turns {
                messages.append([
                    "role": message.role == .user ? "user" : "assistant",
                    "content": message.text.isEmpty ? "…" : message.text,
                ])
            }
            body = [
                "model": config.effectiveModel,
                "messages": messages,
                "temperature": 0.7,
                "max_tokens": 1600,
                "stream": streaming,
            ]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private static func endpointURL(for config: ProviderConfig) -> URL? {
        var base = config.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.isEmpty { base = config.provider.defaultBaseURL }
        while base.hasSuffix("/") { base.removeLast() }
        guard base.hasPrefix("http"), URL(string: base) != nil else { return nil }

        switch config.provider {
        case .anthropic:
            return URL(string: base.hasSuffix("/v1") ? base + "/messages" : base + "/v1/messages")
        case .deepseek:
            return URL(string: base.hasSuffix("/v1") ? base + "/chat/completions" : base + "/chat/completions")
        default:
            return URL(string: base.hasSuffix("/v1") ? base + "/chat/completions" : base + "/v1/chat/completions")
        }
    }

    // MARK: Parsing

    private static func textChunk(from json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        // Anthropic: content_block_delta
        if let delta = object["delta"] as? [String: Any],
           let text = delta["text"] as? String {
            return text
        }
        // OpenAI-kompatibel: choices[0].delta.content
        if let choices = object["choices"] as? [[String: Any]],
           let delta = choices.first?["delta"] as? [String: Any],
           let text = delta["content"] as? String {
            return text
        }
        return nil
    }

    private static func friendly(_ raw: String) -> String {
        if let data = raw.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let error = object["error"] as? [String: Any],
               let message = error["message"] as? String {
                return message
            }
            if let message = object["message"] as? String {
                return message
            }
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "unbekannter Fehler" : String(trimmed.prefix(220))
    }
}
