import SwiftUI

@main
struct ClaudeOpsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var usageService = UsageService.shared
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var history = HistoryStore.shared
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup("ClaudeOps", id: "dashboard") {
            RootView()
                .environmentObject(usageService)
                .environmentObject(settings)
                .environmentObject(history)
                .onAppear {
                    appDelegate.openDashboard = { openWindow(id: "dashboard") }
                }
        }
        .defaultSize(width: 620, height: 500)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Refresh Usage") {
                    Task { await UsageService.shared.refresh() }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
