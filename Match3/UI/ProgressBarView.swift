import SwiftUI

/// A big bar that fills up as matches are made. No digits anywhere: the star at the end is
/// the goal, and it lights up when reached. The fill shimmers and the bar pulses on each gain.
struct ProgressBarView: View {
    let fraction: Double
    private let height: CGFloat = 36

    @State private var shimmer = false
    @State private var pulse = false
    @State private var starSpin = false

    var body: some View {
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
                }
            }
            .frame(height: height)
            .scaleEffect(pulse ? 1.05 : 1)

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
        .onAppear {
            guard !Motion.reduceMotion else { return }
            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) { shimmer = true }
        }
        .onChange(of: fraction) { _, new in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { pulse = true }
            Task {
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(.easeOut(duration: 0.2)) { pulse = false }
            }
            if new >= 1 {
                withAnimation(.easeInOut(duration: 0.7)) { starSpin = true }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(fraction * 100)) percent")
    }
}
