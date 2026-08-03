import Foundation
import CoreGraphics

// The thing the food is served on. Every vessel is drawn — thrown ceramic gets a
// wheel line and a foot ring, wood gets grain, basketry gets a weave — and each
// hands back the patch of the plate the food is allowed to occupy.

struct Bed {
    var cx: Double
    var cy: Double
    var rx: Double
    var ry: Double
    /// Food is clipped to this so nothing floats off the rim.
    var clip: CGPath
    /// Vertical vessels (a glass) want their contents stacked, not spread.
    var upright: Bool = false
    /// Drawn again after the food so the near lip reads in front of it.
    var overdraw: () -> Void = {}
}

// MARK: - Rim motifs

/// Walks a band and hands each step its point and the tangent there.
func aroundEllipse(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double,
                   count: Int, body: (Int, Double, CGPoint, Double) -> Void) {
    guard count > 0 else { return }
    for i in 0..<count {
        let a = Double(i) / Double(count) * 6.283185307
        let p = CGPoint(x: cx + cos(a) * rx, y: cy + sin(a) * ry)
        let t = atan2(cos(a) * ry, -sin(a) * rx)
        body(i, a, p, t)
    }
}

func ringPoints(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, steps: Int = 96) -> [CGPoint] {
    ellipsePoints(cx: cx, cy: cy, rx: rx, ry: ry, steps: steps)
}

enum RimMotif: Int, CaseIterable {
    case meander, wave, sawtooth, dots, doubleLine, vine, lattice, arabesque
    case chevron, scallop, floret, rays, braid, checker, pearls, crescents

    static func forKey(_ key: String) -> RimMotif {
        let all = RimMotif.allCases
        return all[Int(inkSeed(key) % UInt64(all.count))]
    }
}

