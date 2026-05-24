import Foundation
import ServiceManagement

final class SettingsStore: ObservableObject {
    @Published var launchAtLogin: Bool {
        didSet { applyLaunchAtLogin() }
    }

    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    @Published var dailyBudgetUSD: Double {
        didSet { UserDefaults.standard.set(dailyBudgetUSD, forKey: "dailyBudgetUSD") }
    }

    @Published var warningThreshold: Double {
        didSet { UserDefaults.standard.set(warningThreshold, forKey: "warningThreshold") }
    }

    @Published var criticalThreshold: Double {
        didSet { UserDefaults.standard.set(criticalThreshold, forKey: "criticalThreshold") }
    }

    init() {
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.warningThreshold = UserDefaults.standard.object(forKey: "warningThreshold") as? Double ?? 0.80
        self.criticalThreshold = UserDefaults.standard.object(forKey: "criticalThreshold") as? Double ?? 0.95
        let saved = UserDefaults.standard.double(forKey: "dailyBudgetUSD")
        self.dailyBudgetUSD = saved > 0 ? saved : UsageCalculator.defaultDailyBudgetUSD
        registerOnFirstLaunch()
    }

    private func registerOnFirstLaunch() {
        let key = "hasRegisteredLaunchAtLogin"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        try? SMAppService.mainApp.register()
        UserDefaults.standard.set(true, forKey: key)
        launchAtLogin = true
    }

    private func applyLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("SMAppService error: \(error)")
        }
    }
}
