import SwiftUI

/// A special candy going off: a thick ring that races outward from the cell and fades,
/// with a soft flash of color behind it. Big (striped) rings travel further.
struct ShockwaveView: View {
    let color: Color
    let big: Bool
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [.white.opacity(0.9), color.opacity(0.45), .clear], center: .center, startRadius: 0, endRadius: 120))
                .scaleEffect(0.2 + progress * 0.8)
                .opacity(1 - progress)
            Circle()
                .strokeBorder(LinearGradient(colors: [.white, color], startPoint: .top, endPoint: .bottom), lineWidth: big ? 14 : 10)
                .scaleEffect(0.15 + progress * 0.85)
                .opacity(1 - progress * progress)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: (big ? 0.75 : 0.55) * (Motion.reduceMotion ? 0.6 : 1))) { progress = 1 }
        }
    }
}
