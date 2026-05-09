import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var usageService: UsageService
    @State private var authStatus = ""
    @State private var showApiKeySetup = false
    @State private var showResetConfirm = false

    var body: some View {
        Form {
            Section("Authentication") {
                LabeledContent("Status") {
                    Text(authStatus).foregroundStyle(.secondary)
                }
                Button("Change Credentials") { showApiKeySetup = true }
            }

            Section("Thresholds") {
                LabeledContent("Warning") {
                    HStack {
                        Slider(value: $settings.warningThreshold, in: 50...95, step: 5)
                        Text("\(Int(settings.warningThreshold))%")
                            .frame(width: 36, alignment: .trailing)
                            .monospacedDigit()
                    }
                }
                LabeledContent("Critical") {
                    HStack {
                        Slider(value: $settings.criticalThreshold, in: 55...100, step: 5)
                        Text("\(Int(settings.criticalThreshold))%")
                            .frame(width: 36, alignment: .trailing)
                            .monospacedDigit()
                    }
                }
            }

            Section("Notifications") {
                Toggle("Usage Alerts", isOn: $settings.notificationsEnabled)
            }

            Section("Display") {
                Toggle("Compact Menu Bar", isOn: $settings.compactDisplay)
                    .onChange(of: settings.compactDisplay) { _ in
                        (NSApp.delegate as? AppDelegate)?.updateStatusButton(usageService.snapshot)
                    }
                Picker("Refresh Interval", selection: $settings.refreshIntervalSeconds) {
                    Text("1 minute").tag(60)
                    Text("5 minutes").tag(300)
                    Text("15 minutes").tag(900)
                }
            }

            Section("System") {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            }

            Section {
                Button("Reset & Sign Out", role: .destructive) {
                    showResetConfirm = true
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { refreshAuthStatus() }
        .sheet(isPresented: $showApiKeySetup) {
            ApiKeySetupView().environmentObject(settings)
        }
        .confirmationDialog("Reset ClaudeWatch?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset & Sign Out", role: .destructive) {
                settings.reset()
            }
        } message: {
            Text("This will remove your credentials and reset all settings.")
        }
    }

    private func refreshAuthStatus() {
        if (try? KeychainService.readClaudeCodeToken()) != nil {
            authStatus = "Claude Code ✓"
        } else if (try? KeychainService.loadApiKey()) != nil {
            authStatus = "API key ✓"
        } else {
            authStatus = "Not configured"
        }
    }
}
