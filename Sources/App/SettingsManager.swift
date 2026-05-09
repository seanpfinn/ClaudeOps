import Foundation
import Combine
import ServiceManagement

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var warningThreshold: Double {
        didSet { UserDefaults.standard.set(warningThreshold, forKey: "warningThreshold") }
    }
    @Published var criticalThreshold: Double {
        didSet { UserDefaults.standard.set(criticalThreshold, forKey: "criticalThreshold") }
    }
    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }
    @Published var compactDisplay: Bool {
        didSet { UserDefaults.standard.set(compactDisplay, forKey: "compactDisplay") }
    }
    @Published var refreshIntervalSeconds: Int {
        didSet { UserDefaults.standard.set(refreshIntervalSeconds, forKey: "refreshIntervalSeconds") }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            applyLaunchAtLogin()
        }
    }

    private init() {
        let d = UserDefaults.standard
        warningThreshold = d.object(forKey: "warningThreshold") as? Double ?? 80.0
        criticalThreshold = d.object(forKey: "criticalThreshold") as? Double ?? 90.0
        notificationsEnabled = d.object(forKey: "notificationsEnabled") as? Bool ?? true
        compactDisplay = d.object(forKey: "compactDisplay") as? Bool ?? true
        refreshIntervalSeconds = d.object(forKey: "refreshIntervalSeconds") as? Int ?? 300
        hasCompletedOnboarding = d.bool(forKey: "hasCompletedOnboarding")
        launchAtLogin = d.bool(forKey: "launchAtLogin")
    }

    func reset() {
        hasCompletedOnboarding = false
        warningThreshold = 80.0
        criticalThreshold = 90.0
        notificationsEnabled = true
        compactDisplay = true
        refreshIntervalSeconds = 300
        try? KeychainService.deleteApiKey()
    }

    private func applyLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {}
    }
}
