import SwiftUI

/// Gradient plus a few large, faint candies drifting slowly. Shared by every screen so
/// transitions feel like staying in one place.
struct CandyBackground: View {
    @State private var items: [FloatingCandy] = FloatingCandy.makeBackground()

    var body: some View {
        ZStack {
            Theme.background
            GeometryReader { geo in
                ForEach(items) { item in
                    FloatingCandyView(item: item)
                        .position(x: item.x * geo.size.width, y: item.y * geo.size.height)
                }
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

struct FloatingCandy: Identifiable {
    let id = UUID()
    let image: String
    let x: Double
    let y: Double
    let size: Double
    let opacity: Double
    let drift: Double      // vertical travel in points
    let tilt: Double       // degrees of rocking
    let duration: Double
    let delay: Double

    static func makeBackground() -> [FloatingCandy] {
        let spots: [(Double, Double)] = [(0.12, 0.10), (0.85, 0.16), (0.08, 0.48), (0.92, 0.55), (0.18, 0.88), (0.80, 0.90), (0.50, 0.04), (0.55, 0.97)]
        return spots.enumerated().map { i, spot in
            FloatingCandy(image: CandyArt.decorations[(i * 5) % CandyArt.decorations.count],
                          x: spot.0, y: spot.1,
                          size: Double.random(in: 90...140),
                          opacity: 0.28,
                          drift: Double.random(in: 14...28),
                          tilt: Double.random(in: 6...14),
                          duration: Double.random(in: 3.5...6.0),
                          delay: Double.random(in: 0...2))
        }
    }

    static func makePlayScreen() -> [FloatingCandy] {
        let spots: [(Double, Double)] = [(0.15, 0.22), (0.82, 0.18), (0.12, 0.86), (0.92, 0.48), (0.45, 0.94), (0.68, 0.08)]
        return spots.enumerated().map { i, spot in
            FloatingCandy(image: CandyArt.tileImages[i % CandyArt.tileImages.count],
                          x: spot.0, y: spot.1,
                          size: Double.random(in: 70...100),
                          opacity: 1,
                          drift: Double.random(in: 10...20),
                          tilt: Double.random(in: 8...16),
                          duration: Double.random(in: 2.5...4.0),
                          delay: Double.random(in: 0...1.5))
        }
    }
}

/// A candy that bobs up and down and rocks gently, forever.
struct FloatingCandyView: View {
    let item: FloatingCandy
    @State private var up = false

    var body: some View {
        Image(item.image)
            .resizable()
            .scaledToFit()
            .frame(width: item.size, height: item.size)
            .opacity(item.opacity)
            .offset(y: up ? -item.drift : item.drift)
            .rotationEffect(.degrees(up ? item.tilt : -item.tilt))
            .onAppear {
                guard !Motion.reduceMotion else { return }
                withAnimation(.easeInOut(duration: item.duration).repeatForever(autoreverses: true).delay(item.delay)) {
                    up = true
                }
            }
    }
}
