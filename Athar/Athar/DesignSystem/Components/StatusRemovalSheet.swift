import SwiftUI

enum StatusRemovalKind {
    case retire
    case delete

    var titleKey: LocalizedStringKey {
        switch self {
        case .retire: "statuses.retire.title"
        case .delete: "statuses.delete.title"
        }
    }

    var messageKey: LocalizedStringKey {
        switch self {
        case .retire: "statuses.retire.message"
        case .delete: "statuses.delete.message"
        }
    }

    var actionKey: LocalizedStringKey {
        switch self {
        case .retire: "statuses.retire.action"
        case .delete: "statuses.delete.action"
        }
    }
}

struct StatusRemovalSheet: View {
    let statusName: String
    let kind: StatusRemovalKind
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AtharColors.border)
                .frame(width: 38, height: 5)
                .padding(.top, AtharSpacing.x3)
                .padding(.bottom, AtharSpacing.x5)

            VStack(alignment: .leading, spacing: AtharSpacing.x3) {
                Text(kind.titleKey)
                    .font(AtharTypography.sheetTitle)
                    .foregroundStyle(AtharColors.text)

                Text(kind.messageKey)
                    .font(AtharTypography.body)
                    .foregroundStyle(AtharColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(statusName)
                    .font(AtharTypography.rowTitle.weight(.semibold))
                    .foregroundStyle(AtharColors.text)
                    .padding(.top, AtharSpacing.x1)

                HStack(spacing: AtharSpacing.x3) {
                    Button("common.cancel", action: onCancel)
                        .buttonStyle(AtharSecondaryButtonStyle())

                    actionButton
                }
                .padding(.top, AtharSpacing.x4)
            }
            .padding(.horizontal, AtharLayout.screenInset)
            .padding(.bottom, AtharSpacing.x6)
        }
        .background(AtharColors.surface.ignoresSafeArea())
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(AtharRadius.sheetTop)
        .presentationBackground(AtharColors.surface)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch kind {
        case .delete:
            Button(action: onConfirm) {
                Text(kind.actionKey)
            }
            .buttonStyle(AtharDestructiveButtonStyle())
        case .retire:
            Button(action: onConfirm) {
                Text(kind.actionKey)
                    .font(AtharTypography.button)
                    .foregroundStyle(AtharColors.danger)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .overlay {
                        RoundedRectangle(cornerRadius: AtharRadius.button, style: .continuous)
                            .stroke(AtharColors.danger, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
    }

    private var sheetHeight: CGFloat {
        switch kind {
        case .delete: 300
        case .retire: 315
        }
    }
}
