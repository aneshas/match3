import SwiftUI
import Match3Core

/// Progress on top, board in the middle. No level number, no score, no buttons.
struct LevelScreen: View {
    let session: GameSession
    var onHome: () -> Void = {}
    @Environment(\.screenInsets) private var insets

    var body: some View {
        GeometryReader { geo in
            if geo.size.width > geo.size.height {
                // Landscape: the bar stands on the left, the board uses the full height.
                HStack(spacing: 16) {
                    VStack(spacing: 16) {
                        LevelBadge(level: session.config.level)
                        ProgressBarView(fraction: session.progressFraction, goal: session.bonusCandy, bonusMatches: session.bonusMatches, axis: .vertical)
                        HomeButton(action: onHome)
                    }
                    .padding(.leading, 20 + insets.leading)
                    .padding(.vertical, 20)
                    BoardView(session: session)
                        .padding(.trailing, 12 + insets.trailing)
                        .padding(.vertical, 12)
                }
            } else {
                VStack(spacing: 20) {
                    // Keeps clear of the camera cutout on screens with a one-sided inset.
                    ProgressBarView(fraction: session.progressFraction, goal: session.bonusCandy, bonusMatches: session.bonusMatches)
                        .padding(.leading, 24 + insets.leading)
                        .padding(.trailing, 24 + insets.trailing)
                        .padding(.top, 44)  // clear of the notch / camera on phones that report no top inset
                    BoardView(session: session)
                        .padding(.horizontal, 12)
                    // Its own row, so neither disc can ever sit on top of a candy: level
                    // number bottom left, home button bottom right.
                    HStack {
                        LevelBadge(level: session.config.level)
                        Spacer()
                        HomeButton(action: onHome)
                    }
                    .padding(.leading, 20 + insets.leading)
                    .padding(.trailing, 20 + insets.trailing)
                    .padding(.bottom, 16)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { session.playerTouched() }
        .overlay(alignment: .topLeading) { debugCounters }
    }

    /// Invisible to players; lets UI tests read what the session received.
    @ViewBuilder private var debugCounters: some View {
        #if DEBUG
        Text("swipes \(session.swipeAttempts) matches \(session.matchesMade) points \(Int(session.progressPoints * 4)) powers \(session.triggeredPowers)")
            .font(.system(size: 1))
            .opacity(0.01)
            .accessibilityIdentifier("debug.counters")
        #endif
    }
}
