import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var usageService: UsageService
    @EnvironmentObject var settings: SettingsManager
    let openDashboard: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            headerRow

            VStack(spacing: 8) {
                usageRow(
                    label: "5-Hour",
                    percent: usageService.snapshot.fiveHourUtilization,
                    timeRemaining: usageService.snapshot.fiveHourTimeRemaining
                )
                usageRow(
                    label: "Weekly",
                    percent: usageService.snapshot.sevenDayUtilization,
                    timeRemaining: usageService.snapshot.sevenDayTimeRemaining
                )
                if let sonnet = usageService.snapshot.sevenDaySonnetUtilization {
                    usageRow(label: "Sonnet", percent: sonnet, timeRemaining: nil)
                }
            }

            if let error = usageService.error {
                errorRow(error)
            }

            actionRow
        }
        .padding(12)
        .frame(width: 272)
    }

    private var headerRow: some View {
        HStack {
            Text("ClaudeOps")
                .font(.headline)
            Spacer()
            if usageService.isLoading {
                ProgressView().scaleEffect(0.6).frame(width: 16, height: 16)
            } else {
                Button {
                    Task { await usageService.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                }
                .buttonStyle(.borderless)
                .help("Refresh")
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }

    private func usageRow(label: String, percent: Int, timeRemaining: String?) -> some View {
        let color = ColorThreshold.usageColor(
            for: percent,
            warning: settings.warningThreshold,
            critical: settings.criticalThreshold
        )
        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(percent)%")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(color)
            }
            ProgressView(value: Double(percent), total: 100)
                .tint(color)
            if let t = timeRemaining {
                Text("resets in \(t)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
    }

    private func errorRow(_ error: AppError) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(error.errorDescription ?? "Error")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button("Open Dashboard", action: openDashboard)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .frame(maxWidth: .infinity)
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.top, 2)
    }
}
