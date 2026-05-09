import SwiftUI

enum VizStyle: String, CaseIterable {
    case gauge, bars, compact

    var label: String {
        switch self {
        case .gauge:   return "Gauges"
        case .bars:    return "Bars"
        case .compact: return "Compact"
        }
    }
    var icon: String {
        switch self {
        case .gauge:   return "circle.dashed"
        case .bars:    return "chart.bar.horizontal.fill"
        case .compact: return "rectangle.grid.1x2.fill"
        }
    }
}

struct OverviewTab: View {
    @EnvironmentObject var usageService: UsageService
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var history: HistoryStore

    @AppStorage("dashboardVizStyle") private var vizStyle = VizStyle.gauge
    @AppStorage("showProjectionCard") private var showProjection = true
    @AppStorage("showHeatmap") private var showHeatmap = true
    @AppStorage("showTrend") private var showTrend = true
    @State private var showCustomize = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
            ScrollView {
                VStack(spacing: 16) {
                    toolbarHeader
                    statusBanner(now: timeline.date)
                    vizSection(now: timeline.date)
                    if showProjection {
                        projectionCard(now: timeline.date)
                    }
                    if showHeatmap {
                        heatmapCard
                    }
                    if showTrend {
                        trendRow
                    }
                    statusFooter(now: timeline.date)
                }
                .padding(20)
            }
        }
    }

    // MARK: - Toolbar

    private var toolbarHeader: some View {
        HStack(spacing: 8) {
            Spacer()
            HStack(spacing: 2) {
                ForEach(VizStyle.allCases, id: \.self) { style in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { vizStyle = style }
                    } label: {
                        Image(systemName: style.icon)
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 28, height: 26)
                            .background {
                                if vizStyle == style {
                                    RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.15))
                                }
                            }
                            .foregroundStyle(vizStyle == style ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(style.label)
                }
            }
            .padding(3)
            .glassEffect(in: RoundedRectangle(cornerRadius: 9))

            Button { showCustomize.toggle() } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 30, height: 26)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .glassEffect(in: RoundedRectangle(cornerRadius: 9))
            .popover(isPresented: $showCustomize, arrowEdge: .top) {
                customizePopover
            }
        }
    }

    private var customizePopover: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Modules")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Toggle("Projections", isOn: $showProjection)
            Toggle("Weekly Heatmap", isOn: $showHeatmap)
            Toggle("Trend vs Yesterday", isOn: $showTrend)
        }
        .padding(16)
        .frame(width: 210)
        .toggleStyle(.switch)
    }

    // MARK: - Visualization section

    @ViewBuilder
    private func vizSection(now: Date) -> some View {
        switch vizStyle {
        case .gauge:   gaugeSection(now: now)
        case .bars:    barsSection(now: now)
        case .compact: compactSection(now: now)
        }
    }

    private func gaugeSection(now: Date) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                UsageGaugeView(
                    label: "5-Hour",
                    percentage: usageService.snapshot.fiveHourUtilization,
                    timeRemaining: liveTimeRemaining(for: usageService.snapshot.fiveHourResetsAt, from: now),
                    warningThreshold: settings.warningThreshold,
                    criticalThreshold: settings.criticalThreshold
                )
                UsageGaugeView(
                    label: "Weekly",
                    percentage: usageService.snapshot.sevenDayUtilization,
                    timeRemaining: liveTimeRemaining(for: usageService.snapshot.sevenDayResetsAt, from: now),
                    warningThreshold: settings.warningThreshold,
                    criticalThreshold: settings.criticalThreshold
                )
            }
            if let sonnet = usageService.snapshot.sevenDaySonnetUtilization {
                HStack(spacing: 14) {
                    UsageGaugeView(
                        label: "Sonnet (Weekly)",
                        percentage: sonnet,
                        timeRemaining: liveTimeRemaining(for: usageService.snapshot.sevenDayResetsAt, from: now),
                        warningThreshold: settings.warningThreshold,
                        criticalThreshold: settings.criticalThreshold
                    )
                    Color.clear.frame(maxWidth: .infinity).padding(.vertical, 20)
                }
            }
        }
    }

    private func barsSection(now: Date) -> some View {
        VStack(spacing: 10) {
            barRow(
                label: "5-Hour",
                percent: usageService.snapshot.fiveHourUtilization,
                timeRemaining: liveTimeRemaining(for: usageService.snapshot.fiveHourResetsAt, from: now)
            )
            barRow(
                label: "Weekly",
                percent: usageService.snapshot.sevenDayUtilization,
                timeRemaining: liveTimeRemaining(for: usageService.snapshot.sevenDayResetsAt, from: now)
            )
            if let sonnet = usageService.snapshot.sevenDaySonnetUtilization {
                barRow(label: "Sonnet (Weekly)", percent: sonnet, timeRemaining: nil)
            }
        }
    }

    private func barRow(label: String, percent: Int, timeRemaining: String?) -> some View {
        let color = ColorThreshold.usageColor(
            for: percent,
            warning: settings.warningThreshold,
            critical: settings.criticalThreshold
        )
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label).font(.subheadline.weight(.medium))
                Spacer()
                Text("\(percent)%")
                    .font(.title2.monospacedDigit().bold())
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08)).frame(height: 10)
                    Capsule()
                        .fill(color.gradient)
                        .frame(width: max(geo.size.width * CGFloat(percent) / 100, 0), height: 10)
                        .animation(.spring(duration: 0.6), value: percent)
                    Rectangle()
                        .fill(Color.orange.opacity(0.5))
                        .frame(width: 1.5, height: 16)
                        .offset(x: geo.size.width * CGFloat(settings.warningThreshold) / 100 - 0.75)
                    Rectangle()
                        .fill(Color.red.opacity(0.5))
                        .frame(width: 1.5, height: 16)
                        .offset(x: geo.size.width * CGFloat(settings.criticalThreshold) / 100 - 0.75)
                }
            }
            .frame(height: 16)
            if let t = timeRemaining {
                Text("resets in \(t)").font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(in: RoundedRectangle(cornerRadius: 14))
    }

    private func compactSection(now: Date) -> some View {
        HStack(spacing: 10) {
            compactCell(
                label: "5-Hour",
                percent: usageService.snapshot.fiveHourUtilization,
                timeRemaining: liveTimeRemaining(for: usageService.snapshot.fiveHourResetsAt, from: now)
            )
            compactCell(
                label: "Weekly",
                percent: usageService.snapshot.sevenDayUtilization,
                timeRemaining: liveTimeRemaining(for: usageService.snapshot.sevenDayResetsAt, from: now)
            )
            if let sonnet = usageService.snapshot.sevenDaySonnetUtilization {
                compactCell(label: "Sonnet", percent: sonnet, timeRemaining: nil)
            }
        }
    }

    private func compactCell(label: String, percent: Int, timeRemaining: String?) -> some View {
        let color = ColorThreshold.usageColor(
            for: percent,
            warning: settings.warningThreshold,
            critical: settings.criticalThreshold
        )
        return VStack(spacing: 5) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text("\(percent)%")
                .font(.title3.monospacedDigit().bold())
                .foregroundStyle(color)
                .contentTransition(.numericText())
            ProgressView(value: Double(percent), total: 100).tint(color)
            if let t = timeRemaining {
                Text(t).font(.system(size: 9).monospacedDigit()).foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Projection card

    private func projectionCard(now: Date) -> some View {
        let data = buildProjections(now: now)
        guard !data.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.forward.circle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text("Projections")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("at current rate")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                HStack(spacing: 10) {
                    ForEach(data, id: \.label) { proj in
                        projectionCell(proj)
                    }
                }
            }
            .padding(16)
            .glassEffect(in: RoundedRectangle(cornerRadius: 16))
        )
    }

    private func projectionCell(_ proj: ProjectionInfo) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(proj.label).font(.caption).foregroundStyle(.secondary)
            Text(String(format: "%.2f%%/h", proj.velocityPerHour))
                .font(.callout.monospacedDigit().bold())
            Group {
                if let hours = proj.hoursToLimit {
                    if hours < 1 {
                        Text("limit in ~\(Int(hours * 60))m").foregroundStyle(.red)
                    } else if hours < proj.windowHours {
                        Text("limit in ~\(formatHours(hours))").foregroundStyle(.orange)
                    } else {
                        Text("on track").foregroundStyle(.green)
                    }
                } else {
                    Text("no limit risk").foregroundStyle(.green)
                }
            }
            .font(.caption2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
    }

    private func formatHours(_ h: Double) -> String {
        if h >= 24 {
            let days = Int(h / 24)
            let rem = Int(h) % 24
            return rem > 0 ? "\(days)d \(rem)h" : "\(days)d"
        }
        return "\(Int(h))h"
    }

    // MARK: - Heatmap

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("7-Day Heatmap")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 8) {
                    heatLegend(color: .blue, label: "Low")
                    heatLegend(color: .orange, label: "Warn")
                    heatLegend(color: .red, label: "Crit")
                }
            }
            HStack(spacing: 6) {
                ForEach(heatmapDays, id: \.date) { day in
                    heatCell(day: day)
                }
            }
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }

    private func heatCell(day: HeatDay) -> some View {
        let isToday = Calendar.current.isDateInToday(day.date)
        let peak = max(day.peak5h, day.peak7d)
        let color = heatColor(for: peak)
        return VStack(spacing: 4) {
            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                .font(.system(size: 10, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? .primary : .tertiary)
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(peak == 0 ? Color.white.opacity(0.06) : color.opacity(0.75))
                if isToday {
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1.5)
                }
                if peak > 0 {
                    Text("\(peak)")
                        .font(.system(size: 10, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .frame(height: 40)
        }
        .frame(maxWidth: .infinity)
    }

    private func heatColor(for percent: Int) -> Color {
        if percent >= Int(settings.criticalThreshold) { return .red }
        if percent >= Int(settings.warningThreshold) { return .orange }
        return .blue
    }

    private func heatLegend(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.75)).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundStyle(.tertiary)
        }
    }

    private var heatmapDays: [HeatDay] {
        let cal = Calendar.current
        let today = Date()
        return stride(from: 6, through: 0, by: -1).map { daysAgo in
            let date = cal.date(byAdding: .day, value: -daysAgo, to: today)!
            let entries = history.entries.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
            return HeatDay(
                date: date,
                peak5h: entries.map(\.fiveHourUtilization).max() ?? 0,
                peak7d: entries.map(\.sevenDayUtilization).max() ?? 0
            )
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
                Text(status.title).font(.headline)
                Text(status.subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()

            if let nextReset = nextResetDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("next reset").font(.caption2).foregroundStyle(.tertiary)
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

    // MARK: - Trend row

    private var trendRow: some View {
        let (fiveTrend, weekTrend) = trendValues
        guard fiveTrend != nil || weekTrend != nil else { return AnyView(EmptyView()) }
        return AnyView(
            HStack(spacing: 10) {
                if let t = fiveTrend { trendPill(label: "5h vs yesterday", delta: t) }
                if let t = weekTrend { trendPill(label: "Weekly vs yesterday", delta: t) }
                Spacer()
            }
        )
    }

    private func trendPill(label: String, delta: Int) -> some View {
        let isUp = delta > 0
        let color: Color = isUp ? .orange : .green
        let arrow = isUp ? "arrow.up.right" : "arrow.down.right"
        return HStack(spacing: 4) {
            Image(systemName: arrow).font(.caption2.weight(.bold))
            Text("\(isUp ? "+" : "")\(delta)% \(label)").font(.caption)
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

    // MARK: - Models

    private struct ProjectionInfo {
        let label: String
        let velocityPerHour: Double
        let hoursToLimit: Double?
        let windowHours: Double
    }

    private struct HeatDay {
        let date: Date
        let peak5h: Int
        let peak7d: Int
    }

    private struct Status {
        let icon: String
        let title: String
        let subtitle: String
        let color: Color
        let isPulsing: Bool
    }

    // MARK: - Computed helpers

    private func buildProjections(now: Date) -> [ProjectionInfo] {
        var result: [ProjectionInfo] = []
        if let resetsAt = usageService.snapshot.fiveHourResetsAt {
            let elapsed = max(0.1, now.timeIntervalSince(resetsAt.addingTimeInterval(-5 * 3600)) / 3600)
            let util = Double(usageService.snapshot.fiveHourUtilization)
            let vel = util / elapsed
            result.append(ProjectionInfo(
                label: "5-Hour",
                velocityPerHour: vel,
                hoursToLimit: vel > 0 ? (100.0 - util) / vel : nil,
                windowHours: 5
            ))
        }
        if let resetsAt = usageService.snapshot.sevenDayResetsAt {
            let elapsed = max(0.1, now.timeIntervalSince(resetsAt.addingTimeInterval(-7 * 24 * 3600)) / 3600)
            let util = Double(usageService.snapshot.sevenDayUtilization)
            let vel = util / elapsed
            result.append(ProjectionInfo(
                label: "Weekly",
                velocityPerHour: vel,
                hoursToLimit: vel > 0 ? (100.0 - util) / vel : nil,
                windowHours: 7 * 24
            ))
        }
        return result
    }

    private var currentStatus: Status {
        let s = usageService.snapshot
        let worst = max(s.fiveHourUtilization, s.sevenDayUtilization)
        let crit = Int(settings.criticalThreshold)
        let warn = Int(settings.warningThreshold)
        switch worst {
        case crit...:
            return Status(icon: "exclamationmark.octagon.fill", title: "Limit nearly reached",
                          subtitle: "Consider pausing usage until the next reset.", color: .red, isPulsing: true)
        case warn..<crit:
            let which = s.fiveHourUtilization >= s.sevenDayUtilization ? "5-hour" : "weekly"
            return Status(icon: "exclamationmark.triangle.fill", title: "Usage is climbing",
                          subtitle: "Your \(which) usage is approaching the limit.", color: .orange, isPulsing: false)
        default:
            return Status(icon: "checkmark.circle.fill", title: "You're in the clear",
                          subtitle: "Usage is well within both limits.", color: .green, isPulsing: false)
        }
    }

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

    private var trendValues: (fiveHour: Int?, sevenDay: Int?) {
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayEntries = history.entries.filter { cal.isDate($0.timestamp, inSameDayAs: yesterday) }
        guard !yesterdayEntries.isEmpty else { return (nil, nil) }
        let yPeak5h = yesterdayEntries.map(\.fiveHourUtilization).max()!
        let yPeak7d = yesterdayEntries.map(\.sevenDayUtilization).max()!
        let delta5h = usageService.snapshot.fiveHourUtilization - yPeak5h
        let delta7d = usageService.snapshot.sevenDayUtilization - yPeak7d
        return (abs(delta5h) >= 3 ? delta5h : nil, abs(delta7d) >= 3 ? delta7d : nil)
    }
}
