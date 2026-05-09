import SwiftUI

struct OverviewTab: View {
    @EnvironmentObject var usageService: UsageService
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var history: HistoryStore

    var body: some View {
        // Tick every 30 seconds so countdowns stay live
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
            ScrollView {
                VStack(spacing: 16) {
                    statusBanner(now: timeline.date)
                    gaugeRow(now: timeline.date)
                    if let sonnet = usageService.snapshot.sevenDaySonnetUtilization {
                        HStack(spacing: 14) {
                            UsageGaugeView(
                                label: "Sonnet (Weekly)",
                                percentage: sonnet,
                                timeRemaining: liveTimeRemaining(
                                    for: usageService.snapshot.sevenDayResetsAt,
                                    from: timeline.date
                                ),
                                warningThreshold: settings.warningThreshold,
                                criticalThreshold: settings.criticalThreshold
                            )
                            Color.clear.frame(maxWidth: .infinity).padding(.vertical, 20)
                        }
                    }
                    trendRow
                    statusFooter(now: timeline.date)
                }
                .padding(20)
            }
        }
    }

    // MARK: - Status banner

    private func statusBanner(now: Date) -> some View {
        let status = currentStatus
        return HStack(spacing: 14) {
            Image(systemName: status.icon)
                .font(.title2)
                .foregroundStyle(status.color)
                .symbolEffect(.pulse, isActive: status.isPulsing)

            VStack(alignment: .leading, spacing: 3) {
                Text(status.title)
                    .font(.headline)
                Text(status.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            // Next reset countdown
            if let nextReset = nextResetDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("next reset")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(liveTimeRemaining(for: nextReset, from: now) ?? "—")
                        .font(.callout.monospacedDigit().bold())
                        .foregroundStyle(status.color)
                        .contentTransition(.numericText())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Gauge row with live countdowns

    private func gaugeRow(now: Date) -> some View {
        HStack(spacing: 14) {
            UsageGaugeView(
                label: "5-Hour",
                percentage: usageService.snapshot.fiveHourUtilization,
                timeRemaining: liveTimeRemaining(
                    for: usageService.snapshot.fiveHourResetsAt,
                    from: now
                ),
                warningThreshold: settings.warningThreshold,
                criticalThreshold: settings.criticalThreshold
            )
            UsageGaugeView(
                label: "Weekly",
                percentage: usageService.snapshot.sevenDayUtilization,
                timeRemaining: liveTimeRemaining(
                    for: usageService.snapshot.sevenDayResetsAt,
                    from: now
                ),
                warningThreshold: settings.warningThreshold,
                criticalThreshold: settings.criticalThreshold
            )
        }
    }

    // MARK: - Trend vs yesterday

    private var trendRow: some View {
        let (fiveTrend, weekTrend) = trendValues
        guard fiveTrend != nil || weekTrend != nil else { return AnyView(EmptyView()) }

        return AnyView(
            HStack(spacing: 10) {
                if let t = fiveTrend {
                    trendPill(label: "5h vs yesterday", delta: t)
                }
                if let t = weekTrend {
                    trendPill(label: "Weekly vs yesterday", delta: t)
                }
                Spacer()
            }
        )
    }

    private func trendPill(label: String, delta: Int) -> some View {
        let isUp = delta > 0
        let color: Color = isUp ? .orange : .green
        let arrow = isUp ? "arrow.up.right" : "arrow.down.right"
        return HStack(spacing: 4) {
            Image(systemName: arrow)
                .font(.caption2.weight(.bold))
            Text("\(isUp ? "+" : "")\(delta)% \(label)")
                .font(.caption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .glassEffect(in: Capsule())
    }

    // MARK: - Footer

    private func statusFooter(now: Date) -> some View {
        HStack(spacing: 8) {
            if usageService.isLoading {
                ProgressView().scaleEffect(0.65).frame(width: 14, height: 14)
                Text("Updating…").font(.caption).foregroundStyle(.secondary)
            } else {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                Text("Updated \(usageService.snapshot.lastUpdated.formatted(.relative(presentation: .named)))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Refresh") { Task { await usageService.refresh() } }
                .buttonStyle(.borderless).font(.caption).foregroundStyle(.tint)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Helpers

    private struct Status {
        let icon: String
        let title: String
        let subtitle: String
        let color: Color
        let isPulsing: Bool
    }

    private var currentStatus: Status {
        let s = usageService.snapshot
        let max5h  = s.fiveHourUtilization
        let max7d  = s.sevenDayUtilization
        let worst  = max(max5h, max7d)
        let crit   = Int(settings.criticalThreshold)
        let warn   = Int(settings.warningThreshold)

        switch worst {
        case crit...:
            return Status(
                icon: "exclamationmark.octagon.fill",
                title: "Limit nearly reached",
                subtitle: "Consider pausing usage until the next reset.",
                color: .red,
                isPulsing: true
            )
        case warn..<crit:
            let which = max5h >= max7d ? "5-hour" : "weekly"
            return Status(
                icon: "exclamationmark.triangle.fill",
                title: "Usage is climbing",
                subtitle: "Your \(which) usage is approaching the limit.",
                color: .orange,
                isPulsing: false
            )
        default:
            return Status(
                icon: "checkmark.circle.fill",
                title: "You're in the clear",
                subtitle: "Usage is well within both limits.",
                color: .green,
                isPulsing: false
            )
        }
    }

    // The sooner of the two reset dates — the one the user cares about most
    private var nextResetDate: Date? {
        let s = usageService.snapshot
        switch (s.fiveHourResetsAt, s.sevenDayResetsAt) {
        case (let a?, let b?): return min(a, b)
        case (let a?, nil):    return a
        case (nil, let b?):    return b
        case (nil, nil):       return nil
        }
    }

    private func liveTimeRemaining(for date: Date?, from now: Date) -> String? {
        guard let date else { return nil }
        return formatTimeRemaining(until: date, from: now)
    }

    // Compare today's current utilization vs yesterday's peak from history
    private var trendValues: (fiveHour: Int?, sevenDay: Int?) {
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayEntries = history.entries.filter {
            cal.isDate($0.timestamp, inSameDayAs: yesterday)
        }
        guard !yesterdayEntries.isEmpty else { return (nil, nil) }
        let yPeak5h  = yesterdayEntries.map(\.fiveHourUtilization).max()!
        let yPeak7d  = yesterdayEntries.map(\.sevenDayUtilization).max()!
        let delta5h  = usageService.snapshot.fiveHourUtilization - yPeak5h
        let delta7d  = usageService.snapshot.sevenDayUtilization - yPeak7d
        // Only show if there's a meaningful delta
        return (
            abs(delta5h) >= 3 ? delta5h : nil,
            abs(delta7d) >= 3 ? delta7d : nil
        )
    }
}
