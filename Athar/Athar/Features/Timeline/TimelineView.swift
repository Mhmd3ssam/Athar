import Foundation
import SwiftData
import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \DocumentRecord.createdAt, order: .reverse) private var documents: [DocumentRecord]
    @Query(sort: \StatusDefinition.sortOrder) private var statuses: [StatusDefinition]

    let onSettings: () -> Void
    let onScan: () -> Void
    let onViewArchive: () -> Void

    @State private var selectedDocumentID: UUID?
    @State private var statusDocumentID: UUID?
    @State private var pendingDeleteID: UUID?
    @State private var archivedFeedbackID: UUID?
    @State private var selectedTimelineSection: TimelineSection = .week
    @State private var lastRestoredDocumentCount = 0

    private var activeDocuments: [DocumentRecord] {
        documents.filter { DocumentArchiveService.isVisibleOnTimeline($0) }
    }

    private var restoredDocuments: [DocumentRecord] {
        activeDocuments.filter { DocumentArchiveService.isRestoredAndVisible($0) }
    }

    private var normalDocuments: [DocumentRecord] {
        activeDocuments.filter { !DocumentArchiveService.isRestoredAndVisible($0) }
    }

    private var restoredGroups: [TimelineDayGroup] {
        let groups = Dictionary(grouping: restoredDocuments) { document in
            Calendar.current.startOfDay(for: document.restoredAt ?? .now)
        }
        return groups
            .map { day, documents in
                TimelineDayGroup(
                    section: .restored,
                    day: day,
                    documents: documents.sorted {
                        ($0.restoredAt ?? .distantPast) > ($1.restoredAt ?? .distantPast)
                    }
                )
            }
            .sorted { $0.day > $1.day }
    }

    private var groupedDocuments: [TimelineDayGroup] {
        let groups = Dictionary(grouping: normalDocuments) {
            Calendar.current.startOfDay(for: $0.createdAt)
        }
        return groups
            .map { day, documents in
                TimelineDayGroup(
                    section: .week,
                    day: day,
                    documents: documents.sorted { $0.createdAt > $1.createdAt }
                )
            }
            .sorted { $0.day > $1.day }
    }

    private var pendingDeleteDocument: DocumentRecord? {
        guard let pendingDeleteID else { return nil }
        return documents.first { $0.id == pendingDeleteID }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header

                Rectangle()
                    .fill(AtharColors.border)
                    .frame(height: 1)
                    .padding(.horizontal, AtharLayout.screenInset)

                if activeDocuments.isEmpty {
                    Spacer(minLength: AtharSpacing.x8)
                    Group {
                        if documents.isEmpty {
                            firstLaunchEmptyState
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, AtharLayout.screenInset)
                    Spacer(minLength: AtharSpacing.x8)
                } else {
                    if !restoredDocuments.isEmpty {
                        timelineSectionPicker
                    }

                    timelineList
                }
            }
            .background(AtharColors.background)

            if archivedFeedbackID != nil {
                AtharSnackbar(
                    message: "archive.feedback.archived",
                    actionTitle: "common.undo",
                    onAction: undoArchive,
                    onDismiss: { archivedFeedbackID = nil }
                )
                .padding(.bottom, AtharSpacing.x3)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(5)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: archivedFeedbackID)
        .onAppear {
            syncTimelineSectionWithRestoredDocuments()
        }
        .onChange(of: restoredDocuments.count) { oldCount, newCount in
            syncTimelineSectionWithRestoredDocuments(oldCount: oldCount, newCount: newCount)
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { selectedDocumentID != nil },
                set: { if !$0 { selectedDocumentID = nil } }
            )
        ) {
            if let id = selectedDocumentID,
               let document = documents.first(where: { $0.id == id }) {
                DocumentDetailsView(
                    document: document,
                    origin: .timeline,
                    onClose: { selectedDocumentID = nil },
                    onArchived: {
                        archivedFeedbackID = document.id
                        selectedDocumentID = nil
                    },
                    onRestored: { selectedDocumentID = nil },
                    onDeleted: { selectedDocumentID = nil }
                )
            }
        }
        .sheet(
            isPresented: Binding(
                get: { statusDocumentID != nil },
                set: { if !$0 { statusDocumentID = nil } }
            )
        ) {
            if let id = statusDocumentID,
               let document = documents.first(where: { $0.id == id }) {
                ChangeStatusSheet(document: document)
            }
        }
        .sheet(
            isPresented: Binding(
                get: { pendingDeleteID != nil },
                set: { if !$0 { pendingDeleteID = nil } }
            )
        ) {
            if let document = pendingDeleteDocument {
                DocumentDeleteSheet(
                    documentName: document.name,
                    thumbnailFilename: document.thumbnailFilename,
                    onCancel: { pendingDeleteID = nil },
                    onDelete: { deletePendingDocument() }
                )
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: AtharSpacing.x4) {
            VStack(alignment: .leading, spacing: 2) {
                Text("timeline.title")
                    .font(AtharTypography.screenTitle)
                    .foregroundStyle(AtharColors.text)
                    .accessibilityAddTraits(.isHeader)

                Text("timeline.last7days")
                    .font(AtharTypography.body)
                    .foregroundStyle(AtharColors.textSecondary)
            }

            Spacer()

            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(AtharColors.text)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("settings.title"))
        }
        .padding(.horizontal, AtharLayout.screenInset)
        .padding(.top, AtharSpacing.x5)
        .padding(.bottom, AtharSpacing.x4)
    }

    private var timelineSectionPicker: some View {
        HStack(spacing: 0) {
            timelineSectionButton(.week, titleKey: "timeline.section.week")
            timelineSectionButton(.restored, titleKey: "timeline.section.restored")
        }
        .padding(4)
        .background(AtharColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous)
                .stroke(AtharColors.border, lineWidth: 1)
        }
        .padding(.horizontal, AtharLayout.screenInset)
        .padding(.top, AtharSpacing.x4)
    }

    private func timelineSectionButton(_ section: TimelineSection, titleKey: LocalizedStringKey) -> some View {
        Button {
            selectedTimelineSection = section
        } label: {
            Text(titleKey)
                .font(AtharTypography.secondary.weight(.semibold))
                .foregroundStyle(selectedTimelineSection == section ? AtharColors.background : AtharColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 36)
                .background(selectedTimelineSection == section ? AtharColors.primary : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: max(AtharRadius.input - 3, 0), style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selectedTimelineSection == section ? .isSelected : [])
    }

    @ViewBuilder
    private var timelineList: some View {
        switch selectedTimelineSection {
        case .week:
            timelineScroll(
                groups: groupedDocuments,
                restored: false
            )
            // Week and Restored can contain groups from the same calendar day.
            // Give each branch its own identity so SwiftUI never reuses a row
            // from the other tab.
            .id(TimelineSection.week)

        case .restored:
            timelineScroll(
                groups: restoredGroups,
                restored: true
            )
            .id(TimelineSection.restored)
        }
    }

    private func timelineScroll(
        groups: [TimelineDayGroup],
        restored: Bool
    ) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AtharSpacing.x6) {
                ForEach(groups) { group in
                    documentGroup(
                        title: restored ? restoredDayLabel(group.day) : dayLabel(group.day),
                        documents: group.documents,
                        restored: restored
                    )
                }
            }
            .padding(.horizontal, AtharLayout.screenInset)
            .padding(.top, AtharSpacing.x5)
            .padding(.bottom, AtharSpacing.x8)
        }
    }

    private func documentGroup(title: String, documents: [DocumentRecord], restored: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(AtharTypography.secondary.weight(.semibold))
                .foregroundStyle(AtharColors.textSecondary)
                .padding(.bottom, AtharSpacing.x2)

            ForEach(documents, id: \.id) { document in
                documentRow(document, restored: restored)

                if document.id != documents.last?.id {
                    Rectangle()
                        .fill(AtharColors.border)
                        .frame(height: 1)
                }
            }
        }
    }

    private func documentRow(_ document: DocumentRecord, restored: Bool) -> some View {
        let status = statuses.first { $0.id == document.currentStatusID }

        return HStack(alignment: .center, spacing: AtharSpacing.x3) {
            documentThumbnail(document)

            VStack(alignment: .leading, spacing: AtharSpacing.x2) {
                Text(document.name)
                    .font(AtharTypography.rowTitle)
                    .foregroundStyle(AtharColors.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let status {
                    Button {
                        statusDocumentID = document.id
                    } label: {
                        AtharStatusChip(
                            title: status.displayName(language: preferences.language),
                            tone: status.tone,
                            symbolName: status.icon.symbolName
                        )
                    }
                    .buttonStyle(.plain)
                }

                if restored, let restoredAt = document.restoredAt {
                    Text(createdLabel(document.createdAt))
                        .font(AtharTypography.secondary)
                        .foregroundStyle(AtharColors.textSecondary)
                    Text(restoredLabel(restoredAt))
                        .font(AtharTypography.secondary)
                        .foregroundStyle(AtharColors.textSecondary)
                } else {
                    Text(updatedLabel(document.lastUpdatedAt))
                        .font(AtharTypography.secondary)
                        .foregroundStyle(AtharColors.textSecondary)
                }
            }

            Spacer(minLength: 0)

            Menu {
                Button {
                    archive(documentID: document.id)
                } label: {
                    Label("document.archive.action", systemImage: "archivebox")
                }

                Divider()

                Button(role: .destructive) {
                    pendingDeleteID = document.id
                } label: {
                    Label("document.delete.action", systemImage: "trash")
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
        .frame(minHeight: AtharLayout.rowMinimumHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedDocumentID = document.id
        }
        .contextMenu {
            Button {
                archive(documentID: document.id)
            } label: {
                Label("document.archive.action", systemImage: "archivebox")
            }
            Button(role: .destructive) {
                pendingDeleteID = document.id
            } label: {
                Label("document.delete.action", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                archive(documentID: document.id)
            } label: {
                Label("document.archive.action", systemImage: "archivebox")
            }
            .tint(AtharColors.primary)
        }
    }

    @ViewBuilder
    private func documentThumbnail(_ document: DocumentRecord) -> some View {
        if let filename = document.thumbnailFilename,
           let image = AtharImageStore.image(named: filename) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: AtharLayout.thumbnailWidth, height: AtharLayout.thumbnailHeight)
                .background(AtharColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AtharRadius.thumbnail, style: .continuous))
        } else {
            ZStack {
                AtharColors.surface
                Image(systemName: "doc.text")
                    .foregroundStyle(AtharColors.textSecondary)
            }
            .frame(width: AtharLayout.thumbnailWidth, height: AtharLayout.thumbnailHeight)
            .clipShape(RoundedRectangle(cornerRadius: AtharRadius.thumbnail, style: .continuous))
        }
    }

    private var firstLaunchEmptyState: some View {
        VStack(spacing: AtharSpacing.x5) {
            Image("AtharLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)
                .accessibilityHidden(true)

            VStack(spacing: AtharSpacing.x2) {
                Text("timeline.firstLaunch.title")
                    .font(AtharTypography.section)
                    .foregroundStyle(AtharColors.text)
                    .multilineTextAlignment(.center)

                Text("timeline.firstLaunch.body")
                    .font(AtharTypography.body)
                    .foregroundStyle(AtharColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("timeline.scanDocument", action: onScan)
                .buttonStyle(AtharPrimaryButtonStyle())
                .padding(.top, AtharSpacing.x2)

            Button("statuses.manage.title", action: onSettings)
                .font(AtharTypography.body.weight(.medium))
                .foregroundStyle(AtharColors.primary)
                .buttonStyle(.plain)
                .frame(minHeight: AtharLayout.minimumTouchTarget)
        }
        .frame(maxWidth: 330)
    }

    private var emptyState: some View {
        VStack(spacing: AtharSpacing.x5) {
            Image(systemName: "doc.text")
                .font(.system(size: 58, weight: .light))
                .foregroundStyle(AtharColors.textSecondary.opacity(0.72))
                .accessibilityHidden(true)

            VStack(spacing: AtharSpacing.x2) {
                Text("timeline.empty.title")
                    .font(AtharTypography.section)
                    .foregroundStyle(AtharColors.text)
                    .multilineTextAlignment(.center)

                Text("timeline.empty.body")
                    .font(AtharTypography.body)
                    .foregroundStyle(AtharColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("timeline.scanDocument", action: onScan)
                .buttonStyle(AtharPrimaryButtonStyle())
                .padding(.top, AtharSpacing.x2)

            Button("timeline.viewArchive", action: onViewArchive)
                .font(AtharTypography.body)
                .foregroundStyle(AtharColors.primary)
                .buttonStyle(.plain)
                .frame(minHeight: AtharLayout.minimumTouchTarget)
        }
        .frame(maxWidth: 330)
    }

    private func archive(documentID: UUID) {
        guard let document = documents.first(where: { $0.id == documentID }) else { return }

        do {
            try DocumentArchiveService.manualArchive(
                document,
                in: modelContext,
                language: preferences.language
            )
            archivedFeedbackID = document.id
        } catch {
            // Recoverable persistence state will get a dedicated system-state pass.
        }
    }

    private func undoArchive() {
        guard let id = archivedFeedbackID,
              let document = documents.first(where: { $0.id == id }) else {
            archivedFeedbackID = nil
            return
        }

        try? DocumentArchiveService.restore(
            document,
            in: modelContext,
            language: preferences.language
        )
        archivedFeedbackID = nil
    }

    private func deletePendingDocument() {
        guard let document = pendingDeleteDocument else { return }
        try? DocumentArchiveService.delete(document, in: modelContext)
        pendingDeleteID = nil
    }

    private func syncTimelineSectionWithRestoredDocuments(
        oldCount: Int? = nil,
        newCount: Int? = nil
    ) {
        let currentCount = newCount ?? restoredDocuments.count
        let previousCount = oldCount ?? lastRestoredDocumentCount

        if currentCount == 0 {
            selectedTimelineSection = .week
        } else if currentCount > previousCount {
            selectedTimelineSection = .restored
        }

        lastRestoredDocumentCount = currentCount
    }

    private func dayLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return preferences.language == .arabic ? "اليوم" : "Today"
        }
        if calendar.isDateInYesterday(date) {
            return preferences.language == .arabic ? "أمس" : "Yesterday"
        }
        let style = Date.FormatStyle(date: .abbreviated, time: .omitted)
            .locale(preferences.language.locale)
        return date.formatted(style)
    }

    private func restoredDayLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return preferences.language == .arabic ? "تمت الاستعادة اليوم" : "Restored today"
        }
        let formatted = date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted)
                .locale(preferences.language.locale)
        )
        return preferences.language == .arabic ? "تمت الاستعادة · \(formatted)" : "Restored · \(formatted)"
    }

    private func createdLabel(_ date: Date) -> String {
        let value = date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted)
                .locale(preferences.language.locale)
        )
        return preferences.language == .arabic ? "تم الإنشاء \(value)" : "Created \(value)"
    }

    private func restoredLabel(_ date: Date) -> String {
        let value = date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted)
                .locale(preferences.language.locale)
        )
        return preferences.language == .arabic ? "تمت الاستعادة \(value)" : "Restored \(value)"
    }

    private func updatedLabel(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = preferences.language.locale
        formatter.unitsStyle = .short
        let relative = formatter.localizedString(for: date, relativeTo: .now)
        return preferences.language == .arabic ? "آخر تحديث \(relative)" : "Updated \(relative)"
    }
}


private enum TimelineSection: String, Hashable {
    case week
    case restored
}

private struct TimelineDayGroup: Identifiable {
    let section: TimelineSection
    let day: Date
    let documents: [DocumentRecord]

    var id: String {
        "\(section.rawValue)-\(day.timeIntervalSinceReferenceDate)"
    }
}
