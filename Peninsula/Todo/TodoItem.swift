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
    var dueDate: Date
    var link: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        title: String,
        priority: Priority = .normal,
        isDone: Bool = false,
        createdAt: Date = Date(),
        dueDate: Date = Date(),
        link: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.priority = priority
        self.isDone = isDone
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.link = link
        self.notes = notes
    }
}

extension Priority {
    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .normal: return 1
        case .low: return 2
        }
    }
}
