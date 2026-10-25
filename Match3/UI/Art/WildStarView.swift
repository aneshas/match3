import SwiftUI

/// The wildcard star: a glossy gold five-point star with the candy pack's dark outline,
/// so it sits among the candies as one of them. Also the badge on the bonus candy and
/// the marker that rises from a bonus match, so the player links the three.
struct WildStarView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            StarShape()
                .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.93, blue: 0.45), Theme.gold, Theme.goldDark],
                                     startPoint: .top, endPoint: .bottom))
            StarShape()
                .stroke(Color(red: 0.24, green: 0.10, blue: 0.16), style: StrokeStyle(lineWidth: max(1.5, size * 0.055), lineJoin: .round))
            // Gloss: a soft white highlight on the upper left.
            Ellipse()
                .fill(Color.white.opacity(0.55))
                .frame(width: size * 0.26, height: size * 0.14)
                .rotationEffect(.degrees(-30))
                .offset(x: -size * 0.14, y: -size * 0.16)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A five-point star filling its rect.
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2 * 0.95
        let inner = outer * 0.47
        var path = Path()
        for i in 0..<10 {
            let angle = -CGFloat.pi / 2 + CGFloat(i) * .pi / 5
            let radius = i.isMultiple(of: 2) ? outer : inner
            let p = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}
