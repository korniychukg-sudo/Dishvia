import Foundation
import CoreGraphics

// Vessels, second edition: seen from a low three-quarter view, painted in
// opaque gouache. Every vessel has a rim, a wall the light falls down, and an
// interior in shadow for the food to sit in. The caller draws the food, then
// the near rim is struck again so the bowl truly holds it.

struct Bed {
    var cx: Double
    var cy: Double
    var rx: Double
    var ry: Double
    /// Interior + headroom: food may heap above the rim but not spill sideways.
    var clip: CGPath
    var upright: Bool = false
    var overdraw: () -> Void = {}
}

func ringPoints(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, steps: Int = 64) -> [CGPoint] {
    ellipsePoints(cx: cx, cy: cy, rx: rx, ry: ry, steps: steps)
}

/// Interior ellipse plus a column of headroom above it (non-zero winding makes
/// overlapping subpaths a union).
private func cupClip(cx: Double, cy: Double, rx: Double, ry: Double, rise: Double) -> CGPath {
    let path = CGMutablePath()
    path.addPath(polyPath(ringPoints(cx, cy, rx, ry)))
    if rise > 0 {
        path.addRect(CGRect(x: cx - rx * 0.96, y: cy, width: rx * 1.92, height: rise))
    }
    return path
}

// MARK: - Rim motifs

enum RimMotif: Int, CaseIterable {
    case doubleLine, dots, wave, chevron, rays, braid, pearls, dashes

    static func forKey(_ key: String) -> RimMotif {
        let all = RimMotif.allCases
        return all[Int(inkSeed(key) % UInt64(all.count))]
    }
}

/// Decoration painted around the near (visible) half of the rim band.
func rimBand(_ p: Plate, cx: Double, cy: Double, rx: Double, ry: Double,
             motif: RimMotif, colour: Col, unit: Double, seed: UInt64) {
    let w = max(1.0, unit * 0.007)
    func nearArc(_ f: Double, count: Int) -> [CGPoint] {
        var pts: [CGPoint] = []
        for i in 0...count {
            let a = Double.pi + Double(i) / Double(count) * Double.pi
            pts.append(pnt(cx + cos(a) * rx * f, cy + sin(a) * ry * f))
        }
        return pts
    }
    switch motif {
    case .doubleLine:
        for f in [0.90, 0.80] {
            penStroke(p, nearArc(f, count: 30), weight: w * (f > 0.85 ? 1.4 : 0.9),
                      colour: colour, wobble: w * 0.5, taper: false,
                      seed: seed &+ u64(Int(f * 100)))
        }
    case .dots:
        for i in 0...16 {
            let a = Double.pi + Double(i) / 16.0 * Double.pi
            p.disc(cx + cos(a) * rx * 0.86, cy + sin(a) * ry * 0.86,
                   unit * (i % 3 == 0 ? 0.011 : 0.007), colour.al(0.9))
        }
    case .wave:
        var pts: [CGPoint] = []
        for i in 0...60 {
            let a = Double.pi + Double(i) / 60.0 * Double.pi
            let s = sin(Double(i) * 0.8) * unit * 0.010
            pts.append(pnt(cx + cos(a) * (rx * 0.85 + s), cy + sin(a) * (ry * 0.85 + s)))
        }
        penStroke(p, pts, weight: w, colour: colour, wobble: w * 0.4, taper: false, seed: seed)
    case .chevron:
        for i in 0...12 {
            let a = Double.pi + Double(i) / 12.0 * Double.pi
            let bx = cx + cos(a) * rx * 0.85, by = cy + sin(a) * ry * 0.85
            let s = unit * 0.016
            penStroke(p, [pnt(bx - s, by - s * 0.6), pnt(bx, by + s * 0.6), pnt(bx + s, by - s * 0.6)],
                      weight: w * 0.9, colour: colour, wobble: w * 0.3, taper: false,
                      seed: seed &+ UInt64(i))
        }
    case .rays:
        for i in 0...22 {
            let a = Double.pi + Double(i) / 22.0 * Double.pi
            let f0 = 0.78
            let f1 = i % 3 == 0 ? 0.95 : 0.88
            penStroke(p, [pnt(cx + cos(a) * rx * f0, cy + sin(a) * ry * f0),
                          pnt(cx + cos(a) * rx * f1, cy + sin(a) * ry * f1)],
                      weight: w * 0.8, colour: colour, wobble: w * 0.3, taper: true,
                      seed: seed &+ UInt64(i))
        }
    case .braid:
        for lane in 0..<2 {
            var pts: [CGPoint] = []
            let ph = Double(lane) * Double.pi
            for i in 0...60 {
                let a = Double.pi + Double(i) / 60.0 * Double.pi
                let s = sin(Double(i) * 0.62 + ph) * unit * 0.009
                pts.append(pnt(cx + cos(a) * (rx * 0.85 + s), cy + sin(a) * (ry * 0.85 + s)))
            }
            penStroke(p, pts, weight: w * 0.8, colour: colour.al(lane == 0 ? 1 : 0.7),
                      wobble: w * 0.3, taper: false, seed: seed &+ UInt64(lane * 7))
        }
    case .pearls:
        for i in 0...13 {
            let a = Double.pi + Double(i) / 13.0 * Double.pi
            let x = cx + cos(a) * rx * 0.86
            let y = cy + sin(a) * ry * 0.86
            let r = unit * 0.010
            p.disc(x, y, r, colour.al(0.85))
            p.disc(x - r * 0.3, y + r * 0.3, r * 0.35, Paint.creamWhite.al(0.8))
        }
    case .dashes:
        for i in 0...18 where i % 2 == 0 {
            let a0 = Double.pi + Double(i) / 18.0 * Double.pi
            let a1 = Double.pi + Double(min(18, i + 1)) / 18.0 * Double.pi
            penStroke(p, [pnt(cx + cos(a0) * rx * 0.86, cy + sin(a0) * ry * 0.86),
                          pnt(cx + cos(a1) * rx * 0.86, cy + sin(a1) * ry * 0.86)],
                      weight: w * 1.1, colour: colour, wobble: w * 0.4, taper: false,
                      seed: seed &+ UInt64(i))
        }
    }
}

