import Foundation
import SwiftUI

// MARK: - Remote DTO

private struct RemoteTodoDTO: Decodable {
    let id: String
    let text: String
    let pageUrl: String?
    let actionType: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyCodingKey.self)
        id = try c.decodeIfPresent(String.self, forKey: AnyCodingKey("_id"))
            ?? c.decode(String.self, forKey: AnyCodingKey("id"))
        text = try c.decode(String.self, forKey: AnyCodingKey("text"))
        pageUrl = try c.decodeIfPresent(String.self, forKey: AnyCodingKey("pageUrl"))
        actionType = try c.decodeIfPresent(String.self, forKey: AnyCodingKey("actionType"))
    }
}

private struct AnyCodingKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { self.stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

// MARK: - Store

class TodoStore: ObservableObject {
    static let shared = TodoStore()

    private let storageKey = "peninsula.todos"

    @Published var items: [TodoItem] = []
    /// Transient — not persisted. Cleared on app launch.
    @Published var inProgressIds: Set<UUID> = []

    private let demoItemIds: [UUID] = [
        UUID(uuidString: "a1b2c3d4-1234-5678-9abc-def012345678")!,
        UUID(uuidString: "b2c3d4e5-2345-6789-abcd-ef0123456789")!,
        UUID(uuidString: "c3d4e5f6-3456-789a-bcde-f01234567890")!,
    ]

    private var pollTimer: Timer?

    init() {
        load()
        seedDemoItemsIfNeeded()
        refreshDemoItemDates()
        startPolling()
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { await self?.fetchFromServer() }
        }
    }

    private func refreshDemoItemDates() {
        let today = Calendar.current.startOfDay(for: Date())
        var changed = false
        for id in demoItemIds {
            guard let index = items.firstIndex(where: { $0.id == id }) else { continue }
            if !Calendar.current.isDate(items[index].dueDate, inSameDayAs: today) {
                items[index].dueDate = today
                changed = true
            }
        }
        if changed { save() }
    }

    // MARK: - Demo Seed

    private let demoSeedVersionKey = "peninsula.todos.demoSeedVersion"
    private let currentDemoSeedVersion = 2

    private func seedDemoItemsIfNeeded() {
        let savedVersion = UserDefaults.standard.integer(forKey: demoSeedVersionKey)
        guard savedVersion < currentDemoSeedVersion else { return }

        // Remove previously seeded non-server items and replace with current demos
        items.removeAll { $0.serverId == nil }

        let today = Calendar.current.startOfDay(for: Date())
        let demos: [TodoItem] = [
            TodoItem(
                id: UUID(uuidString: "a1b2c3d4-1234-5678-9abc-def012345678") ?? UUID(),
                title: "Schedule sync on Agent Builder roadmap with Viktor",
                priority: .high,
                dueDate: today,
                link: "https://app.slack.com/client/grammarly/agent-quality",
                notes: "Viktor wants to align on eval framework progress before Friday planning. Prepare a short summary of current coverage gaps.",
                actionType: "create_calendar_event",
                actionArguments: ActionArguments(
                    title: "Agent Builder Roadmap Sync",
                    attendees: ["viktor.zamoruev@grammarly.com"],
                    startDate: "2026-03-20T14:00:00.000Z",
                    description: "Discuss eval framework progress, current coverage gaps, and next steps for agent quality track.",
                    duration: 30
                )
            ),
            TodoItem(
                id: UUID(uuidString: "b2c3d4e5-2345-6789-abcd-ef0123456789") ?? UUID(),
                title: "Review and sign updated relocation agreement",
                priority: .normal,
                dueDate: today,
                link: "https://mail.google.com/mail/u/0/#inbox/relocation-thread",
                notes: "HR sent the updated agreement with the Berlin stipend details. Needs signature by Friday."
            ),
            TodoItem(
                id: UUID(uuidString: "c3d4e5f6-3456-789a-bcde-f01234567890") ?? UUID(),
                title: "Set up 1:1 with Ankita to review hackathon results",
                priority: .high,
                dueDate: today,
                link: "https://docs.google.com/document/d/agent-eval-spec",
                notes: "Ankita mentioned wanting to debrief on hackathon feedback and discuss next steps for productionizing the prototype.",
                actionType: "create_calendar_event",
                actionArguments: ActionArguments(
                    title: "Hackathon Debrief — Ankita & Ihor",
                    attendees: ["ankita.pm@grammarly.com"],
                    startDate: "2026-03-19T16:00:00.000Z",
                    description: "Review hackathon demo feedback, discuss path to production, align on next steps.",
                    duration: 25
                )
            ),
        ]
        demos.forEach { items.append($0) }
        save()
        UserDefaults.standard.set(currentDemoSeedVersion, forKey: demoSeedVersionKey)
    }

    // MARK: - CRUD

    /// Add a new item and persist immediately
    func add(_ item: TodoItem) {
        items.append(item)
        save()
    }

