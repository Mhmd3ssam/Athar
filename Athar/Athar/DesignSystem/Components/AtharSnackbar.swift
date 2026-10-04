import SwiftUI

struct AtharSnackbar: View {
    let message: LocalizedStringKey
    var actionTitle: LocalizedStringKey? = nil
    var onAction: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: AtharSpacing.x3) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AtharColors.primary)
                .accessibilityHidden(true)

            Text(message)
                .font(AtharTypography.body)
                .foregroundStyle(AtharColors.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: AtharSpacing.x2)

            if let actionTitle, let onAction {
                Button(action: onAction) {
                    Text(actionTitle)
                        .font(AtharTypography.body.weight(.semibold))
                        .foregroundStyle(AtharColors.primary)
                }
                .buttonStyle(.plain)
                .frame(minHeight: AtharLayout.minimumTouchTarget)
            }

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AtharColors.textSecondary)
                        .frame(width: AtharLayout.minimumTouchTarget, height: AtharLayout.minimumTouchTarget)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("common.close"))
            }
        }
        .padding(.leading, AtharSpacing.x4)
        .padding(.trailing, AtharSpacing.x2)
        .padding(.vertical, AtharSpacing.x2)
        .background(AtharColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AtharRadius.button, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AtharRadius.button, style: .continuous)
                .stroke(AtharColors.primary.opacity(0.55), lineWidth: 1)
        }
        .padding(.horizontal, AtharLayout.screenInset)
        .accessibilityElement(children: .combine)
    }
}
