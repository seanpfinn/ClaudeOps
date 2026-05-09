import SwiftUI

struct RootView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding {
                DashboardView()
            } else {
                WelcomeView()
            }
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
