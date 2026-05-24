import UserNotifications
import Foundation

final class NotificationManager {
    private var firedThresholds: Set<String> = []
    private var lastKnownPercent: Double = 0
    private var lastKnownCost: Double = 0
    private var burnCheckCount = 0

    var notificationsEnabled: Bool = true
    var warningThreshold: Double = 0.80
    var criticalThreshold: Double = 0.95

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func check(usage: AppUsage) {
        let percent = usage.percentUsed

        if lastKnownPercent > 0.10 && percent < 0.05 && !firedThresholds.isEmpty {
            firedThresholds.removeAll()
            guard notificationsEnabled else { lastKnownPercent = percent; return }
            fire(
                id: "reset-\(Int(Date().timeIntervalSince1970))",
                title: "OpenCode Pulse — Window Reset",
                body: "Your usage window appears to have reset. Good to go.",
                sound: nil
            )
        }

        guard notificationsEnabled else { lastKnownPercent = percent; lastKnownCost = usage.costUSD; return }

        if percent >= criticalThreshold && !firedThresholds.contains("critical") {
            fire(
                id: "critical",
                title: "OpenCode Pulse — Usage Critical",
                body: "Usage is critically high. Consider pausing large tasks.",
                sound: .default
            )
            firedThresholds.insert("critical")
            firedThresholds.remove("warning")
        } else if percent >= warningThreshold && !firedThresholds.contains("warning") {
            fire(
                id: "warning",
                title: "OpenCode Pulse — Approaching Limit",
                body: "You've used \(Int(percent * 100))% of your daily budget.",
                sound: .default
            )
            firedThresholds.insert("warning")
        }

        burnCheckCount += 1
        if burnCheckCount >= 4 {
            let costDelta = usage.costUSD - lastKnownCost
            if costDelta > 2.0 {
                fire(
                    id: "spike-\(Int(Date().timeIntervalSince1970))",
                    title: "OpenCode Pulse — Burn Spike",
                    body: "Current burn rate is unusually high. Check active provider/model.",
                    sound: .default
                )
            }
            burnCheckCount = 0
            lastKnownCost = usage.costUSD
        }

        lastKnownPercent = percent
    }

    private func fire(id: String, title: String, body: String, sound: UNNotificationSound?) {
        let content       = UNMutableNotificationContent()
        content.title     = title
        content.body      = body
        if let sound      { content.sound = sound }
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
