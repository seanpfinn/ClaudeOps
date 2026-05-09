import Foundation

struct UsageSnapshot {
    let fiveHourUtilization: Int
    let sevenDayUtilization: Int
    let sevenDaySonnetUtilization: Int?
    let fiveHourResetsAt: Date?
    let sevenDayResetsAt: Date?
    let lastUpdated: Date

    var mostConstrained: Int { max(fiveHourUtilization, sevenDayUtilization) }

    var fiveHourTimeRemaining: String? {
        fiveHourResetsAt.map { formatTimeRemaining(until: $0) }
    }
    var sevenDayTimeRemaining: String? {
        sevenDayResetsAt.map { formatTimeRemaining(until: $0) }
    }

    static var placeholder: UsageSnapshot {
        UsageSnapshot(
            fiveHourUtilization: 0,
            sevenDayUtilization: 0,
            sevenDaySonnetUtilization: nil,
            fiveHourResetsAt: nil,
            sevenDayResetsAt: nil,
            lastUpdated: Date()
        )
    }
}
