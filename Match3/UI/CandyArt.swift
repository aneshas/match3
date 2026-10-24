import SwiftUI
import Match3Core

/// Which images from the candy set are used where. Every tile color has its own
/// silhouette, so pieces differ by shape as well as color. The pack's finishes mark the
/// special candies: wrapper = wrapped, stripes = striped (along the stripes). Plain
/// candies are always plain, so a finish means exactly one thing on the board.
enum CandyArt {
    /// Finish of a piece in the asset pack.
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

    /// One candy from the coming level, shown at the end of the progress bar as the goal:
    /// a random color from that level's set, in that level's finish.
    struct Preview: Equatable {
        let color: TileColor
        let finish: Finish
        var imageName: String { CandyArt.image(for: color, finish: finish) }

        static func forLevel(_ config: LevelConfig) -> Preview {
            var rng = SeededRandom(seed: config.seed ^ 0xCA4D7)
            let color = TileColor(Int(rng.next() % UInt64(config.colorCount)))
            return Preview(color: color, finish: .plain)
        }
    }

    /// Everything that may rain down on the Good Job screen: the board pieces in every
    /// finish, the ovals in their wrappers, and the decorations.
    static let rain: [String] =
        pieces.flatMap { p in Finish.allCases.map { "\(p.shape)_\(p.color)_\($0.rawValue)" } }
        + ["blue", "green", "orange", "purple", "red", "yellow"].map { "oval_\($0)_wrapper" }
        + decorations
}

extension Power {
    /// The pack's finish that marks each special candy.
    var finish: CandyArt.Finish {
        switch self {
        case .none: return .plain
        case .wrapped: return .wrapper
        case .striped(.horizontal): return .horizontal
        case .striped(.vertical): return .vertical
        }
    }
}