/// The decorated band between the outer edge and the well.
func drawRim(_ p: Plate, cx: Double, cy: Double, rx: Double, ry: Double,
             motif: RimMotif, colour: Col, seed: UInt64) {
    var rng = RNG(seed)
    let unit = min(rx, ry)
    let w = max(0.9, unit * 0.020)

    switch motif {
    case .doubleLine:
        for k in [0.0, 1.0] {
            let f = 1.0 - k * 0.13
            penStroke(p, ringPoints(cx, cy, rx * f, ry * f) + [CGPoint(x: cx + rx * f, y: cy)],
                      weight: w * (k == 0 ? 1.3 : 0.8), colour: colour, wobble: w * 0.7,
                      taper: false, seed: seed &+ UInt64(k * 31 + 5))
        }

    case .dots:
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 46) { i, _, pt, _ in
            p.disc(Double(pt.x), Double(pt.y), unit * (i % 4 == 0 ? 0.020 : 0.012),
                   colour.al(rng.r(0.65, 1.0)))
        }

    case .pearls:
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 34) { _, _, pt, _ in
            let r = unit * rng.r(0.016, 0.024)
            p.disc(Double(pt.x), Double(pt.y), r, colour.al(0.85))
            p.disc(Double(pt.x) - r * 0.3, Double(pt.y) + r * 0.3, r * 0.35, Ink.paper.al(0.5))
        }

    case .wave:
        var pts: [CGPoint] = []
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 160) { i, _, pt, t in
            let nx = -sin(t), ny = cos(t)
            let s = sin(Double(i) / 160.0 * 6.283185 * 14) * unit * 0.030
            pts.append(CGPoint(x: Double(pt.x) + nx * s, y: Double(pt.y) + ny * s))
        }
        pts.append(pts[0])
        penStroke(p, pts, weight: w * 1.1, colour: colour, wobble: w * 0.5, taper: false, seed: seed)

    case .sawtooth:
        var pts: [CGPoint] = []
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 120) { i, _, pt, t in
            let nx = -sin(t), ny = cos(t)
            let s = (Double(i % 6) / 5.0 - 0.5) * unit * 0.055
            pts.append(CGPoint(x: Double(pt.x) + nx * s, y: Double(pt.y) + ny * s))
        }
        pts.append(pts[0])
        penStroke(p, pts, weight: w, colour: colour, wobble: w * 0.4, taper: false, seed: seed)

    case .chevron:
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 30) { _, _, pt, t in
            let nx = -sin(t), ny = cos(t)
            let dx = cos(t), dy = sin(t)
            let l = unit * 0.038
            let bx = Double(pt.x), by = Double(pt.y)
            let a = CGPoint(x: bx - dx * l - nx * l * 0.7, y: by - dy * l - ny * l * 0.7)
            let b = CGPoint(x: bx + nx * l * 0.7, y: by + ny * l * 0.7)
            let c = CGPoint(x: bx + dx * l - nx * l * 0.7, y: by + dy * l - ny * l * 0.7)
            penStroke(p, [a, b, c], weight: w * 0.95, colour: colour, wobble: w * 0.4,
                      taper: false, seed: seed &+ u64(Int(bx)))
        }

    case .meander:
        // a Greek key, laid down step by step around the band
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 22) { _, _, pt, t in
            let dx = cos(t), dy = sin(t)
            let nx = -sin(t), ny = cos(t)
            let s = unit * 0.030
            let bx = Double(pt.x), by = Double(pt.y)
            func at(_ u: Double, _ v: Double) -> CGPoint {
                CGPoint(x: bx + dx * u * s + nx * v * s, y: by + dy * u * s + ny * v * s)
            }
            penStroke(p, [at(-1.4, -1), at(1.4, -1), at(1.4, 1), at(0, 1), at(0, 0), at(0.7, 0)],
                      weight: w * 0.85, colour: colour, wobble: w * 0.3, taper: false,
                      seed: seed &+ u64(Int(abs(by))))
        }

    case .lattice:
        for k in 0..<2 {
            let f = 1.0 - Double(k) * 0.11
            penStroke(p, ringPoints(cx, cy, rx * f, ry * f) + [CGPoint(x: cx + rx * f, y: cy)],
                      weight: w * 0.75, colour: colour.al(0.8), wobble: w * 0.4,
                      taper: false, seed: seed &+ UInt64(k))
        }
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 40) { i, _, pt, t in
            let nx = -sin(t), ny = cos(t)
            let dx = cos(t), dy = sin(t)
            let s = unit * 0.045
            let lean: Double = i % 2 == 0 ? 1 : -1
            let bx = Double(pt.x), by = Double(pt.y)
            let a = CGPoint(x: bx + nx * s * 0.55 - dx * s * 0.4 * lean,
                            y: by + ny * s * 0.55 - dy * s * 0.4 * lean)
            let b = CGPoint(x: bx - nx * s * 0.55 + dx * s * 0.4 * lean,
                            y: by - ny * s * 0.55 + dy * s * 0.4 * lean)
            penStroke(p, [a, b], weight: w * 0.7, colour: colour.al(0.85), wobble: w * 0.3,
                      taper: false, seed: seed &+ UInt64(i))
        }

    case .vine:
        var spine: [CGPoint] = []
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 150) { i, _, pt, t in
            let n = CGPoint(x: CGFloat(-sin(t)), y: CGFloat(cos(t)))
            let s = sin(Double(i) / 150.0 * 6.283185 * 9) * unit * 0.024
            spine.append(CGPoint(x: pt.x + n.x * CGFloat(s), y: pt.y + n.y * CGFloat(s)))
        }
        spine.append(spine[0])
        penStroke(p, spine, weight: w * 0.9, colour: colour, wobble: w * 0.4, taper: false, seed: seed)
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 18) { i, _, pt, t in
            let nx = -sin(t), ny = cos(t)
            let dx = cos(t), dy = sin(t)
            let s = unit * 0.040
            let side: Double = i % 2 == 0 ? 1 : -1
            let bx = Double(pt.x), by = Double(pt.y)
            let tipX = bx + nx * s * side + dx * s * 0.5
            let tipY = by + ny * s * side + dy * s * 0.5
            let midX = (bx + tipX) * 0.5
            let midY = (by + tipY) * 0.5
            let leaf = [CGPoint(x: bx, y: by),
                        CGPoint(x: midX + nx * s * 0.35 * side, y: midY + ny * s * 0.35 * side),
                        CGPoint(x: tipX, y: tipY),
                        CGPoint(x: midX - dx * s * 0.25, y: midY - dy * s * 0.25)]
            p.poly(leaf, colour.al(0.55))
            penContour(p, leaf, weight: w * 0.55, colour: colour, seed: seed &+ UInt64(i))
        }

    case .arabesque:
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 26) { i, _, pt, t in
            let nx = -sin(t), ny = cos(t)
            let dx = cos(t), dy = sin(t)
            let s = unit * 0.042
            let bx = Double(pt.x), by = Double(pt.y)
            let flip: Double = i % 2 == 0 ? 1.0 : -1.0
            var arc: [CGPoint] = []
            for k in 0...10 {
                let u = Double(k) / 10.0
                let along = (u - 0.5) * s * 2.6
                let across = sin(u * .pi) * flip * s * 0.8
                arc.append(CGPoint(x: bx + dx * along + nx * across,
                                   y: by + dy * along + ny * across))
            }
            penStroke(p, arc, weight: w * 0.8, colour: colour, wobble: w * 0.3,
                      taper: true, seed: seed &+ UInt64(i))
        }

    case .scallop:
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 24) { i, _, pt, t in
            let nx = -sin(t), ny = cos(t)
            let dx = cos(t), dy = sin(t)
            let s = unit * 0.046
            let bx = Double(pt.x), by = Double(pt.y)
            var arc: [CGPoint] = []
            for k in 0...12 {
                let u = Double(k) / 12.0
                let along = (u - 0.5) * s * 2.2
                let across = sin(u * .pi) * s
                arc.append(CGPoint(x: bx + dx * along - nx * across,
                                   y: by + dy * along - ny * across))
            }
            penStroke(p, arc, weight: w * 0.9, colour: colour, wobble: w * 0.3,
                      taper: false, seed: seed &+ UInt64(i))
        }

    case .floret:
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 16) { i, _, pt, _ in
            let s = unit * 0.028
            for k in 0..<5 {
                let a = Double(k) / 5.0 * 6.283185 + Double(i) * 0.3
                p.ellipse(Double(pt.x) + cos(a) * s * 0.7, Double(pt.y) + sin(a) * s * 0.7,
                          s * 0.42, s * 0.30, colour.al(0.62))
            }
            p.disc(Double(pt.x), Double(pt.y), s * 0.30, colour.al(0.9))
        }

    case .rays:
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 56) { i, _, pt, t in
            let nx = -sin(t), ny = cos(t)
            let s = unit * (i % 4 == 0 ? 0.062 : 0.036)
            let bx = Double(pt.x), by = Double(pt.y)
            let a = CGPoint(x: bx + nx * s * 0.5, y: by + ny * s * 0.5)
            let b = CGPoint(x: bx - nx * s * 0.5, y: by - ny * s * 0.5)
            penStroke(p, [a, b], weight: w * (i % 4 == 0 ? 1.0 : 0.7), colour: colour.al(0.85),
                      wobble: w * 0.3, taper: true, seed: seed &+ UInt64(i))
        }

    case .braid:
        for lane in 0..<2 {
            var pts: [CGPoint] = []
            let ph = Double(lane) * .pi
            aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 170) { i, _, pt, t in
                let nx = -sin(t), ny = cos(t)
                let s = sin(Double(i) / 170.0 * 6.283185 * 11 + ph) * unit * 0.030
                pts.append(CGPoint(x: Double(pt.x) + nx * s, y: Double(pt.y) + ny * s))
            }
            pts.append(pts[0])
            penStroke(p, pts, weight: w * 0.85, colour: colour.al(lane == 0 ? 1.0 : 0.72),
                      wobble: w * 0.35, taper: false, seed: seed &+ UInt64(lane * 17))
        }

    case .checker:
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 36) { i, _, pt, t in
            guard i % 2 == 0 else { return }
            let nx = -sin(t), ny = cos(t)
            let dx = cos(t), dy = sin(t)
            let s = unit * 0.030
            let bx = Double(pt.x), by = Double(pt.y)
            let q = [CGPoint(x: bx + dx * s + nx * s, y: by + dy * s + ny * s),
                     CGPoint(x: bx - dx * s + nx * s, y: by - dy * s + ny * s),
                     CGPoint(x: bx - dx * s - nx * s, y: by - dy * s - ny * s),
                     CGPoint(x: bx + dx * s - nx * s, y: by + dy * s - ny * s)]
            hatch(p, polyPath(q), angle: 0.7, spacing: max(1.6, unit * 0.010), weight: w * 0.6,
                  colour: colour.al(0.8), coverage: 0.95, seed: seed &+ UInt64(i))
            penContour(p, q, weight: w * 0.5, colour: colour.al(0.7), seed: seed &+ UInt64(i * 3))
        }

    case .crescents:
        aroundEllipse(cx, cy, rx * 0.94, ry * 0.94, count: 22) { _, _, pt, t in
            let nx = -sin(t), ny = cos(t)
            let dx = cos(t), dy = sin(t)
            let s = unit * 0.040
            let bx = Double(pt.x), by = Double(pt.y)
            var outer: [CGPoint] = []
            var inner: [CGPoint] = []
            for k in 0...10 {
                let u: Double = Double(k) / 10.0 * Double.pi - Double.pi / 2
                let su: Double = sin(u)
                let cu: Double = cos(u)
                let ax: Double = bx + dx * su * s
                let ay: Double = by + dy * su * s
                outer.append(pnt(ax + nx * cu * s, ay + ny * cu * s))
                let ix: Double = bx + dx * su * s * 0.95
                let iy: Double = by + dy * su * s * 0.95
                inner.append(pnt(ix + nx * cu * s * 0.55, iy + ny * cu * s * 0.55))
            }
            p.poly(outer + inner.reversed(), colour.al(0.6))
        }
    }
}

