import CoreGraphics

enum AtharSpacing {
    static let x1: CGFloat = 4
    static let x2: CGFloat = 8
    static let x3: CGFloat = 12
    static let x4: CGFloat = 16
    static let x5: CGFloat = 20
    static let x6: CGFloat = 24
    static let x8: CGFloat = 32
    static let x10: CGFloat = 40
}

enum AtharLayout {
    static let screenInset: CGFloat = 20
    static let rowGap: CGFloat = 12
    static let sectionGap: CGFloat = 24
    static let rowMinimumHeight: CGFloat = 96
    static let thumbnailWidth: CGFloat = 52
    static let thumbnailHeight: CGFloat = 72
    static let minimumTouchTarget: CGFloat = 44
}

enum AtharRadius {
    static let input: CGFloat = 10
    static let button: CGFloat = 10
    static let thumbnail: CGFloat = 6
    static let sheetTop: CGFloat = 24
}
