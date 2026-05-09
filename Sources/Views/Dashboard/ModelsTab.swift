import SwiftUI

struct ModelsTab: View {
    @EnvironmentObject var usageService: UsageService
    @EnvironmentObject var settings: SettingsManager

    private var rows: [(label: String, percent: Int)] {
        var result = [
            ("All Models (Weekly)", usageService.snapshot.sevenDayUtilization),
            ("All Models (5-Hour)", usageService.snapshot.fiveHourUtilization)
        ]
        if let sonnet = usageService.snapshot.sevenDaySonnetUtilization {
            result.append(("Sonnet (Weekly)", sonnet))
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(rows, id: \.label) { row in
                    modelRow(label: row.label, percent: row.percent)
                }
            }
            .padding(20)
        }
    }

    private func modelRow(label: String, percent: Int) -> some View {
        let color = ColorThreshold.usageColor(
            for: percent,
            warning: settings.warningThreshold,
            critical: settings.criticalThreshold
        )
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                ProgressView(value: Double(percent), total: 100)
                    .tint(color)
            }
            Text("\(percent)%")
                .font(.title3.monospacedDigit().bold())
                .foregroundStyle(color)
                .frame(width: 52, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }
}
