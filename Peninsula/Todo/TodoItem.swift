import Foundation

enum Priority: String, Codable, CaseIterable {
    case high
    case normal
    case low
}

struct TodoItem: Identifiable, Codable {
    var id: UUID
    var title: String
    var priority: Priority
    var isDone: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        priority: Priority = .normal,
        isDone: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.priority = priority
        self.isDone = isDone
        self.createdAt = createdAt
    }
}
