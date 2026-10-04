import SwiftUI

enum AtharRootTab: Hashable {
    case timeline
    case archive
}

struct AtharRootTabBar: View {
    let selected: AtharRootTab
    let onTimeline: () -> Void
    let onScan: () -> Void
    let onArchive: () -> Void

    private let scanOuterDiameter: CGFloat = 70
    private let scanInnerDiameter: CGFloat = 64

    var body: some View {
        ZStack(alignment: .bottom) {
            AtharTabBarBackgroundShape()
                .fill(AtharColors.surface)
                .overlay {
                    AtharTabBarTopEdgeShape()
                        .stroke(AtharColors.border, lineWidth: 1)
                }
                .ignoresSafeArea(edges: .bottom)

            HStack(alignment: .bottom, spacing: 0) {
                tabButton(
                    title: "nav.timeline",
                    symbol: "doc.text.fill",
                    selected: selected == .timeline,
                    action: onTimeline
                )

                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .accessibilityHidden(true)

                tabButton(
                    title: "nav.archive",
                    symbol: "archivebox.fill",
                    selected: selected == .archive,
                    action: onArchive
                )
            }
            .padding(.horizontal, AtharSpacing.x3)
            .padding(.bottom, AtharSpacing.x1)

            Button(action: onScan) {
                VStack(spacing: 1) {
                    ZStack {
                        // Keep a real breathing ring between the scan action and
                        // the raised tab-bar curve, matching the approved design.
                        Circle()
                            .fill(AtharColors.surface)
                            .frame(width: scanOuterDiameter, height: scanOuterDiameter)

                        Circle()
                            .fill(AtharColors.primary)
                            .frame(width: scanInnerDiameter, height: scanInnerDiameter)

                        Image(systemName: "viewfinder")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(AtharColors.onPrimary)
                    }

                    Text("nav.scan")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AtharColors.text)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(y: -5)
            .accessibilityLabel(Text("nav.scan"))
        }
        .frame(height: 92)
    }

    private func tabButton(
        title: LocalizedStringKey,
        symbol: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .medium))

                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(selected ? AtharColors.primary : AtharColors.text)
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct AtharTabBarBackgroundShape: Shape {
    func path(in rect: CGRect) -> Path {
        let centerX = rect.midX
        let topY: CGFloat = 24
        let peakY: CGFloat = 6
        let shoulder: CGFloat = 54

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: topY))
        path.addLine(to: CGPoint(x: centerX - shoulder, y: topY))
        path.addCurve(
            to: CGPoint(x: centerX, y: peakY),
            control1: CGPoint(x: centerX - 38, y: topY),
            control2: CGPoint(x: centerX - 34, y: peakY)
        )
        path.addCurve(
            to: CGPoint(x: centerX + shoulder, y: topY),
            control1: CGPoint(x: centerX + 34, y: peakY),
            control2: CGPoint(x: centerX + 38, y: topY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: topY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct AtharTabBarTopEdgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let centerX = rect.midX
        let topY: CGFloat = 24
        let peakY: CGFloat = 6
        let shoulder: CGFloat = 54

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: topY))
        path.addLine(to: CGPoint(x: centerX - shoulder, y: topY))
        path.addCurve(
            to: CGPoint(x: centerX, y: peakY),
            control1: CGPoint(x: centerX - 38, y: topY),
            control2: CGPoint(x: centerX - 34, y: peakY)
        )
        path.addCurve(
            to: CGPoint(x: centerX + shoulder, y: topY),
            control1: CGPoint(x: centerX + 34, y: peakY),
            control2: CGPoint(x: centerX + 38, y: topY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: topY))
        return path
    }
}
