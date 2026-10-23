import SwiftUI

/// A big bar that fills up as matches are made. No digits anywhere: the star at the end is
/// the goal, and it lights up when reached. The fill shimmers and the bar pulses on each gain.
struct ProgressBarView: View {
    let fraction: Double
    /// Vertical in landscape: the bar stands beside the board and fills bottom to top.
    var axis: Axis = .horizontal
    private let height: CGFloat = 36

    @State private var shimmer = false
    @State private var pulse = false
    @State private var starSpin = false
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(fraction * 100)) percent")
    }

    private var star: some View {
        Image(systemName: "star.fill")
            .font(.system(size: 44))
            .foregroundStyle(
                fraction >= 1
                    ? AnyShapeStyle(LinearGradient(colors: [Theme.gold, Theme.goldDark], startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color.white.opacity(0.8))
            )
            .shadow(color: fraction >= 1 ? Theme.gold.opacity(0.7) : Color.black.opacity(0.1), radius: fraction >= 1 ? 12 : 2, y: 2)
            .scaleEffect(fraction >= 1 ? 1.3 : 1)
            .rotationEffect(.degrees(starSpin ? 360 : 0))
            .animation(.spring(response: 0.45, dampingFraction: 0.5), value: fraction >= 1)
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
            withAnimation(.easeInOut(duration: 0.7)) { starSpin = true }
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(fraction * 100)) percent")
    }
}
