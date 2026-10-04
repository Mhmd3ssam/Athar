import SwiftData
import SwiftUI
import UIKit

struct ChangeStatusSheet: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \StatusDefinition.sortOrder) private var statuses: [StatusDefinition]

    let document: DocumentRecord

    @State private var showingAddStatus = false
    @State private var showingError = false

    private var selectableStatuses: [StatusDefinition] {
        statuses.filter { !$0.isRetired }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtharColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(selectableStatuses) { status in
                            Button {
                                select(status)
                            } label: {
                                HStack(spacing: AtharSpacing.x3) {
                                    ZStack {
                                        Circle()
                                            .fill(status.tone.background)
                                            .frame(width: 42, height: 42)

                                        Image(systemName: status.icon.symbolName)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(status.tone.foreground)
                                    }

                                    Text(status.displayName(language: preferences.language))
                                        .font(AtharTypography.body.weight(.medium))
                                        .foregroundStyle(AtharColors.text)
                                        .multilineTextAlignment(.leading)

                                    Spacer()

                                    Image(systemName: status.id == document.currentStatusID ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundStyle(status.id == document.currentStatusID ? AtharColors.primary : AtharColors.textSecondary)
                                }
                                .padding(.vertical, AtharSpacing.x3)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Rectangle()
                                .fill(AtharColors.border)
                                .frame(height: 1)
                        }

                        Button {
                            showingAddStatus = true
                        } label: {
                            Label("document.status.add", systemImage: "plus")
                                .font(AtharTypography.body.weight(.medium))
                                .foregroundStyle(AtharColors.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(minHeight: 56)
                        }
                        .buttonStyle(.plain)

                        if showingError {
                            Text("document.status.saveError")
                                .font(AtharTypography.secondary)
                                .foregroundStyle(AtharColors.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, AtharSpacing.x2)
                        }
                    }
                    .padding(.horizontal, AtharLayout.screenInset)
                }
            }
            .navigationTitle("document.status.change")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $showingAddStatus) {
            StatusEditorView(mode: .add)
        }
    }

    private func select(_ newStatus: StatusDefinition) {
        guard newStatus.id != document.currentStatusID else {
            dismiss()
            return
        }

        let oldStatus = statuses.first { $0.id == document.currentStatusID }
        let now = Date.now

        modelContext.insert(
            DocumentEvent(
                documentID: document.id,
                kindRawValue: DocumentEventKind.statusChanged.rawValue,
                createdAt: now,
                oldStatusID: oldStatus?.id,
                oldStatusNameSnapshot: oldStatus?.displayName(language: preferences.language),
                oldStatusToneRawValue: oldStatus?.toneRawValue,
                oldStatusIconRawValue: oldStatus?.iconRawValue,
                newStatusID: newStatus.id,
                newStatusNameSnapshot: newStatus.displayName(language: preferences.language),
                newStatusToneRawValue: newStatus.toneRawValue,
                newStatusIconRawValue: newStatus.iconRawValue
            )
        )

        document.currentStatusID = newStatus.id
        document.lastUpdatedAt = now

        do {
            try modelContext.save()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
        } catch {
            showingError = true
        }
    }
}
