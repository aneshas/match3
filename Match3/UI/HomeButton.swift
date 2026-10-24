import SwiftUI

/// Round "go back to the Play screen" button: a house on a soft white disc. One tap, no
/// confirmation; nothing is lost because progress is only ever counted per finished level.
struct HomeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: { SoundPlayer.shared.play(.tap); action() }) {
            Image(systemName: "house.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.text.opacity(0.8))
                .frame(width: 64, height: 64)
                .background(Color.white.opacity(0.9), in: Circle())
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 3))
                .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Home")
        .accessibilityIdentifier("home")
    }
}
