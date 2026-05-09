import SwiftUI

struct ApiKeySetupView: View {
    @EnvironmentObject var settings: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Enter API Key")
                .font(.title2.bold())
            Text("Enter your Anthropic API key. It will be stored securely in your Keychain.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            SecureField("sk-ant-…", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Validate & Save") { validate() }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)
                    .overlay {
                        if isValidating { ProgressView().scaleEffect(0.7) }
                    }
            }
        }
        .padding(24)
        .frame(width: 360)
    }

    private func validate() {
        let key = apiKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }
        isValidating = true
        errorMessage = nil
        Task {
            do {
                try await UsageService.shared.validateApiKey(key)
                try KeychainService.saveApiKey(key)
                await MainActor.run {
                    settings.hasCompletedOnboarding = true
                    UsageService.shared.startPolling()
                    dismiss()
                }
            } catch let err as AppError {
                await MainActor.run {
                    errorMessage = err.errorDescription
                    isValidating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Validation failed: \(error.localizedDescription)"
                    isValidating = false
                }
            }
        }
    }
}
