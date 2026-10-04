import Foundation
import SwiftData

@Model
final class DocumentComment {
    @Attribute(.unique) var id: UUID
    var documentID: UUID
    var text: String
    var createdAt: Date

    init(id: UUID = UUID(), documentID: UUID, text: String, createdAt: Date = .now) {
        self.id = id
        self.documentID = documentID
        self.text = text
        self.createdAt = createdAt
    }
}
