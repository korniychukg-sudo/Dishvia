import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// The app icon: an abstract struck seal, not a picture of food. Opaque RGB with
// no alpha channel — App Store Connect rejects an icon that carries one.
// Build:  swiftc -O icongen.swift -o icongen && ./icongen <out.png>

let side = 1024
let space = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8,
                    bytesPerRow: side * 4, space: space,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setShouldAntialias(true)
ctx.interpolationQuality = .high

func col(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: space, components: [CGFloat(r), CGFloat(g), CGFloat(b), CGFloat(a)])!
}

let W = Double(side)
let mid = W / 2

// A deep buckram field with a warm bloom behind the seal.
ctx.setFillColor(col(0.118, 0.145, 0.129))
ctx.fill(CGRect(x: 0, y: 0, width: W, height: W))
if let g = CGGradient(colorsSpace: space,
                      colors: [col(0.243, 0.259, 0.216, 1), col(0.106, 0.129, 0.118, 1)] as CFArray,
                      locations: [0, 1]) {
    ctx.drawRadialGradient(g, startCenter: CGPoint(x: mid, y: W * 0.58), startRadius: 0,
                           endCenter: CGPoint(x: mid, y: W * 0.58), endRadius: W * 0.72,
                           options: [.drawsAfterEndLocation])
}

var state: UInt64 = 0x5D_EE_CA_FE_BA_BE_00_11
func rnd() -> Double {
    state ^= state << 13; state ^= state >> 7; state ^= state << 17
    return Double(state % 1_000_000) / 1_000_000.0
}

// cloth grain, very faint
for _ in 0..<24_000 {
    let x = rnd() * W, y = rnd() * W
    let long = rnd() < 0.5
    ctx.setFillColor(col(1, 1, 1, 0.012 + rnd() * 0.020))
    ctx.fill(CGRect(x: x, y: y, width: long ? 3 + rnd() * 5 : 1.2,
                    height: long ? 1.2 : 3 + rnd() * 5))
}

// The seal: a gilt disc with a raised rim and a plain engine-turned centre.
let goldHi = col(0.882, 0.792, 0.541)
let gold = col(0.769, 0.639, 0.373)
let goldLo = col(0.541, 0.427, 0.216)

func ring(_ radius: Double, _ width: Double, _ colour: CGColor) {
    ctx.setStrokeColor(colour)
    ctx.setLineWidth(CGFloat(width))
    ctx.strokeEllipse(in: CGRect(x: mid - radius, y: mid - radius,
                                 width: radius * 2, height: radius * 2))
}

let R = W * 0.290
if let g = CGGradient(colorsSpace: space,
                      colors: [goldHi, gold, goldLo] as CFArray,
                      locations: [0, 0.55, 1]) {
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: mid - R, y: mid - R, width: R * 2, height: R * 2))
    ctx.clip()
    ctx.drawLinearGradient(g, start: CGPoint(x: mid - R * 0.7, y: mid + R * 0.9),
                           end: CGPoint(x: mid + R * 0.8, y: mid - R * 0.9), options: [])
    ctx.restoreGState()
}
ring(R * 0.995, W * 0.014, col(0.376, 0.294, 0.145, 0.85))
ring(R * 0.855, W * 0.010, col(0.396, 0.310, 0.157, 0.55))
ring(R * 0.800, W * 0.006, col(0.925, 0.855, 0.647, 0.55))

// An engine-turned rosette in the middle — the guilloche of a document, abstract
// enough that it says "sealed and stamped" without saying what the app is about.
ctx.setLineWidth(W * 0.0032)
ctx.setStrokeColor(col(0.318, 0.239, 0.110, 0.55))
var first = true
ctx.beginPath()
var t = 0.0
while t < 6.283185 * 9 {
    let rr = R * 0.60 * (0.62 + 0.38 * cos(t * 7.4))
    let x = mid + cos(t) * rr
    let y = mid + sin(t) * rr
    if first { ctx.move(to: CGPoint(x: x, y: y)); first = false }
    else { ctx.addLine(to: CGPoint(x: x, y: y)) }
    t += 0.006
}
ctx.strokePath()

// A small raised boss at the centre, and three pips around it.
if let g = CGGradient(colorsSpace: space, colors: [goldHi, goldLo] as CFArray,
                      locations: [0, 1]) {
    ctx.saveGState()
    let br = R * 0.185
    ctx.addEllipse(in: CGRect(x: mid - br, y: mid - br, width: br * 2, height: br * 2))
    ctx.clip()
    ctx.drawLinearGradient(g, start: CGPoint(x: mid - br, y: mid + br),
                           end: CGPoint(x: mid + br, y: mid - br), options: [])
    ctx.restoreGState()
}
ring(R * 0.185, W * 0.006, col(0.361, 0.278, 0.129, 0.7))

for k in 0..<3 {
    let a = Double(k) / 3.0 * 6.283185 - 1.2
    let pr = W * 0.020
    let px = mid + cos(a) * R * 1.36
    let py = mid + sin(a) * R * 1.36
    ctx.setFillColor(col(0.827, 0.729, 0.463, 0.85))
    ctx.fillEllipse(in: CGRect(x: px - pr, y: py - pr, width: pr * 2, height: pr * 2))
}

// The shine across the seal.
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: mid - R, y: mid - R, width: R * 2, height: R * 2))
ctx.clip()
if let g = CGGradient(colorsSpace: space,
                      colors: [col(1, 1, 1, 0.22), col(1, 1, 1, 0)] as CFArray,
                      locations: [0, 1]) {
    ctx.drawRadialGradient(g, startCenter: CGPoint(x: mid - R * 0.34, y: mid + R * 0.40),
                           startRadius: 0,
                           endCenter: CGPoint(x: mid - R * 0.34, y: mid + R * 0.40),
                           endRadius: R * 1.05, options: [])
}
ctx.restoreGState()

// Vignette so the seal sits in the cloth rather than on it.
if let g = CGGradient(colorsSpace: space,
                      colors: [col(0, 0, 0, 0), col(0, 0, 0, 0.42)] as CFArray,
                      locations: [0.52, 1]) {
    ctx.drawRadialGradient(g, startCenter: CGPoint(x: mid, y: mid), startRadius: 0,
                           endCenter: CGPoint(x: mid, y: mid), endRadius: W * 0.78,
                           options: [.drawsAfterEndLocation])
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon-1024.png"
guard let img = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL,
                                                 UTType.png.identifier as CFString, 1, nil) else {
    exit(1)
}
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out)")
