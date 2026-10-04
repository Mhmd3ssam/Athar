import SwiftUI

struct AtharStatusChip: View {
    let title: String
    let tone: AtharStatusTone
    let symbolName: String

    init(title: String, tone: AtharStatusTone, symbolName: String? = nil) {
        self.title = title
        self.tone = tone
        self.symbolName = symbolName ?? tone.symbolName
    }

    var body: some View {
        HStack(spacing: AtharSpacing.x2) {
            Image(systemName: symbolName)
                .font(.system(size: 13, weight: .semibold))
                .accessibilityHidden(true)

            Text(title)
                .font(AtharTypography.secondary.weight(.medium))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(tone.background)
        .clipShape(Capsule())
    }
}
