import Foundation

final class UsageCalculator {
    static let defaultDailyBudgetUSD: Double  = 20.0
    static let activityCutoff: TimeInterval   = 300

    func calculate(entries: [OpenCodeEntry], dailyBudgetUSD: Double, now: Date = Date()) -> AppUsage {
        let dayStart = Calendar.current.startOfDay(for: now)
        let recentCutoff = now.addingTimeInterval(-Self.activityCutoff)

        var totalCost = 0.0
        var totalInputTokens = 0
        var totalOutputTokens = 0
        var isActive = false
        var latestProvider = ""
        var latestModel = ""
        var latestTimestamp = Date.distantPast
        var oldestToday: Date?

        for entry in entries {
            guard entry.lastActivity >= dayStart && entry.lastActivity <= now else { continue }

            totalCost += entry.cost
            totalInputTokens += entry.inputTokens
            totalOutputTokens += entry.outputTokens

            if !isActive && entry.lastActivity >= recentCutoff {
                isActive = true
            }

            if entry.lastActivity > latestTimestamp {
                latestTimestamp = entry.lastActivity
                latestProvider = entry.provider
                latestModel = entry.model
            }

            if oldestToday == nil || entry.timestamp < oldestToday! {
                oldestToday = entry.timestamp
            }
        }

        let totalTokens = totalInputTokens + totalOutputTokens
        let percent = min(totalCost / dailyBudgetUSD, 1.0)
        let hasLimit = dailyBudgetUSD > 0

        let resetInterval: TimeInterval = 24 * 3600
        let resetDate = oldestToday.map { Calendar.current.startOfDay(for: $0).addingTimeInterval(resetInterval) }
            ?? Calendar.current.startOfDay(for: now).addingTimeInterval(resetInterval)
        let secondsUntilReset = max(0, resetDate.timeIntervalSince(now))

        return AppUsage(
            percentUsed: hasLimit ? percent : 0,
            costUSD: totalCost,
            provider: latestProvider,
            model: latestModel,
            isActive: isActive,
            hasLimit: hasLimit,
            resetCountdown: secondsUntilReset,
            totalTokens: totalTokens
        )
    }

}
