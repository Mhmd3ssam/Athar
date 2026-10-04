import SwiftUI

struct AtharPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AtharTypography.button)
            .foregroundStyle(AtharColors.onPrimary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(AtharColors.primary.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AtharRadius.button, style: .continuous))
            .contentShape(Rectangle())
    }
}

struct AtharSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AtharTypography.button)
            .foregroundStyle(AtharColors.text)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(AtharColors.surface.opacity(configuration.isPressed ? 0.72 : 1))
            .overlay {
                RoundedRectangle(cornerRadius: AtharRadius.button, style: .continuous)
                    .stroke(AtharColors.border, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: AtharRadius.button, style: .continuous))
            .contentShape(Rectangle())
    }
}

struct AtharDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AtharTypography.button)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(AtharColors.danger.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AtharRadius.button, style: .continuous))
            .contentShape(Rectangle())
    }
}
