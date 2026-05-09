import Foundation

struct HistoryEntry: Codable, Identifiable {
    var id: Date { timestamp }
    let timestamp: Date
    let fiveHourUtilization: Int
    let sevenDayUtilization: Int
}
