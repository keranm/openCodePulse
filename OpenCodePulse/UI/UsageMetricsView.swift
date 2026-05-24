import SwiftUI

struct UsageMetricsView: View {
    let usage: AppUsage

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 1) {
                    if usage.hasLimit {
                        Text("\(usage.percentInt)%")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(usage.state.color)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.3), value: usage.percentInt)
                    } else {
                        Text("—")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Text(String(format: "$%.2f · today", usage.costUSD))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(usage.hasLimit ? usage.resetCountdownString : "—")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: usage.resetCountdown)

                    Text(usage.hasLimit ? "until reset" : "no limit set")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            if !usage.provider.isEmpty || !usage.model.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text("\(usage.providerDisplay)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    if !usage.model.isEmpty {
                        Text("/")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                        Text("\(usage.modelDisplay)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }

            UsageProgressBar(percent: usage.hasLimit ? usage.percentUsed : 0.5, state: usage.state)

            GuidanceTextView(state: usage.state)
        }
    }
}
