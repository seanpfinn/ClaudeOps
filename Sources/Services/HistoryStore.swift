import Foundation

final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    @Published private(set) var entries: [HistoryEntry] = []

    private let fileURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("ClaudeOps", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("usage-history.json")
    }()

    private init() { load() }

    func append(_ snapshot: UsageSnapshot) {
        let entry = HistoryEntry(
            timestamp: snapshot.lastUpdated,
            fiveHourUtilization: snapshot.fiveHourUtilization,
            sevenDayUtilization: snapshot.sevenDayUtilization
        )
        entries.append(entry)
        trim()
        save()
    }

    // MARK: - Private

    private func trim() {
        let cutoff = Date().addingTimeInterval(-8 * 24 * 3600)
        entries = entries.filter { $0.timestamp > cutoff }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        entries = (try? JSONDecoder().decode([HistoryEntry].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
