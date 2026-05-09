import Foundation

func formatTimeRemaining(until date: Date, from now: Date = Date()) -> String {
    let interval = date.timeIntervalSince(now)
    guard interval > 0 else { return "now" }
    let hours = Int(interval) / 3600
    let minutes = (Int(interval) % 3600) / 60
    if hours > 0 { return "\(hours)h \(minutes)m" }
    return "\(minutes)m"
}
