import AVFoundation
import AppKit
import CoreVideo

// preview-clean <in.mp4> <out.mov> <board.png> <goodjob.png> : hides the simulator's camera disc
// (top right, present in every recorded frame) by pasting that region from a clean
// screenshot: the board one while the progress bar is pink, the Good Job one otherwise.
// Output: ProRes 422.
let inURL = URL(fileURLWithPath: CommandLine.arguments[1]), outURL = URL(fileURLWithPath: CommandLine.arguments[2])
let region = (x: 1170, y: 60, w: 170, h: 160)   // the disc, on the 1398x2034 Duo cover capture

let asset = AVURLAsset(url: inURL)
let track = asset.tracks(withMediaType: .video)[0]
let reader = try! AVAssetReader(asset: asset)
let output = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
reader.add(output); reader.startReading()

try? FileManager.default.removeItem(at: outURL)
let writer = try! AVAssetWriter(outputURL: outURL, fileType: .mov)
let size = track.naturalSize
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.proRes422, AVVideoWidthKey: Int(size.width), AVVideoHeightKey: Int(size.height)])
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
writer.add(input); writer.startWriting(); writer.startSession(atSourceTime: .zero)

func regionBytes(_ path: String) -> [UInt8] {
    let rep = NSBitmapImageRep(data: NSImage(contentsOfFile: path)!.tiffRepresentation!)!
    var out = [UInt8](repeating: 255, count: region.w * region.h * 4)
    for row in 0..<region.h { for col in 0..<region.w {
        let c = rep.colorAt(x: region.x + col, y: region.y + row)!
        let i = (row * region.w + col) * 4
        out[i] = UInt8(c.blueComponent * 255); out[i+1] = UInt8(c.greenComponent * 255); out[i+2] = UInt8(c.redComponent * 255); out[i+3] = 255
    } }
    return out
}
let boardPatch = regionBytes(CommandLine.arguments[3]), goodJobPatch = regionBytes(CommandLine.arguments[4])
let barProbe = (x: 140, y: 207)
var disc: (cx: Double, cy: Double, r: Double)? = nil   // pink while a level is being played
var frames = 0, patched = 0, maxDark = 0
var printedSize = false
while let sample = output.copyNextSampleBuffer() {
    guard let pb = CMSampleBufferGetImageBuffer(sample) else { continue }
    let pts = CMSampleBufferGetPresentationTimeStamp(sample)
    CVPixelBufferLockBaseAddress(pb, [])
    let base = CVPixelBufferGetBaseAddress(pb)!.assumingMemoryBound(to: UInt8.self)
    let stride = CVPixelBufferGetBytesPerRow(pb)
    var dark = 0
    for y in region.y..<(region.y + region.h) {
        for x in region.x..<(region.x + region.w) {
            let p = base + y * stride + x * 4
            if p[0] < 30 && p[1] < 30 && p[2] < 30 { dark += 1 }
        }
    }
    maxDark = max(maxDark, dark)
    if !printedSize { print("buffer \(CVPixelBufferGetWidth(pb))x\(CVPixelBufferGetHeight(pb)) stride \(stride) format \(CVPixelBufferGetPixelFormatType(pb))"); printedSize = true }
    if dark > 1500 {
        let bp = base + barProbe.y * stride + barProbe.x * 4
        let pink = bp[2] > 200 && bp[1] < 200 && Int(bp[2]) - Int(bp[1]) > 50 && bp[0] > 100
        let seconds = CMTimeGetSeconds(pts)
        if pink || seconds < 10 {
            // A level is on: the clean board screenshot has the same bar end and bonus candy.
            boardPatch.withUnsafeBufferPointer { src in
                for row in 0..<region.h {
                    memcpy(base + (region.y + row) * stride + region.x * 4, src.baseAddress! + row * region.w * 4, region.w * 4)
                }
            }
        } else {
            // Good Job: only soft background there, so fill the disc itself by interpolating
            // each row between the pixels just outside it (no seam, nothing to match).
            if disc == nil {
                var minX = Int.max, maxX = 0, minY = Int.max, maxY = 0
                for y in region.y..<(region.y + region.h) { for x in region.x..<(region.x + region.w) {
                    let p = base + y * stride + x * 4
                    if p[0] < 30 && p[1] < 30 && p[2] < 30 { minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y) }
                } }
                disc = (cx: Double(minX + maxX) / 2, cy: Double(minY + maxY) / 2, r: Double(max(maxX - minX, maxY - minY)) / 2 + 4)
            }
            let d = disc!
            for y in Int(d.cy - d.r)...Int(d.cy + d.r) {
                let dy = Double(y) - d.cy
                let half = (d.r * d.r - dy * dy).squareRoot()
                guard half.isFinite else { continue }
                let xl = Int(d.cx - half) - 1, xr = Int(d.cx + half) + 1
                let l = base + y * stride + (xl - 2) * 4, rr = base + y * stride + (xr + 2) * 4
                for x in xl...xr {
                    let t = Double(x - xl) / Double(max(1, xr - xl))
                    let p = base + y * stride + x * 4
                    for c in 0..<3 { p[c] = UInt8(Double(l[c]) * (1 - t) + Double(rr[c]) * t) }
                }
            }
        }
        patched += 1
    }
    CVPixelBufferUnlockBaseAddress(pb, [])
    while !input.isReadyForMoreMediaData { usleep(2000) }
    adaptor.append(pb, withPresentationTime: pts)
    frames += 1
}
input.markAsFinished()
let done = DispatchSemaphore(value: 0)
writer.finishWriting { done.signal() }
done.wait()
print("frames \(frames) patched \(patched) maxDark \(maxDark)")
