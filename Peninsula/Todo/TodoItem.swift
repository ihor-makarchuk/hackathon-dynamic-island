import Foundation

enum Priority: String, Codable, CaseIterable {
    case high
    case normal
    case low
}

struct ActionArguments: Codable {
    var title: String?
    var attendees: [String]?
    var startDate: String?   // ISO 8601
    var description: String?
    var duration: Int?       // minutes
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
    var actionType: String?
    var actionArguments: ActionArguments?
    var serverId: String?
    var completedByAI: Bool

    init(
        id: UUID = UUID(),
        title: String,
        priority: Priority = .normal,
        isDone: Bool = false,
        createdAt: Date = Date(),
        dueDate: Date = Date(),
        link: String? = nil,
        notes: String? = nil,
        actionType: String? = nil,
        actionArguments: ActionArguments? = nil,
        serverId: String? = nil,
        completedByAI: Bool = false
    ) {
        self.id = id
        self.title = title
        self.priority = priority
        self.isDone = isDone
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.link = link
        self.notes = notes
        self.actionType = actionType
        self.actionArguments = actionArguments
        self.serverId = serverId
        self.completedByAI = completedByAI
    }

    // Backward-compatible decoding
    enum CodingKeys: String, CodingKey {
        case id, title, priority, isDone, createdAt, dueDate, link, notes, actionType, actionArguments, serverId, completedByAI
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(UUID.self,     forKey: .id)
        title           = try c.decode(String.self,   forKey: .title)
        priority        = try c.decode(Priority.self, forKey: .priority)
        isDone          = try c.decode(Bool.self,     forKey: .isDone)
        createdAt       = try c.decode(Date.self,     forKey: .createdAt)
        dueDate         = try c.decode(Date.self,     forKey: .dueDate)
        link            = try c.decodeIfPresent(String.self,         forKey: .link)
        notes           = try c.decodeIfPresent(String.self,         forKey: .notes)
        actionType      = try c.decodeIfPresent(String.self,         forKey: .actionType)
        actionArguments = try c.decodeIfPresent(ActionArguments.self, forKey: .actionArguments)
        serverId        = try c.decodeIfPresent(String.self,         forKey: .serverId)
        completedByAI   = try c.decodeIfPresent(Bool.self,           forKey: .completedByAI) ?? false
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
