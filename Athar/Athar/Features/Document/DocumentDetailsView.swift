import SwiftData
import SwiftUI

enum DocumentDetailsOrigin {
    case timeline
    case archive
}

struct DocumentDetailsView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \StatusDefinition.sortOrder) private var statuses: [StatusDefinition]
    @Query(sort: \DocumentEvent.createdAt) private var allEvents: [DocumentEvent]
    @Query(sort: \DocumentComment.createdAt, order: .reverse) private var allComments: [DocumentComment]

    let document: DocumentRecord
    let origin: DocumentDetailsOrigin
    let onClose: () -> Void
    let onArchived: () -> Void
    let onRestored: () -> Void
    let onDeleted: () -> Void

    @State private var showingImageViewer = false
    @State private var showingChangeStatus = false
    @State private var showingAddNote = false
    @State private var showingHistory = false
    @State private var showingDeleteConfirmation = false
    @State private var imageReloadAttempt = 0

    private var isArchived: Bool {
        document.archivedAt != nil
    }

    private var currentStatus: StatusDefinition? {
        statuses.first { $0.id == document.currentStatusID }
    }

    private var events: [DocumentEvent] {
        allEvents.filter { $0.documentID == document.id }
    }

    private var recentEvents: [DocumentEvent] {
        Array(events.suffix(2))
    }

    private var comments: [DocumentComment] {
        allComments.filter { $0.documentID == document.id }
    }

    var body: some View {
        ZStack {
            AtharColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AtharSpacing.x4) {
                    header
                    titleRow
                    imagePreview
                    statusSection
                    metadataSection

                    Rectangle()
                        .fill(AtharColors.border)
                        .frame(height: 1)

                    historySection

                    Rectangle()
                        .fill(AtharColors.border)
                        .frame(height: 1)

                    notesSection

                    if isArchived {
                        restoreSection
                    }
                }
                .padding(.horizontal, AtharLayout.screenInset)
                .padding(.bottom, AtharSpacing.x8)
            }
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            if let image = loadDocumentImage() {
                DocumentImageViewer(image: image, title: document.name) {
                    showingImageViewer = false
                }
            }
        }
        .sheet(isPresented: $showingChangeStatus) {
            ChangeStatusSheet(document: document)
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteSheet(document: document)
        }
        .fullScreenCover(isPresented: $showingHistory) {
            DocumentHistoryView(document: document)
        }
        .sheet(isPresented: $showingDeleteConfirmation) {
            DocumentDeleteSheet(
                documentName: document.name,
                thumbnailFilename: document.thumbnailFilename,
                onCancel: { showingDeleteConfirmation = false },
                onDelete: {
                    showingDeleteConfirmation = false
                    deleteDocument()
                }
            )
        }
    }

    private var header: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AtharColors.text)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("common.back"))

            Spacer()

            Menu {
                if isArchived {
                    Button {
                        restoreDocument()
                    } label: {
                        Label("document.restore.action", systemImage: "arrow.uturn.backward")
                    }
                } else {
                    Button {
                        archiveDocument()
                    } label: {
                        Label("document.archive.action", systemImage: "archivebox")
                    }
                }

                Divider()

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("document.delete.action", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AtharColors.text)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("common.more"))
        }
        .padding(.top, AtharSpacing.x2)
    }

    private var titleRow: some View {
        HStack(alignment: .top, spacing: AtharSpacing.x3) {
            Text(document.name)
                .font(AtharTypography.screenTitle)
                .foregroundStyle(AtharColors.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            if isArchived {
                Text("archive.badge")
                    .font(AtharTypography.secondary.weight(.medium))
                    .foregroundStyle(AtharColors.textSecondary)
                    .padding(.horizontal, AtharSpacing.x3)
                    .padding(.vertical, AtharSpacing.x2)
                    .background(AtharColors.surface)
                    .clipShape(Capsule())
            }
        }
    }

    private var imagePreview: some View {
        ZStack(alignment: .topTrailing) {
            AtharColors.surface

            if let image = AtharImageStore.image(named: document.imageFilename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)

                Button { showingImageViewer = true } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.black.opacity(0.58))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(AtharSpacing.x3)
                .accessibilityLabel(Text("document.enlarge"))
            } else {
                VStack(spacing: AtharSpacing.x4) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 40, weight: .regular))
                        .foregroundStyle(AtharColors.textSecondary)

                    VStack(spacing: AtharSpacing.x2) {
                        Text("document.image.error.title")
                            .font(AtharTypography.rowTitle.weight(.semibold))
                            .foregroundStyle(AtharColors.text)

                        Text("document.image.error.body")
                            .font(AtharTypography.secondary)
                            .foregroundStyle(AtharColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    Button("document.image.retry") {
                        imageReloadAttempt += 1
                    }
                    .font(AtharTypography.button)
                    .foregroundStyle(AtharColors.primary)
                    .padding(.horizontal, AtharSpacing.x4)
                    .frame(minHeight: AtharLayout.minimumTouchTarget)
                    .overlay {
                        Capsule()
                            .stroke(AtharColors.primary, lineWidth: 1.5)
                    }

                    Button("common.back", action: onClose)
                        .font(AtharTypography.body.weight(.medium))
                        .foregroundStyle(AtharColors.textSecondary)
                        .frame(minHeight: AtharLayout.minimumTouchTarget)
                        .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, minHeight: 280)
                .padding(AtharSpacing.x4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 310, maxHeight: 460)
        .clipShape(RoundedRectangle(cornerRadius: AtharRadius.thumbnail, style: .continuous))
        .onTapGesture {
            if loadDocumentImage() != nil {
                showingImageViewer = true
            }
        }
    }

    private func loadDocumentImage() -> UIImage? {
        _ = imageReloadAttempt
        return AtharImageStore.image(named: document.imageFilename)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: AtharSpacing.x2) {
            if isArchived {
                Text("archive.statusWhenArchived")
                    .font(AtharTypography.secondary)
                    .foregroundStyle(AtharColors.textSecondary)

                AtharStatusChip(
                    title: document.archiveStatusNameSnapshot ?? fallbackStatusName,
                    tone: archivedTone,
                    symbolName: archivedIcon.symbolName
                )
            } else {
                HStack(spacing: AtharSpacing.x3) {
                    if let currentStatus {
                        AtharStatusChip(
                            title: currentStatus.displayName(language: preferences.language),
                            tone: currentStatus.tone,
                            symbolName: currentStatus.icon.symbolName
                        )
                    }

                    Spacer()

                    Button("document.status.change") {
                        showingChangeStatus = true
                    }
                    .font(AtharTypography.body.weight(.medium))
                    .foregroundStyle(AtharColors.primary)
                    .buttonStyle(.plain)
                    .frame(minHeight: AtharLayout.minimumTouchTarget)
                }
            }
        }
    }

    @ViewBuilder
    private var metadataSection: some View {
        if isArchived {
            HStack(alignment: .top, spacing: AtharSpacing.x3) {
                metadataItem(title: "document.created", date: document.createdAt)
                metadataDivider
                metadataItem(title: "archive.archivedAt", date: document.archivedAt ?? document.lastUpdatedAt)
                metadataDivider
                metadataItem(title: "document.updated", date: document.lastUpdatedAt)
            }
        } else {
            HStack(alignment: .top, spacing: AtharSpacing.x4) {
                metadataItem(title: "document.created", date: document.createdAt)
                metadataDivider
                metadataItem(title: "document.updated", date: document.lastUpdatedAt)
            }
        }
    }

    private var metadataDivider: some View {
        Rectangle()
            .fill(AtharColors.border)
            .frame(width: 1, height: 52)
    }

    private func metadataItem(title: LocalizedStringKey, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(AtharTypography.secondary)
                .foregroundStyle(AtharColors.textSecondary)

            Text(exactDate(date))
                .font(AtharTypography.secondary)
                .foregroundStyle(AtharColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: AtharSpacing.x3) {
            HStack {
                Text("document.history.title")
                    .font(AtharTypography.section)
                    .foregroundStyle(AtharColors.text)

                Spacer()

                Button("document.history.viewAll") {
                    showingHistory = true
                }
                .font(AtharTypography.secondary.weight(.semibold))
                .foregroundStyle(AtharColors.primary)
                .buttonStyle(.plain)
            }

            ForEach(Array(recentEvents.enumerated()), id: \.element.id) { pair in
                compactHistoryRow(
                    pair.element,
                    isFirst: pair.offset == 0,
                    isLast: pair.offset == recentEvents.count - 1
                )
            }
        }
    }

    private func compactHistoryRow(_ event: DocumentEvent, isFirst: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: AtharSpacing.x3) {
            VStack(spacing: 0) {
                if isLast && !isFirst {
                    Circle()
                        .stroke(AtharColors.primary, lineWidth: 1.5)
                        .frame(width: 10, height: 10)
                } else {
                    Circle()
                        .fill(AtharColors.primary)
                        .frame(width: 10, height: 10)
                }

                if !isLast {
                    Rectangle()
                        .fill(AtharColors.primary.opacity(0.55))
                        .frame(width: 1, height: 24)
                }
            }
            .padding(.top, 5)

            Text(event.createdAt.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(preferences.language.locale)))
                .font(AtharTypography.secondary)
                .foregroundStyle(AtharColors.textSecondary)

            Text(compactHistoryText(event))
                .font(AtharTypography.secondary)
                .foregroundStyle(AtharColors.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AtharSpacing.x3) {
            Text("document.notes.title")
                .font(AtharTypography.section)
                .foregroundStyle(AtharColors.text)

            if comments.isEmpty {
                Text("document.notes.empty")
                    .font(AtharTypography.secondary)
                    .foregroundStyle(AtharColors.textSecondary)
            } else {
                ForEach(comments, id: \.id) { comment in
                    HStack(alignment: .top, spacing: AtharSpacing.x3) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(AtharColors.text)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(comment.text)
                                .font(AtharTypography.body)
                                .foregroundStyle(AtharColors.text)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(exactDate(comment.createdAt))
                                .font(AtharTypography.secondary)
                                .foregroundStyle(AtharColors.textSecondary)
                        }
                    }
                }
            }

            Button {
                showingAddNote = true
            } label: {
                Label("document.note.add", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AtharSecondaryButtonStyle())
        }
    }

    private var restoreSection: some View {
        VStack(spacing: AtharSpacing.x2) {
            Button("document.restore.action") {
                restoreDocument()
            }
            .buttonStyle(AtharPrimaryButtonStyle())

            Text("archive.restore.note")
                .font(AtharTypography.secondary)
                .foregroundStyle(AtharColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, AtharSpacing.x2)
    }

    private var archivedTone: AtharStatusTone {
        AtharStatusTone(rawValue: document.archiveStatusToneRawValue ?? "") ?? .withMe
    }

    private var archivedIcon: AtharStatusIcon {
        AtharStatusIcon(rawValue: document.archiveStatusIconRawValue ?? "") ?? .person
    }

    private var fallbackStatusName: String {
        preferences.language == .arabic ? "حالة" : "Status"
    }

    private func archiveDocument() {
        do {
            try DocumentArchiveService.manualArchive(
                document,
                in: modelContext,
                language: preferences.language
            )
            onArchived()
        } catch {
            // Recoverable persistence state will get a dedicated system-state pass.
        }
    }

    private func restoreDocument() {
        do {
            try DocumentArchiveService.restore(
                document,
                in: modelContext,
                language: preferences.language
            )
            onRestored()
        } catch {
            // Recoverable persistence state will get a dedicated system-state pass.
        }
    }

    private func deleteDocument() {
        do {
            try DocumentArchiveService.delete(document, in: modelContext)
            onDeleted()
        } catch {
            // Recoverable persistence state will get a dedicated system-state pass.
        }
    }

    private func exactDate(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened)
                .locale(preferences.language.locale)
        )
    }

    private func compactHistoryText(_ event: DocumentEvent) -> String {
        switch DocumentEventKind(rawValue: event.kindRawValue) {
        case .created:
            let prefix = preferences.language == .arabic ? "تم الإنشاء" : "Created"
            if let status = event.newStatusNameSnapshot { return "\(prefix) · \(status)" }
            return prefix
        case .statusChanged:
            return "\(event.oldStatusNameSnapshot ?? "—") → \(event.newStatusNameSnapshot ?? "—")"
        case .noteAdded:
            return preferences.language == .arabic ? "تمت إضافة ملاحظة" : "Note added"
        case .nameChanged:
            return preferences.language == .arabic ? "تم تغيير الاسم" : "Name changed"
        case .archived:
            return preferences.language == .arabic ? "تمت الأرشفة" : "Archived"
        case .restored:
            return preferences.language == .arabic ? "تمت الاستعادة" : "Restored"
        case .none:
            return event.detail ?? ""
        }
    }
}
