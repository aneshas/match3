import AppKit
// px <png> x y [x y ...] : prints RGB at points
let a = CommandLine.arguments
let rep = NSBitmapImageRep(data: NSImage(contentsOfFile: a[1])!.tiffRepresentation!)!
var i = 2
while i + 1 < a.count {
    let c = rep.colorAt(x: Int(a[i])!, y: Int(a[i+1])!)!
    print("\(a[i]),\(a[i+1]) -> \(Int(c.redComponent*255)) \(Int(c.greenComponent*255)) \(Int(c.blueComponent*255))")
    i += 2
}
