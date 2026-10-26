import AppKit

// compose-banner <out.png> <width> <height> <capture.png> <candy dir> [seed]
// A text-free landscape banner for the App Store product page header and search results:
// the app's gradient, candies from the pack scattered around, the logo, and a phone capture.
// Nothing important near the edges: the header is cropped to different widths per device.
let a = CommandLine.arguments
let out = a[1], W = Double(a[2])!, H = Double(a[3])!, capturePath = a[4], candyDir = a[5]
var seed: UInt64 = a.count > 6 ? UInt64(a[6])! : 7
func rnd() -> Double { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return Double(seed >> 11) / Double(1 << 53) }

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
let cg = ctx.cgContext

let top = NSColor(red: 1.00, green: 0.97, blue: 0.91, alpha: 1), bottom = NSColor(red: 1.00, green: 0.84, blue: 0.90, alpha: 1)
NSGradient(starting: top, ending: bottom)!.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)
let unit = H / 1000  // everything scales with the height so the three sizes match
for (x, y, r, c) in [(0.08, 0.15, 0.30, NSColor(red: 1.00, green: 0.78, blue: 0.16, alpha: 0.16)),
                     (0.93, 0.85, 0.26, NSColor(red: 0.55, green: 0.80, blue: 1.00, alpha: 0.20)),
                     (0.55, 0.05, 0.18, NSColor(red: 1.00, green: 0.45, blue: 0.65, alpha: 0.16))] as [(Double, Double, Double, NSColor)] {
    c.setFill(); NSBezierPath(ovalIn: NSRect(x: x * W - r * H, y: y * H - r * H, width: 2 * r * H, height: 2 * r * H)).fill()
}

func candy(_ name: String) -> NSImage? { NSImage(contentsOfFile: "\(candyDir)/\(name).imageset/\(name).png") }
func draw(_ img: NSImage, at p: CGPoint, size: Double, angle: Double) {
    cg.saveGState()
    cg.translateBy(x: p.x, y: p.y); cg.rotate(by: angle * .pi / 180)
    cg.setShadow(offset: CGSize(width: 0, height: -8 * unit), blur: 30 * unit, color: NSColor(red: 0.32, green: 0.13, blue: 0.22, alpha: 0.28).cgColor)
    let s = size * img.size.width / max(img.size.width, img.size.height), t = size * img.size.height / max(img.size.width, img.size.height)
    img.draw(in: NSRect(x: -s / 2, y: -t / 2, width: s, height: t), from: .zero, operation: .sourceOver, fraction: 1)
    cg.restoreGState()
}

// The phone capture's frame (right of center) and the logo's centre decide the band the
// scattered candies must stay out of.
let shot = NSImage(contentsOfFile: capturePath)
let phoneH = H * 0.82, phoneW = shot.map { phoneH * $0.size.width / $0.size.height } ?? 0
let phoneRect = NSRect(x: W * 0.56, y: (H - phoneH) / 2, width: phoneW, height: phoneH)
let logoCenter = CGPoint(x: W * 0.36, y: H * 0.5)
let bandLeft = logoCenter.x - 330 * unit, bandRight = phoneRect.maxX + 90 * unit

// Scattered candies on both sides of that band.
let names = ["ball_red_plain", "bean_green_plain", "heart_blue_plain", "triangle_yellow_plain", "square_purple_plain",
             "pear_orange_plain", "oval_blue_plain", "coconut_wheel_pink", "blue_swirl", "green_icing", "heart_red_plain", "bean_yellow_plain",
             "ball_green_plain", "triangle_purple_plain"]
var placed: [CGPoint] = []
for (i, n) in names.enumerated() {
    guard let img = candy(n) else { continue }
    var spot: CGPoint?
    for _ in 0..<120 {
        let p = CGPoint(x: (0.04 + 0.92 * rnd()) * W, y: (0.08 + 0.84 * rnd()) * H)
        let inMiddle = p.x > bandLeft - 90 * unit && p.x < bandRight
        let tooClose = placed.contains { hypot($0.x - p.x, $0.y - p.y) < 240 * unit }
        if !inMiddle && !tooClose { spot = p; break }
    }
    guard let p = spot else { continue }  // no room left (the 3:2 size): leave it out
    placed.append(p)
    draw(img, at: p, size: (120 + 70 * rnd()) * unit, angle: -25 + 50 * rnd() + Double(i % 3) * 5)
}

// Phone capture, right of center, rounded, with a shadow.
if let shot {
    let rect = phoneRect
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: -14 * unit), blur: 60 * unit, color: NSColor(red: 0.32, green: 0.13, blue: 0.22, alpha: 0.35).cgColor)
    NSColor.white.setFill(); NSBezierPath(roundedRect: rect, xRadius: 48 * unit, yRadius: 48 * unit).fill()
    cg.restoreGState()
    cg.saveGState()
    NSBezierPath(roundedRect: rect, xRadius: 48 * unit, yRadius: 48 * unit).addClip()
    shot.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    cg.restoreGState()
}

// The logo, big, left of center, with a soft glow behind it.
if let logo = candy("jazzle") {
    let c = logoCenter
    NSColor.white.withAlphaComponent(0.45).setFill()
    NSBezierPath(ovalIn: NSRect(x: c.x - 300 * unit, y: c.y - 300 * unit, width: 600 * unit, height: 600 * unit)).fill()
    draw(logo, at: c, size: 480 * unit, angle: -8)
}
NSGraphicsContext.restoreGraphicsState()

// No alpha channel: App Store Connect rejects transparency.
let image = rep.cgImage!
let flat = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
                     space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
flat.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, flat.makeImage()!, nil)
CGImageDestinationFinalize(dest)
