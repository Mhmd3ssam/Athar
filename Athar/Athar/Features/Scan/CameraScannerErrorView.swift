import SwiftUI

struct CameraScannerErrorView: View {
    let onRetry: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            AtharColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                AtharSystemNotice(
                    symbol: "exclamationmark.triangle",
                    title: "scan.error.title",
                    message: "scan.error.body",
                    primaryTitle: "common.tryAgain",
                    primaryAction: onRetry,
                    secondaryTitle: "archive.backToTimeline",
                    secondaryAction: onBack
                )
                .padding(.horizontal, AtharLayout.screenInset)

                Spacer()
            }
        }
    }
}
