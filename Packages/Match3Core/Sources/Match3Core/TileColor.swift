import Foundation

/// A tile's color, by index. The app maps an index to an actual color (and later an image).
/// Keeping this as a plain index means the core never knows about rendering.
public struct TileColor: Hashable, Codable, Sendable, CustomStringConvertible {
    public static let maxCount = 6

    public let index: Int

    public init(_ index: Int) {
        precondition(index >= 0 && index < TileColor.maxCount, "color index out of range")
        self.index = index
    }

    public var description: String { "C\(index)" }
}
