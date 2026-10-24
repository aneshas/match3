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

/// A flash across the whole board when a rainbow candy or a combo goes off: all six
/// colors sweeping through for a rainbow, plain white for a combo.
struct BoardFlashView: View {
    let rainbow: Bool
    let cornerRadius: CGFloat
    @State private var faded = false

    private static let rainbowColors: [Color] = [
        Color(red: 0.90, green: 0.20, blue: 0.25), Color(red: 1.00, green: 0.60, blue: 0.15),
        Color(red: 1.00, green: 0.85, blue: 0.20), Color(red: 0.45, green: 0.78, blue: 0.25),
        Color(red: 0.20, green: 0.65, blue: 0.95), Color(red: 0.75, green: 0.30, blue: 0.90),
    ]

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(rainbow
                  ? AnyShapeStyle(AngularGradient(colors: BoardFlashView.rainbowColors + [BoardFlashView.rainbowColors[0]], center: .center))
                  : AnyShapeStyle(Color.white))
            .opacity(faded ? 0 : (rainbow ? 0.75 : 0.85))
            .blendMode(rainbow ? .normal : .plusLighter)
            .onAppear {
                withAnimation(.easeOut(duration: 0.65 * (Motion.reduceMotion ? 0.5 : 1))) { faded = true }
            }
    }
}
