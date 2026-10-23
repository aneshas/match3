import Foundation

/// A single piece on the board. The `id` is stable for the tile's lifetime so the UI can
/// animate it moving between cells.
public struct Tile: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let color: TileColor

    public init(id: UUID = UUID(), color: TileColor) {
        self.id = id
        self.color = color
    }
}

/// A board position. `row` 0 is the top row, `col` 0 is the leftmost column.
public struct Position: Hashable, Sendable, CustomStringConvertible {
    public let row: Int
    public let col: Int

    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }

    public func offset(_ direction: Direction) -> Position {
        switch direction {
        case .up: return Position(row: row - 1, col: col)
        case .down: return Position(row: row + 1, col: col)
        case .left: return Position(row: row, col: col - 1)
        case .right: return Position(row: row, col: col + 1)
        }
    }

    public func isAdjacent(to other: Position) -> Bool {
        abs(row - other.row) + abs(col - other.col) == 1
    }

    public var description: String { "(\(row),\(col))" }
}

public enum Direction: CaseIterable, Sendable {
    case up, down, left, right
}
