import SwiftData
import SwiftUI

struct StoredImagesView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.layoutDirection) private var layoutDirection

    @Query(sort: \DocumentRecord.createdAt, order: .reverse) private var documents: [DocumentRecord]

    @State private var selectedDocumentID: UUID?

    private let columns = [
        GridItem(.adaptive(minimum: 104), spacing: AtharSpacing.x3)
    ]

    var body: some View {
        ZStack {
            AtharColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Rectangle()
                    .fill(AtharColors.border)
                    .frame(height: 1)
                    .padding(.horizontal, AtharLayout.screenInset)

                if documents.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: AtharSpacing.x4) {
                            ForEach(documents, id: \.id) { document in
                                imageTile(document)
                            }
                        }
                        .padding(.horizontal, AtharLayout.screenInset)
                        .padding(.top, AtharSpacing.x5)
                        .padding(.bottom, AtharSpacing.x8)
                    }
                }
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { selectedDocumentID != nil },
                set: { if !$0 { selectedDocumentID = nil } }
            )
        ) {
            if let document = selectedDocument,
               let image = AtharImageStore.image(named: document.imageFilename) {
                DocumentImageViewer(image: image, title: document.name) {
                    selectedDocumentID = nil
                }
            }
        }
    }

    private var selectedDocument: DocumentRecord? {
        guard let selectedDocumentID else { return nil }
        return documents.first { $0.id == selectedDocumentID }
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

            Text("settings.images.gallery.title")
                .font(AtharTypography.screenTitle)
                .foregroundStyle(AtharColors.text)
                .accessibilityAddTraits(.isHeader)

            Spacer()
        }
        .padding(.horizontal, AtharLayout.screenInset)
        .padding(.top, AtharSpacing.x4)
        .padding(.bottom, AtharSpacing.x4)
    }

    private func imageTile(_ document: DocumentRecord) -> some View {
        Button {
            selectedDocumentID = document.id
        } label: {
            VStack(alignment: .leading, spacing: AtharSpacing.x2) {
                ZStack {
                    AtharColors.surface

                    if let filename = document.thumbnailFilename,
                       let image = AtharImageStore.image(named: filename) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let image = AtharImageStore.image(named: document.imageFilename) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 28))
                            .foregroundStyle(AtharColors.textSecondary)
                    }
                }
                .frame(height: 142)
                .clipShape(RoundedRectangle(cornerRadius: AtharRadius.thumbnail, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AtharRadius.thumbnail, style: .continuous)
                        .stroke(AtharColors.border, lineWidth: 1)
                }

                Text(document.name)
                    .font(AtharTypography.secondary.weight(.semibold))
                    .foregroundStyle(AtharColors.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(document.createdAt.formatted(
                    Date.FormatStyle(date: .abbreviated, time: .omitted)
                        .locale(preferences.language.locale)
                ))
                .font(AtharTypography.secondary)
                .foregroundStyle(AtharColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: AtharSpacing.x4) {
            Spacer()

            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AtharColors.textSecondary)

            Text("settings.images.gallery.empty")
                .font(AtharTypography.section)
                .foregroundStyle(AtharColors.text)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, AtharLayout.screenInset)
    }
}
