import AppKit
let dir = CommandLine.arguments[1]; let n = Int(CommandLine.arguments[2])!; let cols = 10
let thumbW: CGFloat = 120; var thumbH: CGFloat = 0
var images: [NSImage] = []
for i in 1...n { if let im = NSImage(contentsOfFile: "\(dir)/gj_\(i).png") { images.append(im) } }
guard let first = images.first else { exit(1) }
thumbH = thumbW * first.size.height / first.size.width
let rows = (images.count + cols - 1) / cols
let sheet = NSImage(size: NSSize(width: thumbW * CGFloat(cols), height: thumbH * CGFloat(rows)))
sheet.lockFocus()
for (i, im) in images.enumerated() {
    let x = CGFloat(i % cols) * thumbW; let y = CGFloat(rows - 1 - i / cols) * thumbH
    im.draw(in: NSRect(x: x, y: y, width: thumbW, height: thumbH))
    let s = NSAttributedString(string: "\(i+1)", attributes: [.font: NSFont.boldSystemFont(ofSize: 14), .foregroundColor: NSColor.red])
    s.draw(at: NSPoint(x: x + 4, y: y + thumbH - 20))
}
sheet.unlockFocus()
let rep = NSBitmapImageRep(data: sheet.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(dir)/sheet.png"))
