import SwiftUI

/// Full-screen celebration between levels: sunburst rays, a bouncing gold star, the words
/// "Good Job!" popping in, and candies raining down. Goes away on its own, or on a tap.
struct GoodJobScreen: View {
    let onContinue: () -> Void

    @State private var rain: [RainDrop] = RainDrop.makeBatch()
    @State private var dropped = false
    @State private var appeared = false
    @State private var bounce = false
    @State private var raysAngle = 0.0

    var body: some View {
        ZStack {
            GeometryReader { geo in
                ForEach(rain) { drop in
                    Image(drop.image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: drop.size, height: drop.size)
                        .rotationEffect(.degrees(dropped ? drop.spin : 0))
                        .position(x: drop.x * geo.size.width,
                                  y: dropped ? geo.size.height + 80 : -80)
                        .animation(.easeIn(duration: drop.duration).delay(drop.delay), value: dropped)
                }
            }
            .allowsHitTesting(false)

            VStack(spacing: 28) {
                ZStack {
                    SunburstView()
                        .frame(width: 420, height: 420)
                        .rotationEffect(.degrees(raysAngle))
                        .opacity(appeared ? 1 : 0)

                    Image(systemName: "star.fill")
                        .font(.system(size: 170))
                        .foregroundStyle(LinearGradient(colors: [Theme.gold, Theme.goldDark], startPoint: .top, endPoint: .bottom))
                        .shadow(color: Theme.gold.opacity(0.6), radius: 24)
                        .scaleEffect(appeared ? (bounce ? 1.12 : 0.96) : 0.1)
                        .rotationEffect(.degrees(bounce ? 8 : -8))
                }
                .frame(height: 260)

                Text("Good Job!")
                    .font(.system(size: 60, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.text)
                    .shadow(color: .white, radius: 0, x: 2, y: 2)
                    .shadow(color: Theme.magenta.opacity(0.3), radius: 10, y: 6)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onContinue() }
        .onAppear {
            Haptics.levelDone()
            dropped = true
            withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) { appeared = true }
            guard !Motion.reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0.5)) { bounce = true }
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) { raysAngle = 360 }
        }
        .task {
            try? await Task.sleep(for: .seconds(2.8))
            onContinue()
        }
    }
}

/// Soft gold rays radiating from the center.
struct SunburstView: View {
    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(LinearGradient(colors: [Theme.gold.opacity(0.35), .clear], startPoint: .center, endPoint: .top))
                    .frame(width: 42, height: 420)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
        }
        .allowsHitTesting(false)
    }
}

struct RainDrop: Identifiable {
    let id = UUID()
    let image: String
    let x: Double
    let size: Double
    let spin: Double
    let delay: Double
    let duration: Double

    static func makeBatch(count: Int = 30) -> [RainDrop] {
        (0..<count).map { i in
            RainDrop(image: CandyArt.rain[(i * 7) % CandyArt.rain.count],
                     x: Double.random(in: 0.05...0.95),
                     size: Double.random(in: 44...76),
                     spin: Double.random(in: -540...540),
                     delay: Double.random(in: 0...1.0),
                     duration: Double.random(in: 1.6...2.6))
        }
    }
}
