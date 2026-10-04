import SwiftUI
import UIKit

struct DocumentImageViewer: View {
    let image: UIImage
    let title: String
    let onClose: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                GeometryReader { proxy in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .contentShape(Rectangle())
                        .gesture(zoomGesture.simultaneously(with: panGesture))
                        .onTapGesture(count: 2) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if scale > 1 {
                                    scale = 1
                                    lastScale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2
                                    lastScale = 2
                                }
                            }
                        }
                }

                HStack(spacing: AtharSpacing.x3) {
                    Image(systemName: "plus.magnifyingglass")
                    Text("document.viewer.hint")
                }
                .font(AtharTypography.body)
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, AtharSpacing.x4)
                .background(Color.black.opacity(0.9))
            }
        }
        .statusBarHidden(true)
    }

    private var header: some View {
        ZStack {
            Text(title)
                .font(AtharTypography.body.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 64)

            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("common.close"))

                Spacer()
            }
        }
        .padding(.horizontal, AtharSpacing.x2)
        .padding(.top, AtharSpacing.x2)
        .padding(.bottom, AtharSpacing.x2)
        .background(Color.black.opacity(0.9))
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, 1), 5)
            }
            .onEnded { value in
                scale = min(max(lastScale * value, 1), 5)
                lastScale = scale
                if scale <= 1 {
                    withAnimation(.easeOut(duration: 0.18)) {
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                guard scale > 1 else {
                    offset = .zero
                    lastOffset = .zero
                    return
                }
                lastOffset = offset
            }
    }
}
