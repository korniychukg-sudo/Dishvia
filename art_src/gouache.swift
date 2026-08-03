import Foundation
import CoreGraphics

// The v2 paint box. Opaque gouache laid back-to-front over an ink drawing:
// overlaps occlude the way real paint does, nothing ghosts. Each palette is a
// chord of three tones — shadow, body, light — plus fixed accents that never
// desaturate.

struct Chord {
    var shadow: Col
    var body: Col
    var light: Col

    init(_ r: Double, _ g: Double, _ b: Double) {
        body = Col(r: r, g: g, b: b)
        shadow = body.mix(Col(r: 0.16, g: 0.10, b: 0.10), 0.42)
        light = body.mix(Col(r: 0.99, g: 0.96, b: 0.88), 0.40)
    }

    init(shadow: Col, body: Col, light: Col) {
        self.shadow = shadow; self.body = body; self.light = light
    }
}

enum Paint {
    // The twelve dish palettes, saturated the way gouache actually covers.
    static func chord(_ key: String) -> Chord {
        switch key {
        case "amber":   return Chord(0.855, 0.565, 0.184)
        case "rust":    return Chord(0.753, 0.361, 0.169)
        case "crimson": return Chord(0.725, 0.216, 0.188)
        case "herb":    return Chord(0.373, 0.545, 0.267)
        case "cream":   return Chord(0.910, 0.816, 0.612)
        case "umber":   return Chord(0.482, 0.322, 0.196)
        case "saffron": return Chord(0.933, 0.678, 0.145)
        case "jade":    return Chord(0.271, 0.545, 0.451)
        case "plum":    return Chord(0.545, 0.286, 0.443)
        case "ochre":   return Chord(0.820, 0.588, 0.216)
        case "char":    return Chord(0.298, 0.263, 0.243)
        case "blush":   return Chord(0.878, 0.529, 0.451)
        default:        return Chord(0.855, 0.565, 0.184)
        }
    }

    // Accents that stay vivid regardless of the dish palette.
    static let herbGreen  = Col(r: 0.298, g: 0.502, b: 0.224)
    static let herbDark   = Col(r: 0.196, g: 0.353, b: 0.157)
    static let chiliRed   = Col(r: 0.784, g: 0.184, b: 0.145)
    static let saffron    = Col(r: 0.949, g: 0.706, b: 0.153)
    static let creamWhite = Col(r: 0.957, g: 0.918, b: 0.827)
    static let charBrown  = Col(r: 0.271, g: 0.196, b: 0.145)
    static let sauceDark  = Col(r: 0.376, g: 0.222, b: 0.129)

    // Ceramics and materials.
    static let porcelain  = Chord(shadow: Col(r: 0.671, g: 0.671, b: 0.663),
                                  body:   Col(r: 0.894, g: 0.886, b: 0.855),
                                  light:  Col(r: 0.975, g: 0.968, b: 0.940))
    static let ironPan    = Chord(shadow: Col(r: 0.129, g: 0.118, b: 0.114),
                                  body:   Col(r: 0.253, g: 0.239, b: 0.231),
                                  light:  Col(r: 0.420, g: 0.404, b: 0.392))
    static let terracotta = Chord(shadow: Col(r: 0.478, g: 0.271, b: 0.171),
                                  body:   Col(r: 0.706, g: 0.424, b: 0.263),
                                  light:  Col(r: 0.851, g: 0.612, b: 0.435))
    static let woodBoard  = Chord(shadow: Col(r: 0.412, g: 0.294, b: 0.180),
                                  body:   Col(r: 0.639, g: 0.478, b: 0.302),
                                  light:  Col(r: 0.788, g: 0.643, b: 0.451))
    static let bamboo     = Chord(shadow: Col(r: 0.557, g: 0.443, b: 0.239),
                                  body:   Col(r: 0.773, g: 0.647, b: 0.396),
                                  light:  Col(r: 0.882, g: 0.792, b: 0.573))
    static let leafGreen  = Chord(shadow: Col(r: 0.239, g: 0.376, b: 0.196),
                                  body:   Col(r: 0.376, g: 0.545, b: 0.271),
                                  light:  Col(r: 0.545, g: 0.686, b: 0.376))
    static let glassBlue  = Chord(shadow: Col(r: 0.557, g: 0.647, b: 0.671),
                                  body:   Col(r: 0.741, g: 0.812, b: 0.820),
                                  light:  Col(r: 0.894, g: 0.933, b: 0.933))
    static let paperWrap  = Chord(shadow: Col(r: 0.706, g: 0.647, b: 0.545),
                                  body:   Col(r: 0.878, g: 0.831, b: 0.729),
                                  light:  Col(r: 0.949, g: 0.918, b: 0.847))

