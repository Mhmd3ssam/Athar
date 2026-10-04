import Foundation
import SwiftData
import SwiftUI

@Model
final class StatusDefinition: Identifiable {
    @Attribute(.unique) var id: UUID
    var seedKey: String?
    var customName: String?
    var toneRawValue: String
    var iconRawValue: String
    var sortOrder: Int
    var isRetired: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        seedKey: String? = nil,
        customName: String? = nil,
        tone: AtharStatusTone,
        icon: AtharStatusIcon,
        sortOrder: Int,
        isRetired: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.seedKey = seedKey
        self.customName = customName
        self.toneRawValue = tone.rawValue
        self.iconRawValue = icon.rawValue
        self.sortOrder = sortOrder
        self.isRetired = isRetired
        self.createdAt = createdAt
    }

    var tone: AtharStatusTone {
        get { AtharStatusTone(rawValue: toneRawValue) ?? .withMe }
        set { toneRawValue = newValue.rawValue }
    }

    var icon: AtharStatusIcon {
        get { AtharStatusIcon(rawValue: iconRawValue) ?? .person }
        set { iconRawValue = newValue.rawValue }
    }

    func displayName(language: AtharLanguage) -> String {
        if let customName, !customName.isEmpty {
            return customName
        }

        switch seedKey {
        case "with_me":
            return language == .arabic ? "معايا" : "With me"
        case "out_for_signature":
            return language == .arabic ? "خرجت للتوقيع" : "Out for signature"
        case "signed":
            return language == .arabic ? "اتمضت" : "Signed"
        case "delivered":
            return language == .arabic ? "تم التسليم" : "Delivered"
        default:
            return language == .arabic ? "حالة" : "Status"
        }
    }
}

enum AtharStatusIcon: String, CaseIterable, Identifiable {
    case person
    case arrow
    case check
    case tray
    case clock
    case document
    case tag
    case folder
    case bookmark
    case more

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .person: "person"
        case .arrow: "arrow.right"
        case .check: "checkmark"
        case .tray: "tray.full"
        case .clock: "clock"
        case .document: "doc"
        case .tag: "tag"
        case .folder: "folder"
        case .bookmark: "bookmark"
        case .more: "ellipsis"
        }
    }
}
