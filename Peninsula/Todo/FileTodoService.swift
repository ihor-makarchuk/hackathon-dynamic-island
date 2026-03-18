import Foundation
import PDFKit

// Top-level type so TodoView and other callers can access it directly.
struct ClaudeTodo: Decodable {
    let title: String
    let priority: String   // "high" | "normal" | "low"
}

/// Extracts text from a dropped file or plain text and calls Claude Haiku to generate todos.
class FileTodoService {
    static let shared = FileTodoService()

    private let supportedExtensions: Set<String> = ["txt", "md", "pdf"]

    // MARK: - Public entry points

    /// Called with a file URL from a drop handler.
    /// Extracts text, calls Claude, and returns the extracted todo array.
    /// Returns [] for unsupported types or empty text; re-throws API errors.
    func process(fileURL: URL) async throws -> [ClaudeTodo] {
        let ext = fileURL.pathExtension.lowercased()
        guard supportedExtensions.contains(ext) else { return [] }

        guard let text = extractText(from: fileURL, extension: ext),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("[FileTodoService] No text extracted from \(fileURL.lastPathComponent)")
            return []
        }

        do {
            return try await callClaudeAPI(content: text)
        } catch {
            print("[FileTodoService] Error processing \(fileURL.lastPathComponent): \(error)")
            throw error
        }
    }

    /// Called with a plain text string (e.g. dragged from another app).
    /// Calls Claude and returns the extracted todo array.
    func process(text: String) async throws -> [ClaudeTodo] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return try await callClaudeAPI(content: trimmed)
    }

    /// One-round chat refinement: applies `instruction` to `originalTodos` and returns the revised list.
    func refine(originalTodos: [ClaudeTodo], instruction: String) async throws -> [ClaudeTodo] {
        guard let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
              !apiKey.isEmpty else {
            print("[FileTodoService] ANTHROPIC_API_KEY not set")
            return originalTodos
        }

        let todosJSON = originalTodos
            .map { "{\"title\":\"\($0.title)\",\"priority\":\"\($0.priority)\"}" }
            .joined(separator: ",")

        let systemPrompt = """
        You are a todo refinement assistant. \
        The user has a list of extracted todos and wants to modify them. \
        Apply the user's instruction to the todo list. \
        Return ONLY a valid JSON array — no prose, no markdown fences. \
        Each element must have exactly two keys: "title" (string) and "priority" ("high", "normal", or "low").
        """

        let userMessage = "Current todos:\n[\(todosJSON)]\n\nUser instruction: \(instruction)"

        _ = apiKey  // already checked above; callClaudeAPIWithMessages re-reads it
        return try await callClaudeAPIWithMessages(system: systemPrompt, user: userMessage)
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

    private func callClaudeAPI(content: String) async throws -> [ClaudeTodo] {
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
        return try await callClaudeAPIWithMessages(system: systemPrompt, user: userMessage)
    }

    private func callClaudeAPIWithMessages(system: String, user: String) async throws -> [ClaudeTodo] {
        guard let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
              !apiKey.isEmpty else {
            print("[FileTodoService] ANTHROPIC_API_KEY not set — skipping API call")
            return []
        }

        let requestBody: [String: Any] = [
            "model": "claude-haiku-4-5",
            "max_tokens": 1024,
            "system": system,
            "messages": [
                ["role": "user", "content": user]
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

    func priority(from string: String) -> Priority {
        switch string.lowercased() {
        case "high":   return .high
        case "low":    return .low
        default:       return .normal
        }
    }
}
