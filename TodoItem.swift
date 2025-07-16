import Foundation

struct TodoItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?
    var reminderDate: Date?
    var reminderEnabled: Bool = true
    var createdAt: Date
    var category: Category
    
    init(title: String, description: String = "", priority: Priority = .medium, dueDate: Date? = nil, category: Category = .personal, reminderDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.isCompleted = false
        self.priority = priority
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.reminderEnabled = true
        self.createdAt = Date()
        self.category = category
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode id if present, otherwise generate new one
        if let id = try? container.decode(UUID.self, forKey: .id) {
            self.id = id
        } else {
            self.id = UUID()
        }
        
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        self.priority = try container.decode(Priority.self, forKey: .priority)
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.reminderDate = try container.decodeIfPresent(Date.self, forKey: .reminderDate)
        self.reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? true
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.category = try container.decode(Category.self, forKey: .category)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(priority, forKey: .priority)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(reminderDate, forKey: .reminderDate)
        try container.encode(reminderEnabled, forKey: .reminderEnabled)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(category, forKey: .category)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, description, isCompleted, priority, dueDate, reminderDate, reminderEnabled, createdAt, category
    }
}

enum Priority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "exclamationmark.circle"
        }
    }
}

enum Category: String, CaseIterable, Codable {
    case personal = "Yours"
    case work = "Work"
    case shopping = "Groceries"
    case learning = "Learning"
    case meetUps = "MeetUps"
    case family = "Family"
    
    var icon: String {
        switch self {
        case .personal: return "person.circle"
        case .work: return "briefcase"
        case .shopping: return "cart"
        case .learning: return "book"
        case .meetUps: return "person.3"
        case .family: return "house.fill"
        }
    }
    
    var color: String {
        switch self {
        case .personal: return "blue"
        case .work: return "purple"
        case .shopping: return "green"
        case .learning: return "orange"
        case .meetUps: return "teal"
        case .family: return "pink"
        }
    }
} 