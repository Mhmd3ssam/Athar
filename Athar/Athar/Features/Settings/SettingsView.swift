import Foundation
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.layoutDirection) private var layoutDirection

    @State private var showAppearance = false
    @State private var showLanguage = false
    @State private var showStatuses = false
    @State private var showStoredImages = false
    @State private var storageUsageBytes: Int64 = 0

    var body: some View {
        ZStack {
            AtharColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AtharSpacing.x6) {
                    header

                    sectionTitle("settings.documents")
                    settingsRow(
                        symbol: "list.bullet",
                        title: "settings.manageStatuses",
                        subtitle: "settings.manageStatuses.subtitle"
                    ) {
                        showStatuses = true
                    }

                    settingsRow(
                        symbol: preferences.appearance.symbolName,
                        title: "settings.appearance",
                        subtitleText: Text(preferences.appearance.titleKey)
                    ) {
                        showAppearance = true
                    }

                    settingsRow(
                        symbol: "globe",
                        title: "settings.language",
                        subtitleText: Text(preferences.language.titleKey)
                    ) {
                        showLanguage = true
                    }

                    sectionTitle("settings.storage")

                    storageRow

                    Text("settings.storage.note")
                        .font(AtharTypography.secondary)
                        .foregroundStyle(AtharColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, AtharSpacing.x2)
                }
                .padding(.horizontal, AtharLayout.screenInset)
                .padding(.bottom, AtharSpacing.x8)
            }
        }
        .task {
            refreshStorageUsage()
        }
        .fullScreenCover(isPresented: $showStatuses) {
            ManageStatusesView()
        }
        .fullScreenCover(isPresented: $showStoredImages) {
            StoredImagesView()
        }
        .sheet(isPresented: $showAppearance) {
            preferenceSheet(
                title: "settings.appearance",
                rows: AtharAppearance.allCases.map { appearance in
                    PreferenceChoice(
                        id: appearance.rawValue,
                        title: appearance.titleKey,
                        symbol: appearance.symbolName,
                        isSelected: appearance == preferences.appearance,
                        action: {
                            preferences.appearance = appearance
                            showAppearance = false
                        }
                    )
                },
                onClose: { showAppearance = false }
            )
        }
        .sheet(isPresented: $showLanguage) {
            preferenceSheet(
                title: "settings.language",
                rows: AtharLanguage.allCases.map { language in
                    PreferenceChoice(
                        id: language.rawValue,
                        title: language.titleKey,
                        symbol: "globe",
                        isSelected: language == preferences.language,
                        action: {
                            preferences.language = language
                            showLanguage = false
                        }
                    )
                },
                onClose: { showLanguage = false }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AtharSpacing.x3) {
            Button(action: { dismiss() }) {
                Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AtharColors.text)
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("common.back"))

            Text("settings.title")
                .font(AtharTypography.screenTitle)
                .foregroundStyle(AtharColors.text)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.top, AtharSpacing.x2)
    }

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(AtharTypography.rowTitle.weight(.semibold))
            .foregroundStyle(AtharColors.text)
            .padding(.top, AtharSpacing.x2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingsRow(
        symbol: String,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        settingsRow(symbol: symbol, title: title, subtitleText: Text(subtitle), action: action)
    }

    private func settingsRow(
        symbol: String,
        title: LocalizedStringKey,
        subtitleText: Text,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AtharSpacing.x4) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AtharColors.text)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AtharTypography.rowTitle)
                        .foregroundStyle(AtharColors.text)

                    subtitleText
                        .font(AtharTypography.secondary)
                        .foregroundStyle(AtharColors.textSecondary)
                }

                Spacer(minLength: AtharSpacing.x3)

                Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AtharColors.textSecondary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 70)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AtharColors.border).frame(height: 1)
        }
    }

    private var storageRow: some View {
        Button {
            showStoredImages = true
        } label: {
            HStack(alignment: .top, spacing: AtharSpacing.x4) {
                Image(systemName: "photo")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AtharColors.text)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("settings.images")
                        .font(AtharTypography.rowTitle)
                        .foregroundStyle(AtharColors.text)

                    Text(storageUsageText)
                        .font(AtharTypography.secondary)
                        .foregroundStyle(AtharColors.textSecondary)

                    Text("settings.savedOnDevice")
                        .font(AtharTypography.secondary)
                        .foregroundStyle(AtharColors.textSecondary)

                    Text("settings.inAppStorage")
                        .font(AtharTypography.secondary)
                        .foregroundStyle(AtharColors.textSecondary)
                }

                Spacer(minLength: AtharSpacing.x3)

                Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AtharColors.textSecondary)
                    .frame(minHeight: 44)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, AtharSpacing.x3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AtharColors.border).frame(height: 1)
        }
    }

    private func preferenceSheet(
        title: LocalizedStringKey,
        rows: [PreferenceChoice],
        onClose: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AtharColors.border)
                .frame(width: 38, height: 5)
                .padding(.top, AtharSpacing.x3)
                .padding(.bottom, AtharSpacing.x4)

            HStack {
                Text(title)
                    .font(AtharTypography.sheetTitle)
                    .foregroundStyle(AtharColors.text)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AtharColors.text)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("common.close"))
            }
            .padding(.horizontal, AtharLayout.screenInset)

            VStack(spacing: 0) {
                ForEach(rows) { row in
                    Button(action: row.action) {
                        HStack(spacing: AtharSpacing.x4) {
                            Image(systemName: row.symbol)
                                .font(.system(size: 19, weight: .medium))
                                .foregroundStyle(AtharColors.text)
                                .frame(width: 28)

                            Text(row.title)
                                .font(AtharTypography.body.weight(.medium))
                                .foregroundStyle(AtharColors.text)

                            Spacer()

                            ZStack {
                                Circle()
                                    .stroke(AtharColors.textSecondary, lineWidth: 1.5)
                                    .frame(width: 22, height: 22)

                                if row.isSelected {
                                    Circle()
                                        .fill(AtharColors.primary)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                        .frame(minHeight: 56)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if row.id != rows.last?.id {
                        Rectangle().fill(AtharColors.border).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, AtharLayout.screenInset)

            Spacer(minLength: AtharSpacing.x6)
        }
        .background(AtharColors.surface.ignoresSafeArea())
        .presentationDetents([.height(CGFloat(170 + rows.count * 56))])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(AtharRadius.sheetTop)
        .presentationBackground(AtharColors.surface)
    }

    private var storageUsageText: String {
        ByteCountFormatter.string(fromByteCount: storageUsageBytes, countStyle: .file)
    }

    private func refreshStorageUsage() {
        storageUsageBytes = AtharImageStore.storageUsageBytes()
    }
}

private struct PreferenceChoice: Identifiable {
    let id: String
    let title: LocalizedStringKey
    let symbol: String
    let isSelected: Bool
    let action: () -> Void
}
