import SwiftUI

struct PopoverHeaderView: View {
    let isActive: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "pulse")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(red: 0.29, green: 0.36, blue: 1.0))

            Text("OpenCode Pulse")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(isActive ? Color(red: 0.2, green: 0.78, blue: 0.35) : Color.gray)
                    .frame(width: 7, height: 7)
                Text(isActive ? "Active" : "Idle")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}
