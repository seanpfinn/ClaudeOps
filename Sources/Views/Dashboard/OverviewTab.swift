import SwiftUI

struct OverviewTab: View {
    @EnvironmentObject var usageService: UsageService
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    UsageGaugeView(
                        label: "5-Hour",
                        percentage: usageService.snapshot.fiveHourUtilization,
                        timeRemaining: usageService.snapshot.fiveHourTimeRemaining,
                        warningThreshold: settings.warningThreshold,
                        criticalThreshold: settings.criticalThreshold
                    )
                    UsageGaugeView(
                        label: "Weekly",
                        percentage: usageService.snapshot.sevenDayUtilization,
                        timeRemaining: usageService.snapshot.sevenDayTimeRemaining,
                        warningThreshold: settings.warningThreshold,
                        criticalThreshold: settings.criticalThreshold
                    )
                }
                if let sonnet = usageService.snapshot.sevenDaySonnetUtilization {
                    HStack(spacing: 14) {
                        UsageGaugeView(
                            label: "Sonnet (Weekly)",
                            percentage: sonnet,
                            timeRemaining: usageService.snapshot.sevenDayTimeRemaining,
                            warningThreshold: settings.warningThreshold,
                            criticalThreshold: settings.criticalThreshold
                        )
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                }
                statusRow
            }
            .padding(20)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            if usageService.isLoading {
                ProgressView().scaleEffect(0.65).frame(width: 14, height: 14)
                Text("Updating…").font(.caption).foregroundStyle(.secondary)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text("Updated \(usageService.snapshot.lastUpdated.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Refresh") { Task { await usageService.refresh() } }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.tint)
        }
        .padding(.horizontal, 4)
    }
}
