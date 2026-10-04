import Foundation
import SwiftData

@MainActor
enum DocumentArchiveService {
    static let visibilityDays = 7

    static func recomputeHistoricalClassification(
        in context: ModelContext,
        language: AtharLanguage,
        now: Date = .now
    ) throws {
        let documents = try context.fetch(FetchDescriptor<DocumentRecord>())
        let statuses = try context.fetch(FetchDescriptor<StatusDefinition>())
        let revisions = try context.fetch(FetchDescriptor<StatusDefinitionRevision>())
        let events = try context.fetch(FetchDescriptor<DocumentEvent>())

        var changed = false

        for document in documents where document.archivedAt == nil {
            guard let boundary = automaticArchiveBoundary(for: document, now: now) else { continue }

            let snapshot = statusSnapshot(
                for: document,
                at: boundary,
                language: language,
                statuses: statuses,
                revisions: revisions,
                events: events
            )

            applyArchive(
                to: document,
                mode: .automatic,
                archivedAt: boundary,
                snapshot: snapshot,
                context: context
            )
            changed = true
        }

        if changed {
            try context.save()
        }
    }

    static func manualArchive(
        _ document: DocumentRecord,
        in context: ModelContext,
        language: AtharLanguage,
        now: Date = .now
    ) throws {
        guard document.archivedAt == nil else { return }

        let statuses = try context.fetch(FetchDescriptor<StatusDefinition>())
        let status = statuses.first { $0.id == document.currentStatusID }
        let snapshot = ArchiveStatusSnapshot(
            name: status?.displayName(language: language) ?? localizedFallbackStatus(language: language),
            toneRawValue: status?.toneRawValue ?? AtharStatusTone.withMe.rawValue,
            iconRawValue: status?.iconRawValue ?? AtharStatusIcon.person.rawValue,
            statusID: status?.id ?? document.currentStatusID
        )

        applyArchive(
            to: document,
            mode: .manual,
            archivedAt: now,
            snapshot: snapshot,
            context: context
        )
        try context.save()
    }

    static func restore(
        _ document: DocumentRecord,
        in context: ModelContext,
        language: AtharLanguage,
        now: Date = .now
    ) throws {
        guard document.archivedAt != nil else { return }

        let statuses = try context.fetch(FetchDescriptor<StatusDefinition>())
        let status = statuses.first { $0.id == document.currentStatusID }

        document.isManuallyArchived = false
        document.archivedAt = nil
        document.archiveModeRawValue = nil
        document.archiveStatusNameSnapshot = nil
        document.archiveStatusToneRawValue = nil
        document.archiveStatusIconRawValue = nil
        document.restoredAt = now
        document.lastUpdatedAt = now

        context.insert(
            DocumentEvent(
                documentID: document.id,
                kindRawValue: DocumentEventKind.restored.rawValue,
                createdAt: now,
                newStatusID: status?.id ?? document.currentStatusID,
                newStatusNameSnapshot: status?.displayName(language: language),
                newStatusToneRawValue: status?.toneRawValue,
                newStatusIconRawValue: status?.iconRawValue,
                detail: language == .arabic ? "عاد إلى الرئيسية لمدة ٧ أيام" : "Back in Timeline for 7 days"
            )
        )

        try context.save()
    }

    static func delete(
        _ document: DocumentRecord,
        in context: ModelContext
    ) throws {
        let events = try context.fetch(FetchDescriptor<DocumentEvent>())
            .filter { $0.documentID == document.id }
        let comments = try context.fetch(FetchDescriptor<DocumentComment>())
            .filter { $0.documentID == document.id }

        events.forEach(context.delete)
        comments.forEach(context.delete)
        AtharImageStore.delete(
            imageFilename: document.imageFilename,
            thumbnailFilename: document.thumbnailFilename
        )
        context.delete(document)
        try context.save()
    }

    static func isVisibleOnTimeline(_ document: DocumentRecord, now: Date = .now) -> Bool {
        guard document.archivedAt == nil else { return false }

        let calendar = Calendar.current
        if let restoredAt = document.restoredAt {
            let restoreDay = calendar.startOfDay(for: restoredAt)
            let expiration = calendar.date(byAdding: .day, value: visibilityDays, to: restoreDay) ?? restoreDay
            return now < expiration
        }

        let today = calendar.startOfDay(for: now)
        let cutoff = calendar.date(byAdding: .day, value: -(visibilityDays - 1), to: today) ?? today
        return document.createdAt >= cutoff
    }

