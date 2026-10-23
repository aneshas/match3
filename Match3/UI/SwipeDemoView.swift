import SwiftUI

/// A pointing hand that appears on one candy, presses, drags to the neighbor and fades.
/// The whole thing is one shot; the session re-creates it (new id) to repeat.
struct SwipeDemoView: View {
    let from: CGPoint
    let to: CGPoint
    let cell: CGFloat

    @State private var t: CGFloat = 0        // 0 = on `from`, 1 = on `to`
    @State private var opacity: Double = 0
    @State private var pressed = false

    var body: some View {
        let hand = cell * 1.2
        let x = from.x + (to.x - from.x) * t
        let y = from.y + (to.y - from.y) * t
        Image("hand_point")
            .resizable()
            .scaledToFit()
            .frame(width: hand, height: hand)
            .shadow(color: Color.black.opacity(0.25), radius: hand * 0.06, y: hand * 0.05)
            .scaleEffect(pressed ? 0.88 : 1, anchor: .top)
            // The fingertip is near the top-center of the image; park it on the candy center.
            .position(x: x + hand * 0.05, y: y + hand * 0.46)
            .opacity(opacity)
            .allowsHitTesting(false)
            .task { await run() }
    }

    private func run() async {
        let m = Motion.reduceMotion ? 0.5 : 1.0
        withAnimation(.easeOut(duration: 0.25 * m)) { opacity = 1 }
        try? await Task.sleep(for: .milliseconds(Int(400 * m)))
        withAnimation(.easeOut(duration: 0.12)) { pressed = true }
        try? await Task.sleep(for: .milliseconds(Int(200 * m)))
        withAnimation(.easeInOut(duration: 0.75 * m)) { t = 1 }
        try? await Task.sleep(for: .milliseconds(Int(850 * m)))
        withAnimation(.easeOut(duration: 0.12)) { pressed = false }
        try? await Task.sleep(for: .milliseconds(Int(250 * m)))
        withAnimation(.easeIn(duration: 0.3 * m)) { opacity = 0 }
    }
}
