import Foundation
import Observation
import Combine

@Observable
final class UsageEngine {
    private(set) var usage: AppUsage = .empty

    private let dataSource = OpenCodeDataSource()
    private let calculator = UsageCalculator()
    private let watcher    = FileWatcher()
    private var countdownTimer: Timer?
    private var settingsCancellable: AnyCancellable?
    private let openCodeDir: URL

    private var debounceTask: Task<Void, Never>?

    var settings: SettingsStore? {
        didSet { observeSettings() }
    }

    init() {
        openCodeDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/opencode")
    }

    func start() {
        watcher.onChange = { [weak self] in self?.scheduleRefresh() }
        watcher.start(path: openCodeDir.path)

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        countdownTimer?.tolerance = 10
        refresh()
    }

    func stop() {
        watcher.stop()
        countdownTimer?.invalidate()
        countdownTimer = nil
        settingsCancellable?.cancel()
        debounceTask?.cancel()
    }

    private func scheduleRefresh() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            refresh()
        }
    }

    func refresh() {
        let budget = settings?.dailyBudgetUSD ?? UsageCalculator.defaultDailyBudgetUSD
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            let entries = self.dataSource.fetchEntries()
            let result  = self.calculator.calculate(entries: entries, dailyBudgetUSD: budget)
            await MainActor.run { self.usage = result }
        }
    }

    private func observeSettings() {
        settingsCancellable?.cancel()
        guard let settings else { return }
        settingsCancellable = settings.objectWillChange.sink { [weak self] _ in
            self?.refresh()
        }
    }

    deinit { stop() }
}
