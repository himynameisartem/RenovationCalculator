import Foundation

struct ChatMessage: Identifiable, Equatable {
    enum Role {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
    let imageData: [Data]
    let createdAt: Date

    init(role: Role, text: String, imageData: [Data] = [], createdAt: Date = Date()) {
        self.role = role
        self.text = text
        self.imageData = imageData
        self.createdAt = createdAt
    }
}
