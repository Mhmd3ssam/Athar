import SwiftData
import SwiftUI
import UIKit

struct AddNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let document: DocumentRecord

    @State private var text = ""
    @State private var showingDiscardConfirmation = false
    @State private var showingSaveError = false

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtharColors.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: AtharSpacing.x4) {
                    TextEditor(text: $text)
                        .font(AtharTypography.body)
                        .foregroundStyle(AtharColors.text)
                        .scrollContentBackground(.hidden)
                        .padding(AtharSpacing.x3)
                        .frame(minHeight: 150)
                        .background(AtharColors.surface)
                        .overlay {
                            RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous)
                                .stroke(AtharColors.border, lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AtharRadius.input, style: .continuous))
                        .onChange(of: text) { _, newValue in
                            if newValue.count > 1000 {
                                text = String(newValue.prefix(1000))
                            }
                        }

                    HStack {
                        if showingSaveError {
                            Text("document.note.saveError")
                                .font(AtharTypography.secondary)
                                .foregroundStyle(AtharColors.danger)
                        }

                        Spacer()

                        Text("\(text.count)/1000")
                            .font(AtharTypography.secondary)
                            .foregroundStyle(AtharColors.textSecondary)
                    }

                    Spacer(minLength: 0)

                    Button("document.note.save", action: saveNote)
                        .buttonStyle(AtharPrimaryButtonStyle())
                        .disabled(trimmedText.isEmpty)
                        .opacity(trimmedText.isEmpty ? 0.55 : 1)
                }
                .padding(AtharLayout.screenInset)
            }
            .navigationTitle("document.note.add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.close", action: requestClose)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(!trimmedText.isEmpty)
        .alert("document.note.discard.title", isPresented: $showingDiscardConfirmation) {
            Button("document.note.discard.keep", role: .cancel) { }
            Button("document.note.discard.action", role: .destructive) { dismiss() }
        }
    }

    private func requestClose() {
        if trimmedText.isEmpty {
            dismiss()
        } else {
            showingDiscardConfirmation = true
        }
    }

    private func saveNote() {
        let value = trimmedText
        guard !value.isEmpty else { return }

        let now = Date.now
        modelContext.insert(DocumentComment(documentID: document.id, text: value, createdAt: now))
        modelContext.insert(
            DocumentEvent(
                documentID: document.id,
                kindRawValue: DocumentEventKind.noteAdded.rawValue,
                createdAt: now,
                detail: value
            )
        )
        document.lastUpdatedAt = now

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            showingSaveError = true
        }
    }
}
