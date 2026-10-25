import Foundation

/// A board shape is a mask over a rows x cols grid. Masked-out cells are holes that never
/// hold a tile. Every shape must keep each column's playable cells vertically contiguous so
/// gravity stays simple (tiles only ever fall straight down and refill from the top).
public enum BoardShape: String, CaseIterable, Codable, Sendable {
    case square
    case roundedCorners
    case diamond
    case cross
    case octagon
    case circle
    case triangle
    case heart

    /// Whether the cell at (row, col) is playable for a board of the given size.
    public func isPlayable(row: Int, col: Int, rows: Int, cols: Int) -> Bool {
        switch self {
        case .square:
            return true

        case .roundedCorners:
            // Cut just the four corner cells.
            let topOrBottom = row == 0 || row == rows - 1
            let leftOrRight = col == 0 || col == cols - 1
            return !(topOrBottom && leftOrRight)

        case .octagon:
            // Cut a small triangle (2-cell leg) off each corner for boards >= 7, 1-cell for smaller.
            let cut = (min(rows, cols) >= 7) ? 2 : 1
            let fromTop = row
            let fromBottom = rows - 1 - row
            let fromLeft = col
            let fromRight = cols - 1 - col
            let v = min(fromTop, fromBottom)
            let h = min(fromLeft, fromRight)
            return v + h >= cut

        case .diamond:
            // Manhattan distance from the center, with a generous threshold so the tips are
            // three cells wide and the board keeps most of its cells (a thin diamond on a
            // 7-column board was smaller than a level-5 board).
            let cr = Double(rows - 1) / 2
            let cc = Double(cols - 1) / 2
            let d = abs(Double(row) - cr) / max(cr, 0.5) + abs(Double(col) - cc) / max(cc, 0.5)
            return d <= 1.0 + 1.0 / min(cr, cc) + 1e-9

        case .circle:
            let cr = Double(rows - 1) / 2
            let cc = Double(cols - 1) / 2
            let dy = (Double(row) - cr) / (cr + 0.5)
            let dx = (Double(col) - cc) / (cc + 0.5)
            return dx * dx + dy * dy <= 1.0

        case .triangle:
            // Point up, with a flat top about three cells wide (two on even widths): the
            // width grows evenly from the top row to the full bottom row. A sharp point
            // would leave half the grid empty.
            let cc = Double(cols - 1) / 2
            let width = 3.0 + (Double(cols) - 3.0) * Double(row) / Double(max(rows - 1, 1))
            return abs(Double(col) - cc) <= width / 2 - 0.5 + 1e-9

        case .heart:
            // Implicit heart curve (x^2 + y^2 - 1)^3 - x^2 y^3 < 0, y pointing up, sampled at
            // cell centers and scaled to fill the grid. Needs an odd column count for the
            // bottom tip and 7+ rows for the notch; `minimumSize` enforces that.
            let x = (Double(col) + 0.5) / Double(cols) * 2.6 - 1.3
            let y = 1.3 - (Double(row) + 0.5) / Double(rows) * 2.4
            let f = pow(x * x + y * y - 1, 3) - x * x * pow(y, 3)
            return f < 0

        case .cross:
            // A thick plus sign: keep the middle band of rows and the middle band of columns.
            // Arm thickness keeps the same parity as the board so the cross is centered.
            func arm(_ n: Int) -> Int {
                var a = max(3, n / 2)
                if (n - a) % 2 != 0 { a += 1 }
                return a
            }
            let armRows = arm(rows)
            let armCols = arm(cols)
            let rowStart = (rows - armRows) / 2
            let colStart = (cols - armCols) / 2
            let inRowBand = row >= rowStart && row < rowStart + armRows
            let inColBand = col >= colStart && col < colStart + armCols
            return inRowBand || inColBand
        }
    }

    /// Smallest board on which this shape still reads as that shape. Below it the shape
    /// collapses into a rounded square (or worse), so `LevelConfig` skips it.
    public func fits(rows: Int, cols: Int) -> Bool {
        switch self {
        case .square: return true
        case .roundedCorners: return rows >= 5 && cols >= 5
        case .diamond: return rows >= 6 && cols >= 6
        case .cross, .circle, .octagon: return rows >= 7 && cols >= 7
        case .triangle: return rows >= 6 && cols >= 6
        case .heart: return rows >= 7 && cols >= 7 && cols % 2 == 1
        }
    }

    /// Returns the full mask for a board size.
    public func mask(rows: Int, cols: Int) -> [[Bool]] {
        (0..<rows).map { r in (0..<cols).map { c in isPlayable(row: r, col: c, rows: rows, cols: cols) } }
    }

    /// Validates the contiguity rule that gravity depends on.
    public static func columnsAreContiguous(_ mask: [[Bool]]) -> Bool {
        guard let first = mask.first else { return true }
        for c in 0..<first.count {
            var seenPlayable = false
            var seenGapAfterPlayable = false
            for r in 0..<mask.count {
                if mask[r][c] {
                    if seenGapAfterPlayable { return false }
                    seenPlayable = true
                } else if seenPlayable {
                    seenGapAfterPlayable = true
                }
            }
        }
        return true
    }
}