    /// Toggle isDone for item with given id, persist immediately
    func toggleDone(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isDone.toggle()
        save()
    }

    /// Mark item as in-progress (transient — not persisted)
    func setInProgress(id: UUID, _ value: Bool) {
        if value { inProgressIds.insert(id) } else { inProgressIds.remove(id) }
    }

    /// Mark item as done by AI agent, store optional event URL as the link
    func markDoneByAI(id: UUID, eventURL: URL?) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isDone = true
        items[index].completedByAI = true
        if let url = eventURL {
            items[index].link = url.absoluteString
        }
        inProgressIds.remove(id)
        save()
    }

    /// Delete item by id, persist immediately
    func delete(id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    /// Update item fields (for detail editing: title, link, notes), persist immediately
    func update(id: UUID, title: String? = nil, link: String? = nil, notes: String? = nil) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if let title = title { items[index].title = title }
        if let link = link { items[index].link = link }
        if let notes = notes { items[index].notes = notes }
        save()
    }

    // MARK: - Filtering

    /// Items for a specific calendar day, sorted: active by priority (high > normal > low), then completed at bottom
    func items(for date: Date) -> [TodoItem] {
        let calendar = Calendar.current
        let dayItems = items.filter { calendar.isDate($0.dueDate, inSameDayAs: date) }
        let inProgress = dayItems.filter { inProgressIds.contains($0.id) }
        let active = dayItems.filter { !$0.isDone && !inProgressIds.contains($0.id) }
            .sorted { $0.priority.sortOrder < $1.priority.sortOrder }
        let done = dayItems.filter { $0.isDone }
        return inProgress + active + done
    }

    /// Count of incomplete items for a specific calendar day
    func incompleteCount(for date: Date) -> Int {
        let calendar = Calendar.current
        return items.filter { calendar.isDate($0.dueDate, inSameDayAs: date) && !$0.isDone }.count
    }

    // MARK: - Remote Sync

    func fetchFromServer() async {
        guard let url = URL(string: "http://localhost:3001/todos") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let dtos = try JSONDecoder().decode([RemoteTodoDTO].self, from: data)
            await MainActor.run { importRemote(dtos) }
        } catch {
            print("[TodoStore] fetchFromServer error: \(error)")
        }
    }

    func hardRefreshFromServer() async {
        await fetchFromServer()
    }

    // MARK: - Keyword action injection

    private typealias InjectedAction = (type: String, args: ActionArguments)

    private func injectedAction(for text: String) -> InjectedAction? {
        let lower = text.lowercased()
        if lower.contains("relocation") {
            return (
                type: "create_calendar_event",
                args: ActionArguments(
                    title: "Sign Relocation Agreement",
                    attendees: ["hr@grammarly.com"],
                    startDate: "2026-03-20T09:00:00.000Z",
                    description: "Review and sign the updated relocation agreement with Berlin stipend details.",
                    duration: 15
                )
            )
        }
        if lower.contains("2pm") {
            return (
                type: "create_calendar_event",
                args: ActionArguments(
                    title: "Agent Builder Roadmap Sync",
                    attendees: ["viktor.zamoruev@grammarly.com"],
                    startDate: "2026-03-20T14:00:00.000Z",
                    description: "Sync on Agent Builder roadmap and eval framework progress.",
                    duration: 30
                )
            )
        }
        return nil
    }

    private func importRemote(_ dtos: [RemoteTodoDTO]) {
        let serverIds = Set(dtos.map { $0.id })
        var changed = false

        // Remove server items no longer returned
        let countBefore = items.count
        items.removeAll { $0.serverId != nil && !serverIds.contains($0.serverId!) }
        if items.count != countBefore { changed = true }

        // Add or update each item from server
        for dto in dtos {
            let injected = injectedAction(for: dto.text)
            let effectiveActionType = dto.actionType ?? injected?.type
            let effectiveArgs = injected?.args

            if let index = items.firstIndex(where: { $0.serverId == dto.id }) {
                if items[index].title != dto.text { items[index].title = dto.text; changed = true }
                // Don't overwrite link when AI stored the calendar event URL there
                if !items[index].completedByAI && items[index].link != dto.pageUrl { items[index].link = dto.pageUrl; changed = true }
                if items[index].actionType != effectiveActionType {
                    items[index].actionType = effectiveActionType
                    changed = true
                }
                if items[index].actionArguments == nil, let args = effectiveArgs {
                    items[index].actionArguments = args
                    changed = true
                }
            } else {
                items.append(TodoItem(
                    title: dto.text,
                    dueDate: Calendar.current.startOfDay(for: Date()),
                    link: dto.pageUrl,
                    actionType: effectiveActionType,
                    actionArguments: effectiveArgs,
                    serverId: dto.id
                ))
                changed = true
            }
        }

        if changed { save() }
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else { return }
        items = decoded
    }
}
