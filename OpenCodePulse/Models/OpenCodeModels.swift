import Foundation

struct OpenCodeEntry {
    let provider: String
    let model: String
    let timestamp: Date
    let lastActivity: Date
    let inputTokens: Int
    let outputTokens: Int
    let cost: Double
    let sessionID: String?
}

struct AppUsage {
    let percentUsed: Double
    let costUSD: Double
    let provider: String
    let model: String
    let isActive: Bool
    let hasLimit: Bool
    let resetCountdown: TimeInterval
    let totalTokens: Int

    var state: UsageState {
        guard hasLimit else { return isActive ? .healthy : .idle }
        return UsageState.from(percent: percentUsed, isActive: isActive)
    }

    var resetCountdownString: String {
        let total = Int(resetCountdown)
        let hours   = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0  { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "<1m"
    }

    var percentInt: Int { Int(percentUsed * 100) }

    var providerDisplay: String {
        provider.isEmpty ? "Unknown" : provider
    }

    var modelDisplay: String {
        model.isEmpty ? "Unknown" : model
    }

    static var empty: AppUsage {
        AppUsage(
            percentUsed: 0, costUSD: 0,
            provider: "", model: "",
            isActive: false, hasLimit: false,
            resetCountdown: 0, totalTokens: 0
        )
    }
}
