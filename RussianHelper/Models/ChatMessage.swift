import Foundation
import UIKit

// MARK: - MessageRole

enum MessageRole {
    case user, assistant
}

// MARK: - ChatMessage

struct ChatMessage: Identifiable {
    let id: UUID
    var role: MessageRole
    var content: String
    var attachedImage: UIImage?
    let createdAt: Date
    var isStreaming: Bool

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String = "",
        attachedImage: UIImage? = nil,
        createdAt: Date = .now,
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.attachedImage = attachedImage
        self.createdAt = createdAt
        self.isStreaming = isStreaming
    }
}

// MARK: - ChatSession

struct ChatSession: Identifiable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    let createdAt: Date

    var lastMessage: ChatMessage? { messages.last }

    init(
        id: UUID = UUID(),
        title: String = "새 채팅",
        messages: [ChatMessage] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
    }
}
