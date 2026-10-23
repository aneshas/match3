import SwiftUI
import Match3Core

/// Candy-shop theme: soft cream-to-pink background, translucent white cells for the board, pink
/// progress, cocoa-colored text. Chosen to sit behind glossy, dark-outlined candy icons.
enum Theme {
    static let backgroundTop = Color(red: 1.00, green: 0.97, blue: 0.91)
    static let backgroundBottom = Color(red: 1.00, green: 0.84, blue: 0.90)
    static var background: LinearGradient {
        LinearGradient(colors: [backgroundTop, backgroundBottom], startPoint: .top, endPoint: .bottom)
    }

    static let cell = Color.white.opacity(0.55)

    static let text = Color(red: 0.32, green: 0.13, blue: 0.22)
    static let gold = Color(red: 1.00, green: 0.78, blue: 0.16)
    static let goldDark = Color(red: 0.85, green: 0.55, blue: 0.05)

    static let pink = Color(red: 1.00, green: 0.45, blue: 0.65)
    static let magenta = Color(red: 0.95, green: 0.22, blue: 0.50)
    static let progressTrack = Color.white.opacity(0.75)
    static var progressFill: LinearGradient {
        LinearGradient(colors: [pink, magenta], startPoint: .leading, endPoint: .trailing)
    }
    static var playButton: LinearGradient {
        LinearGradient(colors: [Color(red: 1.00, green: 0.50, blue: 0.62), Color(red: 0.92, green: 0.18, blue: 0.42)],
                       startPoint: .top, endPoint: .bottom)
    }

    /// Burst particle color per tile color (matches the candy's hue).
    private static let particleColors: [Color] = [
        Color(red: 0.20, green: 0.65, blue: 0.95),  // blue
        Color(red: 1.00, green: 0.85, blue: 0.20),  // yellow
        Color(red: 0.90, green: 0.20, blue: 0.25),  // red
        Color(red: 0.45, green: 0.78, blue: 0.25),  // green
        Color(red: 0.75, green: 0.30, blue: 0.90),  // purple
        Color(red: 1.00, green: 0.60, blue: 0.15),  // orange
    ]

    static func particleColor(for tile: TileColor) -> Color {
        particleColors[tile.index]
    }
}
