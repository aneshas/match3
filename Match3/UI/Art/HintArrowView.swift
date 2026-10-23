import SwiftUI
import Match3Core

/// A chunky, outlined arrow for the escalated hint. Points `direction`; nudges back and
/// forth along it so the eye follows the intended swipe.
struct HintArrowView: View {
    var direction: Direction = .right
    var animated = true

    @State private var nudge = false

    private let ink = Color(red: 0.24, green: 0.10, blue: 0.16)

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ArrowShape()
                .fill(LinearGradient(colors: [Theme.gold, Theme.goldDark], startPoint: .top, endPoint: .bottom))
                .overlay(ArrowShape().stroke(ink, style: StrokeStyle(lineWidth: max(3, s * 0.06), lineJoin: .round)))
                .overlay(alignment: .top) {
                    Capsule().fill(Color.white.opacity(0.45))
                        .frame(width: s * 0.42, height: s * 0.09)
                        .offset(x: -s * 0.12, y: s * 0.30)
                }
                .frame(width: s, height: s)
                .rotationEffect(angle)
                .offset(x: nudge ? dx * s * 0.12 : 0, y: nudge ? dy * s * 0.12 : 0)
                .shadow(color: Theme.gold.opacity(0.6), radius: s * 0.08)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            guard animated, !Motion.reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { nudge = true }
        }
        .accessibilityHidden(true)
    }

    private var angle: Angle {
        switch direction {
        case .right: return .degrees(0)
        case .down: return .degrees(90)
        case .left: return .degrees(180)
        case .up: return .degrees(270)
        }
    }

    private var dx: CGFloat { direction == .right ? 1 : direction == .left ? -1 : 0 }
    private var dy: CGFloat { direction == .down ? 1 : direction == .up ? -1 : 0 }
}

/// Right-pointing arrow: thick shaft plus a wide head, in a unit square.
struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + w * 0.08, y: rect.minY + h * 0.36))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.52, y: rect.minY + h * 0.36))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.52, y: rect.minY + h * 0.16))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.94, y: rect.minY + h * 0.50))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.52, y: rect.minY + h * 0.84))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.52, y: rect.minY + h * 0.64))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.08, y: rect.minY + h * 0.64))
        p.closeSubpath()
        return p
    }
}
