import SwiftUI

/// The app icon: the big jazzle candy on the theme gradient with a soft glow. Rendered to
/// a 1024x1024 PNG by `Tools/render-art.sh`; iOS applies the rounded mask itself.
struct AppIconView: View {
    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width
            ZStack {
                LinearGradient(colors: [Theme.backgroundTop, Theme.backgroundBottom, Theme.pink.opacity(0.9)],
                               startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [Color.white.opacity(0.75), .clear], center: .center, startRadius: 0, endRadius: s * 0.45)
                    .frame(width: s, height: s)
                CandyArt.load(CandyArt.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: s * 0.72, height: s * 0.72)
                    .shadow(color: Color(red: 0.45, green: 0.12, blue: 0.25).opacity(0.35), radius: s * 0.035, y: s * 0.03)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
