import SwiftUI

/// A big bar that fills up as matches are made. No digits anywhere: the candy at the end
/// (one from the next level) is
/// the goal, and it lights up when reached. The fill shimmers and the bar pulses on each gain.
struct ProgressBarView: View {
    let fraction: Double
    /// The candy shown at the end of the bar: this level's bonus candy.
    var goal: CandyArt.Preview? = nil
    /// Goes up by one every time the bonus candy is matched: the candy lights up and spins
    /// for a moment, the same way it does when the bar is full.
    var bonusMatches: Int = 0
    /// Vertical in landscape: the bar stands beside the board and fills bottom to top.
    var axis: Axis = .horizontal
    private let height: CGFloat = 29

    @State private var shimmer = false
    @State private var pulse = false
    @State private var spinDegrees = 0.0
    @State private var celebrating = false
    @State private var celebrationID = 0
    /// Gold bursts at the end of the fill, one per gain: "that match made the bar grow".
    @State private var sparkles: [Sparkle] = []

    private struct Sparkle: Identifiable {
        let id = UUID()
        let fraction: Double
    }

    var body: some View {
        if axis == .vertical {
            vertical
        } else {
            horizontal
        }
    }

    private var vertical: some View {
        VStack(spacing: 14) {
            star
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(Theme.progressTrack)
                        .overlay(Capsule().strokeBorder(Color.white, lineWidth: 3))
                    Capsule()
                        .fill(LinearGradient(colors: [Theme.magenta, Theme.pink], startPoint: .top, endPoint: .bottom))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: height * 0.35)
                                .padding(.vertical, 8)
                                .padding(.leading, 5)
                        }
                        .frame(height: max(height, geo.size.height * fraction))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: fraction)

                    ForEach(sparkles) { sparkle in
                        BurstView(color: Theme.gold, radius: height * 0.7, big: false)
                            .position(x: height / 2, y: geo.size.height - max(height, geo.size.height * sparkle.fraction))
                    }
                }
            }
            .frame(width: height)
            .scaleEffect(pulse ? 1.05 : 1)
        }
        .onChange(of: fraction) { _, new in pulseOnChange(new) }
        .onChange(of: bonusMatches) { _, _ in celebrateBonus() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(fraction * 100)) percent")
    }

    /// The goal candy: this level's bonus candy with a red "+" badge (it scores more), a
    /// little faded while the bar fills, then full color, a gold glow, a bounce and a spin
    /// when the bar is full.
    private var star: some View {
        let done = fraction >= 1 || celebrating
        return CandyArt.load(goal?.imageName ?? CandyArt.tileImages[0])
            .resizable()
            .scaledToFit()
            .frame(width: 52, height: 52)
            .opacity(done ? 1 : 0.85)
            .shadow(color: Color.black.opacity(0.18), radius: 3, y: 2)
            .shadow(color: done ? Theme.gold.opacity(0.8) : .clear, radius: done ? 14 : 0)
            .overlay(alignment: .bottomTrailing) {
                BonusBadge(size: 24).offset(x: 6, y: 6)  // low, clear of the camera at the top
            }
            .scaleEffect(done ? 1.3 : 1)
            .rotationEffect(.degrees(spinDegrees))
            .animation(.spring(response: 0.45, dampingFraction: 0.5), value: done)
    }

    private func pulseOnChange(_ new: Double) {
        if new > 0 {
            let sparkle = Sparkle(fraction: new)
            sparkles.append(sparkle)
            Task {
                try? await Task.sleep(for: .milliseconds(800))
                sparkles.removeAll { $0.id == sparkle.id }
            }
        }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { pulse = true }
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.easeOut(duration: 0.2)) { pulse = false }
        }
        if new >= 1 {
            withAnimation(.easeInOut(duration: 0.7)) { spinDegrees += 360 }
        }
    }

    /// A bonus match: the candy glows, grows and takes one turn, exactly like the full bar,
    /// holds it for a moment, then settles.
    private func celebrateBonus() {
        celebrationID += 1
        let mine = celebrationID
        withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) { celebrating = true }
        withAnimation(.easeInOut(duration: 0.7)) { spinDegrees += 360 }
        Task {
            try? await Task.sleep(for: .milliseconds(1800))
            guard mine == celebrationID else { return }  // a newer match keeps it lit
            withAnimation(.easeOut(duration: 0.4)) { celebrating = false }
        }
    }

    private var horizontal: some View {
        HStack(spacing: 14) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.progressTrack)
                        .overlay(Capsule().strokeBorder(Color.white, lineWidth: 3))

                    Capsule()
                        .fill(Theme.progressFill)
                        .overlay(alignment: .top) {
                            // Glossy highlight along the top edge.
                            Capsule()
                                .fill(Color.white.opacity(0.35))
                                .frame(height: height * 0.35)
                                .padding(.horizontal, 8)
                                .padding(.top, 5)
                        }
                        .overlay {
                            // Moving sheen.
                            LinearGradient(colors: [.clear, .white.opacity(0.55), .clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: 70)
                                .offset(x: shimmer ? geo.size.width : -80)
                        }
                        .clipShape(Capsule())
                        .frame(width: max(height, geo.size.width * fraction))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: fraction)

                    ForEach(sparkles) { sparkle in
                        BurstView(color: Theme.gold, radius: height * 0.7, big: false)
                            .position(x: max(height, geo.size.width * sparkle.fraction), y: height / 2)
                    }
                }
            }
            .frame(height: height)
            .scaleEffect(pulse ? 1.05 : 1)

            star
        }
        .onAppear {
            guard !Motion.reduceMotion else { return }
            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) { shimmer = true }
        }
        .onChange(of: fraction) { _, new in pulseOnChange(new) }
        .onChange(of: bonusMatches) { _, _ in celebrateBonus() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(fraction * 100)) percent")
    }
}


/// A red disc with a white "+": marks the candy that scores more this level. It is a
/// symbol, not a word, so nothing needs reading.
struct BonusBadge: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.bonusRed)
                .overlay(Circle().strokeBorder(Color.white, lineWidth: max(1.5, size * 0.09)))
                .shadow(color: Color.black.opacity(0.25), radius: size * 0.08, y: size * 0.05)
            Image(systemName: "plus")
                .font(.system(size: size * 0.62, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