// MARK: - The standing vessel

/// Shared machinery: shadow, wall from the rim down to a narrower base,
/// interior in shadow tone, rim ring. Returns the bed; overdraw re-inks the rim.
private func standingVessel(_ p: Plate, cx: Double, cy: Double,
                            rimRX: Double, rimRY: Double, wallH: Double,
                            baseScale: Double, chord: Chord, unit: Double,
                            motif: RimMotif?, motifColour: Col,
                            shadowTone: Col, seed: UInt64,
                            foot: Bool = false) -> Bed {
    groundShadow(p, at: cx, y: cy - wallH - rimRY * 0.55, width: rimRX * 2.1,
                 tone: shadowTone, seed: seed &+ 1)

    var wall: [CGPoint] = []
    for i in 0...30 {
        let a = Double.pi + Double(i) / 30.0 * Double.pi
        wall.append(pnt(cx + cos(a) * rimRX, cy + sin(a) * rimRY))
    }
    for i in stride(from: 30, through: 0, by: -1) {
        let a = Double.pi + Double(i) / 30.0 * Double.pi
        wall.append(pnt(cx + cos(a) * rimRX * baseScale,
                        cy - wallH + sin(a) * rimRY * baseScale * 0.8))
    }
    gouacheForm(p, wall, chord, depth: 1.0, seed: seed &+ 3)
    inkOver(p, wall, weight: max(1.4, unit * 0.0042), hatchShadow: true, seed: seed &+ 5)

    if foot {
        let fr = rimRX * baseScale * 0.55
        let footRing = ringPoints(cx, cy - wallH - rimRY * 0.28, fr, fr * 0.22, steps: 30)
        gouache(p, footRing, chord.shadow, seed: seed &+ 7)
        penStroke(p, footRing + [footRing[0]], weight: max(1.0, unit * 0.0030),
                  colour: Ink.sepia.al(0.8), wobble: 0.6, taper: false, seed: seed &+ 9)
    }

    let rim = ringPoints(cx, cy, rimRX, rimRY)
    gouache(p, rim, chord.body, unevenness: 0.06, seed: seed &+ 11)
    let interior = ringPoints(cx, cy, rimRX * 0.86, rimRY * 0.82)
    gouache(p, interior, chord.shadow.dk(0.10), unevenness: 0.05, seed: seed &+ 13)
    penStroke(p, rim + [rim[0]], weight: max(1.5, unit * 0.0048), colour: Ink.sepia,
              wobble: 0.8, taper: false, seed: seed &+ 15)

    if let motif = motif {
        rimBand(p, cx: cx, cy: cy, rx: rimRX, ry: rimRY,
                motif: motif, colour: motifColour, unit: unit, seed: seed &+ 17)
    }

    return Bed(cx: cx, cy: cy, rx: rimRX * 0.80, ry: rimRY * 0.76,
               clip: cupClip(cx: cx, cy: cy, rx: rimRX * 0.88, ry: rimRY * 0.84,
                             rise: unit * 0.30),
               overdraw: {
                   var near: [CGPoint] = []
                   for i in 0...30 {
                       let a = Double.pi + Double(i) / 30.0 * Double.pi
                       near.append(pnt(cx + cos(a) * rimRX, cy + sin(a) * rimRY))
                   }
                   penStroke(p, near, weight: max(1.6, unit * 0.0052),
                             colour: Ink.sepia, wobble: 0.8, taper: false,
                             seed: seed &+ 19)
               })
}

