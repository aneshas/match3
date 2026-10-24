import SwiftUI
import Match3Core

/// Which images from the candy set are used where.
///
/// A board does not have fixed colors: each level plays a `Palette` of candy types, one per
/// `TileColor` index, drawn from the whole pack (7 silhouettes x 6 colors). Within a level
/// every type has its own color and its own shape, so pieces still differ by shape as well
/// as color; from level to level the mix changes and each level brings at least one type
/// the previous level did not have (shown at the end of the progress bar beforehand).
/// The pack's finishes mark the special candies: wrapper = wrapped, stripes = striped.
enum CandyArt {
    /// Finish of a piece in the asset pack.
    enum Finish: String, CaseIterable {
        case plain, horizontal, vertical, wrapper
    }

    enum CandyColor: String, CaseIterable {
        case blue, yellow, red, green, purple, orange

        /// Burst particle color matching the candy's hue.
        var particle: Color {
            switch self {
            case .blue: return Color(red: 0.20, green: 0.65, blue: 0.95)
            case .yellow: return Color(red: 1.00, green: 0.85, blue: 0.20)
            case .red: return Color(red: 0.90, green: 0.20, blue: 0.25)
            case .green: return Color(red: 0.45, green: 0.78, blue: 0.25)
            case .purple: return Color(red: 0.75, green: 0.30, blue: 0.90)
            case .orange: return Color(red: 1.00, green: 0.60, blue: 0.15)
            }
        }
    }

    static let shapes = ["ball", "bean", "heart", "triangle", "square", "pear", "oval"]

    /// One kind of candy: a silhouette in a color.
    struct CandyType: Hashable {
        let shape: String
        let color: CandyColor

        func imageName(_ finish: Finish = .plain) -> String { "\(shape)_\(color.rawValue)_\(finish.rawValue)" }
    }

    /// The candy types a level plays, indexed by `TileColor.index`.
    struct Palette: Equatable {
        let types: [CandyType]

        func type(for color: TileColor) -> CandyType { types[color.index] }
        func imageName(for color: TileColor, power: Power = .none) -> String { type(for: color).imageName(power.finish) }
        func particleColor(for color: TileColor) -> Color { type(for: color).color.particle }

        /// The first type that `previous` did not have (always index 0 when generated with
        /// `random(level:count:avoiding:)`), or the first type when there is no previous level.
        func newType(comparedTo previous: Palette?) -> CandyType {
            guard let previous else { return types[0] }
            return types.first { !previous.types.contains($0) } ?? types[0]
        }

        /// A deterministic random mix for a level: `count` types with distinct colors and
        /// distinct shapes. Slot 0 is guaranteed not to appear in `previous`.
        static func random(level: Int, count: Int, avoiding previous: Palette?) -> Palette {
            var rng = SeededRandom(seed: 0x9A1E77E &+ UInt64(level) &* 2_654_435_761)
            var colors = CandyColor.allCases.shuffled(using: &rng)
            var shapes = CandyArt.shapes.shuffled(using: &rng)
            let count = max(1, min(count, colors.count))

            // The newcomer: a color, then a shape that did not go with it last level. A palette
            // has distinct colors, so at most one shape is ruled out and one always remains.
            let newColor = colors.removeFirst()
            let used = Set(previous?.types.filter { $0.color == newColor }.map(\.shape) ?? [])
            let newShape = shapes.first { !used.contains($0) } ?? shapes[0]
            shapes.removeAll { $0 == newShape }
            var types = [CandyType(shape: newShape, color: newColor)]
            for i in 0..<(count - 1) { types.append(CandyType(shape: shapes[i], color: colors[i])) }
            return Palette(types: types)
        }
    }

    /// The classic six, used wherever there is no level in play (Play screen candies, jar,
    /// sleepy candy, fallback). Indexed like `TileColor`.
    static let tileImages = [
        "ball_blue_plain", "bean_yellow_plain", "heart_red_plain",
        "triangle_green_plain", "square_purple_plain", "pear_orange_plain",
    ]

    /// Loads a named candy image. The app uses the asset catalog; the art-rendering tool
    /// swaps this for file loading so views can be previewed outside Xcode.
    static var load: (String) -> Image = { Image($0) }

    static func tileImage(_ color: TileColor) -> Image {
        load(tileImages[color.index])
    }

    /// Decorative pieces (never on the board) for backgrounds and celebrations.
    static let decorations = [
        "blue_swirl", "green_swirl", "orange_swirl", "purple_swirl", "red_swirl", "yellow_swirl",
        "blue_icing", "green_icing", "orange_icing", "purple_icing", "red_icing", "yellow_icing",
        "coconut_wheel_pink", "coconut_wheel_purple", "coconut_wheel_yellow",
        "pink_liquorice", "blue_liquorice", "green_liquorice", "yellow_liquorice", "orange_liquorice", "red_liquorice",
        "milk_chocolate_square", "dark_chocolate_square", "white_chocolate_square",
    ]

    static let logo = "jazzle"

    /// The candy shown at the end of the progress bar: the next level's newcomer.
    struct Preview: Equatable {
        let type: CandyType
        var imageName: String { type.imageName() }
    }

    /// Everything that may rain down on the Good Job screen: every plain piece in the pack
    /// plus the decorations.
    static let rain: [String] =
        shapes.flatMap { s in CandyColor.allCases.map { "\(s)_\($0.rawValue)_plain" } } + decorations
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
