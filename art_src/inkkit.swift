import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// The drawing kit for Salt Road's plates: toned laid paper, watercolour washes
// that pool at their edges, and pen work that actually tapers and breaks the way
// a nib does. Nothing here fills a flat polygon and calls it an illustration.

// MARK: - Random

struct RNG {
    var s: UInt64
    init(_ seed: UInt64) { s = seed == 0 ? 0x2545F4914F6CDD1D : seed }
    mutating func next() -> UInt64 { s ^= s << 13; s ^= s >> 7; s ^= s << 17; return s }
    mutating func d() -> Double { Double(next() % 1_000_000) / 1_000_000.0 }
    mutating func r(_ a: Double, _ b: Double) -> Double { a + d() * (b - a) }
    mutating func i(_ a: Int, _ b: Int) -> Int { a + Int(next() % UInt64(max(1, b - a + 1))) }
    mutating func chance(_ p: Double) -> Bool { d() < p }
    /// Smooth-ish noise in -1…1, cheap and good enough for wobble.
    mutating func signed() -> Double { d() * 2 - 1 }
}

/// Seed arithmetic that tolerates negative coordinates.
func u64(_ v: Int) -> UInt64 { UInt64(bitPattern: Int64(v)) }

/// A point from plain Doubles. Spelling the conversion out here keeps the type
/// checker from exploring CGFloat/Double overloads inside every drawing expression.
@inline(__always)
func pnt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }

func inkSeed(_ name: String) -> UInt64 {
    var h: UInt64 = 14695981039346656037
    for b in name.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
    return h
}

// MARK: - Colour

struct Col {
    var r: Double, g: Double, b: Double, a: Double = 1
    func al(_ v: Double) -> Col { Col(r: r, g: g, b: b, a: v) }
    func mix(_ o: Col, _ t: Double) -> Col {
        Col(r: r + (o.r - r) * t, g: g + (o.g - g) * t, b: b + (o.b - b) * t, a: a + (o.a - a) * t)
    }
    func lt(_ t: Double) -> Col { mix(Col(r: 1, g: 1, b: 1, a: a), t) }
    func dk(_ t: Double) -> Col { mix(Col(r: 0, g: 0, b: 0, a: a), t) }
}

let inkSpace = CGColorSpaceCreateDeviceRGB()

func cgc(_ c: Col) -> CGColor {
    CGColor(colorSpace: inkSpace,
            components: [CGFloat(c.r), CGFloat(c.g), CGFloat(c.b), CGFloat(c.a)])!
}

/// The studio palette. Three washes and one ink, and that is the whole set.
enum Ink {
    static let paper      = Col(r: 0.918, g: 0.878, b: 0.796)
    static let paperWarm  = Col(r: 0.937, g: 0.898, b: 0.816)
    static let paperCool  = Col(r: 0.886, g: 0.859, b: 0.796)
    static let sepia      = Col(r: 0.204, g: 0.137, b: 0.086)   // the pen
    static let sepiaSoft  = Col(r: 0.294, g: 0.216, b: 0.145)

    // The kitchen washes. Hand-colouring over the pen, never a substitute for it.
    static let amber      = Col(r: 0.804, g: 0.612, b: 0.310)
    static let rust       = Col(r: 0.663, g: 0.400, b: 0.251)
    static let crimson    = Col(r: 0.647, g: 0.259, b: 0.239)
    static let herb       = Col(r: 0.420, g: 0.510, b: 0.337)
    static let cream      = Col(r: 0.867, g: 0.812, b: 0.678)
    static let umber      = Col(r: 0.451, g: 0.337, b: 0.239)
    static let saffron    = Col(r: 0.855, g: 0.671, b: 0.243)
    static let jade       = Col(r: 0.365, g: 0.541, b: 0.478)
    static let plum       = Col(r: 0.478, g: 0.322, b: 0.427)
    static let ochre      = Col(r: 0.741, g: 0.573, b: 0.290)
    static let char       = Col(r: 0.302, g: 0.267, b: 0.243)
    static let blush      = Col(r: 0.816, g: 0.573, b: 0.522)

    static let glaze      = Col(r: 0.549, g: 0.616, b: 0.639)   // ceramic
    static let wood       = Col(r: 0.612, g: 0.478, b: 0.322)
    static let greenLeaf  = Col(r: 0.400, g: 0.510, b: 0.318)

