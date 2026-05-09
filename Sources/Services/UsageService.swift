import Foundation
import Combine

// MARK: - API Response Models

struct OAuthUsageResponse: Decodable {
    let fiveHour: UsagePeriod?
    let sevenDay: UsagePeriod?
    let sevenDaySonnet: UsagePeriod?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
    }

    struct UsagePeriod: Decodable {
        let utilization: Double
        let resetsAt: String

        enum CodingKeys: String, CodingKey {
            case utilization
            case resetsAt = "resets_at"
        }

        var resetsAtDate: Date? {
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = fmt.date(from: resetsAt) { return d }
            fmt.formatOptions = [.withInternetDateTime]
            return fmt.date(from: resetsAt)
        }
    }
}

// MARK: - UsageService

@MainActor
final class UsageService: ObservableObject {
    static let shared = UsageService()

    @Published private(set) var snapshot: UsageSnapshot = .placeholder
    @Published private(set) var error: AppError?
    @Published private(set) var isLoading = false

    var urlSession: URLSession = .shared

    private var consecutiveFailures = 0
    private let baseInterval: TimeInterval = 300
    private let maxInterval: TimeInterval = 900
    private var timer: Timer?
    private var cachedClaudeToken: String?

    private init() {}

    func startPolling() {
        Task { await fetch() }
        scheduleNext(after: baseInterval)
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() async {
        await fetch()
        scheduleNext(after: baseInterval)
    }

    func validateApiKey(_ key: String) async throws {
        _ = try await fetchWithBearerToken(key)
    }

    // MARK: - Private

    private func fetch() async {
        isLoading = true
        do {
            let response = try await resolvedFetch()
            snapshot = UsageSnapshot(
                fiveHourUtilization: Int(response.fiveHour?.utilization ?? 0),
                sevenDayUtilization: Int(response.sevenDay?.utilization ?? 0),
                sevenDaySonnetUtilization: response.sevenDaySonnet.map { Int($0.utilization) },
                fiveHourResetsAt: response.fiveHour?.resetsAtDate,
                sevenDayResetsAt: response.sevenDay?.resetsAtDate,
                lastUpdated: Date()
            )
            error = nil
            consecutiveFailures = 0
            HistoryStore.shared.append(snapshot)
        } catch let err as AppError {
            error = err
            consecutiveFailures += 1
            if err.isFatal { stopPolling() }
        } catch {
            consecutiveFailures += 1
            self.error = .unexpectedResponse(0)
        }
        isLoading = false
    }

    private func resolvedFetch() async throws -> OAuthUsageResponse {
        // Try Claude Code Keychain first
        if let token = cachedClaudeToken {
            return try await fetchWithBearerToken(token)
        }
        do {
            let token = try KeychainService.readClaudeCodeToken()
            cachedClaudeToken = token
            return try await fetchWithBearerToken(token)
        } catch AppError.keychainNotFound {
            // Fall back to stored API key
        }
        let apiKey = try KeychainService.loadApiKey()
        return try await fetchWithBearerToken(apiKey)
    }

    private func fetchWithBearerToken(_ token: String) async throws -> OAuthUsageResponse {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }

        switch http.statusCode {
        case 200:
            return try JSONDecoder().decode(OAuthUsageResponse.self, from: data)
        case 401:
            cachedClaudeToken = nil
            throw AppError.invalidCredentials
        case 429:
            cachedClaudeToken = nil
            throw AppError.rateLimited
        default:
            throw AppError.unexpectedResponse(http.statusCode)
        }
    }

    private func scheduleNext(after interval: TimeInterval) {
        timer?.invalidate()
        let backoff = min(interval * pow(2.0, Double(max(0, consecutiveFailures - 1))), maxInterval)
        let delay = consecutiveFailures > 0 ? backoff : interval
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetch()
                self?.scheduleNext(after: self?.baseInterval ?? 300)
            }
        }
    }
}
