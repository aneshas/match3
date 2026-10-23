import Foundation

extension Board {
    /// Replaces the board contents from rows of letters (a-f = colors 0-5, '.' = empty cell).
    /// Intended for tests and debugging only.
    public mutating func overwrite(with rowStrings: [String]) {
        precondition(rowStrings.count == rows)
        for (r, line) in rowStrings.enumerated() {
            let chars = Array(line)
            precondition(chars.count == cols)
            for (c, ch) in chars.enumerated() {
                guard mask[r][c] else { continue }
                if ch == "." {
                    setCell(row: r, col: c, nil)
                } else {
                    let index = Int(ch.asciiValue! - Character("a").asciiValue!)
                    setCell(row: r, col: c, Tile(color: TileColor(index)))
                }
            }
        }
    }

    public mutating func setCell(row: Int, col: Int, _ tile: Tile?) {
        cells[row][col] = tile
    }
}
