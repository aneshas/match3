import SwiftUI
import Match3Core

/// Progress on top, board in the middle. No level number, no score, no buttons.
struct LevelScreen: View {
    let session: GameSession
    @Environment(\.screenInsets) private var insets

    var body: some View {
        VStack(spacing: 20) {
            // Keeps clear of the camera cutout on screens with a one-sided inset.
            ProgressBarView(fraction: session.progressFraction)
                .padding(.leading, 24 + insets.leading)
                .padding(.trailing, 24 + insets.trailing)
                .padding(.top, 20)

            BoardView(session: session)
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
        }
        .contentShape(Rectangle())
        .onTapGesture { session.playerTouched() }
        .overlay(alignment: .topLeading) { debugCounters }
    }

    /// Invisible to players; lets UI tests read what the session received.
    @ViewBuilder private var debugCounters: some View {
        #if DEBUG
        Text("swipes \(session.swipeAttempts) matches \(session.matchesMade)")
            .font(.system(size: 1))
            .opacity(0.01)
            .accessibilityIdentifier("debug.counters")
        #endif
    }
}
