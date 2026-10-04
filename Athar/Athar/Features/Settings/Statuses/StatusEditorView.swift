import SwiftData
import SwiftUI

enum StatusEditorMode {
    case add
    case edit(StatusDefinition)
}

struct StatusEditorView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.layoutDirection) private var layoutDirection

    @Query(sort: \StatusDefinition.sortOrder) private var statuses: [StatusDefinition]
    @Query private var documents: [DocumentRecord]
    @Query private var events: [DocumentEvent]

    let mode: StatusEditorMode

    @State private var name: String
    @State private var selectedTone: AtharStatusTone
    @State private var selectedIcon: AtharStatusIcon
    @State private var errorKey: LocalizedStringKey?
    @State private var showRetireSheet = false
    @State private var showDeleteSheet = false
    @State private var showKeepOneAlert = false

    init(mode: StatusEditorMode) {
        self.mode = mode

        switch mode {
        case .add:
            _name = State(initialValue: "")
            _selectedTone = State(initialValue: .inReview)
            _selectedIcon = State(initialValue: .clock)
        case .edit(let status):
            _name = State(initialValue: status.customName ?? "")
            _selectedTone = State(initialValue: status.tone)
            _selectedIcon = State(initialValue: status.icon)
        }
    }

    var body: some View {
        ZStack {
            AtharColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AtharSpacing.x6) {
                    header

                    VStack(alignment: .leading, spacing: AtharSpacing.x2) {
                        Text("statuses.editor.name")
                            .font(AtharTypography.body.weight(.medium))
                            .foregroundStyle(AtharColors.text)

                        TextField("statuses.editor.namePlaceholder", text: $name)
                            .font(AtharTypography.body)
                            .foregroundStyle(AtharColors.text)
                            .padding(.horizontal, AtharSpacing.x3)
                            .frame(minHeight: 50)
                            .background(AtharColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous)
                                    .stroke(errorKey == nil ? AtharColors.border : AtharColors.danger, lineWidth: 1)
                            }
                            .textInputAutocapitalization(.sentences)
                            .onChange(of: name) { _, _ in errorKey = nil }

                        if let errorKey {
                            Text(errorKey)
                                .font(AtharTypography.secondary)
                                .foregroundStyle(AtharColors.danger)
                        }
                    }

                    VStack(alignment: .leading, spacing: AtharSpacing.x3) {
                        Text("statuses.editor.color")
                            .font(AtharTypography.body.weight(.medium))
                            .foregroundStyle(AtharColors.text)

                        HStack(spacing: AtharSpacing.x4) {
                            ForEach(AtharStatusTone.allCases) { tone in
                                Button(action: { selectedTone = tone }) {
                                    Circle()
                                        .fill(tone.background)
                                        .frame(width: 44, height: 44)
                                        .overlay {
                                            if selectedTone == tone {
                                                Circle()
                                                    .stroke(AtharColors.primary, lineWidth: 2)
                                                    .padding(-4)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text("statuses.editor.colorChoice"))
                                .accessibilityAddTraits(selectedTone == tone ? .isSelected : [])
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: AtharSpacing.x3) {
                        Text("statuses.editor.icon")
                            .font(AtharTypography.body.weight(.medium))
                            .foregroundStyle(AtharColors.text)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AtharSpacing.x2), count: 5), spacing: AtharSpacing.x2) {
                            ForEach(AtharStatusIcon.allCases) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    Image(systemName: icon.symbolName)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(selectedIcon == icon ? selectedTone.foreground : AtharColors.text)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 54)
                                        .background(selectedIcon == icon ? selectedTone.background : AtharColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous)
                                                .stroke(selectedIcon == icon ? AtharColors.primary : AtharColors.border, lineWidth: selectedIcon == icon ? 2 : 1)
                                        }
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(selectedIcon == icon ? .isSelected : [])
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: AtharSpacing.x3) {
                        Text("statuses.editor.preview")
                            .font(AtharTypography.body.weight(.medium))
                            .foregroundStyle(AtharColors.text)

                        AtharStatusChip(
                            title: previewName,
                            tone: selectedTone,
                            symbolName: selectedIcon.symbolName
                        )

                        Text("statuses.editor.availableHint")
                            .font(AtharTypography.secondary)
                            .foregroundStyle(AtharColors.textSecondary)
                    }

                    Button(action: save) {
                        Text(isEditing ? LocalizedStringKey("common.saveChanges") : LocalizedStringKey("statuses.add.action"))
                    }
                    .buttonStyle(AtharPrimaryButtonStyle())
                    .padding(.top, AtharSpacing.x2)

                    if isEditing {
                        Text("statuses.editor.historyNote")
                            .font(AtharTypography.secondary)
                            .foregroundStyle(AtharColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        if let status = editedStatus, !status.isRetired {
                            Button {
                                requestRemoval(for: status)
                            } label: {
                                Text(isUsed(status) ? LocalizedStringKey("statuses.retire.action") : LocalizedStringKey("statuses.delete.action"))
                                    .font(AtharTypography.button)
                                    .foregroundStyle(AtharColors.danger)
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: AtharRadius.button, style: .continuous)
                                            .stroke(AtharColors.danger, lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                            .padding(.top, AtharSpacing.x2)
                        }
                    }
                }
                .padding(.horizontal, AtharLayout.screenInset)
                .padding(.bottom, AtharSpacing.x8)
            }
        }
        .sheet(isPresented: $showRetireSheet) {
            if let status = editedStatus {
                StatusRemovalSheet(
                    statusName: status.displayName(language: preferences.language),
                    kind: .retire,
                    onCancel: { showRetireSheet = false },
                    onConfirm: { retire(status) }
                )
            }
        }
        .sheet(isPresented: $showDeleteSheet) {
            if let status = editedStatus {
                StatusRemovalSheet(
                    statusName: status.displayName(language: preferences.language),
                    kind: .delete,
                    onCancel: { showDeleteSheet = false },
                    onConfirm: { delete(status) }
                )
            }
        }
        .alert("statuses.keepOne.title", isPresented: $showKeepOneAlert) {
            Button("common.ok") {}
        } message: {
            Text("statuses.keepOne.message")
        }
        .onAppear {
            if case .edit(let status) = mode, name.isEmpty {
                name = status.displayName(language: preferences.language)
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editedStatus: StatusDefinition? {
        if case .edit(let status) = mode { return status }
        return nil
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

            Text(isEditing ? LocalizedStringKey("statuses.edit.title") : LocalizedStringKey("statuses.add.title"))
                .font(AtharTypography.screenTitle)
                .foregroundStyle(AtharColors.text)

            Spacer()
        }
        .padding(.top, AtharSpacing.x4)
    }

    private var previewName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if let editedStatus { return editedStatus.displayName(language: preferences.language) }
        return preferences.language == .arabic ? "قيد المراجعة" : "In review"
    }

    private var selectableCount: Int {
        statuses.filter { !$0.isRetired }.count
    }

    private func isUsed(_ status: StatusDefinition) -> Bool {
        documents.contains { $0.currentStatusID == status.id }
            || events.contains { $0.oldStatusID == status.id || $0.newStatusID == status.id }
    }

    private func requestRemoval(for status: StatusDefinition) {
        guard selectableCount > 1 else {
            showKeepOneAlert = true
            return
        }

        if isUsed(status) {
            showRetireSheet = true
        } else {
            showDeleteSheet = true
        }
    }

    private func retire(_ status: StatusDefinition) {
        status.isRetired = true
        modelContext.insert(
            StatusDefinitionRevision(
                statusID: status.id,
                labelSnapshot: status.displayName(language: preferences.language),
                tone: status.tone,
                icon: status.icon
            )
        )
        do {
            try modelContext.save()
            showRetireSheet = false
            dismiss()
        } catch {
            errorKey = "statuses.validation.saveFailed"
        }
    }

    private func delete(_ status: StatusDefinition) {
        modelContext.delete(status)
        let remaining = statuses.filter { $0.id != status.id }
        for (index, item) in remaining.enumerated() {
            item.sortOrder = index
        }

        do {
            try modelContext.save()
            showDeleteSheet = false
            dismiss()
        } catch {
            errorKey = "statuses.validation.saveFailed"
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            if let editedStatus, editedStatus.customName == nil {
                // Editing a seeded label without entering a replacement keeps its localized seed name.
            } else {
                errorKey = "statuses.validation.blank"
                return
            }
        }

        if trimmed.count > 40 {
            errorKey = "statuses.validation.long"
            return
        }

        let normalized = trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: preferences.language.locale)
        if !normalized.isEmpty {
            let duplicate = statuses.contains { status in
                guard status.id != editedStatus?.id, !status.isRetired else { return false }
                let other = status.displayName(language: preferences.language)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: preferences.language.locale)
                return other == normalized
            }

            if duplicate {
                errorKey = "statuses.validation.duplicate"
                return
            }
        }

        switch mode {
        case .add:
            let nextOrder = (statuses.map(\.sortOrder).max() ?? -1) + 1
            let status = StatusDefinition(
                customName: trimmed,
                tone: selectedTone,
                icon: selectedIcon,
                sortOrder: nextOrder
            )
            modelContext.insert(status)
            modelContext.insert(
                StatusDefinitionRevision(
                    statusID: status.id,
                    labelSnapshot: trimmed,
                    tone: selectedTone,
                    icon: selectedIcon
                )
            )
        case .edit(let status):
            let existingName = status.displayName(language: preferences.language)
            let newName = trimmed.isEmpty ? existingName : trimmed
            if status.customName == nil && trimmed == existingName {
                status.customName = nil
            } else {
                status.customName = newName
            }
            status.tone = selectedTone
            status.icon = selectedIcon
            modelContext.insert(
                StatusDefinitionRevision(
                    statusID: status.id,
                    labelSnapshot: newName,
                    tone: selectedTone,
                    icon: selectedIcon
                )
            )
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorKey = "statuses.validation.saveFailed"
        }
    }
}