private func flatBed(cx: Double, cy: Double, rx: Double, ry: Double, rise: Double) -> Bed {
    Bed(cx: cx, cy: cy, rx: rx, ry: ry,
        clip: cupClip(cx: cx, cy: cy, rx: rx * 1.18, ry: ry * 1.30, rise: rise))
}

// MARK: - The twelve vessels

func vessel(_ p: Plate, kind: String, cuisineKey: String, paletteKey: String,
            seed: UInt64, cx: Double, cy: Double, unit: Double) -> Bed {
    var rng = RNG(seed)
    let motif = RimMotif.forKey(cuisineKey)
    let glazeChord = Paint.glaze(paletteKey)
    let accent = Paint.chord(paletteKey).body.dk(0.18)
    let shadowTone = Col(r: 0.70, g: 0.62, b: 0.51)

    switch kind {

    case "bowlDeep":
        return standingVessel(p, cx: cx, cy: cy,
                              rimRX: unit * 0.315, rimRY: unit * 0.105,
                              wallH: unit * 0.195, baseScale: 0.46,
                              chord: glazeChord, unit: unit, motif: motif,
                              motifColour: accent, shadowTone: shadowTone,
                              seed: seed, foot: true)

    case "bowlWide":
        return standingVessel(p, cx: cx, cy: cy,
                              rimRX: unit * 0.365, rimRY: unit * 0.120,
                              wallH: unit * 0.105, baseScale: 0.58,
                              chord: glazeChord, unit: unit, motif: motif,
                              motifColour: accent, shadowTone: shadowTone,
                              seed: seed)

    case "bowlSmall":
        _ = standingVessel(p, cx: cx + unit * 0.27, cy: cy + unit * 0.115,
                           rimRX: unit * 0.085, rimRY: unit * 0.030,
                           wallH: unit * 0.085, baseScale: 0.62,
                           chord: glazeChord, unit: unit, motif: nil,
                           motifColour: accent, shadowTone: shadowTone,
                           seed: seed &+ 61)
        return standingVessel(p, cx: cx - unit * 0.02, cy: cy,
                              rimRX: unit * 0.235, rimRY: unit * 0.082,
                              wallH: unit * 0.125, baseScale: 0.50,
                              chord: glazeChord, unit: unit, motif: motif,
                              motifColour: accent, shadowTone: shadowTone,
                              seed: seed, foot: true)

    case "plate":
        groundShadow(p, at: cx, y: cy - unit * 0.075, width: unit * 0.82,
                     tone: shadowTone, seed: seed &+ 1)
        let rim = ringPoints(cx, cy, unit * 0.40, unit * 0.140)
        gouacheForm(p, rim, glazeChord, depth: 0.5, seed: seed &+ 3)
        penStroke(p, rim + [rim[0]], weight: max(1.5, unit * 0.0048),
                  colour: Ink.sepia, wobble: 0.8, taper: false, seed: seed &+ 5)
        rimBand(p, cx: cx, cy: cy, rx: unit * 0.40, ry: unit * 0.140,
                motif: motif, colour: accent, unit: unit, seed: seed &+ 7)
        let well = ringPoints(cx, cy + unit * 0.004, unit * 0.295, unit * 0.100)
        gouache(p, well, glazeChord.body.dk(0.06), unevenness: 0.05, seed: seed &+ 9)
        penStroke(p, well + [well[0]], weight: max(1.0, unit * 0.0028),
                  colour: Ink.sepiaSoft.al(0.7), wobble: 0.6, taper: false, seed: seed &+ 11)
        return Bed(cx: cx, cy: cy + unit * 0.004, rx: unit * 0.27, ry: unit * 0.092,
                   clip: cupClip(cx: cx, cy: cy, rx: unit * 0.315, ry: unit * 0.115,
                                 rise: unit * 0.26))

    case "board":
        let hw = unit * 0.40
        let hh = unit * 0.145
        groundShadow(p, at: cx, y: cy - hh * 1.15, width: hw * 1.9,
                     tone: shadowTone, seed: seed &+ 1)
        let lean = rng.r(-0.03, 0.03)
        func c4(_ sx: Double, _ sy: Double) -> CGPoint {
            pnt(cx + sx * hw - sy * hh * lean * 3, cy + sy * hh + sx * hw * lean)
        }
        let top = [c4(-1, 1), c4(1, 1), c4(1, -1), c4(-1, -1)]
        let edgeH = unit * 0.038
        let edge = [top[3], top[2],
                    CGPoint(x: top[2].x, y: top[2].y - CGFloat(edgeH)),
                    CGPoint(x: top[3].x, y: top[3].y - CGFloat(edgeH))]
        gouache(p, edge, Paint.woodBoard.shadow, seed: seed &+ 3)
        gouache(p, top, Paint.woodBoard.body, unevenness: 0.07, seed: seed &+ 5)
        p.clip(polyPath(top)) {
            for k in 0..<9 {
                let t = -0.85 + Double(k) * 0.21
                penBroken(p, [c4(-1.0, t), c4(1.0, t + rng.r(-0.05, 0.05))],
                          weight: max(0.7, unit * 0.0022),
                          colour: Paint.woodBoard.shadow.al(rng.r(0.35, 0.6)),
                          pieces: 2, gap: 0.07, wobble: 0.9, seed: seed &+ UInt64(k * 7))
            }
        }
        inkOver(p, top, weight: max(1.4, unit * 0.0042), hatchShadow: false, seed: seed &+ 9)
        penContour(p, edge, weight: max(1.0, unit * 0.0030), colour: Ink.sepia.al(0.8),
                   seed: seed &+ 11)
        dab(p, x: cx + hw * 1.06, y: cy, rx: unit * 0.032, ry: unit * 0.019,
            Paint.woodBoard.body, outline: max(0.9, unit * 0.0026), seed: seed &+ 13)
        return flatBed(cx: cx, cy: cy, rx: hw * 0.82, ry: hh * 0.80, rise: unit * 0.24)

    case "mat":
        let hw = unit * 0.40
        let hh = unit * 0.150
        groundShadow(p, at: cx, y: cy - hh * 1.1, width: hw * 1.85,
                     tone: shadowTone, seed: seed &+ 1)
        let quad = [pnt(cx - hw, cy + hh), pnt(cx + hw, cy + hh),
                    pnt(cx + hw * 1.03, cy - hh), pnt(cx - hw * 1.03, cy - hh)]
        gouache(p, quad, Paint.bamboo.body, unevenness: 0.06, seed: seed &+ 3)
        p.clip(polyPath(quad)) {
            var x = cx - hw * 1.05
            var k = 0
            while x < cx + hw * 1.05 {
                penStroke(p, [pnt(x, cy - hh * 1.05), pnt(x + hh * 0.14, cy + hh * 1.05)],
                          weight: max(0.8, unit * 0.0026),
                          colour: (k % 2 == 0 ? Paint.bamboo.shadow : Paint.bamboo.light)
                              .al(k % 2 == 0 ? 0.55 : 0.4),
                          wobble: 0.5, taper: false, seed: seed &+ UInt64(k))
                x += unit * 0.022
                k += 1
            }
            for yy in [cy - hh * 0.72, cy + hh * 0.72] {
                penStroke(p, [pnt(cx - hw * 1.05, yy), pnt(cx + hw * 1.05, yy)],
                          weight: max(1.3, unit * 0.0040), colour: Ink.sepia.al(0.75),
                          wobble: 1.0, taper: false, seed: seed &+ u64(Int(yy)))
            }
        }
        inkOver(p, quad, weight: max(1.3, unit * 0.0040), hatchShadow: false, seed: seed &+ 7)
        return flatBed(cx: cx, cy: cy, rx: hw * 0.80, ry: hh * 0.74, rise: unit * 0.22)

    case "claypot":
        groundShadow(p, at: cx, y: cy - unit * 0.24, width: unit * 0.72,
                     tone: shadowTone, seed: seed &+ 1)
        var belly: [CGPoint] = []
        for i in 0...30 {
            let a = Double.pi + Double(i) / 30.0 * Double.pi
            belly.append(pnt(cx + cos(a) * unit * 0.30, cy + sin(a) * unit * 0.095))
        }
        for i in stride(from: 30, through: 0, by: -1) {
            let t = Double(i) / 30.0
            let a = Double.pi + t * Double.pi
            belly.append(pnt(cx + cos(a) * unit * 0.245,
                             cy - unit * 0.22 + sin(a) * unit * 0.070))
        }
        // the swell of the belly midway down each side
        let bellyPath = polyPath(belly)
        _ = bellyPath
        // bow the sides outward so the pot has a belly rather than a bucket flare
        for i in 0..<belly.count {
            let y = Double(belly[i].y)
            let depthT = max(0.0, min(1.0, (cy - y) / (unit * 0.22)))
            let swell = sin(depthT * Double.pi) * unit * 0.045
            if Double(belly[i].x) > cx + unit * 0.02 {
                belly[i].x += CGFloat(swell)
            } else if Double(belly[i].x) < cx - unit * 0.02 {
                belly[i].x -= CGFloat(swell)
            }
        }
        gouacheForm(p, belly, Paint.terracotta, depth: 1.1, seed: seed &+ 3)
        inkOver(p, belly, weight: max(1.5, unit * 0.0046), seed: seed &+ 5)
        for side in [-1.0, 1.0] {
            let lx = cx + side * unit * 0.315
            let ly = cy - unit * 0.055
            var lug: [CGPoint] = []
            for i in 0...12 {
                let a = -Double.pi / 2 + Double(i) / 12.0 * Double.pi
                lug.append(pnt(lx + side * cos(a) * unit * 0.045,
                               ly + sin(a) * unit * 0.030))
            }
            penStroke(p, lug, weight: max(2.2, unit * 0.0075),
                      colour: Paint.terracotta.shadow, wobble: 0.6, taper: false,
                      seed: seed &+ u64(Int(side * 31)))
        }
        let rim = ringPoints(cx, cy, unit * 0.30, unit * 0.095)
        gouache(p, rim, Paint.terracotta.body, unevenness: 0.06, seed: seed &+ 7)
        let interior = ringPoints(cx, cy, unit * 0.26, unit * 0.080)
        gouache(p, interior, Paint.terracotta.shadow.dk(0.12), seed: seed &+ 9)
        penStroke(p, rim + [rim[0]], weight: max(1.5, unit * 0.0048),
                  colour: Ink.sepia, wobble: 0.8, taper: false, seed: seed &+ 11)
        return Bed(cx: cx, cy: cy, rx: unit * 0.235, ry: unit * 0.070,
                   clip: cupClip(cx: cx, cy: cy, rx: unit * 0.265, ry: unit * 0.082,
                                 rise: unit * 0.24),
                   overdraw: {
                       var near: [CGPoint] = []
                       for i in 0...24 {
                           let a = Double.pi + Double(i) / 24.0 * Double.pi
                           near.append(pnt(cx + cos(a) * unit * 0.30,
                                           cy + sin(a) * unit * 0.095))
                       }
                       penStroke(p, near, weight: max(1.6, unit * 0.0052),
                                 colour: Ink.sepia, wobble: 0.8, taper: false,
                                 seed: seed &+ 13)
                   })

    case "pan":
        groundShadow(p, at: cx, y: cy - unit * 0.10, width: unit * 0.78,
                     tone: shadowTone, seed: seed &+ 1)
        let ha = 0.55
        penStroke(p, [pnt(cx + cos(ha) * unit * 0.30, cy + sin(ha) * unit * 0.115),
                      pnt(cx + cos(ha) * unit * 0.56, cy + sin(ha) * unit * 0.24)],
                  weight: max(8.0, unit * 0.030), colour: Paint.ironPan.shadow,
                  wobble: 0.5, taper: false, seed: seed &+ 3)
        penStroke(p, [pnt(cx + cos(ha) * unit * 0.33, cy + sin(ha) * unit * 0.13),
                      pnt(cx + cos(ha) * unit * 0.54, cy + sin(ha) * unit * 0.225)],
                  weight: max(2.6, unit * 0.009), colour: Paint.ironPan.light.al(0.6),
                  wobble: 0.4, taper: true, seed: seed &+ 5)
        let bed = standingVessel(p, cx: cx, cy: cy,
                                 rimRX: unit * 0.33, rimRY: unit * 0.110,
                                 wallH: unit * 0.070, baseScale: 0.82,
                                 chord: Paint.ironPan, unit: unit, motif: nil,
                                 motifColour: accent, shadowTone: shadowTone,
                                 seed: seed &+ 7)
        p.clip(bed.clip) {
            for _ in 0..<10 {
                let a = rng.r(0, 6.283)
                let rr = rng.r(0.2, 0.8)
                p.ellipse(cx + cos(a) * unit * 0.24 * rr, cy + sin(a) * unit * 0.075 * rr,
                          unit * rng.r(0.02, 0.05), unit * rng.r(0.006, 0.014),
                          Paint.ironPan.light.al(rng.r(0.15, 0.3)))
            }
        }
        return bed

    case "leaf":
        let hw = unit * 0.42
        let hh = unit * 0.155
        groundShadow(p, at: cx, y: cy - hh * 1.05, width: hw * 1.8,
                     tone: shadowTone, seed: seed &+ 1)
        var outline: [CGPoint] = []
        for k in 0..<48 {
            let a = Double(k) / 48.0 * 6.283185
            let point = 1.0 + 0.16 * abs(cos(a))
            let ragged = 1.0 + rng.r(-0.03, 0.02)
            outline.append(pnt(cx + cos(a) * hw * point * ragged * 0.92,
                               cy + sin(a) * hh * ragged))
        }
        gouacheForm(p, outline, Paint.leafGreen, depth: 0.7, seed: seed &+ 3)
        penStroke(p, [pnt(cx - hw * 1.02, cy), pnt(cx + hw * 1.02, cy)],
                  weight: max(2.2, unit * 0.0070), colour: Paint.leafGreen.shadow,
                  wobble: 0.8, taper: true, seed: seed &+ 5)
        p.clip(polyPath(outline)) {
            for k in 0..<20 {
                let u = -0.9 + Double(k) / 19.0 * 1.8
                for side in [-1.0, 1.0] {
                    penStroke(p, [pnt(cx + u * hw, cy),
                                  pnt(cx + u * hw + hw * 0.13, cy + side * hh * 1.05)],
                              weight: max(0.7, unit * 0.0020),
                              colour: Paint.leafGreen.shadow.al(rng.r(0.4, 0.65)),
                              wobble: 0.4, taper: true,
                              seed: seed &+ UInt64(k * 5) &+ u64(Int(side)))
                }
            }
        }
        inkOver(p, outline, weight: max(1.2, unit * 0.0036), hatchShadow: false, seed: seed &+ 9)
        return flatBed(cx: cx, cy: cy, rx: hw * 0.66, ry: hh * 0.70, rise: unit * 0.22)

    case "paper":
        let hw = unit * 0.375
        let hh = unit * 0.165
        groundShadow(p, at: cx, y: cy - hh * 1.05, width: hw * 1.8,
                     tone: shadowTone, seed: seed &+ 1)
        var sheet: [CGPoint] = []
        for k in 0..<12 {
            let a = Double(k) / 12.0 * 6.283185
            let rr = 1.0 + rng.r(-0.12, 0.09)
            sheet.append(pnt(cx + cos(a) * hw * rr, cy + sin(a) * hh * rr))
        }
        gouache(p, sheet, Paint.paperWrap.body, unevenness: 0.08, seed: seed &+ 3)
        p.clip(polyPath(sheet)) {
            for k in 0..<8 {
                let a = rng.r(0, 6.283)
                penStroke(p, [pnt(cx + cos(a) * hw * 0.15, cy + sin(a) * hh * 0.15),
                              pnt(cx + cos(a) * hw * 1.05, cy + sin(a) * hh * 1.05)],
                          weight: max(0.8, unit * 0.0024),
                          colour: Paint.paperWrap.shadow.al(rng.r(0.4, 0.6)),
                          wobble: 1.2, taper: true, seed: seed &+ UInt64(k * 11))
            }
            for k in 0..<12 {
                let yy = cy - hh + Double(k) * hh * 2 / 12
                penBroken(p, [pnt(cx - hw * 0.85, yy), pnt(cx + hw * 0.85, yy)],
                          weight: max(0.6, unit * 0.0016),
                          colour: Ink.sepiaSoft.al(0.22), pieces: 5, gap: 0.12,
                          wobble: 0.3, seed: seed &+ UInt64(k * 3))
            }
        }
        inkOver(p, sheet, weight: max(1.1, unit * 0.0032), hatchShadow: false, seed: seed &+ 7)
        return flatBed(cx: cx, cy: cy, rx: hw * 0.68, ry: hh * 0.62, rise: unit * 0.22)

    case "basket":
        let bed = standingVessel(p, cx: cx, cy: cy,
                                 rimRX: unit * 0.315, rimRY: unit * 0.105,
                                 wallH: unit * 0.13, baseScale: 0.72,
                                 chord: Paint.bamboo, unit: unit, motif: nil,
                                 motifColour: accent, shadowTone: shadowTone,
                                 seed: seed)
        var weave: [CGPoint] = []
        for i in 0...30 {
            let a = Double.pi + Double(i) / 30.0 * Double.pi
            weave.append(pnt(cx + cos(a) * unit * 0.315, cy + sin(a) * unit * 0.105))
        }
        for i in stride(from: 30, through: 0, by: -1) {
            let a = Double.pi + Double(i) / 30.0 * Double.pi
            weave.append(pnt(cx + cos(a) * unit * 0.227,
                             cy - unit * 0.13 + sin(a) * unit * 0.061))
        }
        p.clip(polyPath(weave)) {
            for pass in 0..<2 {
                let lean: Double = pass == 0 ? 1 : -1
                var x = cx - unit * 0.34
                var k = 0
                while x < cx + unit * 0.34 {
                    penStroke(p, [pnt(x, cy - unit * 0.15),
                                  pnt(x + lean * unit * 0.05, cy + unit * 0.02)],
                              weight: max(1.2, unit * 0.0040),
                              colour: (k % 2 == 0 ? Paint.bamboo.shadow : Paint.bamboo.light)
                                  .al(pass == 0 ? 0.55 : 0.38),
                              wobble: 0.5, taper: false,
                              seed: seed &+ UInt64(pass * 100 + k))
                    x += unit * 0.026
                    k += 1
                }
            }
        }
        var rimNear: [CGPoint] = []
        for i in 0...24 {
            let a = Double.pi + Double(i) / 24.0 * Double.pi
            rimNear.append(pnt(cx + cos(a) * unit * 0.315, cy + sin(a) * unit * 0.105))
        }
        penStroke(p, rimNear, weight: max(2.6, unit * 0.0085),
                  colour: Paint.bamboo.shadow, wobble: 0.8, taper: false, seed: seed &+ 41)
        return bed

    case "glass":
        let hw = unit * 0.125
        let top = cy + unit * 0.30
        let bot = cy - unit * 0.16
        groundShadow(p, at: cx, y: bot - unit * 0.02, width: hw * 3.2,
                     tone: shadowTone, seed: seed &+ 1)
        var body: [CGPoint] = []
        for k in 0...16 {
            let u = Double(k) / 16.0
            body.append(pnt(cx - hw * (0.78 + 0.22 * u), bot + (top - bot) * u))
        }
        for k in stride(from: 16, through: 0, by: -1) {
            let u = Double(k) / 16.0
            body.append(pnt(cx + hw * (0.78 + 0.22 * u), bot + (top - bot) * u))
        }
        gouache(p, body, Paint.glassBlue.body, unevenness: 0.05, seed: seed &+ 3)
        p.clip(polyPath(body)) {
            let bandTop = top - unit * 0.015
            let bandBot = bot + unit * 0.008
            gouache(p, [pnt(cx - hw * 0.62, bandBot), pnt(cx - hw * 0.30, bandBot),
                        pnt(cx - hw * 0.36, bandTop), pnt(cx - hw * 0.68, bandTop)],
                    Paint.glassBlue.light, unevenness: 0.03, edgeDark: 0.02, seed: seed &+ 5)
            gouache(p, [pnt(cx + hw * 0.42, bandBot), pnt(cx + hw * 0.72, bandBot),
                        pnt(cx + hw * 0.80, bandTop), pnt(cx + hw * 0.48, bandTop)],
                    Paint.glassBlue.shadow, unevenness: 0.03, edgeDark: 0.02, seed: seed &+ 7)
        }
        inkOver(p, body, weight: max(1.4, unit * 0.0042), hatchShadow: false, seed: seed &+ 9)
        let mouth = ringPoints(cx, top, hw, hw * 0.26)
        penStroke(p, mouth + [mouth[0]], weight: max(1.3, unit * 0.0040),
                  colour: Ink.sepia, wobble: 0.5, taper: false, seed: seed &+ 11)
        let fill = polyPath([pnt(cx - hw * 0.92, bot + unit * 0.012),
                             pnt(cx + hw * 0.92, bot + unit * 0.012),
                             pnt(cx + hw * 0.97, top - unit * 0.02),
                             pnt(cx - hw * 0.97, top - unit * 0.02)])
        return Bed(cx: cx, cy: (top + bot) / 2, rx: hw * 0.88, ry: (top - bot) * 0.45,
                   clip: fill, upright: true)

    default:
        return vessel(p, kind: "plate", cuisineKey: cuisineKey, paletteKey: paletteKey,
                      seed: seed, cx: cx, cy: cy, unit: unit)
    }
}
