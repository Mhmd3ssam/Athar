import Foundation
import SwiftData
import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \DocumentRecord.createdAt, order: .reverse) private var documents: [DocumentRecord]
    @Query(sort: \DocumentComment.createdAt, order: .reverse) private var comments: [DocumentComment]

    let onBackToTimeline: () -> Void
    let onRestoredToTimeline: () -> Void

    @State private var searchText = ""
    @State private var isSearching = false
    @State private var expandedWeeks: Set<Date> = []
    @State private var selectedDocumentID: UUID?
    @State private var pendingDeleteID: UUID?

    private var archivedDocuments: [DocumentRecord] {
        documents.filter { $0.archivedAt != nil }
    }

    private var filteredDocuments: [DocumentRecord] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return archivedDocuments }

        return archivedDocuments.filter { document in
            if document.name.localizedCaseInsensitiveContains(trimmed) {
                return true
            }

            return comments
                .filter { $0.documentID == document.id }
                .contains { $0.text.localizedCaseInsensitiveContains(trimmed) }
        }
    }

    private var weekGroups: [ArchiveWeekGroup] {
        let grouped = Dictionary(grouping: filteredDocuments) { weekStart(for: $0.createdAt) }
        return grouped
            .map { weekStart, documents in
                ArchiveWeekGroup(
                    weekStart: weekStart,
                    documents: documents.sorted { $0.createdAt > $1.createdAt }
                )
            }
            .sorted { $0.weekStart > $1.weekStart }
    }

    private var pendingDeleteDocument: DocumentRecord? {
        guard let pendingDeleteID else { return nil }
        return documents.first { $0.id == pendingDeleteID }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if archivedDocuments.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else if filteredDocuments.isEmpty {
                Spacer()
                noResultsState
                Spacer()
            } else {
                archiveList
            }
        }
        .background(AtharColors.background)
        .onAppear {
            expandNewestWeekIfNeeded()
        }
        .onChange(of: weekGroups.map(\.weekStart)) { _, _ in
            expandNewestWeekIfNeeded()
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
                    origin: .archive,
                    onClose: { selectedDocumentID = nil },
                    onArchived: { selectedDocumentID = nil },
                    onRestored: {
                        selectedDocumentID = nil
                        onRestoredToTimeline()
                    },
                    onDeleted: { selectedDocumentID = nil }
                )
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
        VStack(spacing: AtharSpacing.x2) {
            HStack(spacing: AtharSpacing.x3) {
                if isSearching {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AtharColors.textSecondary)

                    TextField("archive.search.placeholder", text: $searchText)
                        .font(AtharTypography.body)
                        .foregroundStyle(AtharColors.text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AtharColors.textSecondary)
                                .frame(width: 32, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("archive.search.clear"))
                    }

                    Button("common.close") {
                        searchText = ""
                        isSearching = false
                    }
                    .font(AtharTypography.body.weight(.medium))
                    .foregroundStyle(AtharColors.primary)
                    .buttonStyle(.plain)
                } else {
                    Text("archive.title")
                        .font(AtharTypography.screenTitle)
                        .foregroundStyle(AtharColors.text)
                        .accessibilityAddTraits(.isHeader)

                    Spacer()

                    Button {
                        isSearching = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(AtharColors.text)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("archive.search"))
                }
            }
            .frame(minHeight: 52)

            Rectangle()
                .fill(AtharColors.border)
                .frame(height: 1)
        }
        .padding(.horizontal, AtharLayout.screenInset)
        .padding(.top, AtharSpacing.x5)
    }

    private var archiveList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(weekGroups) { week in
                    weekSection(week)
                }
            }
            .padding(.horizontal, AtharLayout.screenInset)
            .padding(.bottom, AtharSpacing.x8)
        }
    }

    private func weekSection(_ week: ArchiveWeekGroup) -> some View {
        let expanded = expandedWeeks.contains(week.weekStart)

        return VStack(spacing: 0) {
            Button {
                if expanded {
                    expandedWeeks.remove(week.weekStart)
                } else {
                    expandedWeeks.insert(week.weekStart)
                }
            } label: {
                HStack(spacing: AtharSpacing.x3) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AtharColors.text)
                        .frame(width: 20)

                    Text(weekRangeLabel(week.weekStart))
                        .font(AtharTypography.rowTitle.weight(.semibold))
                        .foregroundStyle(AtharColors.text)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Text(isCurrentWeek(week.weekStart) ? LocalizedStringKey("archive.week.this") : LocalizedStringKey("archive.week.older"))
                        .font(AtharTypography.secondary.weight(.medium))
                        .foregroundStyle(isCurrentWeek(week.weekStart) ? AtharColors.primary : AtharColors.textSecondary)
                        .padding(.horizontal, AtharSpacing.x3)
                        .padding(.vertical, AtharSpacing.x2)
                        .background(isCurrentWeek(week.weekStart) ? AtharColors.primary.opacity(0.12) : AtharColors.surface)
                        .clipShape(Capsule())
                }
                .frame(minHeight: 64)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(AtharColors.border)
                .frame(height: 1)

            if expanded {
                ForEach(dayGroups(in: week), id: \.day) { day in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(archiveDayLabel(day.day))
                            .font(AtharTypography.secondary.weight(.semibold))
                            .foregroundStyle(AtharColors.textSecondary)
                            .padding(.top, AtharSpacing.x3)
                            .padding(.bottom, AtharSpacing.x2)

                        ForEach(day.documents, id: \.id) { document in
                            archivedDocumentRow(document)

                            if document.id != day.documents.last?.id {
                                Rectangle()
                                    .fill(AtharColors.border)
                                    .frame(height: 1)
                            }
                        }
                    }
                }
            }
        }
    }

    private func archivedDocumentRow(_ document: DocumentRecord) -> some View {
        HStack(alignment: .center, spacing: AtharSpacing.x3) {
            documentThumbnail(document)

            VStack(alignment: .leading, spacing: AtharSpacing.x2) {
                Text(document.name)
                    .font(AtharTypography.rowTitle)
                    .foregroundStyle(AtharColors.text)
                    .lineLimit(2)

                AtharStatusChip(
                    title: document.archiveStatusNameSnapshot ?? fallbackStatusName,
                    tone: archiveTone(document),
                    symbolName: archiveIcon(document).symbolName
                )

                Text(LocalizedStringKey(DocumentArchiveService.archiveReasonKey(for: document)))
                    .font(AtharTypography.secondary)
                    .foregroundStyle(AtharColors.textSecondary)
            }

            Spacer(minLength: 0)

            Menu {
                Button {
                    restore(documentID: document.id)
                } label: {
                    Label("document.restore.action", systemImage: "arrow.uturn.backward")
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
                restore(documentID: document.id)
            } label: {
                Label("document.restore.action", systemImage: "arrow.uturn.backward")
            }
            Button(role: .destructive) {
                pendingDeleteID = document.id
            } label: {
                Label("document.delete.action", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                restore(documentID: document.id)
            } label: {
                Label("document.restore.action", systemImage: "arrow.uturn.backward")
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

    private var emptyState: some View {
        VStack(spacing: AtharSpacing.x5) {
            Image(systemName: "doc")
                .font(.system(size: 58, weight: .light))
                .foregroundStyle(AtharColors.textSecondary.opacity(0.72))

            VStack(spacing: AtharSpacing.x2) {
                Text("archive.empty.title")
                    .font(AtharTypography.section)
                    .foregroundStyle(AtharColors.text)
                    .multilineTextAlignment(.center)

                Text("archive.empty.body")
                    .font(AtharTypography.body)
                    .foregroundStyle(AtharColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("archive.backToTimeline", action: onBackToTimeline)
                .font(AtharTypography.body)
                .foregroundStyle(AtharColors.primary)
                .buttonStyle(.plain)
                .frame(minHeight: AtharLayout.minimumTouchTarget)
        }
        .padding(.horizontal, AtharLayout.screenInset)
        .frame(maxWidth: 340)
    }

    private var noResultsState: some View {
        VStack(spacing: AtharSpacing.x4) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AtharColors.textSecondary)

            Text("archive.search.empty")
                .font(AtharTypography.section)
                .foregroundStyle(AtharColors.text)

            Button("archive.search.clear") {
                searchText = ""
            }
            .font(AtharTypography.body.weight(.medium))
            .foregroundStyle(AtharColors.primary)
            .buttonStyle(.plain)
        }
    }

    private func restore(documentID: UUID) {
        guard let document = documents.first(where: { $0.id == documentID }) else { return }

        do {
            try DocumentArchiveService.restore(
                document,
                in: modelContext,
                language: preferences.language
            )
            onRestoredToTimeline()
        } catch {
            // Recoverable persistence state will get a dedicated system-state pass.
        }
    }

    private func deletePendingDocument() {
        guard let document = pendingDeleteDocument else { return }
        try? DocumentArchiveService.delete(document, in: modelContext)
        pendingDeleteID = nil
    }

    private func expandNewestWeekIfNeeded() {
        guard expandedWeeks.isEmpty, let newest = weekGroups.first?.weekStart else { return }
        expandedWeeks.insert(newest)
    }

    private func dayGroups(in week: ArchiveWeekGroup) -> [(day: Date, documents: [DocumentRecord])] {
        let groups = Dictionary(grouping: week.documents) { Calendar.current.startOfDay(for: $0.createdAt) }
        return groups
            .map { ($0.key, $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.day > $1.day }
    }

    private func weekStart(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let day = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: day)
        let daysSinceMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysSinceMonday, to: day) ?? day
    }

    private func weekRangeLabel(_ start: Date) -> String {
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
        let startText = start.formatted(
            Date.FormatStyle().month(.abbreviated).day().locale(preferences.language.locale)
        )
        let endText = end.formatted(
            Date.FormatStyle().month(.abbreviated).day().year().locale(preferences.language.locale)
        )
        return "\(startText) – \(endText)"
    }

    private func archiveDayLabel(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle()
                .weekday(.abbreviated)
                .month(.abbreviated)
                .day()
                .year()
                .locale(preferences.language.locale)
        )
    }

    private func isCurrentWeek(_ start: Date) -> Bool {
        weekStart(for: .now) == start
    }

    private func archiveTone(_ document: DocumentRecord) -> AtharStatusTone {
        AtharStatusTone(rawValue: document.archiveStatusToneRawValue ?? "") ?? .withMe
    }

    private func archiveIcon(_ document: DocumentRecord) -> AtharStatusIcon {
        AtharStatusIcon(rawValue: document.archiveStatusIconRawValue ?? "") ?? .person
    }

    private var fallbackStatusName: String {
        preferences.language == .arabic ? "حالة" : "Status"
    }


}

private struct ArchiveWeekGroup: Identifiable {
    let weekStart: Date
    let documents: [DocumentRecord]

    var id: Date { weekStart }
}
