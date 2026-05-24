import SwiftUI

enum UsageState: Equatable {
    case idle
    case healthy
    case warning
    case critical
    case resetting

    static func from(percent: Double, isActive: Bool) -> UsageState {
        if !isActive { return .idle }
        switch percent {
        case ..<0.70: return .healthy
        case ..<0.90: return .warning
        default:      return .critical
        }
    }

    var color: Color {
        switch self {
        case .idle:      return .gray
        case .healthy:   return Color(red: 0.2, green: 0.78, blue: 0.35)
        case .warning:   return Color(red: 1.0, green: 0.62, blue: 0.04)
        case .critical:  return Color(red: 0.95, green: 0.23, blue: 0.23)
        case .resetting: return .blue
        }
    }

    var nsColor: NSColor {
        switch self {
        case .idle:      return .secondaryLabelColor
        case .healthy:   return NSColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1)
        case .warning:   return NSColor(red: 1.0, green: 0.62, blue: 0.04, alpha: 1)
        case .critical:  return NSColor(red: 0.95, green: 0.23, blue: 0.23, alpha: 1)
        case .resetting: return .systemBlue
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: [color.opacity(0.75), color], startPoint: .leading, endPoint: .trailing)
    }

    var guidanceText: String {
        switch self {
        case .idle:      return "No recent activity"
        case .healthy:   return "Safe to continue coding"
        case .warning:   return "Usage is climbing quickly"
        case .critical:  return "Large tasks may exceed remaining capacity"
        case .resetting: return "Usage window appears to have reset"
        }
    }
}
