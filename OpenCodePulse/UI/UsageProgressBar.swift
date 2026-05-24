import SwiftUI

struct UsageProgressBar: View {
    let percent: Double
    let state: UsageState

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.09))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(state.gradient)
                    .frame(width: max(0, geo.size.width * min(percent, 1.0)), height: 6)
                    .animation(.easeInOut(duration: 0.5), value: percent)
            }
        }
        .frame(height: 6)
    }
}
