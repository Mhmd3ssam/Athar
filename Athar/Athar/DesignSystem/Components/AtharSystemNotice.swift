import SwiftUI

struct AtharSystemNotice: View {
    let symbol: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let primaryTitle: LocalizedStringKey
    let primaryAction: () -> Void
    let secondaryTitle: LocalizedStringKey?
    let secondaryAction: (() -> Void)?

    init(
        symbol: String,
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        primaryTitle: LocalizedStringKey,
        primaryAction: @escaping () -> Void,
        secondaryTitle: LocalizedStringKey? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.symbol = symbol
        self.title = title
        self.message = message
        self.primaryTitle = primaryTitle
        self.primaryAction = primaryAction
        self.secondaryTitle = secondaryTitle
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        VStack(spacing: AtharSpacing.x5) {
            Image(systemName: symbol)
                .font(.system(size: 54, weight: .regular))
                .foregroundStyle(AtharColors.textSecondary)
                .accessibilityHidden(true)

            VStack(spacing: AtharSpacing.x2) {
                Text(title)
                    .font(AtharTypography.sheetTitle)
                    .foregroundStyle(AtharColors.text)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AtharTypography.body)
                    .foregroundStyle(AtharColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: AtharSpacing.x3) {
                Button(primaryTitle, action: primaryAction)
                    .buttonStyle(AtharPrimaryButtonStyle())

                if let secondaryTitle, let secondaryAction {
                    Button(secondaryTitle, action: secondaryAction)
                        .buttonStyle(AtharSecondaryButtonStyle())
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
