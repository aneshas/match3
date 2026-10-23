import SwiftUI
import Match3Core

/// Which images from the candy set are used where. Every tile color has its own
/// silhouette, so pieces differ by shape as well as color.
enum CandyArt {
    /// Indexed by `TileColor.index`: blue, yellow, red, green, purple, orange.
    static let tileImages = [
        "ball_blue_plain",
        "bean_yellow_plain",
        "heart_red_plain",
        "triangle_green_plain",
        "square_purple_plain",
        "pear_orange_plain",
    ]

    static func image(for color: TileColor) -> String {
        tileImages[color.index]
    }

    /// Loads a named candy image. The app uses the asset catalog; the art-rendering tool
    /// swaps this for file loading so views can be previewed outside Xcode.
    static var load: (String) -> Image = { Image($0) }

    static func tileImage(_ color: TileColor) -> Image {
        load(image(for: color))
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

    /// Everything that may rain down on the Good Job screen.
    static let rain = tileImages + decorations
}