    static func wash(_ key: String) -> Col {
        switch key {
        case "amber": return amber
        case "rust": return rust
        case "crimson": return crimson
        case "herb": return herb
        case "cream": return cream
        case "umber": return umber
        case "saffron": return saffron
        case "jade": return jade
        case "plum": return plum
        case "ochre": return ochre
        case "char": return char
        case "blush": return blush
        default: return amber
        }
    }
}

// MARK: - Painter

final class Plate {
    let ctx: CGContext
    let w: Double
    let h: Double
    /// Light direction in radians; shadows fall the other way.
    var light: Double = 2.3

    init(_ wi: Int, _ hi: Int) {
        w = Double(wi); h = Double(hi)
        ctx = CGContext(data: nil, width: wi, height: hi, bitsPerComponent: 8,
                        bytesPerRow: wi * 4, space: inkSpace,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        ctx.setShouldAntialias(true)
        ctx.interpolationQuality = .high
    }

    func fillAll(_ c: Col) {
        ctx.setFillColor(cgc(c)); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    }

    func rect(_ x: Double, _ y: Double, _ rw: Double, _ rh: Double, _ c: Col) {
        ctx.setFillColor(cgc(c)); ctx.fill(CGRect(x: x, y: y, width: rw, height: rh))
    }

    func disc(_ x: Double, _ y: Double, _ rad: Double, _ c: Col) {
        ctx.setFillColor(cgc(c))
        ctx.fillEllipse(in: CGRect(x: x - rad, y: y - rad, width: rad * 2, height: rad * 2))
    }

    func ellipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double, _ c: Col) {
        ctx.setFillColor(cgc(c))
        ctx.fillEllipse(in: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2))
    }

    func poly(_ pts: [CGPoint], _ c: Col) {
        guard pts.count > 2 else { return }
        ctx.setFillColor(cgc(c)); ctx.beginPath(); ctx.move(to: pts[0])
        for p in pts.dropFirst() { ctx.addLine(to: p) }
        ctx.closePath(); ctx.fillPath()
    }

    func clip(_ path: CGPath, _ body: () -> Void) {
        guard !path.isEmpty else { return }
        ctx.saveGState(); ctx.beginPath(); ctx.addPath(path); ctx.clip()
        body()
        ctx.restoreGState()
    }

    /// Clip to the intersection of two paths. Shading bands are built by pulling
    /// an outline inward, and on a composite outline that band can fold over
    /// itself — intersecting with the object keeps the hatching on the object.
    func clip(_ outer: CGPath, _ inner: CGPath, _ body: () -> Void) {
        guard !outer.isEmpty, !inner.isEmpty else { return }
        ctx.saveGState()
        ctx.beginPath(); ctx.addPath(outer); ctx.clip()
        ctx.beginPath(); ctx.addPath(inner); ctx.clip()
        body()
        ctx.restoreGState()
    }

    func clipRect(_ r: CGRect, _ body: () -> Void) {
        ctx.saveGState(); ctx.clip(to: r); body(); ctx.restoreGState()
    }

    /// Written as JPEG: the plates are opaque paper and grain, which PNG stores
    /// terribly — the whole set would not fit in an app bundle.
    func write(_ dir: String, _ name: String, quality: Double = 0.86) {
        guard let img = ctx.makeImage() else { return }
        let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).jpg")
        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, img, [
            kCGImageDestinationLossyCompressionQuality: quality
        ] as CFDictionary)
        CGImageDestinationFinalize(dest)
    }
}

// MARK: - Geometry helpers

func polyPath(_ pts: [CGPoint], close: Bool = true) -> CGPath {
    let p = CGMutablePath()
    guard let first = pts.first else { return p }
    p.move(to: first)
    for pt in pts.dropFirst() { p.addLine(to: pt) }
    if close { p.closeSubpath() }
    return p
}

/// Walks a polyline and returns `count` evenly spaced points along it.
func resample(_ pts: [CGPoint], count: Int) -> [CGPoint] {
    guard pts.count > 1, count > 1 else { return pts }
    var lengths: [Double] = [0]
    var total = 0.0
    for i in 1..<pts.count {
        let dx = Double(pts[i].x - pts[i - 1].x), dy = Double(pts[i].y - pts[i - 1].y)
        total += (dx * dx + dy * dy).squareRoot()
        lengths.append(total)
    }
    guard total > 0 else { return pts }
    var out: [CGPoint] = []
    var seg = 1
    for k in 0..<count {
        let target = total * Double(k) / Double(count - 1)
        while seg < lengths.count - 1 && lengths[seg] < target { seg += 1 }
        let l0 = lengths[seg - 1], l1 = lengths[seg]
        let t = l1 > l0 ? (target - l0) / (l1 - l0) : 0
        let a = pts[seg - 1], b = pts[seg]
        out.append(CGPoint(x: a.x + (b.x - a.x) * CGFloat(t),
                           y: a.y + (b.y - a.y) * CGFloat(t)))
    }
    return out
}

