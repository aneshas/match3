#!/bin/zsh
# Renders the code-drawn art (jar, sleepy candy, hint arrow) to PNGs for review and writes
# the 1024x1024 app icon into the asset catalog. Needs only Command Line Tools.
#   Tools/render-art.sh [output-dir]
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/Tools/render-out}"
BUILD="$OUT/build"
mkdir -p "$BUILD"
SDK="$(xcrun --show-sdk-path)"
TARGET="arm64-apple-macos14.0"

swiftc -O -sdk "$SDK" -target "$TARGET" -emit-library -emit-module -module-name Match3Core \
  -o "$BUILD/libMatch3Core.dylib" "$ROOT"/Packages/Match3Core/Sources/Match3Core/*.swift

cat > "$BUILD/main.swift" <<'SWIFT'
import SwiftUI
import AppKit
import Match3Core

let root = CommandLine.arguments[1]
let out = CommandLine.arguments[2]

func loadImage(_ name: String) -> Image {
    let path = root + "/Match3/Resources/Assets.xcassets/Candy/\(name).imageset/\(name).png"
    guard let ns = NSImage(contentsOfFile: path) else {
        print("missing image:", path)
        return Image(systemName: "questionmark")
    }
    return Image(nsImage: ns)
}

@MainActor func write<V: View>(_ view: V, _ name: String, size: CGFloat, scale: CGFloat = 1, opaque: Bool = false) {
    let r = ImageRenderer(content: view.frame(width: size, height: size))
    r.scale = scale
    r.isOpaque = opaque  // the App Store rejects a 1024 icon with an alpha channel
    guard let cg = r.cgImage else { print("render failed:", name); return }
    let rep = NSBitmapImageRep(cgImage: cg)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name).png"))
    print("wrote \(name).png \(cg.width)x\(cg.height)")
}

MainActor.assumeIsolated {
    CandyArt.load = loadImage
    let bg = Theme.background
    write(ZStack { bg; SleepyCandyView(animated: false).padding(30) }, "sleepy", size: 400)
    write(ZStack { bg; HStack { HintArrowView(animated: false); HintArrowView(direction: .down, animated: false) }.padding(40) }, "arrows", size: 400)
    write(AppIconView(), "AppIcon", size: 1024, opaque: true)
}
SWIFT

swiftc -O -sdk "$SDK" -target "$TARGET" -I "$BUILD" -L "$BUILD" -lMatch3Core \
  -Xlinker -rpath -Xlinker "$BUILD" \
  "$BUILD/main.swift" "$ROOT/Match3/UI/Theme.swift" "$ROOT/Match3/UI/CandyArt.swift" \
  "$ROOT/Match3/Game/Motion.swift" "$ROOT/Match3/Game/Settings.swift" "$ROOT/Match3/App/DebugFlags.swift" "$ROOT"/Match3/UI/Art/*.swift \
  -o "$BUILD/render"
"$BUILD/render" "$ROOT" "$OUT"

cp "$OUT/AppIcon.png" "$ROOT/Match3/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
echo "App icon written to Assets.xcassets/AppIcon.appiconset/AppIcon.png"
