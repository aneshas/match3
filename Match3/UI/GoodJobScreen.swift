import SwiftUI
import Match3Core

/// Full-screen celebration between levels: sunburst rays, a bouncing gold star, the next
/// level's new candy zooming in, spinning and bursting, and candies raining down. No text.
/// Goes away on its own, or on a tap.
struct GoodJobScreen: View {
    /// The candy the progress bar promised: the one new type of the next level.
    var nextCandy: CandyArt.Preview? = nil
    /// True when the free part is over: a soft lock settles where the candy burst before
    /// returning to Play.
    var showsLock = false
    let onContinue: () -> Void
    @State private var lockShown = false

    @State private var rain: [RainDrop] = Motion.reduceMotion ? [] : RainDrop.makeBatch()
    @State private var dropped = false
    @State private var appeared = false
    @State private var bounce = false
    @State private var raysAngle = 0.0
    // The reward: the next candy zooms in, spins up and bursts.
    @State private var candyShown = false
    @State private var candySpin = 0.0
    @State private var candyBurst = false
    @State private var candyWound = false
    @State private var burstID: UUID?

    /// Good Job always lasts the same time; routine is comforting.
    static let duration: Duration = .seconds(4.5)

    var body: some View {
        GeometryReader { geo in
            content(geo)
        }
    }

    private var candyImage: Image {
        CandyArt.load(nextCandy?.imageName ?? CandyArt.tileImages[0])
    }

    private var candyColor: Color {
        nextCandy?.type.color.particle ?? Theme.gold
    }

    private func content(_ geo: GeometryProxy) -> some View {
        ZStack {
            GeometryReader { geo in
                ForEach(rain) { drop in
                    Image(drop.image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: drop.size, height: drop.size)
                        .opacity(0.5)  // keeps the star and candy readable through the rain
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
            let candySize = min(225, short * 0.48)

            VStack(spacing: spacing * 2) {
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

                // No words anywhere in play: the star, the sounds and the new candy say it.
                ZStack {
                    // A strong flash of the candy's color, then three rings of particles.
                    Circle()
                        .fill(candyColor.opacity(0.6))
                        .frame(width: candySize, height: candySize)
                        .scaleEffect(candyBurst ? 3.4 : 0.3)
                        .opacity(candyBurst ? 0 : (burstID == nil ? 0 : 1))
                    if let burstID {
                        BurstView(color: candyColor, radius: candySize * 0.8, big: true, bonus: true)
                            .id(burstID)
                        BurstView(color: candyColor, radius: candySize * 1.3, big: true)
                            .id(burstID.uuidString + "-outer")
                        BurstView(color: candyColor, radius: candySize * 1.9, big: true, bonus: true)
                            .id(burstID.uuidString + "-far")
                    }
                    candyImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: candySize, height: candySize)
                        .shadow(color: candyColor.opacity(0.6), radius: 18)
                        .rotationEffect(.degrees(candySpin))
                        .scaleEffect(candyBurst ? 2.2 : (candyShown ? (candyWound ? 1.25 : 1) : 0.05))
                        .opacity(candyBurst ? 0 : (candyShown ? 1 : 0))
                    if lockShown {
                        Image(systemName: "lock.fill")
                            .font(.system(size: candySize * 0.5, weight: .bold))
                            .foregroundStyle(Theme.text.opacity(0.75))
                            .padding(candySize * 0.14)
                            .background(Color.white.opacity(0.85), in: Circle())
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: candySize, height: candySize)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onContinue() }
        .onAppear {
            Haptics.levelDone()
            Task { await showNextCandy() }
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

    /// The next level's candy zooms in while spinning, winds up faster, then bursts into
    /// particles of its own color. With Reduce Motion it just fades in and out.
    private func showNextCandy() async {
        try? await Task.sleep(for: .milliseconds(600))
        if Motion.reduceMotion {
            withAnimation(.easeOut(duration: 0.4)) { candyShown = true }
            try? await Task.sleep(for: .milliseconds(1600))
            withAnimation(.easeIn(duration: 0.4)) { candyBurst = true }
            if showsLock {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.easeOut(duration: 0.3)) { lockShown = true }
            }
            return
        }
        // Zoom in fast with one turn.
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { candyShown = true }
        withAnimation(.easeOut(duration: 0.5)) { candySpin = 360 }
        try? await Task.sleep(for: .milliseconds(600))
        // Wind up: four fast turns while swelling, then burst.
        withAnimation(.easeIn(duration: 1.3)) { candySpin = 360 + 1440 }
        withAnimation(.easeIn(duration: 1.3)) { candyWound = true }
        try? await Task.sleep(for: .milliseconds(1300))
        burstID = UUID()
        SoundPlayer.shared.play(.matchBig, volume: 1)
        Haptics.powerUp()
        withAnimation(.easeOut(duration: 0.4)) { candyBurst = true }
        if showsLock {
            try? await Task.sleep(for: .milliseconds(600))
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
