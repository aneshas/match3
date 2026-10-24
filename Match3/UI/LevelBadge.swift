import SwiftUI

/// The level number, bottom left of the level screen: the same white disc as the home
/// button on the right, with a bold rounded number in candy pink traced by a dark outline.
/// Caregivers asked for it; the player can ignore it, there is nothing to do with it.
struct LevelBadge: View {
    let level: Int

    var body: some View {
        OutlinedText(text: "\(level)",
                     font: .system(size: level >= 100 ? 24 : 30, weight: .heavy, design: .rounded),
                     fill: AnyShapeStyle(LinearGradient(colors: [Theme.pink, Theme.magenta], startPoint: .top, endPoint: .bottom)),
                     outline: Theme.text,
                     width: 2)
            .frame(width: 64, height: 64)
            .background(Color.white.opacity(0.9), in: Circle())
            .overlay(Circle().strokeBorder(Color.white, lineWidth: 3))
            .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Level \(level)")
            .accessibilityIdentifier("level.badge")
    }
}

/// Text with a solid outline: the same string stamped in the outline color at eight
/// offsets underneath the filled text (SwiftUI has no text stroke).
struct OutlinedText: View {
    let text: String
    let font: Font
    let fill: AnyShapeStyle
    let outline: Color
    let width: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) / 8 * 2 * .pi
                Text(text).font(font).foregroundStyle(outline)
                    .offset(x: cos(angle) * width, y: sin(angle) * width)
            }
            Text(text).font(font).foregroundStyle(fill)
        }
        .compositingGroup()
    }
}
