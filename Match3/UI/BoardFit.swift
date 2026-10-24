import SwiftUI
import Match3Core

/// How many rows fit on this screen without the candies getting smaller than they are on
/// a 7-column board. Mirrors the portrait `LevelScreen` layout: bar, spacing, board, home
/// row. Landscape boards are height-limited anyway, so they stay at most square.
enum BoardFit {
    static func maxRows(for size: CGSize, insets: EdgeInsets) -> Int {
        guard size.width > 0, size.height > 0 else { return LevelConfig.maxRows }
        if size.width > size.height { return LevelConfig.maxCols }
        let boardWidth = size.width - insets.leading - insets.trailing - 24 - 12   // horizontal padding + board inset
        let cell = boardWidth / CGFloat(LevelConfig.maxCols)
        let chrome: CGFloat = 44 + 29 + 20 + 20 + 64 + 16 + 12               // bar padding, bar, spacings, home row, board inset
        let boardHeight = size.height - insets.top - insets.bottom - chrome
        let rows = Int(boardHeight / cell)
        return max(LevelConfig.maxCols, min(LevelConfig.maxRows, rows))
    }
}