// MARK: - Vessels

private func ceramicBody(_ p: Plate, cx: Double, cy: Double, rx: Double, ry: Double,
                         tint: Col, seed: UInt64) {
    let ring = ringPoints(cx, cy, rx, ry)
    wash(p, ring, tint, strength: 0.34, bleed: min(rx, ry) * 0.030, seed: seed)
    formShade(p, ring, inset: min(rx, ry) * 0.30, depth: 2,
              spacing: max(2.4, min(rx, ry) * 0.030), colour: Ink.sepiaSoft.al(0.55), seed: seed &+ 9)
    penContour(p, ring, weight: max(1.4, min(rx, ry) * 0.020), seed: seed &+ 17)
}

/// Faint concentric turning marks — the give-away that a pot was thrown.
private func wheelLines(_ p: Plate, cx: Double, cy: Double, rx: Double, ry: Double,
                        count: Int, seed: UInt64) {
    var rng = RNG(seed)
    for k in 0..<count {
        let f = 0.30 + Double(k) / Double(max(1, count)) * 0.62
        penBroken(p, ringPoints(cx, cy, rx * f, ry * f, steps: 60),
                  weight: max(0.5, min(rx, ry) * 0.006), colour: Ink.sepiaSoft.al(rng.r(0.16, 0.30)),
                  pieces: 2, gap: 0.22, wobble: 0.7, seed: seed &+ UInt64(k * 13))
    }
}

