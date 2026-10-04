import SwiftData
import SwiftUI

struct DocumentHistoryView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.layoutDirection) private var layoutDirection

    @Query(sort: \DocumentEvent.createdAt) private var allEvents: [DocumentEvent]

    let document: DocumentRecord

    private var events: [DocumentEvent] {
        allEvents.filter { $0.documentID == document.id }
    }

    private var groupedEvents: [(day: Date, events: [DocumentEvent])] {
        let groups = Dictionary(grouping: events) { Calendar.current.startOfDay(for: $0.createdAt) }
        return groups
            .map { ($0.key, $0.value.sorted { $0.createdAt < $1.createdAt }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        ZStack {
            AtharColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AtharSpacing.x5) {
                    header

                    VStack(alignment: .leading, spacing: AtharSpacing.x2) {
                        Text("document.history.title")
                            .font(AtharTypography.screenTitle)
                            .foregroundStyle(AtharColors.text)

                        Text(document.name)
                            .font(AtharTypography.body)
                            .foregroundStyle(AtharColors.textSecondary)
                    }

                    Text("document.history.note")
                        .font(AtharTypography.secondary)
                        .foregroundStyle(AtharColors.textSecondary)
                        .padding(AtharSpacing.x3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AtharColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous))

                    ForEach(groupedEvents, id: \.day) { group in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(dayLabel(group.day))
                                .font(AtharTypography.rowTitle.weight(.semibold))
                                .foregroundStyle(AtharColors.text)
                                .padding(.bottom, AtharSpacing.x3)

                            ForEach(Array(group.events.enumerated()), id: \.element.id) { pair in
                                HistoryEventRow(
                                    event: pair.element,
                                    isLast: pair.offset == group.events.count - 1
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, AtharLayout.screenInset)
                .padding(.bottom, AtharSpacing.x8)
            }
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AtharColors.text)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("common.back"))

            Spacer()
        }
        .padding(.top, AtharSpacing.x2)
    }

    private func dayLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let dateText = date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted)
                .locale(preferences.language.locale)
        )
        if calendar.isDateInToday(date) {
            return (preferences.language == .arabic ? "اليوم · " : "Today · ") + dateText
        }
        return dateText
    }
}

struct HistoryEventRow: View {
    @EnvironmentObject private var preferences: AppPreferences

    let event: DocumentEvent
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AtharSpacing.x3) {
            VStack(spacing: 0) {
                Circle()
                    .fill(AtharColors.primary)
                    .frame(width: 11, height: 11)

                if !isLast {
                    Rectangle()
                        .fill(AtharColors.primary.opacity(0.45))
                        .frame(width: 1, height: 52)
                }
            }
            .padding(.top, 7)

            Text(event.createdAt.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(preferences.language.locale)))
                .font(AtharTypography.secondary)
                .foregroundStyle(AtharColors.textSecondary)
                .frame(width: 72, alignment: .leading)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 3) {
                Label(eventTitle, systemImage: eventSymbol)
                    .font(AtharTypography.rowTitle.weight(.semibold))
                    .foregroundStyle(AtharColors.text)

                if let detail = eventDetail, !detail.isEmpty {
                    Text(detail)
                        .font(AtharTypography.body)
                        .foregroundStyle(AtharColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, AtharSpacing.x4)
        }
    }

    private var kind: DocumentEventKind? {
        DocumentEventKind(rawValue: event.kindRawValue)
    }

    private var eventTitle: LocalizedStringKey {
        switch kind {
        case .created: "document.history.created"
        case .statusChanged: "document.history.statusChanged"
        case .noteAdded: "document.history.noteAdded"
        case .nameChanged: "document.history.nameChanged"
        case .archived: "document.history.archived"
        case .restored: "document.history.restored"
        case .none: "document.history.updated"
        }
    }

    private var eventSymbol: String {
        switch kind {
        case .created: "doc.text"
        case .statusChanged: "arrow.left.arrow.right"
        case .noteAdded: "text.bubble"
        case .nameChanged: "pencil"
        case .archived: "archivebox"
        case .restored: "arrow.uturn.backward"
        case .none: "clock"
        }
    }

    private var eventDetail: String? {
        switch kind {
        case .created:
            return event.newStatusNameSnapshot
        case .statusChanged:
            let old = event.oldStatusNameSnapshot ?? "—"
            let new = event.newStatusNameSnapshot ?? "—"
            return "\(old) → \(new)"
        case .noteAdded:
            return event.detail.map { "“\($0)”" }
        case .archived:
            if event.detail == DocumentArchiveMode.manual.rawValue {
                return preferences.language == .arabic ? "تمت الأرشفة يدويًا" : "Archived manually"
            }
            if event.detail == DocumentArchiveMode.automatic.rawValue {
                return preferences.language == .arabic ? "أقدم من ٧ أيام" : "Older than 7 days"
            }
            return event.detail
        case .nameChanged, .restored, .none:
            return event.detail
        }
    }
}