// MARK: - Paper

/// Toned laid paper. The same recipe on every plate so the set reads as one book.
func layPaper(_ p: Plate, seed: UInt64, tone: Col = Ink.paper) {
    var rng = RNG(seed)
    p.fillAll(tone)

    // uneven bloom across the sheet, kept faint enough to feel like paper
    for _ in 0..<16 {
        let x = rng.d() * p.w, y = rng.d() * p.h
        let rr = rng.r(p.w * 0.05, p.w * 0.15)
        let warm = rng.chance(0.6)
        if let g = CGGradient(colorsSpace: inkSpace,
                              colors: [cgc(warm ? tone.lt(0.035).al(0.20) : tone.dk(0.030).al(0.16)),
                                       cgc(tone.al(0))] as CFArray,
                              locations: [0, 1]) {
            p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: x, y: y), startRadius: 0,
                                     endCenter: CGPoint(x: x, y: y), endRadius: rr, options: [])
        }
    }

    // laid lines — the close horizontal ribs of handmade paper
    var y = 0.0
    while y < p.h {
        p.rect(0, y, p.w, 1.0, tone.dk(0.055).al(0.34))
        y += rng.r(5.5, 7.2)
    }
    // chain lines — the widely spaced vertical ones
    var x = rng.r(0, 90)
    while x < p.w {
        p.rect(x, 0, 1.4, p.h, tone.lt(0.10).al(0.30))
        x += rng.r(86, 104)
    }

    // fibres
    for _ in 0..<Int(p.w * p.h / 5200) {
        let fx = rng.d() * p.w, fy = rng.d() * p.h
        let a = rng.r(0, 6.283), len = rng.r(3, 13)
        p.ctx.setStrokeColor(cgc(tone.dk(rng.r(0.05, 0.16)).al(rng.r(0.15, 0.4))))
        p.ctx.setLineWidth(rng.r(0.6, 1.3))
        p.ctx.beginPath()
        p.ctx.move(to: CGPoint(x: fx, y: fy))
        p.ctx.addLine(to: CGPoint(x: fx + cos(a) * len, y: fy + sin(a) * len))
        p.ctx.strokePath()
    }

    // a couple of pale old stains
    for _ in 0..<rng.i(1, 3) {
        let sx = rng.d() * p.w, sy = rng.d() * p.h
        let rr = rng.r(p.w * 0.05, p.w * 0.14)
        var ring: [CGPoint] = []
        var a = 0.0
        while a < 6.283 {
            let rad = rr * rng.r(0.82, 1.18)
            ring.append(CGPoint(x: sx + cos(a) * rad, y: sy + sin(a) * rad))
            a += 0.35
        }
        p.poly(ring, Col(r: 0.545, g: 0.463, b: 0.325, a: 0.055))
    }

    // edge tone, as if the sheet has been handled
    if let g = CGGradient(colorsSpace: inkSpace,
                          colors: [cgc(tone.dk(0.14).al(0)), cgc(tone.dk(0.14).al(0.55))] as CFArray,
                          locations: [0.62, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: p.w / 2, y: p.h / 2), startRadius: 0,
                                 endCenter: CGPoint(x: p.w / 2, y: p.h / 2),
                                 endRadius: max(p.w, p.h) * 0.74,
                                 options: [.drawsAfterEndLocation])
    }
}

// MARK: - Wash

