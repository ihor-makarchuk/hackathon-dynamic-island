import Foundation
import EventKit

enum CalendarAgentError: LocalizedError {
    case accessDenied
    case noDefaultCalendar
    case apiKeyMissing
    case dateParsingFailed
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .accessDenied: return "Calendar access denied. Open System Settings > Privacy & Security > Calendars."
        case .noDefaultCalendar: return "No default calendar found."
        case .apiKeyMissing: return "ANTHROPIC_API_KEY not set."
        case .dateParsingFailed: return "Could not determine event date."
        case .saveFailed(let e): return "Failed to save event: \(e.localizedDescription)"
        }
    }
}

class CalendarAgentService {
    static let shared = CalendarAgentService()
    private let store = EKEventStore()

    /// Creates a calendar event from a TodoItem.
    /// 1. Requests write-only EventKit access
    /// 2. Calls Claude to infer date/time from title + notes
    /// 3. Creates and saves EKEvent to default calendar
    func createEvent(from item: TodoItem) async throws {
        // 1. Check authorization and request if needed
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .denied || status == .restricted {
            throw CalendarAgentError.accessDenied
        }
        let granted = try await store.requestWriteOnlyAccessToEvents()
        guard granted else {
            throw CalendarAgentError.accessDenied
        }

        // 2. Infer event date from title + notes via Claude
        let eventDate = try await inferEventDate(from: item)

        // 3. Create EKEvent
        guard let calendar = store.defaultCalendarForNewEvents else {
            throw CalendarAgentError.noDefaultCalendar
        }

        let event = EKEvent(eventStore: store)
        event.title = item.title
        event.notes = item.notes
        if let linkStr = item.link, let url = URL(string: linkStr) {
            event.url = url
        }
        event.startDate = eventDate
        event.endDate = eventDate.addingTimeInterval(3600)  // 1-hour default
        event.calendar = calendar

        do {
            try store.save(event, span: .thisEvent)
        } catch {
            throw CalendarAgentError.saveFailed(error)
        }
    }

    // MARK: - Date Inference via Claude

    private func inferEventDate(from item: TodoItem) async throws -> Date {
        guard let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
              !apiKey.isEmpty else {
            // Fallback: tomorrow at 10 AM
            print("[CalendarAgent] No API key — using fallback date")
            return fallbackDate()
        }

        let context = [item.title, item.notes].compactMap { $0 }.joined(separator: "\n")

        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let nowISO = formatter.string(from: now)

        let systemPrompt = """
        You are a calendar event date assistant. Given a todo item, extract the event date and time. \
        The current date/time is \(nowISO). \
        Return ONLY valid JSON with exactly two keys: "startISO" (ISO 8601 date-time, local time) and "title" (string). \
        If no date/time is found in the text, use tomorrow at 10:00 AM local time. \
        No prose, no markdown fences, no explanation.
        """

        let userMessage = "Todo item:\n\(context)"

        let requestBody: [String: Any] = [
            "model": "claude-haiku-4-5",
            "max_tokens": 256,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return fallbackDate()
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
            print("[CalendarAgent] API error — using fallback date")
            return fallbackDate()
        }

        // Parse Anthropic response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstContent = contentArray.first,
              let rawText = firstContent["text"] as? String else {
            return fallbackDate()
        }

        // Parse the JSON Claude returned
        guard let jsonData = rawText.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let startISO = parsed["startISO"] as? String else {
            return fallbackDate()
        }

        // Try parsing ISO 8601
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: startISO) {
            return date
        }

        // Try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: startISO) {
            return date
        }

        // Try DateFormatter for common ISO variants
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for format in ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm", "yyyy-MM-dd HH:mm"] {
            df.dateFormat = format
            if let date = df.date(from: startISO) {
                return date
            }
        }

        return fallbackDate()
    }

    private func fallbackDate() -> Date {
        // Tomorrow at 10:00 AM
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow)!
    }
}
