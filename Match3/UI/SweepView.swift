import SwiftUI

/// The flash of a striped candy clearing its row or column: a bright capsule that grows
/// along the line, then fades.
struct SweepView: View {
    let color: Color
    let horizontal: Bool
    @State private var grown = false
    @State private var faded = false

    var body: some View {
        Capsule()
            .fill(LinearGradient(colors: [.white, color, .white],
                                 startPoint: horizontal ? .leading : .top,
                                 endPoint: horizontal ? .trailing : .bottom))
            .scaleEffect(x: horizontal ? (grown ? 1 : 0.08) : 0.75,
                         y: horizontal ? 0.75 : (grown ? 1 : 0.08))
            .opacity(faded ? 0 : 0.9)
            .blur(radius: 1)
            .onAppear {
                let m = Motion.reduceMotion ? 0.5 : 1.0
                withAnimation(.easeOut(duration: 0.22 * m)) { grown = true }
                withAnimation(.easeIn(duration: 0.4).delay(0.25 * m)) { faded = true }
            }
    }
}
