import AppKit
// probe <png> x y w h : counts pixels darker than 30 and prints the darkest value in the rect
let a = CommandLine.arguments
let rep = NSBitmapImageRep(data: NSImage(contentsOfFile: a[1])!.tiffRepresentation!)!
let x0 = Int(a[2])!, y0 = Int(a[3])!, w = Int(a[4])!, h = Int(a[5])!
var n = 0; var darkest = 255.0
for y in y0..<(y0 + h) { for x in x0..<(x0 + w) {
    guard let c = rep.colorAt(x: x, y: y) else { continue }
    let v = max(c.redComponent, c.greenComponent, c.blueComponent) * 255
    darkest = min(darkest, v); if v < 30 { n += 1 }
} }
print("\(a[1].split(separator: "/").last!) size \(rep.pixelsWide)x\(rep.pixelsHigh) dark \(n) darkest \(Int(darkest))")
