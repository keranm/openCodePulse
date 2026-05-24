import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        Form {
            Section("Usage Budget") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Daily cost budget")
                        Spacer()
                        Text(String(format: "$%.2f / day", settings.dailyBudgetUSD))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $settings.dailyBudgetUSD, in: 1.0...100.0, step: 1.0)
                    Text("Set a daily budget to track percentage-based usage. OpenCodePulse will show your usage against this budget.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Notifications") {
                Toggle("Enable usage warnings", isOn: $settings.notificationsEnabled)

                if settings.notificationsEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Warning at")
                            Spacer()
                            Text("\(Int(settings.warningThreshold * 100))%")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $settings.warningThreshold, in: 0.5...0.95, step: 0.05)

                        HStack {
                            Text("Critical at")
                            Spacer()
                            Text("\(Int(settings.criticalThreshold * 100))%")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $settings.criticalThreshold, in: 0.70...1.0, step: 0.05)
                    }
                    .padding(.leading)
                }
            }

            Section("Data Source") {
                HStack {
                    Text("Data directory")
                    Spacer()
                    Text("~/.local/share/opencode")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Privacy")
                    Spacer()
                    Text("All processing is local")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("System") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
            }

            Text("OpenCode Pulse uses your locally stored usage data. It'll never be as accurate as OpenCode's usage portal.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 510)
        .navigationTitle("OpenCode Pulse Settings")
    }
}
