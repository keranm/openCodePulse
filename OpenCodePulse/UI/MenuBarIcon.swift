import AppKit

final class MenuBarIcon {
    private static var cachedPercent: Double = -1
    private static var cachedState: UsageState?
    private static var cachedImage: NSImage?

    static func image(percent: Double, state: UsageState, size: CGFloat = 16) -> NSImage {
        let roundedPercent = (percent * 1000).rounded() / 1000
        if roundedPercent == cachedPercent,
           let last = cachedState, last == state,
           let img = cachedImage {
            return img
        }

        let img = draw(percent: roundedPercent, state: state, size: size)
        cachedPercent = roundedPercent
        cachedState   = state
        cachedImage   = img
        return img
    }

    private static func draw(percent: Double, state: UsageState, size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let center     = CGPoint(x: rect.midX, y: rect.midY)
            let radius     = (rect.width / 2) - 1.5
            let lineWidth: CGFloat = 2.0
            let startAngle: CGFloat = 90
            let endAngle: CGFloat   = 90 - (360 * percent)

            NSColor.tertiaryLabelColor.setStroke()
            let track = NSBezierPath()
            track.appendArc(withCenter: center, radius: radius,
                            startAngle: startAngle, endAngle: startAngle - 360,
                            clockwise: true)
            track.lineWidth = lineWidth
            track.stroke()

            if percent > 0.01 {
                state.nsColor.setStroke()
                let progress = NSBezierPath()
                progress.appendArc(withCenter: center, radius: radius,
                                   startAngle: startAngle, endAngle: endAngle,
                                   clockwise: true)
                progress.lineWidth    = lineWidth
                progress.lineCapStyle = .round
                progress.stroke()
            }
            return true
        }
        image.isTemplate = false
        return image
    }
}
