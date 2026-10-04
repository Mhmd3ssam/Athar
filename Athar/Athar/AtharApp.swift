//
//  AtharApp.swift
//  Athar
//
//  Created by Mhmd Essam on 03/10/2026.
//

import SwiftData
import SwiftUI

@main
@MainActor
struct AtharApp: App {
    @StateObject private var preferences = AppPreferences()
    private let modelContainer = AtharDataController.makeContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .environment(\.locale, preferences.language.locale)
                .environment(\.layoutDirection, preferences.language.layoutDirection)
                .preferredColorScheme(preferences.appearance.colorScheme)
        }
        .modelContainer(modelContainer)
    }
}
