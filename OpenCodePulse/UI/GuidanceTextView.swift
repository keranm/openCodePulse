import SwiftUI

struct GuidanceTextView: View {
    let state: UsageState

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Circle()
                .fill(state.color)
                .frame(width: 7, height: 7)
            Text(state.guidanceText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
