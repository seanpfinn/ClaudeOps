import Foundation

enum AppError: LocalizedError, Equatable {
    case keychainNotFound
    case invalidCredentials
    case rateLimited
    case networkUnavailable
    case notConfigured
    case unexpectedResponse(Int)

    var errorDescription: String? {
        switch self {
        case .keychainNotFound:
            return "Claude Code not detected. Make sure Claude Code is installed and signed in."
        case .invalidCredentials:
            return "Invalid credentials. Check your API key in Settings."
        case .rateLimited:
            return "Rate limited — retrying in 15 minutes."
        case .networkUnavailable:
            return "No network connection."
        case .notConfigured:
            return "No credentials configured."
        case .unexpectedResponse(let code):
            return "Unexpected response (HTTP \(code))."
        }
    }

    var recoveryAction: String? {
        switch self {
        case .keychainNotFound, .notConfigured:
            return "Set up credentials"
        case .invalidCredentials:
            return "Open Settings"
        case .rateLimited, .networkUnavailable, .unexpectedResponse:
            return nil
        }
    }

    var isFatal: Bool {
        switch self {
        case .invalidCredentials, .notConfigured: return true
        default: return false
        }
    }
}
