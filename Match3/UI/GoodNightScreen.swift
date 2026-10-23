import SwiftUI
import Match3Core

/// Gentle end of a caregiver-timed session: the light dims, a candy falls asleep, a few
/// stars twinkle, and after a moment the app goes back to the Play screen. No words.
struct GoodNightScreen: View {
    let onFinish: () -> Void

    @State private var dimmed = false
    @State private var twinkle = false

    var body: some View {
        ZStack {
            Color(red: 0.25, green: 0.12, blue: 0.35)
                .opacity(dimmed ? 0.45 : 0)
                .ignoresSafeArea()

            GeometryReader { geo in
                ForEach(Array(stars.enumerated()), id: \.offset) { i, star in
                    Image(systemName: "star.fill")
                        .font(.system(size: star.size))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .opacity(twinkle == (i % 2 == 0) ? 1 : 0.25)
                        .position(x: star.x * geo.size.width, y: star.y * geo.size.height)
                }
            }
            .allowsHitTesting(false)

            GeometryReader { geo in
                SleepyCandyView(color: TileColor(2))
                    .frame(width: min(260, min(geo.size.width, geo.size.height) * 0.45))
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
                .scaleEffect(dimmed ? 1 : 0.6)
                .opacity(dimmed ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { onFinish() }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) { dimmed = true }
            guard !Motion.reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { twinkle = true }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(400))
            SoundPlayer.shared.saySeeYouSoon()
            try? await Task.sleep(for: .seconds(4.5))
            onFinish()
        }
    }

    private let stars: [(x: Double, y: Double, size: Double)] = [
        (0.15, 0.12, 22), (0.80, 0.10, 16), (0.30, 0.25, 12), (0.88, 0.30, 24),
        (0.10, 0.45, 14), (0.92, 0.60, 12), (0.20, 0.82, 18), (0.75, 0.86, 20),
    ]
}