    /// A vessel glaze tinted faintly toward the dish palette, so the ceramics
    /// belong to the plate without stealing its colour.
    static func glaze(_ paletteKey: String) -> Chord {
        let c = chord(paletteKey)
        return Chord(shadow: porcelain.shadow.mix(c.shadow, 0.14),
                     body: porcelain.body.mix(c.body, 0.10),
                     light: porcelain.light.mix(c.light, 0.06))
    }
}

// MARK: - Opaque paint

/// Fill a region with body paint: opaque, slightly uneven the way a loaded
/// brush covers, pooled darker at the boundary.
func gouache(_ p: Plate, _ region: [CGPoint], _ tone: Col,
             unevenness: Double = 0.10, edgeDark: Double = 0.14, seed: UInt64) {
    guard region.count > 2 else { return }
    var rng = RNG(seed)
    let path = polyPath(region)

    p.ctx.setFillColor(cgc(tone))
    p.ctx.addPath(path)
    p.ctx.fillPath()

    p.clip(path) {
        let box = path.boundingBox
        guard box.width > 2, box.height > 2 else { return }
        let unit = Double(min(box.width, box.height))
        // brush unevenness: broad soft patches a touch lighter and darker
        let patches = max(6, Int(Double(box.width * box.height) / (unit * unit) * 9))
        for _ in 0..<min(60, patches) {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let rx = unit * rng.r(0.10, 0.30)
            let lighter = rng.chance(0.5)
            let delta = rng.r(0.03, unevenness)
            p.ellipse(x, y, rx, rx * rng.r(0.5, 0.9),
                      (lighter ? tone.lt(delta) : tone.dk(delta)).al(rng.r(0.25, 0.5)))
        }
        // dry-brush flecks where the paper tooth shows
        for _ in 0..<Int(Double(box.width * box.height) / 2600) {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            p.disc(x, y, rng.r(0.5, 1.4), tone.lt(rng.r(0.10, 0.22)).al(rng.r(0.2, 0.45)))
        }
    }
    // the pooled edge
    p.ctx.setStrokeColor(cgc(tone.dk(edgeDark).al(0.75)))
    p.ctx.setLineWidth(CGFloat(max(1.2, Double(min(path.boundingBox.width,
                                                   path.boundingBox.height)) * 0.012)))
    p.ctx.setLineJoin(.round)
    p.ctx.addPath(path)
    p.ctx.strokePath()
}

