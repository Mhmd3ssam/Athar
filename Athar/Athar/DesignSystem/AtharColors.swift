import SwiftUI
import UIKit

private extension UIColor {
    convenience init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var integer: UInt64 = 0
        Scanner(string: value).scanHexInt64(&integer)

        let red, green, blue, alpha: UInt64
        switch value.count {
        case 8:
            red = (integer >> 24) & 0xFF
            green = (integer >> 16) & 0xFF
            blue = (integer >> 8) & 0xFF
            alpha = integer & 0xFF
        default:
            red = (integer >> 16) & 0xFF
            green = (integer >> 8) & 0xFF
            blue = integer & 0xFF
            alpha = 0xFF
        }

        self.init(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: CGFloat(alpha) / 255
        )
    }
}

private extension Color {
    static func atharAdaptive(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

enum AtharColors {
    static let background = Color.atharAdaptive(light: "#F6F4EE", dark: "#191E1A")
    static let surface = Color.atharAdaptive(light: "#FFFEFA", dark: "#242B25")
    static let text = Color.atharAdaptive(light: "#242822", dark: "#F2F4EE")
    static let textSecondary = Color.atharAdaptive(light: "#60665E", dark: "#B3BBAF")
    static let border = Color.atharAdaptive(light: "#D9D4C8", dark: "#424B40")
    static let primary = Color.atharAdaptive(light: "#426453", dark: "#A8C69D")
    static let onPrimary = Color.atharAdaptive(light: "#FFFFFF", dark: "#172014")
    static let danger = Color.atharAdaptive(light: "#A52F2D", dark: "#FFB3AA")
    static let dangerSurface = Color.atharAdaptive(light: "#FBE5E2", dark: "#472C29")
    static let focus = Color.atharAdaptive(light: "#426453", dark: "#A8C69D")
}

enum AtharStatusTone: String, CaseIterable, Identifiable {
    case withMe
    case outForSignature
    case signed
    case delivered
    case inReview

    var id: String { rawValue }

    var background: Color {
        switch self {
        case .withMe: .atharAdaptive(light: "#E2E9F5", dark: "#273747")
        case .outForSignature: .atharAdaptive(light: "#F9E7BA", dark: "#44371D")
        case .signed: .atharAdaptive(light: "#DFEBDE", dark: "#293E2D")
        case .delivered: .atharAdaptive(light: "#E9E2F0", dark: "#3A3046")
        case .inReview: .atharAdaptive(light: "#EFE0E9", dark: "#44313B")
        }
    }

    var foreground: Color {
        switch self {
        case .withMe: .atharAdaptive(light: "#284B75", dark: "#C2D7F4")
        case .outForSignature: .atharAdaptive(light: "#714D06", dark: "#F5D899")
        case .signed: .atharAdaptive(light: "#2C5735", dark: "#B5DAB8")
        case .delivered: .atharAdaptive(light: "#5C4375", dark: "#D5BFE8")
        case .inReview: .atharAdaptive(light: "#714459", dark: "#EDC6D9")
        }
    }

    var symbolName: String {
        switch self {
        case .withMe: "person.fill"
        case .outForSignature: "arrow.right"
        case .signed: "checkmark"
        case .delivered: "tray.full.fill"
        case .inReview: "clock.fill"
        }
    }
}
