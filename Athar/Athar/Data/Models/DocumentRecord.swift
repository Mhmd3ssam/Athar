import Foundation
import SwiftData

@Model
final class DocumentRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var imageFilename: String
    var thumbnailFilename: String?
    var createdAt: Date
    var lastUpdatedAt: Date
    var currentStatusID: UUID
    var isManuallyArchived: Bool
    var restoredAt: Date?
    var archivedAt: Date?
    var archiveModeRawValue: String?
    var archiveStatusNameSnapshot: String?
    var archiveStatusToneRawValue: String?
    var archiveStatusIconRawValue: String?

    init(
        id: UUID = UUID(),
        name: String,
        imageFilename: String,
        thumbnailFilename: String? = nil,
        createdAt: Date = .now,
        lastUpdatedAt: Date = .now,
        currentStatusID: UUID,
        isManuallyArchived: Bool = false,
        restoredAt: Date? = nil,
        archivedAt: Date? = nil,
        archiveModeRawValue: String? = nil,
        archiveStatusNameSnapshot: String? = nil,
        archiveStatusToneRawValue: String? = nil,
        archiveStatusIconRawValue: String? = nil
    ) {
        self.id = id
        self.name = name
        self.imageFilename = imageFilename
        self.thumbnailFilename = thumbnailFilename
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
        self.currentStatusID = currentStatusID
        self.isManuallyArchived = isManuallyArchived
        self.restoredAt = restoredAt
        self.archivedAt = archivedAt
        self.archiveModeRawValue = archiveModeRawValue
        self.archiveStatusNameSnapshot = archiveStatusNameSnapshot
        self.archiveStatusToneRawValue = archiveStatusToneRawValue
        self.archiveStatusIconRawValue = archiveStatusIconRawValue
    }
}
