import Foundation
import SwiftData

@MainActor
enum AtharDataController {
    static func makeContainer() -> ModelContainer {
        do {
            let schema = Schema([
                StatusDefinition.self,
                StatusDefinitionRevision.self,
                DocumentRecord.self,
                DocumentEvent.self,
                DocumentComment.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            try seedIfNeeded(in: container.mainContext)
            try ensureStatusRevisions(in: container.mainContext)
            return container
        } catch {
            fatalError("Unable to create Athar local store: \(error)")
        }
    }

    static func seedIfNeeded(in context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<StatusDefinition>())
        guard existing.isEmpty else { return }

        let defaults: [StatusDefinition] = [
            StatusDefinition(seedKey: "with_me", tone: .withMe, icon: .person, sortOrder: 0),
            StatusDefinition(seedKey: "out_for_signature", tone: .outForSignature, icon: .arrow, sortOrder: 1),
            StatusDefinition(seedKey: "signed", tone: .signed, icon: .check, sortOrder: 2),
            StatusDefinition(seedKey: "delivered", tone: .delivered, icon: .tray, sortOrder: 3)
        ]

        defaults.forEach(context.insert)
        try context.save()
    }

    static func ensureStatusRevisions(in context: ModelContext) throws {
        let statuses = try context.fetch(FetchDescriptor<StatusDefinition>())
        let revisions = try context.fetch(FetchDescriptor<StatusDefinitionRevision>())
        let statusIDsWithRevision = Set(revisions.map(\.statusID))

        for status in statuses where !statusIDsWithRevision.contains(status.id) {
            let label: String
            switch status.seedKey {
            case "with_me": label = "With me"
            case "out_for_signature": label = "Out for signature"
            case "signed": label = "Signed"
            case "delivered": label = "Delivered"
            default: label = status.customName ?? "Status"
            }

            context.insert(
                StatusDefinitionRevision(
                    statusID: status.id,
                    recordedAt: status.createdAt,
                    labelSnapshot: label,
                    tone: status.tone,
                    icon: status.icon
                )
            )
        }

        try context.save()
    }
}
