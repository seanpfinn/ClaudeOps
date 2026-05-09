import SwiftUI

enum SidebarItem: String, CaseIterable, Hashable {
    case overview = "Overview"
    case history  = "History"
    case models   = "Models"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .overview: return "gauge.with.needle.fill"
        case .history:  return "chart.bar.fill"
        case .models:   return "cpu.fill"
        case .settings: return "gear"
        }
    }

    var color: Color {
        switch self {
        case .overview: return .blue
        case .history:  return .purple
        case .models:   return .orange
        case .settings: return .gray
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem
    @EnvironmentObject var usageService: UsageService
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        VStack(spacing: 0) {
            appHeader
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)

            usageSummary
                .padding(.horizontal, 12)
                .padding(.bottom, 16)

            Divider()
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

            navList

            Spacer()
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - App header

    private var appHeader: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text("ClaudeWatch")
                .font(.title3.bold())
            Spacer()
            if usageService.isLoading {
                ProgressView().scaleEffect(0.55).frame(width: 12, height: 12)
            }
        }
    }

    // MARK: - Usage summary cards

    private var usageSummary: some View {
        VStack(spacing: 8) {
            usageCard(
                label: "5-Hour",
                percent: usageService.snapshot.fiveHourUtilization,
                resetIn: usageService.snapshot.fiveHourTimeRemaining
            )
            usageCard(
                label: "Weekly",
                percent: usageService.snapshot.sevenDayUtilization,
                resetIn: usageService.snapshot.sevenDayTimeRemaining
            )
        }
    }

    private func usageCard(label: String, percent: Int, resetIn: String?) -> some View {
        let color = ColorThreshold.usageColor(
            for: percent,
            warning: settings.warningThreshold,
            critical: settings.criticalThreshold
        )
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(percent)%")
                    .font(.callout.monospacedDigit().bold())
                    .foregroundStyle(color)
            }
            ProgressView(value: Double(percent), total: 100)
                .tint(color)
            if let t = resetIn {
                Text("resets in \(t)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Navigation list

    private var navList: some View {
        VStack(spacing: 2) {
            ForEach(SidebarItem.allCases, id: \.self) { item in
                navRow(item)
            }
        }
        .padding(.horizontal, 8)
    }

    private func navRow(_ item: SidebarItem) -> some View {
        let isSelected = selection == item
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selection = item }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : item.color)
                    .frame(width: 20)
                Text(item.rawValue)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : .primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.color.gradient)
                        .shadow(color: item.color.opacity(0.4), radius: 6, y: 3)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
