import Combine
import SwiftUI

enum AtharAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .system: "appearance.system"
        case .light: "appearance.light"
        case .dark: "appearance.dark"
        }
    }

    var symbolName: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }
}

enum AtharLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case arabic = "ar"

    var id: String { rawValue }
    var locale: Locale { Locale(identifier: rawValue) }
    var layoutDirection: LayoutDirection { self == .arabic ? .rightToLeft : .leftToRight }

    var titleKey: LocalizedStringKey {
        switch self {
        case .english: "language.english"
        case .arabic: "language.arabic"
        }
    }
}

final class AppPreferences: ObservableObject {
    private enum Key {
        static let appearance = "athar.appearance"
        static let language = "athar.language"
        static let lastStatusID = "athar.lastStatusID"
    }

    private let defaults: UserDefaults

    @Published var appearance: AtharAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    @Published var language: AtharLanguage {
        didSet { defaults.set(language.rawValue, forKey: Key.language) }
    }

    var lastStatusID: UUID? {
        get {
            guard let rawValue = defaults.string(forKey: Key.lastStatusID) else { return nil }
            return UUID(uuidString: rawValue)
        }
        set {
            defaults.set(newValue?.uuidString, forKey: Key.lastStatusID)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.appearance = AtharAppearance(rawValue: defaults.string(forKey: Key.appearance) ?? "") ?? .system
        self.language = AtharLanguage(rawValue: defaults.string(forKey: Key.language) ?? "") ?? .english
    }
}
