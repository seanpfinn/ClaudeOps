import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var authState: AuthState = .checking
    @State private var showApiKeySetup = false

    enum AuthState: Equatable {
        case checking, detected, notFound, error(String)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 10) {
                    Image(systemName: "gauge.with.needle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)
                        .symbolEffect(.bounce, value: authState == .detected)
                    Text("ClaudeWatch")
                        .font(.largeTitle.bold())
                    Text("Monitor your Claude usage limits from the menu bar.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 0) {
                    switch authState {
                    case .checking:
                        ProgressView("Detecting credentials…")
                            .padding(24)
                    case .detected:
                        detectedView
                    case .notFound:
                        notFoundView
                    case .error(let msg):
                        VStack(spacing: 12) {
                            Text(msg).foregroundStyle(.red).font(.caption)
                            notFoundView
                        }
                    }
                }
                .glassEffect(in: RoundedRectangle(cornerRadius: 20))

                Spacer()
            }
            .padding(40)
            .frame(width: 440, height: 480)
        }
        .sheet(isPresented: $showApiKeySetup) {
            ApiKeySetupView()
                .environmentObject(settings)
        }
        .onAppear { detectAuth() }
    }

    private var detectedView: some View {
        VStack(spacing: 16) {
            Label("Connected via Claude Code", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.headline)
            Text("ClaudeWatch will use your existing Claude Code credentials. No additional setup needed.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Get Started") { completeOnboarding() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(24)
    }

    private var notFoundView: some View {
        VStack(spacing: 16) {
            Text("Claude Code not detected")
                .font(.headline)
            HStack(spacing: 12) {
                Button("Use API Key") { showApiKeySetup = true }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Button("I use Claude Code") { detectAuth() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .help("Re-check after signing in to Claude Code")
            }
            Text("Make sure Claude Code is installed and signed in, then try again.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }

    private func detectAuth() {
        authState = .checking
        DispatchQueue.global().async {
            do {
                _ = try KeychainService.readClaudeCodeToken()
                DispatchQueue.main.async { authState = .detected }
            } catch {
                DispatchQueue.main.async { authState = .notFound }
            }
        }
    }

    private func completeOnboarding() {
        settings.hasCompletedOnboarding = true
        UsageService.shared.startPolling()
    }
}
