import SwiftUI
import Match3Core

/// Which images from the candy set are used where. Every tile color has its own
/// silhouette, so pieces differ by shape as well as color. The pack has four finishes per
/// piece; the board rotates through them level by level purely for variety (same shapes,
/// same colors, nothing new to learn).
enum CandyArt {
    /// Finish of a piece in the asset pack. Purely cosmetic in this game.
    enum Finish: String, CaseIterable {
        case plain, horizontal, vertical, wrapper
    }

    /// (silhouette, color name) indexed by `TileColor.index`: blue, yellow, red, green, purple, orange.
    private static let pieces: [(shape: String, color: String)] = [
        ("ball", "blue"), ("bean", "yellow"), ("heart", "red"),
        ("triangle", "green"), ("square", "purple"), ("pear", "orange"),
    ]

    static func image(for color: TileColor, finish: Finish = .plain) -> String {
        let p = pieces[color.index]
        return "\(p.shape)_\(p.color)_\(finish.rawValue)"
    }

    /// The plain pieces, indexed by `TileColor.index`.
    static let tileImages = pieces.map { "\($0.shape)_\($0.color)_plain" }

    /// The first levels stay plain so the six shapes settle in; after that the finish
    /// changes every level: plain, striped, wrapped, striped the other way, and round again.
    static func finish(for level: Int) -> Finish {
        guard level > 3 else { return .plain }
        let cycle: [Finish] = [.plain, .horizontal, .wrapper, .vertical]
        return cycle[(level - 4) % cycle.count]
    }

    /// Loads a named candy image. The app uses the asset catalog; the art-rendering tool
    /// swaps this for file loading so views can be previewed outside Xcode.
    static var load: (String) -> Image = { Image($0) }

    static func tileImage(_ color: TileColor) -> Image {
        load(image(for: color))
    }

    /// Decorative pieces (never on the board) for backgrounds and celebrations. The oval
    /// silhouette is not used on the board, so it lives here.
    static let decorations = [
        "blue_swirl", "green_swirl", "orange_swirl", "purple_swirl", "red_swirl", "yellow_swirl",
        "blue_icing", "green_icing", "orange_icing", "purple_icing", "red_icing", "yellow_icing",
        "coconut_wheel_pink", "coconut_wheel_purple", "coconut_wheel_yellow",
        "pink_liquorice", "blue_liquorice", "green_liquorice", "yellow_liquorice", "orange_liquorice", "red_liquorice",
        "milk_chocolate_square", "dark_chocolate_square", "white_chocolate_square",
        "oval_blue_plain", "oval_green_plain", "oval_orange_plain", "oval_purple_plain", "oval_red_plain", "oval_yellow_plain",
    ]

    static let logo = "jazzle"

    /// Everything that may rain down on the Good Job screen: the board pieces in every
    /// finish, the ovals in their wrappers, and the decorations.
    static let rain: [String] =
        pieces.flatMap { p in Finish.allCases.map { "\(p.shape)_\(p.color)_\($0.rawValue)" } }
        + ["blue", "green", "orange", "purple", "red", "yellow"].map { "oval_\($0)_wrapper" }
        + decorations
}
