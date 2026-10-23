import SwiftUI
import Match3Core

/// A candy that has fallen asleep: closed eyes, blushing cheeks, drifting Zs. Used for the
/// gentle "time to rest" moment when a caregiver's session timer ends. No words needed.
struct SleepyCandyView: View {
    var color: TileColor = TileColor(2)  // red heart by default
    var animated = true

    @State private var breathe = false
    @State private var zPhase = false

    private let ink = Color(red: 0.24, green: 0.10, blue: 0.16)

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                CandyArt.tileImage(color)
                    .resizable()
                    .scaledToFit()
                    .frame(width: s * 0.78, height: s * 0.78)
                    .scaleEffect(breathe ? 1.03 : 0.98)
                    .position(x: s * 0.46, y: s * 0.58)

                // Closed eyes: two downward arcs.
                ForEach([-1.0, 1.0], id: \.self) { side in
                    ClosedEyeShape()
                        .stroke(ink, style: StrokeStyle(lineWidth: s * 0.03, lineCap: .round))
                        .frame(width: s * 0.13, height: s * 0.06)
                        .position(x: s * 0.46 + side * s * 0.13, y: s * 0.56)
                }
                // Blush.
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Ellipse()
                        .fill(Color(red: 1.0, green: 0.55, blue: 0.65).opacity(0.55))
                        .frame(width: s * 0.11, height: s * 0.06)
                        .position(x: s * 0.46 + side * s * 0.20, y: s * 0.63)
                }
                // Little smile.
                SmileShape()
                    .stroke(ink, style: StrokeStyle(lineWidth: s * 0.025, lineCap: .round))
                    .frame(width: s * 0.10, height: s * 0.04)
                    .position(x: s * 0.46, y: s * 0.68)

                // Drifting Zs.
                ForEach(0..<3, id: \.self) { i in
                    let k = CGFloat(i)
                    Image(systemName: "zzz")
                        .font(.system(size: s * (0.09 + 0.03 * Double(i)), weight: .heavy, design: .rounded))
                        .foregroundStyle(ink)
                        .opacity(zPhase ? 0.15 + 0.3 * Double(i) : 0.9 - 0.25 * Double(i))
                        .offset(x: (zPhase ? s * 0.08 : 0) + k * s * 0.06,
                                y: (zPhase ? -s * 0.10 : 0) - k * s * 0.09)
                        .position(x: s * 0.80, y: s * 0.30)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            guard animated, !Motion.reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { zPhase = true }
        }
        .accessibilityLabel("Sleeping candy")
    }
}

struct ClosedEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: rect.maxY * 1.6))
        return p
    }
}

struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: rect.maxY * 1.8))
        return p
    }
}
