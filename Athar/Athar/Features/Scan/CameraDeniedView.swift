import SwiftUI
import UIKit

struct CameraDeniedView: View {
    let onClose: () -> Void

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
                    Image(systemName: "camera.fill")
                        .font(.system(size: 58, weight: .regular))
                        .foregroundStyle(AtharColors.text)
                        .accessibilityHidden(true)

                    VStack(spacing: AtharSpacing.x2) {
                        Text("scan.denied.title")
                            .font(AtharTypography.sheetTitle)
                            .foregroundStyle(AtharColors.text)

                        Text("scan.denied.body")
                            .font(AtharTypography.body)
                            .foregroundStyle(AtharColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, AtharLayout.screenInset)

                Spacer()

                VStack(spacing: AtharSpacing.x3) {
                    Button("scan.denied.settings") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                    .buttonStyle(AtharPrimaryButtonStyle())

                    Button("archive.backToTimeline", action: onClose)
                        .buttonStyle(AtharSecondaryButtonStyle())
                }
                .padding(.horizontal, AtharLayout.screenInset)
                .padding(.bottom, AtharSpacing.x8)
            }
        }
    }
}
