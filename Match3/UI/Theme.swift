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
    static let cellBorder = Color.white.opacity(0.7)
    /// High contrast: cocoa cells with a dark rim so bright candies sit on a dark, even ground.
    static let cellHighContrast = Color(red: 0.45, green: 0.26, blue: 0.36)
    static let cellBorderHighContrast = Color(red: 0.22, green: 0.08, blue: 0.16)

    static let text = Color(red: 0.32, green: 0.13, blue: 0.22)
    static let gold = Color(red: 1.00, green: 0.78, blue: 0.16)
    static let goldDark = Color(red: 0.85, green: 0.55, blue: 0.05)

    static let pink = Color(red: 1.00, green: 0.45, blue: 0.65)
    static let magenta = Color(red: 0.95, green: 0.22, blue: 0.50)
    /// The "+" badge of the level's bonus candy.
    static let bonusRed = Color(red: 0.92, green: 0.18, blue: 0.22)
    static let progressTrack = Color.white.opacity(0.75)
    static var progressFill: LinearGradient {
        LinearGradient(colors: [pink, magenta], startPoint: .leading, endPoint: .trailing)
    }
    static var playButton: LinearGradient {
        LinearGradient(colors: [Color(red: 1.00, green: 0.50, blue: 0.62), Color(red: 0.92, green: 0.18, blue: 0.42)],
                       startPoint: .top, endPoint: .bottom)
    }

    /// Burst particle color for the classic six (board effects use the level's palette:
    /// `CandyArt.Palette.particleColor`).
    static func particleColor(for tile: TileColor) -> Color {
        CandyArt.CandyColor.allCases[tile.index].particle
    }
}
