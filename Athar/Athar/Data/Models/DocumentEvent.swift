import Foundation
import SwiftData

@Model
final class DocumentEvent {
    @Attribute(.unique) var id: UUID
    var documentID: UUID
    var kindRawValue: String
    var createdAt: Date
    var oldStatusID: UUID?
    var oldStatusNameSnapshot: String?
    var oldStatusToneRawValue: String?
    var oldStatusIconRawValue: String?
    var newStatusID: UUID?
    var newStatusNameSnapshot: String?
    var newStatusToneRawValue: String?
    var newStatusIconRawValue: String?
    var detail: String?

    init(
        id: UUID = UUID(),
        documentID: UUID,
        kindRawValue: String,
        createdAt: Date = .now,
        oldStatusID: UUID? = nil,
        oldStatusNameSnapshot: String? = nil,
        oldStatusToneRawValue: String? = nil,
        oldStatusIconRawValue: String? = nil,
        newStatusID: UUID? = nil,
        newStatusNameSnapshot: String? = nil,
        newStatusToneRawValue: String? = nil,
        newStatusIconRawValue: String? = nil,
        detail: String? = nil
    ) {
        self.id = id
        self.documentID = documentID
        self.kindRawValue = kindRawValue
        self.createdAt = createdAt
        self.oldStatusID = oldStatusID
        self.oldStatusNameSnapshot = oldStatusNameSnapshot
        self.oldStatusToneRawValue = oldStatusToneRawValue
        self.oldStatusIconRawValue = oldStatusIconRawValue
        self.newStatusID = newStatusID
        self.newStatusNameSnapshot = newStatusNameSnapshot
        self.newStatusToneRawValue = newStatusToneRawValue
        self.newStatusIconRawValue = newStatusIconRawValue
        self.detail = detail
    }
}
