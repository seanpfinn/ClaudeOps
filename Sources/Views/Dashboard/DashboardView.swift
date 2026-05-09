import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var usageService: UsageService
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var history: HistoryStore
    @State private var selection: SidebarItem = .overview

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .environmentObject(usageService)
                .environmentObject(settings)
                .navigationSplitViewColumnWidth(min: 180, ideal: 190, max: 220)
        } detail: {
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.prominentDetail)
        .frame(minWidth: 720, minHeight: 480)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .overview:
            OverviewTab()
        case .history:
            HistoryTab()
        case .models:
            ModelsTab()
        case .settings:
            SettingsView()
        }
    }
}
