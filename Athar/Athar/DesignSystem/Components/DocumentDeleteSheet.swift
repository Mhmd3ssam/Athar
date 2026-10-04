import SwiftUI

struct DocumentDeleteSheet: View {
    @EnvironmentObject private var preferences: AppPreferences

    let documentName: String
    let thumbnailFilename: String?
    let onCancel: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AtharColors.border)
                .frame(width: 38, height: 5)
                .padding(.top, AtharSpacing.x3)
                .padding(.bottom, AtharSpacing.x5)

            VStack(alignment: .leading, spacing: AtharSpacing.x5) {
                Text("document.delete.sheet.title")
                    .font(AtharTypography.sheetTitle)
                    .foregroundStyle(AtharColors.text)

                HStack(spacing: AtharSpacing.x4) {
                    thumbnail

                    Text(documentName)
                        .font(AtharTypography.rowTitle)
                        .foregroundStyle(AtharColors.text)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }

                Text("document.delete.sheet.body")
                    .font(AtharTypography.body)
                    .foregroundStyle(AtharColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: AtharSpacing.x3) {
                    Button("common.cancel", action: onCancel)
                        .buttonStyle(AtharSecondaryButtonStyle())

                    Button("document.delete.action", action: onDelete)
                        .buttonStyle(AtharDestructiveButtonStyle())
                }
            }
            .padding(.horizontal, AtharLayout.screenInset)
            .padding(.bottom, AtharSpacing.x6)
        }
        .background(AtharColors.surface.ignoresSafeArea())
        .presentationDetents([.height(390)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(AtharRadius.sheetTop)
        .presentationBackground(AtharColors.surface)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let thumbnailFilename,
           let image = AtharImageStore.image(named: thumbnailFilename) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 76)
                .background(AtharColors.background)
                .clipShape(RoundedRectangle(cornerRadius: AtharRadius.thumbnail, style: .continuous))
        } else {
            ZStack {
                AtharColors.background
                Image(systemName: "doc.text")
                    .foregroundStyle(AtharColors.textSecondary)
            }
            .frame(width: 56, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: AtharRadius.thumbnail, style: .continuous))
        }
    }
}
