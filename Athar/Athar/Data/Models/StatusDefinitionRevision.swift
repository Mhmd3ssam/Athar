import Foundation
import SwiftData

@Model
final class StatusDefinitionRevision {
    @Attribute(.unique) var id: UUID
    var statusID: UUID
    var recordedAt: Date
    var labelSnapshot: String
    var toneRawValue: String
    var iconRawValue: String

    init(
        id: UUID = UUID(),
        statusID: UUID,
        recordedAt: Date = .now,
        labelSnapshot: String,
        tone: AtharStatusTone,
        icon: AtharStatusIcon
    ) {
        self.id = id
        self.statusID = statusID
        self.recordedAt = recordedAt
        self.labelSnapshot = labelSnapshot
        self.toneRawValue = tone.rawValue
        self.iconRawValue = icon.rawValue
    }
}