/// Paint a rounded form with its full chord: body everywhere, shadow crescent
/// away from the light, a lit crescent toward it. Opaque, so it can sit on top
/// of anything already painted.
func gouacheForm(_ p: Plate, _ pts: [CGPoint], _ chord: Chord,
                 depth: Double = 1.0, seed: UInt64) {
    guard pts.count > 3 else { return }
    gouache(p, pts, chord.body, seed: seed)

    var cx = 0.0, cy = 0.0
    for pt in pts { cx += Double(pt.x); cy += Double(pt.y) }
    cx /= Double(pts.count); cy /= Double(pts.count)
    let lx = cos(p.light), ly = sin(p.light)
    let path = polyPath(pts)

    func crescent(_ facingSign: Double, _ pull: Double) -> [CGPoint] {
        var outer: [CGPoint] = []
        var inner: [CGPoint] = []
        for pt in pts {
            var dx = Double(pt.x) - cx, dy = Double(pt.y) - cy
            let len = (dx * dx + dy * dy).squareRoot()
            guard len > 0 else { continue }
            dx /= len; dy /= len
            let facing = (dx * lx + dy * ly) * facingSign
            guard facing > 0.10 else { continue }
            outer.append(pt)
            let k = pull * min(1.0, facing + 0.15)
            inner.append(CGPoint(x: pt.x - CGFloat(dx * len * k),
                                 y: pt.y - CGFloat(dy * len * k)))
        }
        guard outer.count > 2 else { return [] }
        return outer + inner.reversed()
    }

    let shade = crescent(-1, 0.42 * depth)
    if shade.count > 2 {
        p.clip(path) {
            gouache(p, shade, chord.shadow, unevenness: 0.06, edgeDark: 0.05,
                    seed: seed &+ 7)
        }
    }
    let lit = crescent(1, 0.26 * depth)
    if lit.count > 2 {
        p.clip(path) {
            gouache(p, lit, chord.light, unevenness: 0.06, edgeDark: 0.03,
                    seed: seed &+ 13)
        }
    }
}

/// The ink pass over painted form: contour heavier on the shadow side, and a
/// few broken hatch strokes tucked into the shadow only.
func inkOver(_ p: Plate, _ pts: [CGPoint], weight: Double,
             hatchShadow: Bool = true, seed: UInt64) {
    penContour(p, pts, weight: weight, colour: Ink.sepia, seed: seed)
    guard hatchShadow, pts.count > 3 else { return }
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
        guard dx * lx + dy * ly < -0.25 else { continue }
        outer.append(pt)
        inner.append(CGPoint(x: pt.x - CGFloat(dx * len * 0.24),
                             y: pt.y - CGFloat(dy * len * 0.24)))
    }
    if outer.count > 2 {
        hatch(p, polyPath(outer + inner.reversed()), angle: p.light + .pi / 2,
              spacing: max(3.0, weight * 3.4), weight: weight * 0.55,
              colour: Ink.sepia.al(0.38), coverage: 0.7, seed: seed &+ 31,
              bound: polyPath(pts))
    }
}

/// A grounded cast shadow: one opaque soft-edged pool, not hatching.
func groundShadow(_ p: Plate, at x: Double, y: Double, width: Double,
                  tone: Col, seed: UInt64) {
    guard width > 4 else { return }
    let dir = -cos(p.light)
    let ring = blob(cx: x + dir * width * 0.22, cy: y,
                    rx: width * 0.56, ry: width * 0.105,
                    rough: 0.06, steps: 26, seed: seed)
    gouache(p, ring, tone, unevenness: 0.04, edgeDark: 0.02, seed: seed &+ 3)
}

/// Small opaque blob — one olive, one crumb, one petal. The unit of garnish.
func dab(_ p: Plate, x: Double, y: Double, rx: Double, ry: Double,
         _ tone: Col, tilt: Double = 0, outline: Double = 0, seed: UInt64 = 5) {
    var pts: [CGPoint] = []
    var rng = RNG(seed)
    for k in 0..<12 {
        let a = Double(k) / 12.0 * 6.283185
        let w = 1.0 + rng.signed() * 0.12
        let px = cos(a) * rx * w, py = sin(a) * ry * w
        pts.append(CGPoint(x: x + px * cos(tilt) - py * sin(tilt),
                           y: y + px * sin(tilt) + py * cos(tilt)))
    }
    p.poly(pts, tone)
    if outline > 0 {
        penContour(p, pts, weight: outline, colour: Ink.sepia.al(0.7), seed: seed &+ 3)
    }
}
