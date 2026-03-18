import Foundation
import PDFKit

/// Extracts text from a dropped file and calls Claude Haiku to generate todos.
class FileTodoService {
    static let shared = FileTodoService()

    private let supportedExtensions: Set<String> = ["txt", "md", "pdf"]

    // MARK: - Public entry point

    /// Called with a file URL from the drop handler.
    /// Extracts text, calls Claude, adds todos to today's list.
    /// Silently ignores unsupported types; logs errors to console, never crashes.
    func process(fileURL: URL) {
        let ext = fileURL.pathExtension.lowercased()
        guard supportedExtensions.contains(ext) else { return }

        Task {
            do {
                guard let text = extractText(from: fileURL, extension: ext),
                      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    print("[FileTodoService] No text extracted from \(fileURL.lastPathComponent)")
                    return
                }
                let todos = try await callClaudeAPI(content: text)
                await MainActor.run {
                    for todo in todos {
                        TodoStore.shared.add(TodoItem(
                            title: todo.title,
                            priority: priority(from: todo.priority),
                            dueDate: Calendar.current.startOfDay(for: Date())
                        ))
                    }
                }
            } catch {
                print("[FileTodoService] Error processing \(fileURL.lastPathComponent): \(error)")
            }
        }
    }

    // MARK: - Text Extraction

    private func extractText(from url: URL, extension ext: String) -> String? {
        switch ext {
        case "txt", "md":
            return try? String(contentsOf: url, encoding: .utf8)
        case "pdf":
            guard let doc = PDFDocument(url: url) else { return nil }
            return doc.string
        default:
            return nil
        }
    }

    // MARK: - Claude API

    private struct ClaudeTodo: Decodable {
        let title: String
        let priority: String   // "high" | "normal" | "low"
    }

    private func callClaudeAPI(content: String) async throws -> [ClaudeTodo] {
        guard let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
              !apiKey.isEmpty else {
            print("[FileTodoService] ANTHROPIC_API_KEY not set — skipping API call")
            return []
        }

        let truncated = String(content.prefix(8000))  // stay well within token limits

        let systemPrompt = """
You are a todo extraction assistant. \
Analyze the provided text and extract actionable todo items. \
Return ONLY a valid JSON array — no prose, no markdown fences, no explanation. \
Each element must have exactly two keys: "title" (string) and "priority" ("high", "normal", or "low"). \
"high" means urgent or blocking. "low" means optional or nice-to-have. "normal" for everything else. \
Extract between 1 and 10 items. If nothing actionable is found, return an empty array [].
"""

        let userMessage = "Extract todo items from the following content:\n\n\(truncated)"

        let requestBody: [String: Any] = [
            "model": "claude-haiku-4-5",
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("[FileTodoService] API error: \(body)")
            throw URLError(.badServerResponse)
        }

        // Anthropic response shape: { "content": [{ "type": "text", "text": "..." }] }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstContent = contentArray.first,
              let rawText = firstContent["text"] as? String else {
            print("[FileTodoService] Unexpected API response shape")
            return []
        }

        // Parse the JSON array Claude returned
        guard let jsonData = rawText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .data(using: .utf8),
              let todos = try? JSONDecoder().decode([ClaudeTodo].self, from: jsonData) else {
            print("[FileTodoService] Failed to parse Claude response as JSON array: \(rawText)")
            return []
        }

        return todos
    }

    // MARK: - Priority Mapping

    private func priority(from string: String) -> Priority {
        switch string.lowercased() {
        case "high":   return .high
        case "low":    return .low
        default:       return .normal
        }
    }
}
