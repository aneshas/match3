import SwiftUI

/// The whole start screen: a big candy as the logo, one huge button, some candies bobbing
/// around. Nothing else to read or decide.
struct PlayScreen: View {
    let onPlay: () -> Void
    /// Hidden caregiver entry: three fingers held for three seconds.
    var onCaregiverHold: () -> Void = {}
    /// Free levels used up and nothing bought: the button shows a lock and does nothing.
    var locked = false

    @State private var breathing = false
    @State private var logoSpin = false

    /// The Play button is a big candy from the whole pack, picked once per launch.
    private static let launchCandy: String = {
        let shape = CandyArt.shapes.randomElement() ?? CandyArt.shapes[0]
        let color = CandyArt.CandyColor.allCases.randomElement() ?? .red
        return CandyArt.CandyType(shape: shape, color: color).imageName()
    }()
    @State private var candies: [FloatingCandy] = FloatingCandy.makePlayScreen()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(candies) { c in
                    FloatingCandyView(item: c)
                        .position(x: c.x * geo.size.width, y: c.y * geo.size.height)
                }
                .allowsHitTesting(false)

                let landscape = geo.size.width > geo.size.height
                let logoSize = landscape ? min(geo.size.height * 0.5, 240) : min(geo.size.width * 0.5, 240, geo.size.height * 0.28)
                let layout = landscape ? AnyLayout(HStackLayout(spacing: 48)) : AnyLayout(VStackLayout(spacing: 40))

                layout {
                    Image(CandyArt.logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: logoSize)
                        .rotationEffect(.degrees(logoSpin ? 6 : -6))
                        .shadow(color: Color.black.opacity(0.2), radius: 12, y: 8)
                        .accessibilityIdentifier("logo")
                        .debugLogoHold(onCaregiverHold)

                    // The button: a big candy (a little bigger than the logo) with a play icon on
                    // top. Icon only, so the app has no words in any language. Locked: the candy
                    // fades to grey and the icon becomes a lock.
                    let candySize = logoSize * 1.2
                    Button(action: { guard !locked else { return }; SoundPlayer.shared.play(.tap); onPlay() }) {
                        ZStack {
                            CandyArt.load(PlayScreen.launchCandy)
                                .resizable()
                                .scaledToFit()
                                .frame(width: candySize, height: candySize)
                                .saturation(locked ? 0.1 : 1)
                                .opacity(locked ? 0.75 : 1)
                                .shadow(color: Color.black.opacity(0.22), radius: 12, y: 8)
                            OutlinedSymbol(name: locked ? "lock.fill" : "play.fill",
                                           font: .system(size: candySize * 0.38, weight: .bold),
                                           fill: .white, outline: Theme.text, width: 3)
                                .shadow(color: Color.black.opacity(0.3), radius: 6, y: 4)
                        }
                        .frame(width: candySize * 1.1, height: candySize * 1.1)
                        .contentShape(Circle())
                        .shadow(color: Theme.magenta.opacity(locked ? 0 : 0.4), radius: 24, y: 10)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .scaleEffect(breathing && !locked ? 1.04 : 1.0)
                    .accessibilityLabel(locked ? "Locked" : "Play")
                }
                .position(x: geo.size.width / 2, y: geo.size.height * (landscape ? 0.5 : 0.46))
                .zIndex(2)  // nothing decorative may ever cover the Play button

                ThreeFingerHold(action: onCaregiverHold)
                    .ignoresSafeArea()
                    .zIndex(3)

            }
        }
        .onAppear {
            guard !Motion.reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { breathing = true }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { logoSpin = true }
        }
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private extension View {
    /// Debug builds only: the Simulator cannot produce three touches, so holding one finger
    /// on the logo for three seconds also opens the caregiver panel. Not compiled in Release.
    @ViewBuilder
    func debugLogoHold(_ action: @escaping () -> Void) -> some View {
        #if DEBUG
        self.onLongPressGesture(minimumDuration: 3, maximumDistance: 40) { action() }
        #else
        self
        #endif
    }
}
