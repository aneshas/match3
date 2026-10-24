import Foundation

/// A single piece on the board. The `id` is stable for the tile's lifetime so the UI can
/// animate it moving between cells.
public struct Tile: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let color: TileColor
    /// Special candy, if any. Matches by color exactly like a plain candy; the power only
    /// changes what gets cleared when it is matched.
    public var power: Power

    public init(id: UUID = UUID(), color: TileColor, power: Power = .none) {
        self.id = id
        self.color = color
        self.power = power
    }
}

public enum LineAxis: Hashable, Sendable {
    case horizontal, vertical
}

/// Special candies. They are never required: a level is finished by ordinary matches, and
/// a special candy is still a normal candy of its color if the player ignores it.
public enum Power: Hashable, Sendable {
    case none
    /// Earned by a match of four (or an L/T). When matched it also bursts its 8 neighbors.
    case wrapped
    /// Earned by five in a line. When matched it clears its whole row (horizontal stripes)
    /// or column (vertical stripes).
    case striped(LineAxis)
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
