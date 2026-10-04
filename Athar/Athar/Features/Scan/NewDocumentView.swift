import SwiftData
import SwiftUI
import UIKit

private enum NewDocumentDiscardAction {
    case close
    case retake
}

private enum NewDocumentSaveErrorKind {
    case storage
    case generic
}

struct NewDocumentView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \StatusDefinition.sortOrder) private var statuses: [StatusDefinition]
    @Query(sort: \DocumentRecord.createdAt, order: .reverse) private var existingDocuments: [DocumentRecord]

    let image: UIImage
    let capturedAt: Date
    let onClose: () -> Void
    let onRetake: () -> Void
    let onSaved: () -> Void

    @State private var name = ""
    @State private var note = ""
    @State private var selectedStatusID: UUID?
    @State private var initialStatusID: UUID?
    @State private var isSaving = false
    @State private var showingImageViewer = false
    @State private var showingSaveError = false
    @State private var saveErrorKind: NewDocumentSaveErrorKind = .generic
    @State private var showingDiscardConfirmation = false
    @State private var pendingDiscardAction: NewDocumentDiscardAction = .close

    private var selectableStatuses: [StatusDefinition] {
        statuses.filter { !$0.isRetired }
    }

    private var selectedStatus: StatusDefinition? {
        selectableStatuses.first { $0.id == selectedStatusID }
    }

    var body: some View {
        ZStack {
            AtharColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: AtharSpacing.x4) {
                        imagePreview
                        retakeButton
                        documentNameField
                        statusField
                        noteField

                        Text(capturedLabel)
                            .font(AtharTypography.secondary)
                            .foregroundStyle(AtharColors.textSecondary)

                        if showingSaveError {
                            saveError
                        }

                        Button(action: saveDocument) {
                            HStack(spacing: AtharSpacing.x2) {
                                if isSaving {
                                    ProgressView()
                                        .tint(AtharColors.onPrimary)
                                }
                                Text(isSaving ? LocalizedStringKey("document.saving") : LocalizedStringKey("document.save"))
                            }
                        }
                        .buttonStyle(AtharPrimaryButtonStyle())
                        .disabled(isSaving || selectedStatus == nil)
                        .opacity((isSaving || selectedStatus == nil) ? 0.64 : 1)

                        if isSaving {
                            Text("document.saving.device")
                                .font(AtharTypography.secondary)
                                .foregroundStyle(AtharColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, AtharLayout.screenInset)
                    .padding(.bottom, AtharSpacing.x8)
                }
            }
        }
        .onAppear(perform: chooseInitialStatus)
        .fullScreenCover(isPresented: $showingImageViewer) {
            CapturedImageViewer(image: image) {
                showingImageViewer = false
            }
        }
        .alert("document.discard.title", isPresented: $showingDiscardConfirmation) {
            Button("document.discard.keep", role: .cancel) {}
            Button("document.discard.action", role: .destructive) {
                performPendingDiscardAction()
            }
        } message: {
            Text("document.discard.body")
        }
    }

    private var header: some View {
        HStack(spacing: AtharSpacing.x3) {
            Button(action: requestClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AtharColors.text)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("common.close"))

            Spacer()

            Text("document.new.title")
                .font(AtharTypography.rowTitle.weight(.semibold))
                .foregroundStyle(AtharColors.text)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, AtharSpacing.x2)
        .padding(.top, AtharSpacing.x2)
    }

    private var imagePreview: some View {
        ZStack(alignment: .topTrailing) {
            AtharColors.surface

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)

            Button(action: { showingImageViewer = true }) {
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
        }
        .frame(maxWidth: .infinity)
        .frame(height: 360)
        .clipShape(RoundedRectangle(cornerRadius: AtharRadius.thumbnail, style: .continuous))
    }

    private var retakeButton: some View {
        Button(action: requestRetake) {
            HStack(spacing: AtharSpacing.x2) {
                Image(systemName: "arrow.counterclockwise")
                Text("document.retake")
            }
            .font(AtharTypography.body.weight(.medium))
            .foregroundStyle(AtharColors.text)
            .frame(minHeight: AtharLayout.minimumTouchTarget)
        }
        .buttonStyle(.plain)
    }

    private var documentNameField: some View {
        VStack(alignment: .leading, spacing: AtharSpacing.x2) {
            Text("document.name")
                .font(AtharTypography.body)
                .foregroundStyle(AtharColors.text)

            TextField("document.name.placeholder", text: $name)
                .font(AtharTypography.body)
                .foregroundStyle(AtharColors.text)
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, AtharSpacing.x3)
                .frame(minHeight: 48)
                .background(AtharColors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous)
                        .stroke(AtharColors.border, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous))
        }
    }

    private var statusField: some View {
        VStack(alignment: .leading, spacing: AtharSpacing.x2) {
            Text("document.status")
                .font(AtharTypography.body)
                .foregroundStyle(AtharColors.text)

            Menu {
                ForEach(selectableStatuses) { status in
                    Button {
                        selectedStatusID = status.id
                    } label: {
                        Label(
                            status.displayName(language: preferences.language),
                            systemImage: status.icon.symbolName
                        )
                    }
                }
            } label: {
                HStack(spacing: AtharSpacing.x3) {
                    if let selectedStatus {
                        AtharStatusChip(
                            title: selectedStatus.displayName(language: preferences.language),
                            tone: selectedStatus.tone,
                            symbolName: selectedStatus.icon.symbolName
                        )
                    } else {
                        Text("document.status.choose")
                            .font(AtharTypography.body)
                            .foregroundStyle(AtharColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AtharColors.text)
                }
                .padding(.horizontal, AtharSpacing.x2)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(AtharColors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous)
                        .stroke(AtharColors.border, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: AtharSpacing.x2) {
            Text("document.note")
                .font(AtharTypography.body)
                .foregroundStyle(AtharColors.text)

            TextField("document.note.placeholder", text: $note, axis: .vertical)
                .font(AtharTypography.body)
                .foregroundStyle(AtharColors.text)
                .lineLimit(2...5)
                .padding(AtharSpacing.x3)
                .background(AtharColors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous)
                        .stroke(AtharColors.border, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous))
                .onChange(of: note) { _, newValue in
                    if newValue.count > 1000 {
                        note = String(newValue.prefix(1000))
                    }
                }
        }
    }

    private var saveError: some View {
        VStack(alignment: .leading, spacing: AtharSpacing.x3) {
            VStack(alignment: .leading, spacing: AtharSpacing.x2) {
                Label(saveErrorTitleKey, systemImage: "exclamationmark.circle")
                    .font(AtharTypography.button)
                    .foregroundStyle(AtharColors.danger)

                Text(saveErrorBodyKey)
                    .font(AtharTypography.secondary)
                    .foregroundStyle(AtharColors.textSecondary)
            }

            Button("document.saveError.retry", action: saveDocument)
                .font(AtharTypography.button)
                .foregroundStyle(AtharColors.danger)
                .frame(minHeight: AtharLayout.minimumTouchTarget)
                .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AtharSpacing.x3)
        .background(AtharColors.dangerSurface)
        .clipShape(RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous))
    }

    private var capturedLabel: String {
        let style = Date.FormatStyle(date: .abbreviated, time: .shortened)
            .locale(preferences.language.locale)
        let prefix = preferences.language == .arabic ? "تم التصوير" : "Captured"
        return prefix + " " + capturedAt.formatted(style)
    }

    private func chooseInitialStatus() {
        guard selectedStatusID == nil else { return }

        if let lastID = preferences.lastStatusID,
           selectableStatuses.contains(where: { $0.id == lastID }) {
            selectedStatusID = lastID
        } else {
            selectedStatusID = selectableStatuses.first?.id
        }
        initialStatusID = selectedStatusID
    }

    private var detailsAreDirty: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedStatusID != initialStatusID
    }

    private func requestClose() {
        pendingDiscardAction = .close
        showingDiscardConfirmation = true
    }

    private func requestRetake() {
        guard detailsAreDirty else {
            onRetake()
            return
        }
        pendingDiscardAction = .retake
        showingDiscardConfirmation = true
    }

    private func performPendingDiscardAction() {
        switch pendingDiscardAction {
        case .close:
            onClose()
        case .retake:
            onRetake()
        }
    }

    private func saveDocument() {
        guard let status = selectedStatus else { return }

        isSaving = true
        showingSaveError = false

        Task { @MainActor in
            await Task.yield()

            let documentID = UUID()
            var storedFiles: (imageFilename: String, thumbnailFilename: String)?

            do {
                storedFiles = try AtharImageStore.save(image: image, documentID: documentID)
                guard let storedFiles else { throw AtharImageStoreError.encodeFailed }

                let resolvedName = makeDocumentName()
                let document = DocumentRecord(
                    id: documentID,
                    name: resolvedName,
                    imageFilename: storedFiles.imageFilename,
                    thumbnailFilename: storedFiles.thumbnailFilename,
                    createdAt: capturedAt,
                    lastUpdatedAt: capturedAt,
                    currentStatusID: status.id
                )
                modelContext.insert(document)

                modelContext.insert(
                    DocumentEvent(
                        documentID: documentID,
                        kindRawValue: DocumentEventKind.created.rawValue,
                        createdAt: capturedAt,
                        newStatusID: status.id,
                        newStatusNameSnapshot: status.displayName(language: preferences.language),
                        newStatusToneRawValue: status.toneRawValue,
                        newStatusIconRawValue: status.iconRawValue
                    )
                )

                let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedNote.isEmpty {
                    modelContext.insert(
                        DocumentComment(
                            documentID: documentID,
                            text: trimmedNote,
                            createdAt: capturedAt
                        )
                    )
                    modelContext.insert(
                        DocumentEvent(
                            documentID: documentID,
                            kindRawValue: DocumentEventKind.noteAdded.rawValue,
                            createdAt: capturedAt,
                            detail: trimmedNote
                        )
                    )
                }

                try modelContext.save()
                preferences.lastStatusID = status.id
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                isSaving = false
                onSaved()
            } catch {
                saveErrorKind = classifySaveError(error)
                modelContext.rollback()
                if let storedFiles {
                    AtharImageStore.delete(
                        imageFilename: storedFiles.imageFilename,
                        thumbnailFilename: storedFiles.thumbnailFilename
                    )
                }
                isSaving = false
                showingSaveError = true
            }
        }
    }

    private var saveErrorTitleKey: LocalizedStringKey {
        saveErrorKind == .storage ? "document.saveError.storageTitle" : "document.saveError.title"
    }

    private var saveErrorBodyKey: LocalizedStringKey {
        saveErrorKind == .storage ? "document.saveError.storageBody" : "document.saveError.body"
    }

    private func classifySaveError(_ error: Error) -> NewDocumentSaveErrorKind {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain,
           nsError.code == CocoaError.fileWriteOutOfSpace.rawValue {
            return .storage
        }

        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError,
           underlying.domain == NSCocoaErrorDomain,
           underlying.code == CocoaError.fileWriteOutOfSpace.rawValue {
            return .storage
        }

        return .generic
    }

    private func makeDocumentName() -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty else { return trimmed }

        let style = Date.FormatStyle(date: .abbreviated, time: .shortened)
            .locale(preferences.language.locale)
        let noun = preferences.language == .arabic ? "مستند" : "Document"
        let base = "\(noun) · \(capturedAt.formatted(style))"

        let existingNames = Set(existingDocuments.map { $0.name.folding(options: .caseInsensitive, locale: preferences.language.locale) })
        if !existingNames.contains(base.folding(options: .caseInsensitive, locale: preferences.language.locale)) {
            return base
        }

        var suffix = 2
        while existingNames.contains("\(base) · \(suffix)".folding(options: .caseInsensitive, locale: preferences.language.locale)) {
            suffix += 1
        }
        return "\(base) · \(suffix)"
    }
}