/// A watercolour wash: irregular edge, darker pooling where it dried, a little
/// granulation inside, and deliberate misregistration against the pen work.
func wash(_ p: Plate, _ region: [CGPoint], _ colour: Col,
          strength: Double = 0.42, bleed: Double = 6, seed: UInt64) {
    guard region.count > 2 else { return }
    var rng = RNG(seed)

    // wobble the boundary so no edge is ever straight
    var edge: [CGPoint] = []
    for pt in resample(region + [region[0]], count: max(24, region.count * 3)) {
        edge.append(CGPoint(x: pt.x + CGFloat(rng.signed() * bleed),
                            y: pt.y + CGFloat(rng.signed() * bleed)))
    }
    let path = polyPath(edge)

    p.ctx.setFillColor(cgc(colour.al(strength)))
    p.ctx.addPath(path)
    p.ctx.fillPath()

    // the dark rim left as the water retreated
    p.ctx.setStrokeColor(cgc(colour.dk(0.18).al(strength * 0.55)))
    p.ctx.setLineWidth(bleed * 1.6)
    p.ctx.setLineJoin(.round)
    p.ctx.addPath(path)
    p.ctx.strokePath()

    // granulation and a few lifted patches
    p.clip(path) {
        let box = path.boundingBox
        let unit = Double(min(box.width, box.height))
        let count = Int(Double(box.width * box.height) / (unit * unit * 0.5)) + 18
        for _ in 0..<min(140, count) {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let rx = rng.r(unit * 0.020, unit * 0.085)
            let ry = rx * rng.r(0.35, 0.85)
            let darker = rng.chance(0.62)
            p.ellipse(x, y, rx, ry,
                      darker ? colour.dk(0.14).al(strength * 0.13)
                             : colour.lt(0.24).al(strength * 0.10))
        }
    }
}

/// A wash laid under a horizon: sky above, ground below, both irregular.
func washBand(_ p: Plate, from y0: Double, to y1: Double, _ colour: Col,
              strength: Double, seed: UInt64) {
    var rng = RNG(seed)
    var top: [CGPoint] = []
    var x = -20.0
    while x <= p.w + 20 {
        top.append(CGPoint(x: x, y: y1 + CGFloat(rng.signed() * (p.h * 0.012))))
        x += p.w / 22
    }
    var region: [CGPoint] = [CGPoint(x: -20, y: y0)]
    region.append(contentsOf: top)
    region.append(CGPoint(x: p.w + 20, y: y0))
    wash(p, region, colour, strength: strength, bleed: p.h * 0.008, seed: seed &+ 5)
}

// MARK: - Pen

/// A stroke that actually swells and tapers, with a hand's wobble in it.
/// This is the primitive everything else is drawn with.
func penStroke(_ p: Plate, _ pts: [CGPoint], weight: Double, colour: Col = Ink.sepia,
               wobble: Double = 1.1, taper: Bool = true, seed: UInt64 = 7) {
    guard pts.count > 1, weight > 0 else { return }
    var rng = RNG(seed)
    let n = max(10, min(90, Int(weight * 14)))
    let spine = resample(pts, count: n)

    var left: [CGPoint] = []
    var right: [CGPoint] = []
    for i in 0..<spine.count {
        let t = Double(i) / Double(spine.count - 1)
        let a = spine[max(0, i - 1)], b = spine[min(spine.count - 1, i + 1)]
        var tx = Double(b.x - a.x), ty = Double(b.y - a.y)
        let len = (tx * tx + ty * ty).squareRoot()
        if len > 0 { tx /= len; ty /= len } else { tx = 1; ty = 0 }
        let nx = -ty, ny = tx

        // a nib swells in the middle and lifts at both ends
        let swell = taper ? pow(sin(.pi * t), 0.42) : 1.0
        let hw = max(0.35, weight * 0.5 * (0.55 + 0.45 * swell)) * rng.r(0.88, 1.12)
        let off = rng.signed() * wobble

        let cx = Double(spine[i].x) + nx * off
        let cy = Double(spine[i].y) + ny * off
        left.append(CGPoint(x: cx + nx * hw, y: cy + ny * hw))
        right.append(CGPoint(x: cx - nx * hw, y: cy - ny * hw))
    }
    p.poly(left + right.reversed(), colour)
}

/// The same stroke, broken into a few pieces the way a dry nib skips.
func penBroken(_ p: Plate, _ pts: [CGPoint], weight: Double, colour: Col = Ink.sepia,
               pieces: Int = 3, gap: Double = 0.10, wobble: Double = 1.0, seed: UInt64 = 11) {
    var rng = RNG(seed)
    let spine = resample(pts, count: 60)
    var t = 0.0
    var k = 0
    while t < 1.0 {
        let run = rng.r(0.7, 1.3) / Double(max(1, pieces))
        let end = min(1.0, t + run)
        let i0 = Int(t * 59), i1 = Int(end * 59)
        if i1 > i0 + 1 {
            penStroke(p, Array(spine[i0...i1]), weight: weight * rng.r(0.82, 1.12),
                      colour: colour, wobble: wobble, taper: true, seed: seed &+ UInt64(k) &+ 1)
        }
        t = end + rng.r(gap * 0.4, gap * 1.4)
        k += 1
    }
}

