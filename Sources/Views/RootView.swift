import SwiftUI

struct RootView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        if settings.hasCompletedOnboarding {
            DashboardView()
        } else {
            WelcomeView()
        }
    }
}
