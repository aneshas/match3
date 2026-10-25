import SwiftUI

/// Particles flying out of a matched candy: a ring that expands and fades plus a handful
/// of colored dots. Purely procedural, no sprites.
struct BurstView: View {
    let color: Color
    let radius: CGFloat
    let big: Bool
    /// The level's bonus candy: more particles, and a second gold ring.
    var bonus: Bool = false

    @State private var progress: CGFloat = 0
    private let particles: [Particle]

    init(color: Color, radius: CGFloat, big: Bool, bonus: Bool = false) {
        self.color = color
        self.radius = radius
        self.big = big
        self.bonus = bonus
        self.particles = Particle.make(count: bonus ? 20 : (big ? 14 : 8))
    }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(color.opacity(0.9), lineWidth: big ? 5 : 3)
                .frame(width: radius * 1.2, height: radius * 1.2)
                .scaleEffect(0.4 + progress * (big ? 2.0 : 1.4))
                .opacity(1 - progress)
            if bonus {
                Circle()
                    .strokeBorder(Theme.gold, lineWidth: 4)
                    .frame(width: radius * 1.2, height: radius * 1.2)
                    .scaleEffect(0.2 + progress * 2.6)
                    .opacity(1 - progress)
            }

            ForEach(particles) { p in
                Circle()
                    .fill(p.light ? Color.white : color)
                    .frame(width: p.size, height: p.size)
                    .offset(x: cos(p.angle) * radius * p.distance * progress,
                            y: sin(p.angle) * radius * p.distance * progress)
                    .scaleEffect(1 - progress * 0.8)
                    .opacity(1 - progress)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { progress = 1 }
        }
    }

    struct Particle: Identifiable {
        let id = UUID()
        let angle: CGFloat
        let distance: CGFloat
        let size: CGFloat
        let light: Bool

        static func make(count: Int) -> [Particle] {
            (0..<count).map { i in
                Particle(angle: CGFloat(i) / CGFloat(count) * .pi * 2 + CGFloat.random(in: -0.3...0.3),
                         distance: CGFloat.random(in: 0.9...1.6),
                         size: CGFloat.random(in: 6...12),
                         light: i % 3 == 0)
            }
        }
    }
}


/// The star that rises from a match of the bonus candy and fades: the same badge as on the
/// bar, so the player sees that this candy fills the bar faster.
struct BonusPopView: View {
    let size: CGFloat
    @State private var risen = false

    var body: some View {
        BonusBadge(size: size)
            .scaleEffect(risen ? 1.3 : 0.6)
            .offset(y: risen ? -size * 1.6 : 0)
            .opacity(risen ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 1.8 * (Motion.reduceMotion ? 0.5 : 1))) { risen = true }
            }
    }
}
