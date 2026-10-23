import SwiftUI

/// The whole start screen: a big candy as the logo, one huge button, some candies bobbing
/// around. Nothing else to read or decide.
struct PlayScreen: View {
    let onPlay: () -> Void
    /// Hidden caregiver entry: three fingers held for three seconds.
    var onCaregiverHold: () -> Void = {}
    /// Candies in the jar: one per finished level. Pure reward, nothing to do with it.
    var completedLevels: Int = 0

    @State private var breathing = false
    @State private var logoSpin = false
    @State private var candies: [FloatingCandy] = FloatingCandy.makePlayScreen()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(candies) { c in
                    FloatingCandyView(item: c)
                        .position(x: c.x * geo.size.width, y: c.y * geo.size.height)
                }
                .allowsHitTesting(false)

                let logoSize = min(geo.size.width * 0.5, 240, geo.size.height * 0.28)
                let jarWidth = min(geo.size.width * 0.22, 100)

                VStack(spacing: 40) {
                    Image(CandyArt.logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: logoSize)
                        .rotationEffect(.degrees(logoSpin ? 6 : -6))
                        .shadow(color: Color.black.opacity(0.2), radius: 12, y: 8)
                        .debugLogoHold(onCaregiverHold)

                    Button(action: { SoundPlayer.shared.play(.tap); onPlay() }) {
                        HStack(spacing: 20) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 56, weight: .bold))
                            Text("Play")
                                .font(.system(size: 64, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .shadow(color: Color.black.opacity(0.25), radius: 2, y: 2)
                        .frame(width: max(geo.size.width * 0.75, 280), height: 140)
                        .background(Theme.playButton, in: Capsule())
                        .overlay(alignment: .top) {
                            Capsule()
                                .fill(Color.white.opacity(0.28))
                                .frame(height: 52)
                                .padding(.horizontal, 22)
                                .padding(.top, 10)
                        }
                        .overlay(Capsule().strokeBorder(Color.white, lineWidth: 5))
                        .shadow(color: Theme.magenta.opacity(0.45), radius: 18, y: 10)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .scaleEffect(breathing ? 1.04 : 1.0)
                    .accessibilityLabel("Play")
                }
                // Slightly above center so the jar in the bottom corner never reaches the button.
                .position(x: geo.size.width / 2, y: geo.size.height * 0.44)
                .zIndex(2)  // nothing decorative may ever cover the Play button

                ThreeFingerHold(action: onCaregiverHold)
                    .ignoresSafeArea()
                    .zIndex(3)

                if completedLevels > 0 {
                    JarView(count: completedLevels)
                        .frame(width: jarWidth)
                        .position(x: geo.size.width - jarWidth * 0.6 - 12,
                                  y: geo.size.height - jarWidth * 0.7 - 20)
                        .allowsHitTesting(false)
                        .zIndex(1)
                }
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