    static func isRestoredAndVisible(_ document: DocumentRecord, now: Date = .now) -> Bool {
        guard document.archivedAt == nil, document.restoredAt != nil else { return false }
        return isVisibleOnTimeline(document, now: now)
    }

    static func archiveReasonKey(for document: DocumentRecord) -> String {
        switch DocumentArchiveMode(rawValue: document.archiveModeRawValue ?? "") {
        case .manual: "archive.reason.manual"
        case .automatic: "archive.reason.automatic"
        case .none: "archive.reason.automatic"
        }
    }

    private static func automaticArchiveBoundary(for document: DocumentRecord, now: Date) -> Date? {
        let calendar = Calendar.current
        let sourceDate = document.restoredAt ?? document.createdAt
        let start = calendar.startOfDay(for: sourceDate)
        guard let boundary = calendar.date(byAdding: .day, value: visibilityDays, to: start) else {
            return nil
        }
        return now >= boundary ? boundary : nil
    }

    private static func applyArchive(
        to document: DocumentRecord,
        mode: DocumentArchiveMode,
        archivedAt: Date,
        snapshot: ArchiveStatusSnapshot,
        context: ModelContext
    ) {
        document.isManuallyArchived = mode == .manual
        document.archivedAt = archivedAt
        document.archiveModeRawValue = mode.rawValue
        document.archiveStatusNameSnapshot = snapshot.name
        document.archiveStatusToneRawValue = snapshot.toneRawValue
        document.archiveStatusIconRawValue = snapshot.iconRawValue
        document.lastUpdatedAt = archivedAt

        context.insert(
            DocumentEvent(
                documentID: document.id,
                kindRawValue: DocumentEventKind.archived.rawValue,
                createdAt: archivedAt,
                newStatusID: snapshot.statusID,
                newStatusNameSnapshot: snapshot.name,
                newStatusToneRawValue: snapshot.toneRawValue,
                newStatusIconRawValue: snapshot.iconRawValue,
                detail: mode.rawValue
            )
        )
    }

    private static func statusSnapshot(
        for document: DocumentRecord,
        at boundary: Date,
        language: AtharLanguage,
        statuses: [StatusDefinition],
        revisions: [StatusDefinitionRevision],
        events: [DocumentEvent]
    ) -> ArchiveStatusSnapshot {
        let relevantStatusEvent = events
            .filter {
                $0.documentID == document.id &&
                $0.createdAt <= boundary &&
                ($0.kindRawValue == DocumentEventKind.created.rawValue || $0.kindRawValue == DocumentEventKind.statusChanged.rawValue) &&
                $0.newStatusID != nil
            }
            .max { $0.createdAt < $1.createdAt }

        let statusID = relevantStatusEvent?.newStatusID ?? document.currentStatusID
        let status = statuses.first { $0.id == statusID }
        let revision = revisions
            .filter { $0.statusID == statusID && $0.recordedAt <= boundary }
            .max { $0.recordedAt < $1.recordedAt }

        let label: String
        if let revision {
            label = localizedRevisionLabel(revision.labelSnapshot, status: status, language: language)
        } else if let eventLabel = relevantStatusEvent?.newStatusNameSnapshot {
            label = eventLabel
        } else {
            label = status?.displayName(language: language) ?? localizedFallbackStatus(language: language)
        }

        return ArchiveStatusSnapshot(
            name: label,
            toneRawValue: revision?.toneRawValue ?? relevantStatusEvent?.newStatusToneRawValue ?? status?.toneRawValue ?? AtharStatusTone.withMe.rawValue,
            iconRawValue: revision?.iconRawValue ?? relevantStatusEvent?.newStatusIconRawValue ?? status?.iconRawValue ?? AtharStatusIcon.person.rawValue,
            statusID: statusID
        )
    }

    private static func localizedRevisionLabel(
        _ label: String,
        status: StatusDefinition?,
        language: AtharLanguage
    ) -> String {
        guard let status, status.customName == nil else { return label }

        switch status.seedKey {
        case "with_me": return language == .arabic ? "معايا" : "With me"
        case "out_for_signature": return language == .arabic ? "خرجت للتوقيع" : "Out for signature"
        case "signed": return language == .arabic ? "اتمضت" : "Signed"
        case "delivered": return language == .arabic ? "تم التسليم" : "Delivered"
        default: return label
        }
    }

    private static func localizedFallbackStatus(language: AtharLanguage) -> String {
        language == .arabic ? "حالة" : "Status"
    }
}

private struct ArchiveStatusSnapshot {
    let name: String
    let toneRawValue: String
    let iconRawValue: String
    let statusID: UUID
}
