import Foundation
import SwiftUI

class TodoStore: ObservableObject {
    static let shared = TodoStore()

    private let storageKey = "peninsula.todos"

    @Published var items: [TodoItem] = []

    init() {
        load()
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
        let active = dayItems.filter { !$0.isDone }.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
        let done = dayItems.filter { $0.isDone }
        return active + done
    }

    /// Count of incomplete items for a specific calendar day
    func incompleteCount(for date: Date) -> Int {
        let calendar = Calendar.current
        return items.filter { calendar.isDate($0.dueDate, inSameDayAs: date) && !$0.isDone }.count
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
