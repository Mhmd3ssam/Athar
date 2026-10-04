import SwiftUI

struct CameraPermissionIntroView: View {
    let onClose: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            AtharColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(AtharColors.text)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("common.close"))

                    Spacer()
                }
                .padding(.horizontal, AtharSpacing.x3)
                .padding(.top, AtharSpacing.x2)

                Spacer()

                VStack(spacing: AtharSpacing.x5) {
                    Image(systemName: "camera")
                        .font(.system(size: 58, weight: .regular))
                        .foregroundStyle(AtharColors.text)
                        .accessibilityHidden(true)

                    VStack(spacing: AtharSpacing.x2) {
                        Text("scan.permission.title")
                            .font(AtharTypography.sheetTitle)
                            .foregroundStyle(AtharColors.text)

                        Text("scan.permission.body")
                            .font(AtharTypography.body)
                            .foregroundStyle(AtharColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, AtharLayout.screenInset)

                Spacer()

                VStack(spacing: AtharSpacing.x3) {
                    Button("scan.permission.continue", action: onContinue)
                        .buttonStyle(AtharPrimaryButtonStyle())

                    Button("scan.permission.notNow", action: onClose)
                        .buttonStyle(AtharSecondaryButtonStyle())

                    Text("scan.permission.storageNote")
                        .font(AtharTypography.secondary)
                        .foregroundStyle(AtharColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, AtharSpacing.x5)
                }
                .padding(.horizontal, AtharLayout.screenInset)
                .padding(.bottom, AtharSpacing.x8)
            }
        }
    }
}
