import SwiftData
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: AtharRootTab = .timeline
    @State private var showingSettings = false
    @State private var showingScan = false
    @State private var showRestoredFeedback = false

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .timeline:
                    TimelineView(
                        onSettings: { showingSettings = true },
                        onScan: { showingScan = true },
                        onViewArchive: { selectedTab = .archive }
                    )
                case .archive:
                    ArchiveView(
                        onBackToTimeline: { selectedTab = .timeline },
                        onRestoredToTimeline: {
                            selectedTab = .timeline
                            showRestoredFeedback = true
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            AtharRootTabBar(
                selected: selectedTab,
                onTimeline: { selectedTab = .timeline },
                onScan: { showingScan = true },
                onArchive: { selectedTab = .archive }
            )
        }
        .background(AtharColors.background.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            if showRestoredFeedback {
                AtharSnackbar(
                    message: "archive.feedback.restored",
                    onDismiss: { showRestoredFeedback = false }
                )
                .padding(.bottom, 86)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showRestoredFeedback)
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showingScan) {
            ScanFlowView(
                onCancel: { showingScan = false },
                onSaved: {
                    showingScan = false
                    selectedTab = .timeline
                }
            )
        }
        .task {
            recomputeArchiveClassification()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                recomputeArchiveClassification()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            recomputeArchiveClassification()
        }
        .onChange(of: showRestoredFeedback) { _, isShowing in
            guard isShowing else { return }
            Task {
                try? await Task.sleep(for: .seconds(4))
                if !Task.isCancelled {
                    showRestoredFeedback = false
                }
            }
        }
    }

    private func recomputeArchiveClassification() {
        try? DocumentArchiveService.recomputeHistoricalClassification(
            in: modelContext,
            language: preferences.language
        )
    }
}