/// Outline a shape with a pen, heavier on the side away from the light.
func penContour(_ p: Plate, _ pts: [CGPoint], weight: Double, colour: Col = Ink.sepia,
                seed: UInt64 = 13) {
    guard pts.count > 2 else { return }
    let closed = pts + [pts[0]]
    for i in 0..<(closed.count - 1) {
        let a = closed[i], b = closed[i + 1]
        let ang = atan2(Double(b.y - a.y), Double(b.x - a.x))
        // facing away from the light gets the fat line
        let facing = cos(ang + .pi / 2 - p.light)
        let w = weight * (0.62 + 0.62 * max(0, -facing))
        penStroke(p, [a, b], weight: w, colour: colour, wobble: weight * 0.30,
                  taper: false, seed: seed &+ UInt64(i * 17 + 3))
    }
}

// MARK: - Tone

/// Broken hatching inside a shape. Two calls at different angles gives cross-hatch.
func hatch(_ p: Plate, _ path: CGPath, angle: Double, spacing: Double,
           weight: Double = 1.2, colour: Col = Ink.sepiaSoft,
           coverage: Double = 0.9, seed: UInt64 = 17, bound: CGPath? = nil) {
    var rng = RNG(seed)
    guard !path.isEmpty, spacing > 0.2 else { return }
    let box = path.boundingBox.insetBy(dx: -6, dy: -6)
    guard box.width > 1, box.height > 1, box.width.isFinite, box.height.isFinite else { return }
    let dx = cos(angle), dy = sin(angle)
    let span = Double(box.width + box.height) * 1.2

    let run: (@escaping () -> Void) -> Void = { work in
        if let bound = bound { p.clip(bound, path, work) } else { p.clip(path, work) }
    }

    run {
        var t = -span / 2
        while t < span / 2 {
            if rng.d() <= coverage {
                let cx = Double(box.midX) - dy * t
                let cy = Double(box.midY) + dx * t
                // each rule is drawn as one or two skipping strokes, never edge to edge
                let pieces = rng.i(1, 2)
                var u = -0.5 + rng.r(0, 0.18)
                for k in 0..<pieces {
                    let run = rng.r(0.30, 0.62)
                    let a = CGPoint(x: cx + dx * span * u, y: cy + dy * span * u)
                    let b = CGPoint(x: cx + dx * span * (u + run), y: cy + dy * span * (u + run))
                    penStroke(p, [a, b], weight: weight * rng.r(0.7, 1.25),
                              colour: colour.al(rng.r(0.55, 0.95)),
                              wobble: 0.9, taper: true,
                              seed: seed &+ u64(Int(t) &* 31 &+ k &+ 101))
                    u += run + rng.r(0.05, 0.20)
                }
            }
            t += spacing * rng.r(0.86, 1.18)
        }
    }
}

/// Shade a shape according to the plate's light: one pass, or three where it is darkest.
func shade(_ p: Plate, _ path: CGPath, depth: Int, spacing: Double,
           colour: Col = Ink.sepiaSoft, seed: UInt64 = 23, bound: CGPath? = nil) {
    let base = p.light + .pi / 2
    hatch(p, path, angle: base, spacing: spacing, weight: 1.1, colour: colour,
          coverage: 0.92, seed: seed, bound: bound)
    if depth >= 2 {
        hatch(p, path, angle: base + 1.0, spacing: spacing * 1.15, weight: 1.0,
              colour: colour, coverage: 0.80, seed: seed &+ 71, bound: bound)
    }
    if depth >= 3 {
        hatch(p, path, angle: base - 0.9, spacing: spacing * 1.35, weight: 0.9,
              colour: colour, coverage: 0.65, seed: seed &+ 131, bound: bound)
    }
}