func vessel(_ p: Plate, kind: String, cuisineKey: String, palette: Col, seed: UInt64) -> Bed {
    let cx = p.w * 0.5
    let cy = p.h * 0.47
    let unit = min(p.w, p.h)
    let motif = RimMotif.forKey(cuisineKey)
    var rng = RNG(seed)

    switch kind {

    case "bowlDeep":
        let rx = unit * 0.345, ry = unit * 0.250
        let depth = unit * 0.235
        let footRX = rx * 0.34
        // A proper bowl silhouette: the near half of the rim, both walls falling
        // away in a curve, and a small foot it stands on.
        var body: [CGPoint] = []
        for k in 0...26 {                      // near rim, left to right
            let u: Double = Double(k) / 26.0
            let a: Double = Double.pi - u * Double.pi
            body.append(pnt(cx + cos(a) * rx, cy - sin(a) * ry))
        }
        for k in 0...18 {                      // right wall down to the foot
            let u: Double = Double(k) / 18.0
            let x: Double = rx + (footRX - rx) * (u * u * 0.75 + u * 0.25)
            body.append(pnt(cx + x, cy - depth * u))
        }
        body.append(pnt(cx - footRX, cy - depth))
        for k in stride(from: 18, through: 0, by: -1) {   // left wall back up
            let u: Double = Double(k) / 18.0
            let x: Double = rx + (footRX - rx) * (u * u * 0.75 + u * 0.25)
            body.append(pnt(cx - x, cy - depth * u))
        }
        castShadow(p, at: cx, y: cy - depth * 1.02, width: rx * 1.8, seed: seed &+ 3)
        wash(p, body, Ink.glaze.mix(palette, 0.25), strength: 0.30, bleed: unit * 0.008, seed: seed &+ 5)
        formShade(p, body, inset: unit * 0.055, depth: 2, spacing: max(2.6, unit * 0.0075),
                  colour: Ink.sepiaSoft.al(0.6), seed: seed &+ 11)
        penContour(p, body, weight: max(1.6, unit * 0.0055), seed: seed &+ 19)
        // the foot it stands on
        let foot = ringPoints(cx, cy - depth, footRX, footRX * 0.30, steps: 34)
        penStroke(p, foot + [foot[0]], weight: max(1.1, unit * 0.0038),
                  colour: Ink.sepiaSoft, wobble: 0.7, taper: false, seed: seed &+ 23)
        // the mouth, seen from slightly above
        let mouth = ringPoints(cx, cy, rx, ry)
        let mouthPath = polyPath(mouth)
        wash(p, mouth, Ink.glaze.mix(palette, 0.40), strength: 0.22,
             bleed: unit * 0.006, seed: seed &+ 25)
        penStroke(p, mouth + [mouth[0]], weight: max(1.5, unit * 0.0050),
                  colour: Ink.sepia, wobble: 0.8, taper: false, seed: seed &+ 27)
        drawRim(p, cx: cx, cy: cy, rx: rx, ry: ry, motif: motif,
                colour: Ink.sepiaSoft.al(0.75), seed: seed &+ 29)
        // the inner wall, so the bowl reads as deep rather than as a disc
        let innerRing = ringPoints(cx, cy - unit * 0.020, rx * 0.84, ry * 0.76)
        hatch(p, polyPath(innerRing), angle: p.light + .pi / 2,
              spacing: max(3.0, unit * 0.012), weight: unit * 0.0030,
              colour: Ink.sepiaSoft.al(0.30), coverage: 0.55, seed: seed &+ 30,
              bound: mouthPath)
        penStroke(p, innerRing + [innerRing[0]], weight: max(1.0, unit * 0.0035),
                  colour: Ink.sepiaSoft.al(0.8), wobble: 0.8, taper: false, seed: seed &+ 31)
        return Bed(cx: cx, cy: cy - unit * 0.020, rx: rx * 0.82, ry: ry * 0.74,
                   clip: polyPath(innerRing),
                   overdraw: {
                       penStroke(p, Array(mouth[0..<(mouth.count / 2)]),
                                 weight: max(1.6, unit * 0.0055), colour: Ink.sepia,
                                 wobble: 0.9, taper: false, seed: seed &+ 37)
                   })

    case "bowlWide":
        let rx = unit * 0.365, ry = unit * 0.268
        castShadow(p, at: cx, y: cy - ry * 0.75, width: rx * 1.85, seed: seed &+ 3)
        ceramicBody(p, cx: cx, cy: cy, rx: rx, ry: ry, tint: Ink.glaze.mix(palette, 0.18), seed: seed)
        wheelLines(p, cx: cx, cy: cy, rx: rx, ry: ry, count: 3, seed: seed &+ 41)
        drawRim(p, cx: cx, cy: cy, rx: rx, ry: ry, motif: motif,
                colour: Ink.sepiaSoft.al(0.8), seed: seed &+ 29)
        let inner = ringPoints(cx, cy - unit * 0.010, rx * 0.78, ry * 0.72)
        penStroke(p, inner + [inner[0]], weight: max(1.0, unit * 0.0032),
                  colour: Ink.sepiaSoft.al(0.75), wobble: 0.8, taper: false, seed: seed &+ 31)
        return Bed(cx: cx, cy: cy - unit * 0.010, rx: rx * 0.76, ry: ry * 0.70,
                   clip: polyPath(inner))

    case "bowlSmall":
        let rx = unit * 0.255, ry = unit * 0.190
        // a companion saucer, so the composition is not one lonely circle
        let sx = cx + unit * 0.235, sy = cy - unit * 0.155
        castShadow(p, at: sx, y: sy - unit * 0.05, width: unit * 0.22, seed: seed &+ 61)
        ceramicBody(p, cx: sx, cy: sy, rx: unit * 0.115, ry: unit * 0.085,
                    tint: Ink.glaze.mix(palette, 0.30), seed: seed &+ 63)
        castShadow(p, at: cx, y: cy - ry * 0.8, width: rx * 1.9, seed: seed &+ 3)
        ceramicBody(p, cx: cx, cy: cy, rx: rx, ry: ry, tint: Ink.glaze.mix(palette, 0.20), seed: seed)
        drawRim(p, cx: cx, cy: cy, rx: rx, ry: ry, motif: motif,
                colour: Ink.sepiaSoft.al(0.8), seed: seed &+ 29)
        let inner = ringPoints(cx, cy - unit * 0.008, rx * 0.80, ry * 0.74)
        return Bed(cx: cx, cy: cy - unit * 0.008, rx: rx * 0.78, ry: ry * 0.72,
                   clip: polyPath(inner))

    case "plate":
        let rx = unit * 0.385, ry = unit * 0.285
        castShadow(p, at: cx, y: cy - ry * 0.72, width: rx * 1.9, seed: seed &+ 3)
        ceramicBody(p, cx: cx, cy: cy, rx: rx, ry: ry, tint: Ink.glaze.mix(palette, 0.14), seed: seed)
        drawRim(p, cx: cx, cy: cy, rx: rx, ry: ry, motif: motif,
                colour: Ink.sepiaSoft.al(0.85), seed: seed &+ 29)
        let well = ringPoints(cx, cy - unit * 0.006, rx * 0.70, ry * 0.66)
        penStroke(p, well + [well[0]], weight: max(1.0, unit * 0.0034),
                  colour: Ink.sepiaSoft.al(0.8), wobble: 0.8, taper: false, seed: seed &+ 31)
        wheelLines(p, cx: cx, cy: cy, rx: rx * 0.66, ry: ry * 0.62, count: 2, seed: seed &+ 41)
        return Bed(cx: cx, cy: cy - unit * 0.006, rx: rx * 0.68, ry: ry * 0.64,
                   clip: polyPath(well))

    case "board":
        let hw = unit * 0.375, hh = unit * 0.255
        let tilt = rng.r(-0.05, 0.05)
        func corner(_ sx: Double, _ sy: Double) -> CGPoint {
            CGPoint(x: cx + (sx * hw) * cos(tilt) - (sy * hh) * sin(tilt),
                    y: cy + (sx * hw) * sin(tilt) + (sy * hh) * cos(tilt))
        }
        var quad = [corner(-1, -1), corner(1, -1), corner(1, 1), corner(-1, 1)]
        // a handle hole at one end reads immediately as a board
        castShadow(p, at: cx, y: cy - hh * 0.9, width: hw * 1.8, seed: seed &+ 3)
        wash(p, quad, Ink.wood, strength: 0.40, bleed: unit * 0.010, seed: seed &+ 5)
        let bp = polyPath(quad)
        // grain: long broken rules with a couple of knots
        for k in 0..<16 {
            let v = -1.0 + Double(k) / 8.0
            penBroken(p, [corner(-1.02, v), corner(1.02, v + rng.r(-0.05, 0.05))],
                      weight: max(0.7, unit * 0.0028),
                      colour: Ink.umber.dk(0.35).al(rng.r(0.28, 0.55)),
                      pieces: 2, gap: 0.06, wobble: 1.0, seed: seed &+ UInt64(k * 7))
        }
        p.clip(bp) {
            for k in 0..<2 {
                let kx = rng.r(-0.6, 0.6), ky = rng.r(-0.7, 0.7)
                let c = corner(kx, ky)
                for j in 0..<3 {
                    let e = ellipsePoints(cx: Double(c.x), cy: Double(c.y),
                                          rx: unit * (0.012 + Double(j) * 0.008),
                                          ry: unit * (0.008 + Double(j) * 0.005), steps: 20)
                    penStroke(p, e + [e[0]], weight: max(0.6, unit * 0.0022),
                              colour: Ink.umber.dk(0.4).al(0.5), wobble: 0.8, taper: false,
                              seed: seed &+ UInt64(k * 31 + j))
                }
            }
        }
        penContour(p, quad, weight: max(1.6, unit * 0.0050), seed: seed &+ 19)
        quad = quad.map { $0 }
        return Bed(cx: cx, cy: cy, rx: hw * 0.82, ry: hh * 0.76, clip: bp)

    case "mat":
        let hw = unit * 0.370, hh = unit * 0.245
        castShadow(p, at: cx, y: cy - hh * 0.95, width: hw * 1.8, seed: seed &+ 3)
        let quad = [CGPoint(x: cx - hw, y: cy - hh), CGPoint(x: cx + hw, y: cy - hh),
                    CGPoint(x: cx + hw, y: cy + hh), CGPoint(x: cx - hw, y: cy + hh)]
        wash(p, quad, Ink.ochre, strength: 0.30, bleed: unit * 0.008, seed: seed &+ 5)
        let mp = polyPath(quad)
        p.clip(mp) {
            var x = cx - hw
            var k = 0
            while x < cx + hw {
                let wsl = unit * rng.r(0.026, 0.034)
                penStroke(p, [CGPoint(x: x, y: cy - hh), CGPoint(x: x, y: cy + hh)],
                          weight: max(0.9, unit * 0.0032), colour: Ink.sepiaSoft.al(0.55),
                          wobble: 0.8, taper: false, seed: seed &+ UInt64(k))
                hatch(p, polyPath([CGPoint(x: x, y: cy - hh), CGPoint(x: x + wsl, y: cy - hh),
                                   CGPoint(x: x + wsl, y: cy + hh), CGPoint(x: x, y: cy + hh)]),
                      angle: 1.5708, spacing: max(2.0, unit * 0.011), weight: 0.6,
                      colour: Ink.sepiaSoft.al(k % 2 == 0 ? 0.18 : 0.30), coverage: 0.6,
                      seed: seed &+ UInt64(k * 5))
                x += wsl
                k += 1
            }
            // the binding cord at both ends
            for yy in [cy - hh * 0.86, cy + hh * 0.86] {
                penStroke(p, [CGPoint(x: cx - hw, y: yy), CGPoint(x: cx + hw, y: yy)],
                          weight: max(1.4, unit * 0.0045), colour: Ink.sepia.al(0.8),
                          wobble: 1.2, taper: false, seed: seed &+ u64(Int(yy)))
            }
        }
        penContour(p, quad, weight: max(1.4, unit * 0.0044), seed: seed &+ 19)
        return Bed(cx: cx, cy: cy, rx: hw * 0.80, ry: hh * 0.70, clip: mp)

    case "claypot":
        let rx = unit * 0.320, ry = unit * 0.232
        castShadow(p, at: cx, y: cy - ry * 0.9, width: rx * 2.0, seed: seed &+ 3)
        // belly
        var belly: [CGPoint] = []
        for k in 0...44 {
            let a = Double(k) / 44.0 * 6.283185
            let bulge = 1.0 + 0.13 * max(0, -sin(a))
            belly.append(CGPoint(x: cx + cos(a) * rx * bulge,
                                 y: cy + sin(a) * ry * (a > .pi ? 1.28 : 1.0)))
        }
        wash(p, belly, Ink.rust.mix(palette, 0.25), strength: 0.42, bleed: unit * 0.010, seed: seed &+ 5)
        formShade(p, belly, inset: unit * 0.070, depth: 3, spacing: max(2.6, unit * 0.0080),
                  colour: Ink.sepiaSoft.al(0.6), seed: seed &+ 11)
        penContour(p, belly, weight: max(1.7, unit * 0.0058), seed: seed &+ 19)
        // two lug handles
        for side in [-1.0, 1.0] {
            let hx = cx + side * rx * 1.02, hy = cy - ry * 0.30
            var lug: [CGPoint] = []
            for k in 0...14 {
                let u = Double(k) / 14.0 * .pi
                lug.append(CGPoint(x: hx + side * cos(u - .pi / 2) * unit * 0.055,
                                   y: hy + sin(u - .pi / 2) * unit * 0.030 + unit * 0.030))
            }
            penStroke(p, lug, weight: max(2.0, unit * 0.0070), colour: Ink.sepia,
                      wobble: 0.8, taper: false, seed: seed &+ u64(Int(side * 71)))
        }
        wheelLines(p, cx: cx, cy: cy, rx: rx, ry: ry, count: 4, seed: seed &+ 41)
        let mouth = ringPoints(cx, cy + ry * 0.06, rx * 0.80, ry * 0.60)
        penStroke(p, mouth + [mouth[0]], weight: max(1.5, unit * 0.0050),
                  colour: Ink.sepia, wobble: 0.9, taper: false, seed: seed &+ 31)
        return Bed(cx: cx, cy: cy + ry * 0.05, rx: rx * 0.74, ry: ry * 0.54,
                   clip: polyPath(mouth),
                   overdraw: {
                       penStroke(p, Array(mouth[0..<(mouth.count / 2)]),
                                 weight: max(1.5, unit * 0.0050), colour: Ink.sepia,
                                 wobble: 0.9, taper: false, seed: seed &+ 33)
                   })

    case "pan":
        let rx = unit * 0.320, ry = unit * 0.238
        castShadow(p, at: cx, y: cy - ry * 0.8, width: rx * 1.9, seed: seed &+ 3)
        // handle running off to the upper right
        let ha = 0.72
        let hOuter = [CGPoint(x: cx + cos(ha) * rx * 0.96, y: cy + sin(ha) * ry * 0.96),
                      CGPoint(x: cx + cos(ha) * rx * 1.9, y: cy + sin(ha) * ry * 2.1)]
        penStroke(p, hOuter, weight: max(7.0, unit * 0.026), colour: Ink.char.dk(0.1),
                  wobble: 0.6, taper: false, seed: seed &+ 43)
        penStroke(p, hOuter, weight: max(3.0, unit * 0.010), colour: Ink.paper.al(0.20),
                  wobble: 0.4, taper: true, seed: seed &+ 45)
        let ring = ringPoints(cx, cy, rx, ry)
        wash(p, ring, Ink.char, strength: 0.50, bleed: unit * 0.008, seed: seed &+ 5)
        formShade(p, ring, inset: unit * 0.060, depth: 3, spacing: max(2.4, unit * 0.0070),
                  colour: Ink.sepiaSoft.al(0.7), seed: seed &+ 11)
        penContour(p, ring, weight: max(2.0, unit * 0.0068), seed: seed &+ 19)
        let inner = ringPoints(cx, cy - unit * 0.012, rx * 0.86, ry * 0.82)
        penStroke(p, inner + [inner[0]], weight: max(1.2, unit * 0.0040),
                  colour: Ink.sepiaSoft.al(0.85), wobble: 0.8, taper: false, seed: seed &+ 31)
        // seasoning: a faint sheen where the light strikes
        p.clip(polyPath(inner)) {
            for k in 0..<26 {
                let a = rng.r(0, 6.283)
                let rr = rng.r(0.2, 0.9)
                p.ellipse(cx + cos(a) * rx * rr, cy - unit * 0.012 + sin(a) * ry * rr,
                          unit * rng.r(0.010, 0.030), unit * rng.r(0.004, 0.012),
                          Ink.paper.al(rng.r(0.04, 0.12)))
                _ = k
            }
        }
        return Bed(cx: cx, cy: cy - unit * 0.012, rx: rx * 0.82, ry: ry * 0.78,
                   clip: polyPath(inner))

    case "leaf":
        let hw = unit * 0.400, hh = unit * 0.250
        castShadow(p, at: cx, y: cy - hh * 0.9, width: hw * 1.7, seed: seed &+ 3)
        var outline: [CGPoint] = []
        for k in 0..<64 {
            let a = Double(k) / 64.0 * 6.283185
            // torn, slightly ragged edge
            let ragged = 1.0 + rng.r(-0.035, 0.020)
            outline.append(CGPoint(x: cx + cos(a) * hw * ragged,
                                   y: cy + sin(a) * hh * ragged))
        }
        wash(p, outline, Ink.greenLeaf, strength: 0.36, bleed: unit * 0.012, seed: seed &+ 5)
        let lp = polyPath(outline)
        // midrib and the parallel veins that make it read as a leaf, not a green oval
        penStroke(p, [CGPoint(x: cx - hw * 0.98, y: cy), CGPoint(x: cx + hw * 0.98, y: cy)],
                  weight: max(2.4, unit * 0.0080), colour: Ink.sepiaSoft, wobble: 1.0,
                  taper: true, seed: seed &+ 47)
        p.clip(lp) {
            for k in 0..<34 {
                let u = -0.94 + Double(k) / 33.0 * 1.88
                let x0 = cx + u * hw
                for side in [-1.0, 1.0] {
                    penStroke(p, [CGPoint(x: x0, y: cy),
                                  CGPoint(x: x0 + hw * 0.16, y: cy + side * hh * 1.05)],
                              weight: max(0.7, unit * 0.0026),
                              colour: Ink.sepiaSoft.al(rng.r(0.30, 0.55)),
                              wobble: 0.6, taper: true, seed: seed &+ UInt64(k * 5) &+ u64(Int(side)))
                }
            }
        }
        penContour(p, outline, weight: max(1.3, unit * 0.0042), seed: seed &+ 19)
        return Bed(cx: cx, cy: cy, rx: hw * 0.72, ry: hh * 0.66, clip: lp)

    case "paper":
        let hw = unit * 0.360, hh = unit * 0.262
        castShadow(p, at: cx, y: cy - hh * 0.9, width: hw * 1.8, seed: seed &+ 3)
        // a crumpled sheet: an irregular polygon with creases radiating from the middle
        var sheet: [CGPoint] = []
        for k in 0..<14 {
            let a = Double(k) / 14.0 * 6.283185
            let rr = 1.0 + rng.r(-0.14, 0.10)
            sheet.append(CGPoint(x: cx + cos(a) * hw * rr, y: cy + sin(a) * hh * rr))
        }
        wash(p, sheet, Ink.cream, strength: 0.30, bleed: unit * 0.012, seed: seed &+ 5)
        let sp = polyPath(sheet)
        p.clip(sp) {
            for k in 0..<11 {
                let a = rng.r(0, 6.283)
                penStroke(p, [CGPoint(x: cx + cos(a) * hw * rng.r(0.1, 0.3),
                                      y: cy + sin(a) * hh * rng.r(0.1, 0.3)),
                              CGPoint(x: cx + cos(a) * hw * 1.05, y: cy + sin(a) * hh * 1.05)],
                          weight: max(0.8, unit * 0.0030), colour: Ink.sepiaSoft.al(rng.r(0.25, 0.5)),
                          wobble: 1.4, taper: true, seed: seed &+ UInt64(k * 11))
            }
            // newsprint: rules of grey type, never legible
            for k in 0..<22 {
                let yy = cy - hh + Double(k) * hh * 2.0 / 22.0
                penBroken(p, [CGPoint(x: cx - hw * 0.9, y: yy), CGPoint(x: cx + hw * 0.9, y: yy)],
                          weight: max(0.6, unit * 0.0022), colour: Ink.sepiaSoft.al(0.16),
                          pieces: 5, gap: 0.10, wobble: 0.4, seed: seed &+ UInt64(k * 3))
            }
        }
        penContour(p, sheet, weight: max(1.2, unit * 0.0038), seed: seed &+ 19)
        return Bed(cx: cx, cy: cy, rx: hw * 0.70, ry: hh * 0.62, clip: sp)

    case "basket":
        let rx = unit * 0.330, ry = unit * 0.245
        castShadow(p, at: cx, y: cy - ry * 0.85, width: rx * 1.9, seed: seed &+ 3)
        let ring = ringPoints(cx, cy, rx, ry)
        wash(p, ring, Ink.ochre.mix(Ink.wood, 0.4), strength: 0.34, bleed: unit * 0.009, seed: seed &+ 5)
        let bp = polyPath(ring)
        // the weave: two hatch passes at right angles, broken so it reads as splints
        hatch(p, bp, angle: 0.34, spacing: max(3.2, unit * 0.017), weight: max(1.3, unit * 0.0044),
              colour: Ink.umber.al(0.55), coverage: 0.95, seed: seed &+ 51)
        hatch(p, bp, angle: 0.34 + 1.5708, spacing: max(3.2, unit * 0.017),
              weight: max(1.3, unit * 0.0044), colour: Ink.umber.al(0.45), coverage: 0.95,
              seed: seed &+ 53)
        formShade(p, ring, inset: unit * 0.050, depth: 2, spacing: max(2.6, unit * 0.0080),
                  colour: Ink.sepiaSoft.al(0.5), seed: seed &+ 11)
        // the bound rim, two turns of splint
        for f in [1.0, 0.93] {
            let r = ringPoints(cx, cy, rx * f, ry * f)
            penStroke(p, r + [r[0]], weight: max(2.2, unit * 0.0072) * (f == 1.0 ? 1.0 : 0.6),
                      colour: Ink.sepia, wobble: 0.9, taper: false, seed: seed &+ u64(Int(f * 100)))
        }
        let inner = ringPoints(cx, cy - unit * 0.010, rx * 0.84, ry * 0.78)
        return Bed(cx: cx, cy: cy - unit * 0.010, rx: rx * 0.80, ry: ry * 0.74,
                   clip: polyPath(inner))

    case "glass":
        // Seen from the side: contents stack instead of spreading.
        let hw = unit * 0.150, top = cy + unit * 0.250, bot = cy - unit * 0.215
        castShadow(p, at: cx, y: bot, width: hw * 3.0, seed: seed &+ 3)
        var body: [CGPoint] = []
        for k in 0...20 {
            let u = Double(k) / 20.0
            let y = bot + (top - bot) * u
            body.append(CGPoint(x: cx - hw * (0.80 + 0.20 * u), y: y))
        }
        for k in stride(from: 20, through: 0, by: -1) {
            let u = Double(k) / 20.0
            let y = bot + (top - bot) * u
            body.append(CGPoint(x: cx + hw * (0.80 + 0.20 * u), y: y))
        }
        wash(p, body, Ink.glaze.al(0.5), strength: 0.16, bleed: unit * 0.006, seed: seed &+ 5)
        penContour(p, body, weight: max(1.6, unit * 0.0052), seed: seed &+ 19)
        // the two highlights that say "glass"
        for side in [-0.55, 0.42] {
            penStroke(p, [CGPoint(x: cx + hw * side, y: bot + (top - bot) * 0.12),
                          CGPoint(x: cx + hw * side * 1.06, y: bot + (top - bot) * 0.88)],
                      weight: max(1.4, unit * 0.0048), colour: Ink.paper.al(0.55),
                      wobble: 0.5, taper: true, seed: seed &+ u64(Int(side * 100)))
        }
        let mouth = ringPoints(cx, top, hw, hw * 0.30)
        penStroke(p, mouth + [mouth[0]], weight: max(1.4, unit * 0.0048),
                  colour: Ink.sepia, wobble: 0.7, taper: false, seed: seed &+ 31)
        let fill = polyPath([CGPoint(x: cx - hw, y: bot + unit * 0.012),
                             CGPoint(x: cx + hw, y: bot + unit * 0.012),
                             CGPoint(x: cx + hw * 0.99, y: top - unit * 0.030),
                             CGPoint(x: cx - hw * 0.99, y: top - unit * 0.030)])
        return Bed(cx: cx, cy: (top + bot) / 2, rx: hw * 0.90, ry: (top - bot) * 0.44,
                   clip: fill, upright: true)

    default:
        return vessel(p, kind: "plate", cuisineKey: cuisineKey, palette: palette, seed: seed)
    }
}
