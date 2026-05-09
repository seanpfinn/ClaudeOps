import SwiftUI
import Charts

struct HistoryTab: View {
    @EnvironmentObject var history: HistoryStore
    @EnvironmentObject var settings: SettingsManager

    private var chartData: [ChartPoint] {
        let grouped = Dictionary(grouping: history.entries) { entry -> String in
            let cal = Calendar.current
            let comps = cal.dateComponents([.year, .month, .day], from: entry.timestamp)
            return "\(comps.year!)-\(comps.month!)-\(comps.day!)"
        }
        return grouped.compactMap { key, entries -> ChartPoint? in
            guard let first = entries.first else { return nil }
            return ChartPoint(
                day: first.timestamp,
                fiveHourPeak: entries.map(\.fiveHourUtilization).max() ?? 0,
                sevenDayPeak: entries.map(\.sevenDayUtilization).max() ?? 0
            )
        }.sorted { $0.day < $1.day }
    }

    var body: some View {
        if history.entries.isEmpty {
            VStack(spacing: 14) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.tertiary)
                Text("No History Yet")
                    .font(.title3.bold())
                Text("Usage history will appear here once ClaudeWatch starts collecting data.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Chart(chartData) { point in
                        BarMark(
                            x: .value("Day", point.day, unit: .day),
                            y: .value("5-Hour Peak", point.fiveHourPeak)
                        )
                        .foregroundStyle(by: .value("Metric", "5-Hour Peak"))
                        .cornerRadius(4)
                        BarMark(
                            x: .value("Day", point.day, unit: .day),
                            y: .value("Weekly Peak", point.sevenDayPeak)
                        )
                        .foregroundStyle(by: .value("Metric", "Weekly Peak"))
                        .cornerRadius(4)
                    }
                    .chartForegroundStyleScale([
                        "5-Hour Peak": Color.blue,
                        "Weekly Peak": Color.purple
                    ])
                    .chartYAxis {
                        AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                            AxisGridLine().foregroundStyle(.white.opacity(0.1))
                            AxisValueLabel { Text("\(value.as(Int.self) ?? 0)%").font(.caption2) }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine().foregroundStyle(.white.opacity(0.1))
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                .font(.caption2)
                        }
                    }
                    .frame(height: 220)
                    .chartLegend(position: .bottom)

                    HStack(spacing: 16) {
                        legendItem(color: .orange, label: "Warning (\(Int(settings.warningThreshold))%)")
                        legendItem(color: .red, label: "Critical (\(Int(settings.criticalThreshold))%)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(20)
                .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                .padding(20)
            }
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }
}

private struct ChartPoint: Identifiable {
    var id: Date { day }
    let day: Date
    let fiveHourPeak: Int
    let sevenDayPeak: Int
}
