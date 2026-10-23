import SwiftUI
import Match3Core

/// A glass candy jar drawn in code, filled with the game's own candy images. `count` is how
/// many candies are inside; beyond `capacity` the jar just looks full.
struct JarView: View {
    var count: Int
    var capacity: Int = 20
    var lidColor: Color = Theme.magenta

    private let outline = Color(red: 0.24, green: 0.10, blue: 0.16)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let stroke = max(3, w * 0.035)
            let bodyRect = CGRect(x: w * 0.08, y: h * 0.22, width: w * 0.84, height: h * 0.76)
            let neckRect = CGRect(x: w * 0.20, y: h * 0.13, width: w * 0.60, height: h * 0.14)
            let lidRect = CGRect(x: w * 0.16, y: h * 0.04, width: w * 0.68, height: h * 0.13)

            ZStack {
                // Candies inside, clipped to the glass.
                ZStack {
                    ForEach(Array(slots(in: bodyRect, size: w).prefix(min(count, capacity)).enumerated()), id: \.offset) { i, slot in
                        CandyArt.tileImage(TileColor(i % TileColor.maxCount))
                            .resizable()
                            .scaledToFit()
                            .frame(width: slot.size, height: slot.size)
                            .rotationEffect(.degrees(slot.rotation))
                            .position(slot.center)
                    }
                }
                .clipShape(JarGlassShape(bodyRect: bodyRect, neckRect: neckRect))

                // Glass: tint, outline, highlights.
                JarGlassShape(bodyRect: bodyRect, neckRect: neckRect)
                    .fill(Color.white.opacity(0.22))
                JarGlassShape(bodyRect: bodyRect, neckRect: neckRect)
                    .stroke(outline, lineWidth: stroke)
                Capsule()
                    .fill(Color.white.opacity(0.38))
                    .frame(width: w * 0.055, height: h * 0.42)
                    .position(x: bodyRect.minX + w * 0.13, y: bodyRect.midY - h * 0.04)
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: w * 0.04, height: h * 0.14)
                    .position(x: bodyRect.minX + w * 0.13, y: bodyRect.maxY - h * 0.16)

                // Lid: colored band with a glossy top and dark outline.
                RoundedRectangle(cornerRadius: lidRect.height * 0.35, style: .continuous)
                    .fill(LinearGradient(colors: [lidColor.opacity(0.85), lidColor], startPoint: .top, endPoint: .bottom))
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(Color.white.opacity(0.35))
                            .frame(height: lidRect.height * 0.28)
                            .padding(.horizontal, lidRect.width * 0.12)
                            .padding(.top, lidRect.height * 0.14)
                    }
                    .overlay(RoundedRectangle(cornerRadius: lidRect.height * 0.35, style: .continuous).stroke(outline, lineWidth: stroke))
                    .frame(width: lidRect.width, height: lidRect.height)
                    .position(x: lidRect.midX, y: lidRect.midY)
            }
        }
        .aspectRatio(0.8, contentMode: .fit)
        .accessibilityLabel("Candy jar")
        .accessibilityValue("\(count) candies")
    }

    private struct Slot {
        let center: CGPoint
        let size: CGFloat
        let rotation: Double
    }

    /// Candy positions filling the jar from the bottom up, slightly jittered so it looks
    /// poured rather than stacked. Deterministic so the jar never reshuffles between renders.
    private func slots(in rect: CGRect, size w: CGFloat) -> [Slot] {
        let perRow = 4
        let candy = rect.width / CGFloat(perRow) * 0.95
        var out: [Slot] = []
        var rng = SeededRandom(seed: 7)
        let rows = Int(ceil(Double(capacity) / Double(perRow)))
        for r in 0..<rows {
            let offset = r.isMultiple(of: 2) ? 0 : candy * 0.5
            for c in 0..<perRow {
                let jitterX = CGFloat(Double(rng.next() % 1000) / 1000 - 0.5) * candy * 0.15
                let jitterY = CGFloat(Double(rng.next() % 1000) / 1000 - 0.5) * candy * 0.10
                let rotation = Double(rng.next() % 60) - 30
                let x = rect.minX + candy * 0.55 + CGFloat(c) * candy * 0.92 + offset + jitterX
                let y = rect.maxY - candy * 0.55 - CGFloat(r) * candy * 0.80 + jitterY
                out.append(Slot(center: CGPoint(x: min(x, rect.maxX - candy * 0.4), y: y), size: candy, rotation: rotation))
            }
        }
        return out
    }
}

/// Jar silhouette: a rounded body with a narrower neck, as one path so the glass outline
/// is continuous.
struct JarGlassShape: Shape {
    let bodyRect: CGRect
    let neckRect: CGRect

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = bodyRect.width * 0.18
        let shoulder = bodyRect.minY + r * 0.6
        p.move(to: CGPoint(x: neckRect.minX, y: neckRect.minY))
        p.addLine(to: CGPoint(x: neckRect.maxX, y: neckRect.minY))
        p.addLine(to: CGPoint(x: neckRect.maxX, y: bodyRect.minY))
        p.addQuadCurve(to: CGPoint(x: bodyRect.maxX, y: shoulder + r * 0.6),
                       control: CGPoint(x: bodyRect.maxX, y: bodyRect.minY))
        p.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY - r))
        p.addQuadCurve(to: CGPoint(x: bodyRect.maxX - r, y: bodyRect.maxY),
                       control: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY))
        p.addLine(to: CGPoint(x: bodyRect.minX + r, y: bodyRect.maxY))
        p.addQuadCurve(to: CGPoint(x: bodyRect.minX, y: bodyRect.maxY - r),
                       control: CGPoint(x: bodyRect.minX, y: bodyRect.maxY))
        p.addLine(to: CGPoint(x: bodyRect.minX, y: shoulder + r * 0.6))
        p.addQuadCurve(to: CGPoint(x: neckRect.minX, y: bodyRect.minY),
                       control: CGPoint(x: bodyRect.minX, y: bodyRect.minY))
        p.closeSubpath()
        return p
    }
}
