import SwiftUI
import Match3Core

/// Progress on top, board in the middle. No level number, no score, no buttons.
struct LevelScreen: View {
    let session: GameSession

    var body: some View {
        VStack(spacing: 20) {
            ProgressBarView(fraction: session.progressFraction)
                .padding(.horizontal, 24)
                .padding(.top, 20)

            // The bar stays inside the safe area (camera top-right on some devices); the board
            // is centered on the physical screen.
            BoardView(session: session)
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
                .centeredOnScreen()
        }
        .contentShape(Rectangle())
        .onTapGesture { session.playerTouched() }
    }
}
