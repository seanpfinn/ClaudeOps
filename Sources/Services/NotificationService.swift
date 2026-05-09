import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    // Tracks the last percent we notified at for each key to implement hysteresis
    private var lastNotified: [String: Int] = [:]
    private let hysteresis = 10

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func checkThresholds(snapshot: UsageSnapshot, settings: SettingsManager) {
        guard settings.notificationsEnabled else { return }
        check(
            key: "5h",
            percent: snapshot.fiveHourUtilization,
            label: "5-Hour",
            warning: Int(settings.warningThreshold),
            critical: Int(settings.criticalThreshold)
        )
        check(
            key: "7d",
            percent: snapshot.sevenDayUtilization,
            label: "Weekly",
            warning: Int(settings.warningThreshold),
            critical: Int(settings.criticalThreshold)
        )
    }

    // MARK: - Private

    private func check(key: String, percent: Int, label: String, warning: Int, critical: Int) {
        let warnKey = "\(key)-warn"
        let critKey = "\(key)-crit"

        if percent >= critical {
            if (lastNotified[critKey] ?? 0) < critical - hysteresis {
                send(id: critKey, title: "\(label) Usage Critical", body: "\(percent)% of your \(label) limit used.")
            }
            lastNotified[critKey] = percent
        } else {
            if percent < critical - hysteresis { lastNotified[critKey] = 0 }
        }

        if percent >= warning && percent < critical {
            if (lastNotified[warnKey] ?? 0) < warning - hysteresis {
                send(id: warnKey, title: "\(label) Usage Warning", body: "\(percent)% of your \(label) limit used.")
            }
            lastNotified[warnKey] = percent
        } else {
            if percent < warning - hysteresis { lastNotified[warnKey] = 0 }
        }
    }

    private func send(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { _ in }
    }
}
