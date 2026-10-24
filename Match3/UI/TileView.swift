import SwiftUI
import Match3Core

/// One candy. Hinting adds a glow and a slow pulse; wiggling shakes it sideways.
struct TileView: View {
    /// Asset name of the candy to draw (palette type in the tile's finish).
    let imageName: String
    let size: CGFloat
    let wiggling: Bool
    let hinting: Bool
    /// 1 = gentle pulse, 2+ = bright gold glow and a bigger pulse.
    var hintStrength: Int = 1
    /// High contrast: a thick dark rim traced around the candy's silhouette.
    var outlined: Bool = false
    /// Special candies shiver all the time so they can be told from the plain ones.
    var special: Bool = false

    @State private var hintPulse = false
    @State private var shiver = false

    var body: some View {
        let strong = hinting && hintStrength >= 2
        candy
            .shadow(color: Color.black.opacity(outlined ? 0.3 : 0.18), radius: size * 0.05, y: size * 0.05)
            .shadow(color: hinting ? (strong ? Theme.gold : Color.white.opacity(0.95)) : .clear,
                    radius: hinting && hintPulse ? size * (strong ? 0.45 : 0.25) : 0)
            .shadow(color: strong && hintPulse ? Theme.gold.opacity(0.8) : .clear, radius: size * 0.2)
            .scaleEffect(hinting && hintPulse ? (strong ? 1.22 : 1.14) : 1)
            .rotationEffect(.degrees(special && shiver ? 4 : (special ? -4 : 0)))
            .scaleEffect(special && shiver ? 1.04 : 1)
            .modifier(WiggleModifier(active: wiggling))
            .onChange(of: special, initial: true) { _, isSpecial in
                guard isSpecial, !Motion.reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.16).repeatForever(autoreverses: true)) { shiver = true }
            }
            .onChange(of: hinting, initial: true) { _, isHinting in
                if isHinting {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { hintPulse = true }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) { hintPulse = false }
                }
            }
    }

    private var image: Image { CandyArt.load(imageName) }

    /// The candy, and in high contrast the same image stamped in black at eight offsets
    /// underneath it, which traces an outline that follows each candy's own shape.
    @ViewBuilder private var candy: some View {
        if outlined {
            let rim = size * 0.055
            ZStack {
                ForEach(0..<8, id: \.self) { i in
                    let angle = Double(i) / 8 * 2 * .pi
                    image.renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Theme.cellBorderHighContrast)
                        .frame(width: size, height: size)
                        .offset(x: cos(angle) * rim, y: sin(angle) * rim)
                }
                image.resizable().scaledToFit().frame(width: size, height: size)
            }
            .compositingGroup()
        } else {
            image.resizable().scaledToFit().frame(width: size, height: size)
        }
    }
}

/// Short left-right shake used for an invalid swap. Implemented as a GeometryEffect so
/// SwiftUI interpolates the *phase* (and we get real oscillation), not the final offset.
struct WiggleModifier: ViewModifier {
    let active: Bool
    @State private var shakes: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(shakes: shakes))
            .onChange(of: active) { _, isActive in
                guard isActive else { return }
                withAnimation(.linear(duration: 0.35)) { shakes += 3 }
            }
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var amplitude: CGFloat = 6

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: sin(shakes * .pi * 2) * amplitude, y: 0))
    }
}
