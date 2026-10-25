import AppKit

// compose <out.png> <width> <height> <shot.png> <caption> [cropX cropY cropW cropH]  (caption may be empty)
let a = CommandLine.arguments
let out = a[1], W = Double(a[2])!, H = Double(a[3])!, shotPath = a[4], caption = a[5]
let shot = NSImage(contentsOfFile: shotPath)!
let shotRep = NSBitmapImageRep(data: shot.tiffRepresentation!)!
let fullW = Double(shotRep.pixelsWide), fullH = Double(shotRep.pixelsHigh)
var crop = CGRect(x: 0, y: 0, width: fullW, height: fullH)
if a.count >= 10 { crop = CGRect(x: Double(a[6])!, y: Double(a[7])!, width: Double(a[8])!, height: Double(a[9])!) }
// NSImage draws from a bottom-left rect in its own point size.
let px = Double(shot.size.width) / fullW, py = Double(shot.size.height) / fullH
let fromRect = NSRect(x: crop.minX * px, y: (fullH - crop.maxY) * py, width: crop.width * px, height: crop.height * py)
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
let cg = ctx.cgContext

// Background: the app's cream-to-pink gradient, plus soft candy discs.
let top = NSColor(red: 1.00, green: 0.97, blue: 0.91, alpha: 1), bottom = NSColor(red: 1.00, green: 0.84, blue: 0.90, alpha: 1)
NSGradient(starting: top, ending: bottom)!.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)
let discs: [(Double, Double, Double, NSColor)] = [
    (0.12, 0.10, 0.22, NSColor(red: 1.00, green: 0.78, blue: 0.16, alpha: 0.18)),
    (0.90, 0.18, 0.18, NSColor(red: 1.00, green: 0.45, blue: 0.65, alpha: 0.22)),
    (0.85, 0.92, 0.16, NSColor(red: 0.55, green: 0.80, blue: 1.00, alpha: 0.22)),
    (0.08, 0.80, 0.14, NSColor(red: 0.95, green: 0.22, blue: 0.50, alpha: 0.14)),
]
for (x, y, r, c) in discs {
    c.setFill()
    NSBezierPath(ovalIn: NSRect(x: x * W - r * W, y: y * H - r * W, width: 2 * r * W, height: 2 * r * W)).fill()
}

// Caption: big, rounded, cocoa.
let scale = W / 1320
let font = NSFont.systemFont(ofSize: 92 * scale, weight: .bold)
let rounded = NSFont(descriptor: font.fontDescriptor.withDesign(.rounded)!, size: font.pointSize) ?? font
let para = NSMutableParagraphStyle(); para.alignment = .center; para.lineSpacing = 6 * scale
let attrs: [NSAttributedString.Key: Any] = [.font: rounded, .paragraphStyle: para,
    .foregroundColor: NSColor(red: 0.32, green: 0.13, blue: 0.22, alpha: 1)]
let text = NSAttributedString(string: caption, attributes: attrs)
let margin = 90 * scale
let captionBox = text.boundingRect(with: NSSize(width: W - 2 * margin, height: 600 * scale), options: [.usesLineFragmentOrigin])
let captionTop = H - 150 * scale
var areaTop = H - 110 * scale
if !caption.isEmpty {
    text.draw(with: NSRect(x: margin, y: captionTop - captionBox.height, width: W - 2 * margin, height: captionBox.height), options: [.usesLineFragmentOrigin])
    areaTop = captionTop - captionBox.height - 80 * scale
}

// Screenshot: fit under the caption, rounded corners, soft shadow.
let areaBottom = 110 * scale
let maxW = W - 2 * margin, maxH = areaTop - areaBottom
let sw = crop.width, sh = crop.height
let k = min(maxW / sw, maxH / sh)
let dw = sw * k, dh = sh * k
let rect = NSRect(x: (W - dw) / 2, y: areaBottom + (maxH - dh) / 2, width: dw, height: dh)
cg.saveGState()
cg.setShadow(offset: CGSize(width: 0, height: -18 * scale), blur: 70 * scale, color: NSColor(red: 0.32, green: 0.13, blue: 0.22, alpha: 0.35).cgColor)
NSColor.white.setFill()
NSBezierPath(roundedRect: rect, xRadius: 56 * scale, yRadius: 56 * scale).fill()
cg.restoreGState()
NSBezierPath(roundedRect: rect, xRadius: 56 * scale, yRadius: 56 * scale).addClip()
shot.draw(in: rect, from: fromRect, operation: .sourceOver, fraction: 1)
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
