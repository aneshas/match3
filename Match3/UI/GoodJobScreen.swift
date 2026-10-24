import SwiftUI
import Match3Core

/// Full-screen celebration between levels: sunburst rays, a bouncing gold star, the words
/// "Good Job!" popping in, and candies raining down. Goes away on its own, or on a tap.
struct GoodJobScreen: View {
    /// Levels finished including this one; the jar shows one candy per level.
    var completedLevels: Int = 1
    /// True when the free part is over: a soft lock settles on the jar before returning to Play.
    var showsLock = false
    let onContinue: () -> Void
    @State private var lockShown = false

    @State private var rain: [RainDrop] = Motion.reduceMotion ? [] : RainDrop.makeBatch()
    @State private var dropped = false
    @State private var appeared = false
    @State private var bounce = false
    @State private var raysAngle = 0.0
    // The reward: one candy flies from the star into the jar.
    @State private var jarCount = 0
    @State private var flyingCandy = false
    @State private var candyLanded = false
    @State private var jarBounce = false

    /// Good Job always lasts the same time; routine is comforting.
    static let duration: Duration = .seconds(5.5)

    var body: some View {
        GeometryReader { geo in
            content(geo)
        }
    }

    private func content(_ geo: GeometryProxy) -> some View {
        ZStack {
            GeometryReader { geo in
                ForEach(rain) { drop in
                    Image(drop.image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: drop.size, height: drop.size)
                        .opacity(0.5)  // keeps the star, text and jar readable through the rain
                        .rotationEffect(.degrees(dropped ? drop.spin : 0))
                        .position(x: drop.x * geo.size.width,
                                  y: dropped ? geo.size.height + 80 : -80)
                        .animation(.easeIn(duration: drop.duration).delay(drop.delay), value: dropped)
                }
            }
            .allowsHitTesting(false)

            let short = min(geo.size.width, geo.size.height)
            let starSize = min(170, short * 0.3)
            let spacing = short * 0.04
            let textSize = min(60, short * 0.11)
            let jarWidth = min(120, short * 0.26)
            let jarHeight = jarWidth / 0.8
            let starBlock = starSize * 1.5
            let totalHeight = starBlock + spacing + textSize * 1.3 + spacing + jarHeight
            let starCenterY = geo.size.height / 2 - totalHeight / 2 + starBlock / 2
            let jarMouthY = geo.size.height / 2 + totalHeight / 2 - jarHeight * 0.9

            VStack(spacing: spacing) {
                ZStack {
                    SunburstView()
                        .frame(width: starSize * 2.5, height: starSize * 2.5)
                        .rotationEffect(.degrees(raysAngle))
                        .opacity(appeared ? 1 : 0)

                    Image(systemName: "star.fill")
                        .font(.system(size: starSize))
                        .foregroundStyle(LinearGradient(colors: [Theme.gold, Theme.goldDark], startPoint: .top, endPoint: .bottom))
                        .shadow(color: Theme.gold.opacity(0.6), radius: 24)
                        .scaleEffect(appeared ? (bounce ? 1.12 : 0.96) : 0.1)
                        .rotationEffect(.degrees(bounce ? 8 : -8))
                }
                .frame(height: starSize * 1.5)

                Text("Good Job!")
                    .font(.system(size: textSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.text)
                    .shadow(color: .white, radius: 0, x: 2, y: 2)
                    .shadow(color: Theme.magenta.opacity(0.3), radius: 10, y: 6)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)

                JarView(count: jarCount)
                    .frame(width: jarWidth)
                    .scaleEffect(jarBounce ? 1.1 : 1, anchor: .bottom)
                    .opacity(appeared ? 1 : 0)
                    .overlay(alignment: .top) {
                        if lockShown {
                            Image(systemName: "lock.fill")
                                .font(.system(size: jarWidth * 0.34, weight: .bold))
                                .foregroundStyle(Theme.text.opacity(0.75))
                                .padding(jarWidth * 0.1)
                                .background(Color.white.opacity(0.85), in: Circle())
                                .offset(y: -jarWidth * 0.3)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
            }

            if flyingCandy {
                CandyArt.tileImage(TileColor(max(0, jarCount) % TileColor.maxCount))
                    .resizable()
                    .scaledToFit()
                    .frame(width: candyLanded ? jarWidth * 0.28 : starSize * 0.5)
                    .position(x: geo.size.width / 2, y: candyLanded ? jarMouthY : starCenterY)
                    .opacity(candyLanded ? 0 : 1)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onContinue() }
        .onAppear {
            Haptics.levelDone()
            jarCount = max(0, completedLevels - 1)
            Task { await dropCandyIntoJar() }
            dropped = true
            withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) { appeared = true }
            guard !Motion.reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0.5)) { bounce = true }
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) { raysAngle = 360 }
        }
        .task {
            try? await Task.sleep(for: GoodJobScreen.duration)
            onContinue()
        }
    }

    /// A candy leaves the star, drops into the jar, the jar bounces and shows one more.
    private func dropCandyIntoJar() async {
        try? await Task.sleep(for: .milliseconds(900))
        if Motion.reduceMotion {
            jarCount = completedLevels
            if showsLock { lockShown = true }
            return
        }
        flyingCandy = true
        try? await Task.sleep(for: .milliseconds(150))
        withAnimation(.easeIn(duration: 0.6)) { candyLanded = true }
        try? await Task.sleep(for: .milliseconds(600))
        flyingCandy = false
        jarCount = completedLevels
        SoundPlayer.shared.play(.match, volume: 0.8)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { jarBounce = true }
        try? await Task.sleep(for: .milliseconds(300))
        withAnimation(.easeOut(duration: 0.2)) { jarBounce = false }
        if showsLock {
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { lockShown = true }
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
