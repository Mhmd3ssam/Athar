import SwiftData
import SwiftUI

struct ManageStatusesView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.layoutDirection) private var layoutDirection

    @Query(sort: \StatusDefinition.sortOrder) private var statuses: [StatusDefinition]
    @Query private var documents: [DocumentRecord]
    @Query private var events: [DocumentEvent]

    @State private var editingStatus: StatusDefinition?
    @State private var isAddingStatus = false
    @State private var pendingDeletion: StatusDefinition?
    @State private var pendingRetirement: StatusDefinition?
    @State private var blockedMessage: LocalizedStringKey?

    var body: some View {
        ZStack {
            AtharColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Rectangle()
                    .fill(AtharColors.border)
                    .frame(height: 1)
                    .padding(.horizontal, AtharLayout.screenInset)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(statuses) { status in
                            statusRow(status)

                            if status.id != statuses.last?.id {
                                Rectangle()
                                    .fill(AtharColors.border)
                                    .frame(height: 1)
                            }
                        }
                    }
                    .padding(.horizontal, AtharLayout.screenInset)

                    Button(action: { isAddingStatus = true }) {
                        Label("statuses.add", systemImage: "plus")
                            .font(AtharTypography.button)
                            .foregroundStyle(AtharColors.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 60)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AtharLayout.screenInset)
                    .padding(.top, AtharSpacing.x2)

                    Text("statuses.archiveNote")
                        .font(AtharTypography.secondary)
                        .foregroundStyle(AtharColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, AtharLayout.screenInset)
                        .padding(.top, AtharSpacing.x6)
                        .padding(.bottom, AtharSpacing.x8)
                }
            }
        }
        .fullScreenCover(isPresented: $isAddingStatus) {
            StatusEditorView(mode: .add)
        }
        .fullScreenCover(item: $editingStatus) { status in
            StatusEditorView(mode: .edit(status))
        }
        .sheet(item: $pendingDeletion) { status in
            StatusRemovalSheet(
                statusName: status.displayName(language: preferences.language),
                kind: .delete,
                onCancel: { pendingDeletion = nil },
                onConfirm: { delete(status) }
            )
        }
        .sheet(item: $pendingRetirement) { status in
            StatusRemovalSheet(
                statusName: status.displayName(language: preferences.language),
                kind: .retire,
                onCancel: { pendingRetirement = nil },
                onConfirm: { retire(status) }
            )
        }
        .alert(
            "statuses.keepOne.title",
            isPresented: Binding(
                get: { blockedMessage != nil },
                set: { if !$0 { blockedMessage = nil } }
            )
        ) {
            Button("common.ok") { blockedMessage = nil }
        } message: {
            if let blockedMessage {
                Text(blockedMessage)
            }
        }
    }

    private var header: some View {
        HStack(spacing: AtharSpacing.x3) {
            Button(action: { dismiss() }) {
                Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AtharColors.text)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("common.back"))

            Text("statuses.manage.title")
                .font(AtharTypography.screenTitle)
                .foregroundStyle(AtharColors.text)
                .accessibilityAddTraits(.isHeader)

            Spacer()
        }
        .padding(.horizontal, AtharLayout.screenInset)
        .padding(.top, AtharSpacing.x4)
        .padding(.bottom, AtharSpacing.x4)
    }

    private func statusRow(_ status: StatusDefinition) -> some View {
        HStack(spacing: AtharSpacing.x4) {
            ZStack {
                Circle()
                    .fill(status.tone.background)
                    .frame(width: 44, height: 44)

                Image(systemName: status.icon.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(status.tone.foreground)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(status.displayName(language: preferences.language))
                    .font(AtharTypography.rowTitle)
                    .foregroundStyle(AtharColors.text)
                    .fixedSize(horizontal: false, vertical: true)

                if status.isRetired {
                    Text("statuses.retired")
                        .font(AtharTypography.secondary)
                        .foregroundStyle(AtharColors.textSecondary)
                }
            }

            Spacer(minLength: AtharSpacing.x3)

            Menu {
                Button("statuses.edit", systemImage: "pencil") {
                    editingStatus = status
                }

                if status.sortOrder > 0 {
                    Button("statuses.moveUp", systemImage: "arrow.up") {
                        move(status, offset: -1)
                    }
                }

                if status.sortOrder < statuses.count - 1 {
                    Button("statuses.moveDown", systemImage: "arrow.down") {
                        move(status, offset: 1)
                    }
                }

                Divider()

                if status.isRetired {
                    Button("statuses.reactivate", systemImage: "arrow.uturn.backward") {
                        reactivate(status)
                    }
                } else if isUsed(status) {
                    Button("statuses.retire.action", systemImage: "archivebox", role: .destructive) {
                        requestRetire(status)
                    }
                } else {
                    Button("statuses.delete.action", systemImage: "trash", role: .destructive) {
                        requestDelete(status)
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AtharColors.text)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(Text("common.more"))
        }
        .frame(minHeight: 68)
    }

    private var selectableCount: Int {
        statuses.filter { !$0.isRetired }.count
    }

    private func isUsed(_ status: StatusDefinition) -> Bool {
        documents.contains { $0.currentStatusID == status.id }
            || events.contains { $0.oldStatusID == status.id || $0.newStatusID == status.id }
    }

    private func requestDelete(_ status: StatusDefinition) {
        guard selectableCount > 1 || status.isRetired else {
            blockedMessage = "statuses.keepOne.message"
            return
        }
        pendingDeletion = status
    }

    private func requestRetire(_ status: StatusDefinition) {
        guard selectableCount > 1 else {
            blockedMessage = "statuses.keepOne.message"
            return
        }
        pendingRetirement = status
    }

    private func delete(_ status: StatusDefinition) {
        modelContext.delete(status)
        normalizeOrder()
        try? modelContext.save()
        pendingDeletion = nil
    }

    private func retire(_ status: StatusDefinition) {
        status.isRetired = true
        recordRevision(status)
        try? modelContext.save()
        pendingRetirement = nil
    }

    private func reactivate(_ status: StatusDefinition) {
        status.isRetired = false
        recordRevision(status)
        try? modelContext.save()
    }

    private func move(_ status: StatusDefinition, offset: Int) {
        guard let currentIndex = statuses.firstIndex(where: { $0.id == status.id }) else { return }
        let targetIndex = currentIndex + offset
        guard statuses.indices.contains(targetIndex) else { return }

        let target = statuses[targetIndex]
        let originalOrder = status.sortOrder
        status.sortOrder = target.sortOrder
        target.sortOrder = originalOrder
        try? modelContext.save()
    }

    private func normalizeOrder() {
        let remaining = statuses.filter { $0.id != pendingDeletion?.id }
        for (index, status) in remaining.enumerated() {
            status.sortOrder = index
        }
    }

    private func recordRevision(_ status: StatusDefinition) {
        modelContext.insert(
            StatusDefinitionRevision(
                statusID: status.id,
                labelSnapshot: status.displayName(language: preferences.language),
                tone: status.tone,
                icon: status.icon
            )
        )
    }
}