/// Shade a rounded form the way light actually falls on it: a crescent hugging
/// the side turned away from the light, rather than a straight cut down the middle.
func formShade(_ p: Plate, _ pts: [CGPoint], inset: Double, depth: Int, spacing: Double,
               colour: Col = Ink.sepiaSoft, seed: UInt64 = 53) {
    guard pts.count > 3 else { return }
    var cx = 0.0, cy = 0.0
    for pt in pts { cx += Double(pt.x); cy += Double(pt.y) }
    cx /= Double(pts.count); cy /= Double(pts.count)
    let lx = cos(p.light), ly = sin(p.light)

    var outer: [CGPoint] = []
    var inner: [CGPoint] = []
    for pt in pts {
        var dx = Double(pt.x) - cx, dy = Double(pt.y) - cy
        let len = (dx * dx + dy * dy).squareRoot()
        guard len > 0 else { continue }
        dx /= len; dy /= len
        let facing = dx * lx + dy * ly          // +1 toward the light, -1 away
        guard facing < 0.12 else { continue }
        let pull = inset * min(1.0, -facing + 0.12) * 1.4
        outer.append(pt)
        inner.append(CGPoint(x: pt.x - CGFloat(dx * pull), y: pt.y - CGFloat(dy * pull)))
    }
    guard outer.count > 2 else { return }
    let band = outer + inner.reversed()
    // Bounded by the object itself: on a composite outline the band folds over
    // and would otherwise let the hatching run out across the paper.
    shade(p, polyPath(band), depth: depth, spacing: spacing, colour: colour,
          seed: seed, bound: polyPath(pts))
}

/// Stipple — the texture for sand, grit and distant ground.
func stipple(_ p: Plate, _ path: CGPath, density: Double, sizeMin: Double, sizeMax: Double,
             colour: Col = Ink.sepiaSoft, seed: UInt64 = 29) {
    var rng = RNG(seed)
    let box = path.boundingBox
    let count = Int(Double(box.width * box.height) * density)
    p.clip(path) {
        for _ in 0..<max(0, count) {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            p.disc(x, y, rng.r(sizeMin, sizeMax), colour.al(rng.r(0.3, 0.85)))
        }
    }
}

/// Short curved flicks — foliage, fur, grass.
func flicks(_ p: Plate, _ path: CGPath, count: Int, length: Double, weight: Double,
            spread: Double, colour: Col = Ink.sepia, seed: UInt64 = 31) {
    var rng = RNG(seed)
    let box = path.boundingBox
    p.clip(path) {
        for k in 0..<count {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let a = rng.r(-spread, spread) - .pi / 2
            let len = length * rng.r(0.6, 1.4)
            let mid = CGPoint(x: x + cos(a + 0.4) * len * 0.5, y: y - sin(a) * len * 0.5)
            penStroke(p, [CGPoint(x: x, y: y), mid,
                          CGPoint(x: x + cos(a) * len * 0.4, y: y - sin(a) * len)],
                      weight: weight * rng.r(0.7, 1.3), colour: colour,
                      wobble: 0.5, taper: true, seed: seed &+ UInt64(k))
        }
    }
}

/// A cast shadow pooling away from the light under an object standing on the ground.
func castShadow(_ p: Plate, at x: Double, y: Double, width: Double, seed: UInt64 = 37) {
    guard width > 4 else { return }
    let dir = -cos(p.light)
    let cx = x + dir * width * 0.38
    let ring = ellipsePoints(cx: cx, cy: y, rx: width * 0.58, ry: width * 0.11, steps: 26)
    let path = polyPath(ring)
    hatch(p, path, angle: 0.22, spacing: max(2.6, width * 0.014), weight: width * 0.004,
          colour: Ink.sepiaSoft.al(0.42), coverage: 0.85, seed: seed)
}

func ellipsePoints(cx: Double, cy: Double, rx: Double, ry: Double, steps: Int) -> [CGPoint] {
    var out: [CGPoint] = []
    for i in 0..<steps {
        let a = Double(i) / Double(steps) * 6.283185
        out.append(CGPoint(x: cx + cos(a) * rx, y: cy + sin(a) * ry))
    }
    return out
}

/// A wobbled closed blob — the base shape for rocks, dunes, foliage masses.
func blob(cx: Double, cy: Double, rx: Double, ry: Double, rough: Double,
          steps: Int = 26, seed: UInt64 = 41) -> [CGPoint] {
    var rng = RNG(seed)
    var out: [CGPoint] = []
    for i in 0..<steps {
        let a = Double(i) / Double(steps) * 6.283185
        let k = 1.0 + rng.signed() * rough
        out.append(CGPoint(x: cx + cos(a) * rx * k, y: cy + sin(a) * ry * k))
    }
    return out
}
