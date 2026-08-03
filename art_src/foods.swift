import Foundation
import CoreGraphics

// Thirty ways food sits on a plate. Each one is drawn — contour, form shading,
// texture — never a filled silhouette. They compose: a bed can take a main
// archetype and up to two more, then garnish on top.

// MARK: - Shared primitives

/// A rounded mass of something: wash, form shading, contour. The workhorse.
func mass(_ p: Plate, _ pts: [CGPoint], _ colour: Col, depth: Int = 2,
          weight: Double = 1.6, spacing: Double = 3.0, strength: Double = 0.44,
          seed: UInt64 = 5) {
    guard pts.count > 2 else { return }
    wash(p, pts, colour, strength: strength, bleed: max(1.2, weight * 1.6), seed: seed)
    formShade(p, pts, inset: spacing * 3.4, depth: depth, spacing: spacing,
              colour: Ink.sepiaSoft.al(0.6), seed: seed &+ 7)
    penContour(p, pts, weight: weight, seed: seed &+ 13)
}

/// A highlight where the light strikes a rounded thing.
func sheen(_ p: Plate, cx: Double, cy: Double, rx: Double, ry: Double, seed: UInt64) {
    let lx = cos(p.light), ly = sin(p.light)
    p.ellipse(cx + lx * rx * 0.38, cy + ly * ry * 0.38, rx * 0.30, ry * 0.22,
              Ink.paper.al(0.30))
    _ = seed
}

func inBed(_ p: Plate, _ bed: Bed, _ body: () -> Void) {
    p.clip(bed.clip, body)
}

private func jitterRing(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double,
                        rough: Double, steps: Int, seed: UInt64) -> [CGPoint] {
    blob(cx: cx, cy: cy, rx: rx, ry: ry, rough: rough, steps: steps, seed: seed)
}

// MARK: - Archetypes

func drawFood(_ p: Plate, _ kind: String, bed: Bed, palette: Col, seed: UInt64, layer: Int) {
    let u = min(bed.rx, bed.ry)
    var rng = RNG(seed &+ UInt64(layer * 101))
    // Later layers sit a little back and to one side so nothing stacks dead centre.
    let ox = layer == 0 ? 0.0 : rng.r(-0.30, 0.30) * bed.rx
    let oy = layer == 0 ? 0.0 : rng.r(0.05, 0.34) * bed.ry
    let cx = bed.cx + ox
    let cy = bed.cy + oy
    let sc = layer == 0 ? 1.0 : 0.62

    inBed(p, bed) {
        switch kind {

        case "noodleNest":
            let rx = bed.rx * 0.86 * sc, ry = bed.ry * 0.80 * sc
            // the mass of the nest first, so the strands read against something
            let heap = jitterRing(cx, cy, rx * 0.94, ry * 0.90, rough: 0.07, steps: 28,
                                  seed: seed &+ 3)
            wash(p, heap, palette.lt(0.10), strength: 0.34, bleed: u * 0.024, seed: seed &+ 5)
            for k in 0..<34 {
                let a0 = rng.r(0, 6.283)
                let rr = rng.r(0.26, 0.98)
                let span = rng.r(2.0, 4.2)
                var strand: [CGPoint] = []
                for j in 0...20 {
                    let a = a0 + span * Double(j) / 20.0
                    let wob = 1.0 + sin(Double(j) * 0.8 + Double(k)) * 0.09
                    strand.append(pnt(cx + cos(a) * rx * rr * wob,
                                      cy + sin(a) * ry * rr * wob))
                }
                // a pale body with a dark edge is what makes a strand read as round
                penStroke(p, strand, weight: u * rng.r(0.056, 0.082),
                          colour: palette.lt(rng.r(0.20, 0.42)).al(0.95),
                          wobble: u * 0.006, taper: true, seed: seed &+ UInt64(k * 7))
                penStroke(p, strand.map { pnt(Double($0.x), Double($0.y) - u * 0.020) },
                          weight: u * rng.r(0.016, 0.026),
                          colour: Ink.sepia.al(rng.r(0.55, 0.85)),
                          wobble: u * 0.005, taper: true, seed: seed &+ UInt64(k * 11 + 3))
            }
            // a few strands lifted clear of the nest
            for k in 0..<5 {
                let a = rng.r(0, 6.283)
                penStroke(p, [CGPoint(x: cx + cos(a) * rx * 0.3, y: cy + sin(a) * ry * 0.3),
                              CGPoint(x: cx + cos(a) * rx * 0.9, y: cy + sin(a) * ry * 0.9 + ry * 0.25),
                              CGPoint(x: cx + cos(a) * rx * 1.05, y: cy + sin(a) * ry * 1.1 + ry * 0.10)],
                          weight: u * 0.048, colour: Ink.sepia.al(0.9), wobble: u * 0.008,
                          taper: true, seed: seed &+ UInt64(k * 31 + 3))
            }

        case "brothSurface":
            let ring = jitterRing(cx, cy, bed.rx * 0.97, bed.ry * 0.95, rough: 0.02, steps: 40,
                                  seed: seed &+ 3)
            wash(p, ring, palette.dk(0.06), strength: 0.40, bleed: u * 0.030, seed: seed &+ 5)
            // ripples
            for k in 0..<4 {
                let f = 0.32 + Double(k) * 0.18
                penBroken(p, ellipsePoints(cx: cx, cy: cy, rx: bed.rx * f, ry: bed.ry * f, steps: 40),
                          weight: u * 0.014, colour: Ink.sepiaSoft.al(0.28),
                          pieces: 3, gap: 0.16, wobble: u * 0.006, seed: seed &+ UInt64(k * 11))
            }
            // beads of fat catching the light
            for k in 0..<16 {
                let a = rng.r(0, 6.283), rr = rng.r(0.1, 0.9)
                let x = cx + cos(a) * bed.rx * rr, y = cy + sin(a) * bed.ry * rr
                let r = u * rng.r(0.020, 0.058)
                let e = ellipsePoints(cx: x, cy: y, rx: r, ry: r * 0.78, steps: 16)
                p.poly(e, Ink.saffron.al(0.30))
                penStroke(p, e + [e[0]], weight: u * 0.008, colour: Ink.sepiaSoft.al(0.45),
                          wobble: 0.4, taper: false, seed: seed &+ UInt64(k * 5))
                p.ellipse(x - r * 0.25, y + r * 0.25, r * 0.28, r * 0.20, Ink.paper.al(0.35))
            }

        case "riceMound":
            let rx = bed.rx * 0.66 * sc, ry = bed.ry * 0.62 * sc
            var dome: [CGPoint] = []
            for k in 0..<34 {
                let a = Double(k) / 34.0 * 6.283185
                let lift = 1.0 + 0.30 * max(0, sin(a))
                dome.append(CGPoint(x: cx + cos(a) * rx * (1 + rng.r(-0.03, 0.03)),
                                    y: cy + sin(a) * ry * lift))
            }
            mass(p, dome, Ink.cream, depth: 2, weight: u * 0.020, spacing: u * 0.030,
                 strength: 0.30, seed: seed &+ 5)
            p.clip(polyPath(dome)) {
                for k in 0..<260 {
                    let a = rng.r(0, 6.283), rr = rng.r(0, 1)
                    let gx = cx + cos(a) * rx * rr
                    let gy = cy + sin(a) * ry * rr * 1.2
                    let ga = rng.r(0, 3.14)
                    let gl = u * rng.r(0.020, 0.040)
                    penStroke(p, [CGPoint(x: gx - cos(ga) * gl, y: gy - sin(ga) * gl),
                                  CGPoint(x: gx + cos(ga) * gl, y: gy + sin(ga) * gl)],
                              weight: u * 0.011, colour: Ink.sepiaSoft.al(rng.r(0.18, 0.48)),
                              wobble: 0.3, taper: true, seed: seed &+ UInt64(k))
                }
            }

        case "riceScatter":
            for k in 0..<300 {
                let a = rng.r(0, 6.283), rr = pow(rng.d(), 0.55)
                let gx = cx + cos(a) * bed.rx * 0.92 * rr * sc
                let gy = cy + sin(a) * bed.ry * 0.88 * rr * sc
                let ga = rng.r(0, 3.14)
                let gl = u * rng.r(0.024, 0.044)
                let tone = rng.chance(0.22) ? palette : Ink.cream
                penStroke(p, [CGPoint(x: gx - cos(ga) * gl, y: gy - sin(ga) * gl),
                              CGPoint(x: gx + cos(ga) * gl, y: gy + sin(ga) * gl)],
                          weight: u * rng.r(0.014, 0.022), colour: tone.dk(0.25).al(rng.r(0.4, 0.9)),
                          wobble: 0.3, taper: true, seed: seed &+ UInt64(k))
            }

        case "flatbread":
            let rx = bed.rx * 0.90 * sc, ry = bed.ry * 0.86 * sc
            let round = jitterRing(cx, cy, rx, ry, rough: 0.045, steps: 34, seed: seed &+ 3)
            mass(p, round, Ink.ochre.mix(palette, 0.30), depth: 1, weight: u * 0.022,
                 spacing: u * 0.034, strength: 0.34, seed: seed &+ 5)
            p.clip(polyPath(round)) {
                // blisters from the oven
                for k in 0..<26 {
                    let a = rng.r(0, 6.283), rr = pow(rng.d(), 0.6)
                    let bx = cx + cos(a) * rx * rr, by = cy + sin(a) * ry * rr
                    let br = u * rng.r(0.030, 0.085)
                    let bl = jitterRing(bx, by, br, br * 0.78, rough: 0.30, steps: 14,
                                        seed: seed &+ UInt64(k * 13))
                    p.poly(bl, Ink.char.al(rng.r(0.20, 0.42)))
                    penContour(p, bl, weight: u * 0.008, colour: Ink.sepiaSoft.al(0.5),
                               seed: seed &+ UInt64(k))
                }
                // a fold, so it is bread and not a coaster
                penStroke(p, [CGPoint(x: cx - rx * 0.8, y: cy + ry * 0.30),
                              CGPoint(x: cx, y: cy + ry * 0.12),
                              CGPoint(x: cx + rx * 0.78, y: cy + ry * 0.34)],
                          weight: u * 0.020, colour: Ink.sepiaSoft.al(0.7), wobble: u * 0.008,
                          taper: true, seed: seed &+ 41)
            }

        case "loafSlices":
            for k in 0..<3 {
                let lean = Double(k) - 1.0
                let sx = cx + lean * bed.rx * 0.44 * sc
                let sy = cy - lean * bed.ry * 0.10
                let hw = bed.rx * 0.30 * sc, hh = bed.ry * 0.56 * sc
                var sl: [CGPoint] = []
                for j in 0..<26 {
                    let a = Double(j) / 26.0 * 6.283185
                    let sq = 1.0 + 0.16 * cos(a * 2)
                    sl.append(CGPoint(x: sx + cos(a + 0.12 * lean) * hw * sq,
                                      y: sy + sin(a + 0.12 * lean) * hh * sq))
                }
                mass(p, sl, Ink.cream.mix(palette, 0.20), depth: 2, weight: u * 0.020,
                     spacing: u * 0.030, strength: 0.32, seed: seed &+ UInt64(k * 17))
                // crust band and an open crumb
                penStroke(p, sl + [sl[0]], weight: u * 0.030, colour: Ink.umber.al(0.55),
                          wobble: u * 0.006, taper: false, seed: seed &+ UInt64(k * 5))
                p.clip(polyPath(sl)) {
                    for j in 0..<44 {
                        let bx = sx + rng.r(-0.75, 0.75) * hw
                        let by = sy + rng.r(-0.75, 0.75) * hh
                        let br = u * rng.r(0.012, 0.034)
                        p.ellipse(bx, by, br, br * 0.8, Ink.sepiaSoft.al(rng.r(0.12, 0.30)))
                        _ = j
                    }
                }
            }

        case "dumplings":
            let n = rng.i(4, 6)
            for k in 0..<n {
                let a = Double(k) / Double(n) * 6.283185 + rng.r(-0.2, 0.2)
                let dx = cx + cos(a) * bed.rx * 0.46 * sc
                let dy = cy + sin(a) * bed.ry * 0.42 * sc
                let rx = bed.rx * 0.30 * sc, ry = bed.ry * 0.26 * sc
                var body: [CGPoint] = []
                for j in 0..<26 {
                    let t = Double(j) / 26.0 * 6.283185
                    // flat-bottomed, plump on top
                    let lift = sin(t) > 0 ? 1.10 : 0.70
                    body.append(CGPoint(x: dx + cos(t) * rx, y: dy + sin(t) * ry * lift))
                }
                mass(p, body, Ink.cream.mix(palette, 0.14), depth: 2, weight: u * 0.018,
                     spacing: u * 0.026, strength: 0.30, seed: seed &+ UInt64(k * 23))
                // the pleats along the crest
                for j in 0..<6 {
                    let t = -0.35 + Double(j) / 5.0 * 0.70
                    let px = dx + t * rx * 1.5
                    penStroke(p, [CGPoint(x: px, y: dy + ry * 0.30),
                                  CGPoint(x: px + rx * 0.10, y: dy + ry * 1.02)],
                              weight: u * 0.014, colour: Ink.sepiaSoft.al(0.75),
                              wobble: u * 0.004, taper: true, seed: seed &+ UInt64(k * 31 + j))
                }
                sheen(p, cx: dx, cy: dy, rx: rx, ry: ry, seed: seed)
            }

        case "skewers":
            let n = rng.i(2, 3)
            for k in 0..<n {
                let spread = (Double(k) - Double(n - 1) / 2)
                let ang = 0.28 + spread * 0.34
                let dx = cos(ang), dy = sin(ang)
                let sx = cx - dx * bed.rx * 0.95 * sc - spread * bed.ry * 0.22
                let sy = cy - dy * bed.rx * 0.95 * sc - spread * bed.ry * 0.30
                let ex = cx + dx * bed.rx * 1.02 * sc - spread * bed.ry * 0.22
                let ey = cy + dy * bed.rx * 1.02 * sc - spread * bed.ry * 0.30
                penStroke(p, [CGPoint(x: sx, y: sy), CGPoint(x: ex, y: ey)],
                          weight: u * 0.026, colour: Ink.wood.dk(0.15),
                          wobble: u * 0.004, taper: true, seed: seed &+ UInt64(k * 7))
                for j in 0..<4 {
                    let t = 0.24 + Double(j) / 3.0 * 0.56
                    let bx = sx + (ex - sx) * t, by = sy + (ey - sy) * t
                    let br = u * 0.135 * sc
                    let chunk = jitterRing(bx, by, br, br * 0.86, rough: 0.16, steps: 18,
                                           seed: seed &+ UInt64(k * 41 + j))
                    mass(p, chunk, j % 2 == 0 ? palette : palette.dk(0.18), depth: 2,
                         weight: u * 0.016, spacing: u * 0.024, strength: 0.48,
                         seed: seed &+ UInt64(k * 53 + j))
                    // char where it met the fire
                    penBroken(p, [CGPoint(x: bx - br * 0.7, y: by + br * 0.4),
                                  CGPoint(x: bx + br * 0.7, y: by + br * 0.2)],
                              weight: u * 0.016, colour: Ink.char.al(0.55), pieces: 2,
                              gap: 0.2, wobble: 0.6, seed: seed &+ UInt64(j))
                }
            }

        case "stewChunks":
            let pool = jitterRing(cx, cy, bed.rx * 0.92 * sc, bed.ry * 0.86 * sc,
                                  rough: 0.05, steps: 30, seed: seed &+ 3)
            wash(p, pool, palette.dk(0.10), strength: 0.46, bleed: u * 0.028, seed: seed &+ 5)
            for k in 0..<7 {
                let a = rng.r(0, 6.283), rr = pow(rng.d(), 0.5)
                let bx = cx + cos(a) * bed.rx * 0.58 * rr * sc
                let by = cy + sin(a) * bed.ry * 0.54 * rr * sc
                let br = u * rng.r(0.105, 0.175) * sc
                let chunk = jitterRing(bx, by, br, br * rng.r(0.68, 0.92), rough: 0.22,
                                       steps: 16, seed: seed &+ UInt64(k * 19))
                mass(p, chunk, k % 3 == 0 ? Ink.herb : palette.lt(0.16), depth: 2,
                     weight: u * 0.016, spacing: u * 0.024, strength: 0.46,
                     seed: seed &+ UInt64(k * 29))
                sheen(p, cx: bx, cy: by, rx: br, ry: br * 0.8, seed: seed)
            }

        case "curryPool":
            let pool = jitterRing(cx, cy, bed.rx * 0.88 * sc, bed.ry * 0.82 * sc,
                                  rough: 0.07, steps: 30, seed: seed &+ 3)
            wash(p, pool, palette, strength: 0.52, bleed: u * 0.034, seed: seed &+ 5)
            penContour(p, pool, weight: u * 0.016, colour: Ink.sepiaSoft.al(0.6), seed: seed &+ 9)
            // the oil that separates and rides on top
            for k in 0..<9 {
                let a = rng.r(0, 6.283), rr = rng.r(0.15, 0.85)
                let ex = cx + cos(a) * bed.rx * 0.6 * rr
                let ey = cy + sin(a) * bed.ry * 0.55 * rr
                let er = u * rng.r(0.030, 0.075)
                let ring = ellipsePoints(cx: ex, cy: ey, rx: er, ry: er * 0.8, steps: 16)
                p.poly(ring, Ink.saffron.al(0.34))
                penStroke(p, ring + [ring[0]], weight: u * 0.008,
                          colour: Ink.rust.al(0.45), wobble: 0.4, taper: false,
                          seed: seed &+ UInt64(k * 7))
            }
            // a swirl through the middle
            var swirl: [CGPoint] = []
            for j in 0...30 {
                let t = Double(j) / 30.0
                let a = t * 6.0
                let r = bed.rx * 0.10 + t * bed.rx * 0.52
                swirl.append(CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r * 0.9))
            }
            penStroke(p, swirl, weight: u * 0.020, colour: Ink.cream.al(0.55),
                      wobble: u * 0.006, taper: true, seed: seed &+ 47)

        case "wholeFish":
            let L = bed.rx * 0.95 * sc, H = bed.ry * 0.36 * sc
            var body: [CGPoint] = []
            for j in 0...36 {
                let t = Double(j) / 36.0
                let x = cx - L + 2 * L * t
                body.append(CGPoint(x: x, y: cy + H * sin(.pi * t) * (0.75 + 0.25 * cos(t * 3))))
            }
            for j in stride(from: 36, through: 0, by: -1) {
                let t = Double(j) / 36.0
                let x = cx - L + 2 * L * t
                body.append(CGPoint(x: x, y: cy - H * sin(.pi * t) * (0.70 + 0.20 * cos(t * 2))))
            }
            mass(p, body, palette.lt(0.20), depth: 2, weight: u * 0.020, spacing: u * 0.026,
                 strength: 0.36, seed: seed &+ 5)
            p.clip(polyPath(body)) {
                // scales: overlapping arcs, not dots
                var col = 0
                var x = cx - L * 0.55
                while x < cx + L * 0.85 {
                    var y = cy - H * 0.85
                    while y < cy + H * 0.85 {
                        var arc: [CGPoint] = []
                        for j in 0...8 {
                            let a = .pi * 0.15 + Double(j) / 8.0 * .pi * 0.7
                            arc.append(CGPoint(x: x + cos(a) * u * 0.070,
                                               y: y + sin(a) * u * 0.055))
                        }
                        penStroke(p, arc, weight: u * 0.009,
                                  colour: Ink.sepiaSoft.al(0.42), wobble: 0.3, taper: true,
                                  seed: seed &+ u64(Int(x) &* 7 &+ Int(y)))
                        y += u * 0.090
                    }
                    x += u * 0.075
                    col += 1
                    _ = col
                }
            }
            // tail
            let tail = [CGPoint(x: cx - L * 0.98, y: cy),
                        CGPoint(x: cx - L * 1.30, y: cy + H * 1.05),
                        CGPoint(x: cx - L * 1.18, y: cy),
                        CGPoint(x: cx - L * 1.30, y: cy - H * 1.05)]
            mass(p, tail, palette.lt(0.30), depth: 1, weight: u * 0.016, spacing: u * 0.022,
                 strength: 0.30, seed: seed &+ 11)
            // dorsal fin
            var fin: [CGPoint] = []
            for j in 0...9 {
                let t = Double(j) / 9.0
                fin.append(CGPoint(x: cx - L * 0.35 + t * L * 0.85,
                                   y: cy + H * (0.75 + (j % 2 == 0 ? 0.50 : 0.28))))
            }
            fin.append(CGPoint(x: cx + L * 0.50, y: cy + H * 0.6))
            fin.append(CGPoint(x: cx - L * 0.35, y: cy + H * 0.6))
            mass(p, fin, palette.lt(0.34), depth: 1, weight: u * 0.013, spacing: u * 0.022,
                 strength: 0.26, seed: seed &+ 13)
            // head, gill and eye
            penStroke(p, [CGPoint(x: cx + L * 0.52, y: cy + H * 0.75),
                          CGPoint(x: cx + L * 0.46, y: cy),
                          CGPoint(x: cx + L * 0.54, y: cy - H * 0.72)],
                      weight: u * 0.017, colour: Ink.sepia, wobble: u * 0.004,
                      taper: true, seed: seed &+ 17)
            p.disc(cx + L * 0.78, cy + H * 0.22, u * 0.048, Ink.paper.al(0.85))
            p.disc(cx + L * 0.78, cy + H * 0.22, u * 0.028, Ink.sepia)
            let eye = ellipsePoints(cx: cx + L * 0.78, cy: cy + H * 0.22, rx: u * 0.050,
                                    ry: u * 0.050, steps: 18)
            penStroke(p, eye + [eye[0]], weight: u * 0.010, colour: Ink.sepia,
                      wobble: 0.3, taper: false, seed: seed &+ 19)

        case "shellfish":
            // two fan shells and a prawn curled between them
            for k in 0..<2 {
                let sx = cx + (k == 0 ? -1.0 : 1.0) * bed.rx * 0.44 * sc
                let sy = cy + (k == 0 ? 0.22 : -0.16) * bed.ry * sc
                let r = u * 0.30 * sc
                var fan: [CGPoint] = [CGPoint(x: sx, y: sy - r * 0.8)]
                for j in 0...16 {
                    let a = -.pi * 0.10 + Double(j) / 16.0 * .pi * 1.20
                    fan.append(CGPoint(x: sx + cos(a) * r, y: sy - r * 0.8 + sin(a) * r * 1.15))
                }
                mass(p, fan, Ink.blush.mix(palette, 0.35), depth: 2, weight: u * 0.016,
                     spacing: u * 0.024, strength: 0.36, seed: seed &+ UInt64(k * 23))
                for j in 0...8 {
                    let a = -.pi * 0.06 + Double(j) / 8.0 * .pi * 1.12
                    penStroke(p, [CGPoint(x: sx, y: sy - r * 0.78),
                                  CGPoint(x: sx + cos(a) * r * 0.96,
                                          y: sy - r * 0.8 + sin(a) * r * 1.10)],
                              weight: u * 0.010, colour: Ink.sepiaSoft.al(0.6),
                              wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 31 + j))
                }
            }
            do {
                let r = u * 0.34 * sc
                var prawn: [CGPoint] = []
                for j in 0...18 {
                    let a = .pi * 0.15 + Double(j) / 18.0 * .pi * 1.5
                    prawn.append(CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r * 0.9))
                }
                for j in stride(from: 18, through: 0, by: -1) {
                    let a = .pi * 0.15 + Double(j) / 18.0 * .pi * 1.5
                    let rr = r - u * 0.115 * (0.5 + 0.5 * Double(j) / 18.0)
                    prawn.append(CGPoint(x: cx + cos(a) * rr, y: cy + sin(a) * rr * 0.9))
                }
                mass(p, prawn, Ink.blush, depth: 2, weight: u * 0.016, spacing: u * 0.022,
                     strength: 0.44, seed: seed &+ 61)
                for j in 0...6 {
                    let a = .pi * 0.25 + Double(j) / 6.0 * .pi * 1.25
                    penStroke(p, [CGPoint(x: cx + cos(a) * r * 1.0, y: cy + sin(a) * r * 0.9),
                                  CGPoint(x: cx + cos(a) * (r - u * 0.115),
                                          y: cy + sin(a) * (r - u * 0.115) * 0.9)],
                              weight: u * 0.011, colour: Ink.rust.al(0.75),
                              wobble: 0.3, taper: true, seed: seed &+ UInt64(j * 13))
                }
            }

        case "saladHeap":
            for k in 0..<16 {
                let a = rng.r(0, 6.283), rr = pow(rng.d(), 0.45)
                let lx = cx + cos(a) * bed.rx * 0.72 * rr * sc
                let ly = cy + sin(a) * bed.ry * 0.66 * rr * sc
                let lr = u * rng.r(0.14, 0.26) * sc
                let tilt = rng.r(0, 6.283)
                var leaf: [CGPoint] = []
                for j in 0..<20 {
                    let t = Double(j) / 20.0 * 6.283185
                    let ruffle = 1.0 + 0.20 * sin(t * 5)
                    let px = cos(t) * lr * 1.15 * ruffle
                    let py = sin(t) * lr * 0.68 * ruffle
                    leaf.append(CGPoint(x: lx + px * cos(tilt) - py * sin(tilt),
                                        y: ly + px * sin(tilt) + py * cos(tilt)))
                }
                let tone = rng.chance(0.25) ? palette : Ink.herb.lt(rng.r(0, 0.28))
                mass(p, leaf, tone, depth: 1, weight: u * 0.012, spacing: u * 0.022,
                     strength: 0.36, seed: seed &+ UInt64(k * 17))
                penStroke(p, [CGPoint(x: lx - cos(tilt) * lr, y: ly - sin(tilt) * lr),
                              CGPoint(x: lx + cos(tilt) * lr, y: ly + sin(tilt) * lr)],
                          weight: u * 0.010, colour: Ink.sepiaSoft.al(0.55),
                          wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 7))
            }

        case "rollSlices":
            let n = rng.i(5, 6)
            for k in 0..<n {
                let a = Double(k) / Double(n) * 6.283185 + 0.3
                let dx = cx + cos(a) * bed.rx * 0.50 * sc
                let dy = cy + sin(a) * bed.ry * 0.46 * sc
                let r = u * 0.23 * sc
                let outer = jitterRing(dx, dy, r, r * 0.94, rough: 0.05, steps: 22,
                                       seed: seed &+ UInt64(k * 13))
                mass(p, outer, Ink.cream, depth: 2, weight: u * 0.016, spacing: u * 0.024,
                     strength: 0.28, seed: seed &+ UInt64(k * 19))
                // the dark wrapper and the core
                penStroke(p, outer + [outer[0]], weight: u * 0.026,
                          colour: Ink.char.mix(Ink.herb, 0.35).al(0.85),
                          wobble: u * 0.004, taper: false, seed: seed &+ UInt64(k * 5))
                let core = jitterRing(dx, dy, r * 0.42, r * 0.40, rough: 0.10, steps: 16,
                                      seed: seed &+ UInt64(k * 29))
                mass(p, core, palette, depth: 1, weight: u * 0.012, spacing: u * 0.020,
                     strength: 0.52, seed: seed &+ UInt64(k * 31))
                // grains of rice around the core
                p.clip(polyPath(outer)) {
                    for j in 0..<40 {
                        let ga = rng.r(0, 6.283), grr = rng.r(0.45, 0.95)
                        let gx = dx + cos(ga) * r * grr, gy = dy + sin(ga) * r * grr
                        let gl = u * 0.020
                        let gd = rng.r(0, 3.14)
                        penStroke(p, [CGPoint(x: gx - cos(gd) * gl, y: gy - sin(gd) * gl),
                                      CGPoint(x: gx + cos(gd) * gl, y: gy + sin(gd) * gl)],
                                  weight: u * 0.009, colour: Ink.sepiaSoft.al(0.30),
                                  wobble: 0.2, taper: true, seed: seed &+ UInt64(j))
                    }
                }
            }

        case "wrappedParcel":
            let L = bed.rx * 0.74 * sc, H = bed.ry * 0.52 * sc
            var tube: [CGPoint] = []
            for j in 0...24 {
                let t = Double(j) / 24.0
                tube.append(CGPoint(x: cx - L + 2 * L * t, y: cy + H * (0.92 + 0.10 * sin(t * 6))))
            }
            tube.append(CGPoint(x: cx + L * 1.04, y: cy))
            for j in stride(from: 24, through: 0, by: -1) {
                let t = Double(j) / 24.0
                tube.append(CGPoint(x: cx - L + 2 * L * t, y: cy - H * (0.92 + 0.10 * sin(t * 5))))
            }
            tube.append(CGPoint(x: cx - L * 1.04, y: cy))
            mass(p, tube, Ink.cream.mix(palette, 0.22), depth: 2, weight: u * 0.020,
                 spacing: u * 0.028, strength: 0.34, seed: seed &+ 5)
            // the folds along the seam
            for j in 0..<5 {
                let t = 0.15 + Double(j) / 4.0 * 0.7
                let x = cx - L + 2 * L * t
                penStroke(p, [CGPoint(x: x, y: cy - H * 0.85),
                              CGPoint(x: x + L * 0.06, y: cy + H * 0.88)],
                          weight: u * 0.013, colour: Ink.sepiaSoft.al(0.65),
                          wobble: u * 0.004, taper: true, seed: seed &+ UInt64(j * 11))
            }
            // the open end showing what is inside
            let open = ellipsePoints(cx: cx + L * 0.92, cy: cy, rx: H * 0.44, ry: H * 0.92, steps: 20)
            mass(p, open, palette.dk(0.10), depth: 2, weight: u * 0.014, spacing: u * 0.020,
                 strength: 0.55, seed: seed &+ 23)
            for j in 0..<5 {
                let a = rng.r(0, 6.283)
                penStroke(p, [CGPoint(x: cx + L * 0.92, y: cy),
                              CGPoint(x: cx + L * 0.92 + cos(a) * H * 0.36,
                                      y: cy + sin(a) * H * 0.74)],
                          weight: u * 0.012, colour: Ink.herb.dk(0.10).al(0.8),
                          wobble: 0.4, taper: true, seed: seed &+ UInt64(j * 7))
            }

        case "layeredSlice":
            let hw = bed.rx * 0.62 * sc, hh = bed.ry * 0.60 * sc
            let apex = CGPoint(x: cx - hw, y: cy + hh * 0.10)
            let strata = 5
            for k in 0..<strata {
                let y0 = cy - hh + Double(k) / Double(strata) * hh * 2
                let y1 = cy - hh + Double(k + 1) / Double(strata) * hh * 2
                let quad = [CGPoint(x: apex.x + hw * 0.30, y: y0),
                            CGPoint(x: cx + hw, y: y0 + hh * 0.06),
                            CGPoint(x: cx + hw, y: y1 + hh * 0.06),
                            CGPoint(x: apex.x + hw * 0.30, y: y1)]
                let tone: Col = k % 2 == 0 ? palette : Ink.cream.mix(palette, 0.25)
                wash(p, quad, tone, strength: 0.44, bleed: u * 0.014, seed: seed &+ UInt64(k * 13))
                hatch(p, polyPath(quad), angle: k % 2 == 0 ? 0.5 : 2.4,
                      spacing: max(2.4, u * 0.040), weight: u * 0.010,
                      colour: Ink.sepiaSoft.al(k % 2 == 0 ? 0.34 : 0.20),
                      coverage: 0.8, seed: seed &+ UInt64(k * 17))
                penContour(p, quad, weight: u * 0.013, colour: Ink.sepiaSoft.al(0.8),
                           seed: seed &+ UInt64(k * 19))
            }
            // the cut face and the top crust
            penStroke(p, [CGPoint(x: apex.x + hw * 0.30, y: cy - hh),
                          CGPoint(x: apex.x + hw * 0.30, y: cy + hh)],
                      weight: u * 0.022, colour: Ink.sepia, wobble: u * 0.004,
                      taper: false, seed: seed &+ 41)
            penStroke(p, [CGPoint(x: apex.x + hw * 0.30, y: cy + hh),
                          CGPoint(x: cx + hw, y: cy + hh + hh * 0.06)],
                      weight: u * 0.024, colour: Ink.umber, wobble: u * 0.005,
                      taper: false, seed: seed &+ 43)

        case "grillMarks":
            let hw = bed.rx * 0.76 * sc, hh = bed.ry * 0.52 * sc
            let slab = jitterRing(cx, cy, hw, hh, rough: 0.06, steps: 26, seed: seed &+ 3)
            mass(p, slab, palette.dk(0.12), depth: 3, weight: u * 0.022, spacing: u * 0.026,
                 strength: 0.52, seed: seed &+ 5)
            p.clip(polyPath(slab)) {
                for k in 0..<5 {
                    let t = -0.8 + Double(k) / 4.0 * 1.6
                    penStroke(p, [CGPoint(x: cx + t * hw - hw * 0.5, y: cy - hh * 1.1),
                                  CGPoint(x: cx + t * hw + hw * 0.5, y: cy + hh * 1.1)],
                              weight: u * 0.052, colour: Ink.char.al(0.72),
                              wobble: u * 0.006, taper: false, seed: seed &+ UInt64(k * 11))
                }
                for k in 0..<3 {
                    let t = -0.6 + Double(k) / 2.0 * 1.2
                    penStroke(p, [CGPoint(x: cx - hw * 1.1, y: cy + t * hh + hh * 0.35),
                                  CGPoint(x: cx + hw * 1.1, y: cy + t * hh - hh * 0.35)],
                              weight: u * 0.040, colour: Ink.char.al(0.48),
                              wobble: u * 0.006, taper: false, seed: seed &+ UInt64(k * 17))
                }
            }
            sheen(p, cx: cx, cy: cy, rx: hw, ry: hh, seed: seed)

        case "friedPieces":
            let n = rng.i(5, 7)
            for k in 0..<n {
                let a = Double(k) / Double(n) * 6.283185 + rng.r(-0.3, 0.3)
                let rr = rng.r(0.15, 0.60)
                let fx = cx + cos(a) * bed.rx * rr * sc
                let fy = cy + sin(a) * bed.ry * rr * sc
                let fr = u * rng.r(0.16, 0.26) * sc
                // a knobbly, crusted outline — the crust IS the shape
                var piece: [CGPoint] = []
                for j in 0..<30 {
                    let t = Double(j) / 30.0 * 6.283185
                    let knob = 1.0 + 0.20 * sin(t * rng.r(4, 7)) + rng.r(-0.09, 0.09)
                    piece.append(CGPoint(x: fx + cos(t) * fr * knob,
                                         y: fy + sin(t) * fr * knob * 0.86))
                }
                mass(p, piece, Ink.ochre.mix(palette, 0.35), depth: 2, weight: u * 0.016,
                     spacing: u * 0.024, strength: 0.44, seed: seed &+ UInt64(k * 23))
                stipple(p, polyPath(piece), density: 0.0035, sizeMin: u * 0.006,
                        sizeMax: u * 0.016, colour: Ink.umber.al(0.55), seed: seed &+ UInt64(k * 29))
                sheen(p, cx: fx, cy: fy, rx: fr, ry: fr * 0.8, seed: seed)
            }

        case "eggDish":
            let n = rng.i(1, 2)
            for k in 0..<n {
                let ex = cx + (n == 1 ? 0 : (Double(k) - 0.5) * bed.rx * 0.62 * sc)
                let ey = cy + (n == 1 ? 0 : (Double(k) - 0.5) * bed.ry * 0.24 * sc)
                let white = jitterRing(ex, ey, bed.rx * 0.46 * sc, bed.ry * 0.40 * sc,
                                       rough: 0.16, steps: 28, seed: seed &+ UInt64(k * 13))
                wash(p, white, Ink.cream.lt(0.35), strength: 0.26, bleed: u * 0.020,
                     seed: seed &+ UInt64(k * 17))
                penContour(p, white, weight: u * 0.014, colour: Ink.sepiaSoft.al(0.65),
                           seed: seed &+ UInt64(k * 19))
                let yr = u * 0.20 * sc
                let yolk = ellipsePoints(cx: ex, cy: ey, rx: yr, ry: yr * 0.92, steps: 24)
                mass(p, yolk, Ink.saffron, depth: 2, weight: u * 0.016, spacing: u * 0.022,
                     strength: 0.62, seed: seed &+ UInt64(k * 23))
                p.ellipse(ex - yr * 0.28, ey + yr * 0.28, yr * 0.26, yr * 0.20, Ink.paper.al(0.42))
            }

        case "porridge":
            let heap = jitterRing(cx, cy, bed.rx * 0.80 * sc, bed.ry * 0.74 * sc,
                                  rough: 0.06, steps: 30, seed: seed &+ 3)
            mass(p, heap, palette.lt(0.18), depth: 2, weight: u * 0.020, spacing: u * 0.028,
                 strength: 0.40, seed: seed &+ 5)
            p.clip(polyPath(heap)) {
                // the drag of a spoon through it
                for k in 0..<7 {
                    var drag: [CGPoint] = []
                    let a0 = rng.r(0, 6.283)
                    for j in 0...12 {
                        let t = Double(j) / 12.0
                        let a = a0 + t * 1.6
                        let r = bed.rx * (0.12 + t * 0.60) * sc
                        drag.append(CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r * 0.9))
                    }
                    penStroke(p, drag, weight: u * 0.026, colour: Ink.sepiaSoft.al(rng.r(0.25, 0.5)),
                              wobble: u * 0.006, taper: true, seed: seed &+ UInt64(k * 11))
                }
                stipple(p, polyPath(heap), density: 0.0016, sizeMin: u * 0.006,
                        sizeMax: u * 0.014, colour: Ink.umber.al(0.35), seed: seed &+ 31)
            }

        case "tacoFolds":
            let n = rng.i(2, 3)
            for k in 0..<n {
                let tx = cx + (Double(k) - Double(n - 1) / 2) * bed.rx * 0.58 * sc
                let ty = cy + (Double(k) - Double(n - 1) / 2) * bed.ry * 0.14 * sc
                let r = u * 0.36 * sc
                // a folded round seen end-on: a U of shell, filling heaped inside
                var shell: [CGPoint] = []
                for j in 0...18 {
                    let a = .pi + Double(j) / 18.0 * .pi
                    shell.append(CGPoint(x: tx + cos(a) * r, y: ty + sin(a) * r * 1.05))
                }
                for j in stride(from: 18, through: 0, by: -1) {
                    let a = .pi + Double(j) / 18.0 * .pi
                    shell.append(CGPoint(x: tx + cos(a) * r * 0.80, y: ty + sin(a) * r * 0.86))
                }
                mass(p, shell, Ink.ochre.mix(palette, 0.20), depth: 2, weight: u * 0.018,
                     spacing: u * 0.024, strength: 0.38, seed: seed &+ UInt64(k * 19))
                // filling spilling over the lip
                for j in 0..<9 {
                    let fx = tx + rng.r(-0.75, 0.75) * r
                    let fy = ty + rng.r(-0.05, 0.30) * r
                    let fr = u * rng.r(0.045, 0.085)
                    let bit = jitterRing(fx, fy, fr, fr * 0.8, rough: 0.28, steps: 12,
                                         seed: seed &+ UInt64(k * 41 + j))
                    mass(p, bit, j % 3 == 0 ? Ink.herb : palette, depth: 1, weight: u * 0.010,
                         spacing: u * 0.018, strength: 0.5, seed: seed &+ UInt64(j * 7))
                }
            }

        case "pancakeStack":
            let n = rng.i(3, 4)
            for k in 0..<n {
                let ry = bed.ry * 0.16 * sc
                let cyk = cy - bed.ry * 0.28 * sc + Double(k) * ry * 1.55
                let rx = bed.rx * (0.72 - Double(k) * 0.015) * sc
                let disc = jitterRing(cx, cyk, rx, ry * 1.6, rough: 0.05, steps: 26,
                                      seed: seed &+ UInt64(k * 13))
                mass(p, disc, Ink.ochre.mix(palette, 0.25), depth: 2, weight: u * 0.018,
                     spacing: u * 0.024, strength: 0.36, seed: seed &+ UInt64(k * 17))
                // the browned face
                stipple(p, polyPath(disc), density: 0.0020, sizeMin: u * 0.005,
                        sizeMax: u * 0.013, colour: Ink.umber.al(0.42), seed: seed &+ UInt64(k * 23))
            }

        case "pastryTart":
            let rx = bed.rx * 0.82 * sc, ry = bed.ry * 0.76 * sc
            let outer = ellipsePoints(cx: cx, cy: cy, rx: rx, ry: ry, steps: 60)
            mass(p, outer, Ink.ochre.mix(Ink.cream, 0.35), depth: 2, weight: u * 0.020,
                 spacing: u * 0.028, strength: 0.34, seed: seed &+ 5)
            // crimped edge
            aroundEllipse(cx, cy, rx * 0.97, ry * 0.97, count: 26) { i, _, pt, t in
                let n = CGPoint(x: CGFloat(-sin(t)), y: CGFloat(cos(t)))
                penStroke(p, [CGPoint(x: pt.x + n.x * CGFloat(u * 0.075),
                                      y: pt.y + n.y * CGFloat(u * 0.075)),
                              CGPoint(x: pt.x - n.x * CGFloat(u * 0.075),
                                      y: pt.y - n.y * CGFloat(u * 0.075))],
                          weight: u * 0.018, colour: Ink.umber.al(0.7), wobble: u * 0.004,
                          taper: true, seed: seed &+ UInt64(i * 7))
            }
            // the filling inside the shell
            let fill = ellipsePoints(cx: cx, cy: cy, rx: rx * 0.74, ry: ry * 0.70, steps: 40)
            mass(p, fill, palette, depth: 1, weight: u * 0.014, spacing: u * 0.024,
                 strength: 0.50, seed: seed &+ 29)
            p.clip(polyPath(fill)) {
                for k in 0..<7 {
                    let a = rng.r(0, 6.283), rr = rng.r(0.2, 0.85)
                    let fx = cx + cos(a) * rx * 0.7 * rr, fy = cy + sin(a) * ry * 0.66 * rr
                    let fr = u * rng.r(0.055, 0.10)
                    let piece = jitterRing(fx, fy, fr, fr * 0.85, rough: 0.14, steps: 14,
                                           seed: seed &+ UInt64(k * 31))
                    mass(p, piece, palette.dk(0.16), depth: 1, weight: u * 0.010,
                         spacing: u * 0.018, strength: 0.45, seed: seed &+ UInt64(k * 37))
                }
            }

        case "scoop":
            let n = rng.i(2, 3)
            for k in 0..<n {
                let a = Double(k) / Double(n) * 6.283185 + 0.6
                let sx = cx + cos(a) * bed.rx * 0.34 * sc
                let sy = cy + sin(a) * bed.ry * 0.30 * sc
                let r = u * 0.30 * sc
                let ball = jitterRing(sx, sy, r, r * 0.92, rough: 0.07, steps: 26,
                                      seed: seed &+ UInt64(k * 13))
                mass(p, ball, k == 0 ? palette : palette.lt(0.22), depth: 2, weight: u * 0.018,
                     spacing: u * 0.024, strength: 0.44, seed: seed &+ UInt64(k * 17))
                // the ridge a scoop leaves
                var ridge: [CGPoint] = []
                for j in 0...14 {
                    let t = Double(j) / 14.0
                    let ang = .pi * 0.15 + t * .pi * 1.5
                    ridge.append(CGPoint(x: sx + cos(ang) * r * (0.30 + t * 0.55),
                                         y: sy + sin(ang) * r * (0.30 + t * 0.55) * 0.9))
                }
                penStroke(p, ridge, weight: u * 0.020, colour: Ink.sepiaSoft.al(0.55),
                          wobble: u * 0.005, taper: true, seed: seed &+ UInt64(k * 23))
                sheen(p, cx: sx, cy: sy, rx: r, ry: r * 0.9, seed: seed)
            }

        case "cornCob":
            let L = bed.rx * 0.82 * sc, H = bed.ry * 0.24 * sc
            var cob: [CGPoint] = []
            for j in 0...26 {
                let t = Double(j) / 26.0
                cob.append(CGPoint(x: cx - L + 2 * L * t, y: cy + H * sin(.pi * min(1, t * 1.08))))
            }
            for j in stride(from: 26, through: 0, by: -1) {
                let t = Double(j) / 26.0
                cob.append(CGPoint(x: cx - L + 2 * L * t, y: cy - H * sin(.pi * min(1, t * 1.08))))
            }
            mass(p, cob, Ink.saffron.mix(palette, 0.25), depth: 2, weight: u * 0.020,
                 spacing: u * 0.026, strength: 0.42, seed: seed &+ 5)
            p.clip(polyPath(cob)) {
                var row = 0
                var yy = cy - H
                while yy < cy + H {
                    var xx = cx - L
                    while xx < cx + L {
                        let k = ellipsePoints(cx: xx + Double(row % 2) * u * 0.045,
                                              cy: yy, rx: u * 0.042, ry: u * 0.034, steps: 12)
                        p.poly(k, Ink.saffron.lt(0.10).al(0.55))
                        penContour(p, k, weight: u * 0.008, colour: Ink.umber.al(0.5),
                                   seed: seed &+ u64(Int(xx) &+ Int(yy)))
                        xx += u * 0.090
                    }
                    yy += u * 0.068
                    row += 1
                }
            }

        case "pickleFan":
            let n = 7
            for k in 0..<n {
                let t = Double(k) / Double(n - 1) - 0.5
                let sx = cx + t * bed.rx * 1.05 * sc
                let sy = cy - abs(t) * bed.ry * 0.18 * sc
                let r = u * 0.20 * sc
                let slice = ellipsePoints(cx: sx, cy: sy, rx: r * 0.86, ry: r, steps: 22)
                mass(p, slice, k % 2 == 0 ? palette : palette.lt(0.20), depth: 1,
                     weight: u * 0.014, spacing: u * 0.020, strength: 0.42,
                     seed: seed &+ UInt64(k * 13))
                let inner = ellipsePoints(cx: sx, cy: sy, rx: r * 0.52, ry: r * 0.62, steps: 18)
                penStroke(p, inner + [inner[0]], weight: u * 0.010,
                          colour: Ink.sepiaSoft.al(0.55), wobble: 0.3, taper: false,
                          seed: seed &+ UInt64(k * 17))
            }

        case "cubes":
            let n = rng.i(6, 8)
            for k in 0..<n {
                let a = rng.r(0, 6.283), rr = pow(rng.d(), 0.5)
                let bx = cx + cos(a) * bed.rx * 0.62 * rr * sc
                let by = cy + sin(a) * bed.ry * 0.56 * rr * sc
                let s = u * rng.r(0.11, 0.16) * sc
                let top = [CGPoint(x: bx, y: by + s * 0.62),
                           CGPoint(x: bx + s, y: by + s * 0.20),
                           CGPoint(x: bx, y: by - s * 0.22),
                           CGPoint(x: bx - s, y: by + s * 0.20)]
                let left = [top[3], top[2], CGPoint(x: bx, y: by - s * 0.95),
                            CGPoint(x: bx - s, y: by - s * 0.52)]
                let right = [top[2], top[1], CGPoint(x: bx + s, y: by - s * 0.52),
                             CGPoint(x: bx, y: by - s * 0.95)]
                wash(p, top, palette.lt(0.24), strength: 0.42, bleed: u * 0.008,
                     seed: seed &+ UInt64(k * 7))
                wash(p, left, palette.dk(0.10), strength: 0.46, bleed: u * 0.008,
                     seed: seed &+ UInt64(k * 11))
                wash(p, right, palette.dk(0.24), strength: 0.50, bleed: u * 0.008,
                     seed: seed &+ UInt64(k * 13))
                hatch(p, polyPath(right), angle: 1.2, spacing: max(2.0, u * 0.028),
                      weight: u * 0.008, colour: Ink.sepiaSoft.al(0.45), coverage: 0.85,
                      seed: seed &+ UInt64(k * 17))
                for face in [top, left, right] {
                    penContour(p, face, weight: u * 0.012, seed: seed &+ UInt64(k * 19))
                }
            }

        case "meatSlab":
            let hw = bed.rx * 0.56 * sc, hh = bed.ry * 0.48 * sc
            let joint = jitterRing(cx - bed.rx * 0.20 * sc, cy, hw, hh, rough: 0.09, steps: 28,
                                   seed: seed &+ 3)
            mass(p, joint, palette.dk(0.14), depth: 3, weight: u * 0.022, spacing: u * 0.026,
                 strength: 0.52, seed: seed &+ 5)
            // three slices carved off and fanned
            for k in 0..<3 {
                let sx = cx + bed.rx * (0.24 + Double(k) * 0.20) * sc
                let sy = cy - bed.ry * (0.06 + Double(k) * 0.10) * sc
                let slice = jitterRing(sx, sy, hw * 0.52, hh * 0.62, rough: 0.08, steps: 22,
                                       seed: seed &+ UInt64(k * 13))
                mass(p, slice, palette.lt(0.10), depth: 2, weight: u * 0.016,
                     spacing: u * 0.022, strength: 0.44, seed: seed &+ UInt64(k * 17))
                p.clip(polyPath(slice)) {
                    for j in 0..<7 {
                        let t = Double(j) / 6.0 - 0.5
                        penBroken(p, [CGPoint(x: sx - hw * 0.5, y: sy + t * hh * 1.1),
                                      CGPoint(x: sx + hw * 0.5, y: sy + t * hh * 1.1 + hh * 0.08)],
                                  weight: u * 0.010, colour: Ink.cream.al(0.55),
                                  pieces: 2, gap: 0.14, wobble: 0.5,
                                  seed: seed &+ UInt64(k * 31 + j))
                    }
                }
            }

        case "dropBalls":
            let n = rng.i(4, 6)
            for k in 0..<n {
                let a = Double(k) / Double(n) * 6.283185 + rng.r(-0.2, 0.2)
                let rr = k == 0 ? 0.0 : rng.r(0.42, 0.66)
                let bx = cx + cos(a) * bed.rx * rr * sc
                let by = cy + sin(a) * bed.ry * rr * sc
                let r = u * rng.r(0.17, 0.23) * sc
                let ball = jitterRing(bx, by, r, r * 0.94, rough: 0.06, steps: 24,
                                      seed: seed &+ UInt64(k * 13))
                mass(p, ball, palette, depth: 2, weight: u * 0.018, spacing: u * 0.024,
                     strength: 0.48, seed: seed &+ UInt64(k * 17))
                stipple(p, polyPath(ball), density: 0.0030, sizeMin: u * 0.005,
                        sizeMax: u * 0.012, colour: Ink.umber.al(0.45), seed: seed &+ UInt64(k * 23))
                sheen(p, cx: bx, cy: by, rx: r, ry: r * 0.9, seed: seed)
            }

        case "springRolls":
            let n = 3
            for k in 0..<n {
                let t = Double(k) - 1.0
                let rx = bed.rx * 0.66 * sc, ry = bed.ry * 0.13 * sc
                let rcx = cx + t * bed.rx * 0.10, rcy = cy + t * bed.ry * 0.38 * sc
                let ang = 0.22 * t
                var tube: [CGPoint] = []
                for j in 0...20 {
                    let uu = Double(j) / 20.0 * 2 - 1
                    tube.append(CGPoint(x: rcx + uu * rx * cos(ang) - ry * sin(ang),
                                        y: rcy + uu * rx * sin(ang) + ry * cos(ang)))
                }
                for j in stride(from: 20, through: 0, by: -1) {
                    let uu = Double(j) / 20.0 * 2 - 1
                    tube.append(CGPoint(x: rcx + uu * rx * cos(ang) + ry * sin(ang),
                                        y: rcy + uu * rx * sin(ang) - ry * cos(ang)))
                }
                mass(p, tube, Ink.ochre.mix(palette, 0.28), depth: 2, weight: u * 0.018,
                     spacing: u * 0.022, strength: 0.40, seed: seed &+ UInt64(k * 19))
                // the blistered skin
                stipple(p, polyPath(tube), density: 0.0040, sizeMin: u * 0.004,
                        sizeMax: u * 0.011, colour: Ink.umber.al(0.5), seed: seed &+ UInt64(k * 23))
                // the cut end
                let end = ellipsePoints(cx: rcx + rx * cos(ang), cy: rcy + rx * sin(ang),
                                        rx: ry * 0.55, ry: ry * 1.02, steps: 16)
                mass(p, end, Ink.herb.mix(palette, 0.35), depth: 1, weight: u * 0.012,
                     spacing: u * 0.016, strength: 0.5, seed: seed &+ UInt64(k * 29))
            }

        default:
            let heap = jitterRing(cx, cy, bed.rx * 0.70 * sc, bed.ry * 0.64 * sc,
                                  rough: 0.10, steps: 28, seed: seed &+ 3)
            mass(p, heap, palette, depth: 2, weight: u * 0.020, spacing: u * 0.026,
                 strength: 0.46, seed: seed &+ 5)
        }
    }

    if layer == 0 { bed.overdraw() }
}

// MARK: - Garnish

func drawGarnish(_ p: Plate, _ kind: String, bed: Bed, palette: Col, seed: UInt64, index: Int) {
    let u = min(bed.rx, bed.ry)
    var rng = RNG(seed &+ UInt64(index * 733) &+ 17)

    inBed(p, bed) {
        switch kind {

        case "herbSprigs":
            for k in 0..<rng.i(4, 7) {
                let a = rng.r(0, 6.283), rr = rng.r(0.15, 0.80)
                let hx = bed.cx + cos(a) * bed.rx * rr
                let hy = bed.cy + sin(a) * bed.ry * rr
                let dir = rng.r(0, 6.283)
                let len = u * rng.r(0.16, 0.30)
                let stem = [CGPoint(x: hx, y: hy),
                            CGPoint(x: hx + cos(dir) * len * 0.6, y: hy + sin(dir) * len * 0.6),
                            CGPoint(x: hx + cos(dir + 0.3) * len, y: hy + sin(dir + 0.3) * len)]
                penStroke(p, stem, weight: u * 0.012, colour: Ink.herb.dk(0.20),
                          wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 13))
                for j in 0..<5 {
                    let t = 0.25 + Double(j) / 4.0 * 0.72
                    let lx = hx + cos(dir + 0.15) * len * t
                    let ly = hy + sin(dir + 0.15) * len * t
                    let side: Double = j % 2 == 0 ? 1 : -1
                    let leaf = ellipsePoints(cx: lx + cos(dir + side * 1.4) * u * 0.035,
                                             cy: ly + sin(dir + side * 1.4) * u * 0.035,
                                             rx: u * 0.038, ry: u * 0.020, steps: 12)
                    p.poly(leaf, Ink.herb.al(0.75))
                    penContour(p, leaf, weight: u * 0.007, colour: Ink.herb.dk(0.35),
                               seed: seed &+ UInt64(k * 31 + j))
                }
            }

        case "seedScatter":
            for k in 0..<90 {
                let a = rng.r(0, 6.283), rr = pow(rng.d(), 0.5)
                let sx = bed.cx + cos(a) * bed.rx * 0.92 * rr
                let sy = bed.cy + sin(a) * bed.ry * 0.88 * rr
                let sr = u * rng.r(0.008, 0.017)
                p.ellipse(sx, sy, sr, sr * 0.72, Ink.umber.al(rng.r(0.45, 0.9)))
                _ = k
            }

        case "sesameDust":
            for k in 0..<130 {
                let a = rng.r(0, 6.283), rr = pow(rng.d(), 0.45)
                let sx = bed.cx + cos(a) * bed.rx * 0.90 * rr
                let sy = bed.cy + sin(a) * bed.ry * 0.86 * rr
                let sr = u * rng.r(0.006, 0.012)
                let dark = rng.chance(0.3)
                let e = ellipsePoints(cx: sx, cy: sy, rx: sr * 1.3, ry: sr * 0.8, steps: 8)
                p.poly(e, dark ? Ink.char.al(0.8) : Ink.cream.al(0.9))
                penContour(p, e, weight: u * 0.004, colour: Ink.sepiaSoft.al(0.5),
                           seed: seed &+ UInt64(k))
            }

        case "chiliSlices":
            for k in 0..<rng.i(4, 7) {
                let a = rng.r(0, 6.283), rr = rng.r(0.2, 0.82)
                let sx = bed.cx + cos(a) * bed.rx * rr
                let sy = bed.cy + sin(a) * bed.ry * rr
                let r = u * rng.r(0.045, 0.075)
                let ring = ellipsePoints(cx: sx, cy: sy, rx: r, ry: r * rng.r(0.55, 0.9), steps: 16)
                p.poly(ring, Ink.crimson.al(0.80))
                penContour(p, ring, weight: u * 0.008, colour: Ink.crimson.dk(0.35),
                           seed: seed &+ UInt64(k * 11))
                for j in 0..<5 {
                    let sa = Double(j) / 5.0 * 6.283
                    p.disc(sx + cos(sa) * r * 0.42, sy + sin(sa) * r * 0.32, u * 0.008,
                           Ink.cream.al(0.85))
                }
            }

        case "scallionRings":
            for k in 0..<rng.i(6, 10) {
                let a = rng.r(0, 6.283), rr = rng.r(0.15, 0.85)
                let sx = bed.cx + cos(a) * bed.rx * rr
                let sy = bed.cy + sin(a) * bed.ry * rr
                let r = u * rng.r(0.035, 0.058)
                let outer = ellipsePoints(cx: sx, cy: sy, rx: r, ry: r * rng.r(0.6, 0.95), steps: 16)
                p.poly(outer, Ink.herb.lt(0.10).al(0.85))
                penContour(p, outer, weight: u * 0.008, colour: Ink.herb.dk(0.35),
                           seed: seed &+ UInt64(k * 7))
                let inner = ellipsePoints(cx: sx, cy: sy, rx: r * 0.45, ry: r * 0.38, steps: 12)
                p.poly(inner, Ink.paper.al(0.55))
                penContour(p, inner, weight: u * 0.005, colour: Ink.herb.dk(0.20),
                           seed: seed &+ UInt64(k * 13))
            }

        case "citrusWedge":
            let a = rng.r(0, 6.283)
            let wx = bed.cx + cos(a) * bed.rx * 0.66
            let wy = bed.cy + sin(a) * bed.ry * 0.60
            let r = u * 0.24
            let tilt = rng.r(0, 6.283)
            var wedge: [CGPoint] = [CGPoint(x: wx, y: wy)]
            for j in 0...14 {
                let t = tilt - 0.6 + Double(j) / 14.0 * 1.2
                wedge.append(CGPoint(x: wx + cos(t) * r, y: wy + sin(t) * r))
            }
            mass(p, wedge, Ink.saffron.lt(0.10), depth: 1, weight: u * 0.014,
                 spacing: u * 0.020, strength: 0.44, seed: seed &+ 5)
            for j in 0..<5 {
                let t = tilt - 0.5 + Double(j) / 4.0 * 1.0
                penStroke(p, [CGPoint(x: wx, y: wy),
                              CGPoint(x: wx + cos(t) * r * 0.92, y: wy + sin(t) * r * 0.92)],
                          weight: u * 0.009, colour: Ink.cream.al(0.85), wobble: 0.3,
                          taper: true, seed: seed &+ UInt64(j * 11))
            }
            penStroke(p, [CGPoint(x: wx + cos(tilt - 0.6) * r, y: wy + sin(tilt - 0.6) * r),
                          CGPoint(x: wx + cos(tilt) * r * 1.06, y: wy + sin(tilt) * r * 1.06),
                          CGPoint(x: wx + cos(tilt + 0.6) * r, y: wy + sin(tilt + 0.6) * r)],
                      weight: u * 0.024, colour: Ink.herb.mix(Ink.saffron, 0.5).dk(0.10),
                      wobble: u * 0.004, taper: false, seed: seed &+ 23)

        case "sauceDrizzle":
            for k in 0..<3 {
                var line: [CGPoint] = []
                let a0 = rng.r(0, 6.283)
                for j in 0...26 {
                    let t = Double(j) / 26.0
                    let a = a0 + t * 5.2
                    let r = bed.rx * (0.14 + t * 0.66)
                    line.append(CGPoint(x: bed.cx + cos(a) * r, y: bed.cy + sin(a) * r * 0.92))
                }
                penStroke(p, line, weight: u * rng.r(0.018, 0.030),
                          colour: (k % 2 == 0 ? Ink.char : palette.dk(0.30)).al(0.72),
                          wobble: u * 0.005, taper: true, seed: seed &+ UInt64(k * 17))
            }

        case "creamDollop":
            let a = rng.r(0, 6.283)
            let dx = bed.cx + cos(a) * bed.rx * 0.30
            let dy = bed.cy + sin(a) * bed.ry * 0.28
            let r = u * 0.22
            var dollop: [CGPoint] = []
            for j in 0..<26 {
                let t = Double(j) / 26.0 * 6.283185
                let peak = 1.0 + 0.30 * max(0, sin(t)) + 0.10 * sin(t * 5)
                dollop.append(CGPoint(x: dx + cos(t) * r, y: dy + sin(t) * r * peak))
            }
            mass(p, dollop, Ink.cream.lt(0.40), depth: 1, weight: u * 0.014,
                 spacing: u * 0.020, strength: 0.24, seed: seed &+ 5)
            penStroke(p, [CGPoint(x: dx, y: dy + r * 1.15),
                          CGPoint(x: dx + r * 0.22, y: dy + r * 1.42)],
                      weight: u * 0.016, colour: Ink.sepiaSoft.al(0.6), wobble: 0.4,
                      taper: true, seed: seed &+ 11)

        case "nutCrumbs":
            for k in 0..<rng.i(14, 22) {
                let a = rng.r(0, 6.283), rr = pow(rng.d(), 0.5)
                let nx = bed.cx + cos(a) * bed.rx * 0.85 * rr
                let ny = bed.cy + sin(a) * bed.ry * 0.80 * rr
                let nr = u * rng.r(0.018, 0.040)
                let bit = blob(cx: nx, cy: ny, rx: nr, ry: nr * rng.r(0.5, 0.85), rough: 0.30,
                               steps: 10, seed: seed &+ UInt64(k * 13))
                p.poly(bit, Ink.ochre.dk(0.10).al(0.8))
                penContour(p, bit, weight: u * 0.006, colour: Ink.umber.al(0.7),
                           seed: seed &+ UInt64(k * 7))
            }

        case "oliveScatter":
            for k in 0..<rng.i(4, 7) {
                let a = rng.r(0, 6.283), rr = rng.r(0.2, 0.82)
                let ox = bed.cx + cos(a) * bed.rx * rr
                let oy = bed.cy + sin(a) * bed.ry * rr
                let r = u * rng.r(0.045, 0.070)
                let ol = ellipsePoints(cx: ox, cy: oy, rx: r, ry: r * 0.78, steps: 16)
                mass(p, ol, rng.chance(0.5) ? Ink.herb.dk(0.25) : Ink.plum.dk(0.15),
                     depth: 1, weight: u * 0.010, spacing: u * 0.016, strength: 0.6,
                     seed: seed &+ UInt64(k * 11))
                p.ellipse(ox - r * 0.25, oy + r * 0.22, r * 0.24, r * 0.16, Ink.paper.al(0.35))
            }

        case "powderDust":
            for k in 0..<220 {
                let a = rng.r(0, 6.283), rr = pow(rng.d(), 0.35)
                let dx = bed.cx + cos(a) * bed.rx * 0.94 * rr
                let dy = bed.cy + sin(a) * bed.ry * 0.90 * rr
                p.disc(dx, dy, u * rng.r(0.003, 0.009),
                       (rng.chance(0.5) ? Ink.crimson : Ink.saffron).al(rng.r(0.20, 0.55)))
                _ = k
            }

        case "flowerPetals":
            for k in 0..<rng.i(3, 6) {
                let a = rng.r(0, 6.283), rr = rng.r(0.25, 0.85)
                let fx = bed.cx + cos(a) * bed.rx * rr
                let fy = bed.cy + sin(a) * bed.ry * rr
                let r = u * rng.r(0.045, 0.070)
                let tilt = rng.r(0, 6.283)
                for j in 0..<5 {
                    let pa = tilt + Double(j) / 5.0 * 6.283185
                    let petal = ellipsePoints(cx: fx + cos(pa) * r * 0.62,
                                              cy: fy + sin(pa) * r * 0.62,
                                              rx: r * 0.44, ry: r * 0.28, steps: 12)
                    p.poly(petal, Ink.blush.al(0.72))
                    penContour(p, petal, weight: u * 0.005, colour: Ink.plum.al(0.55),
                               seed: seed &+ UInt64(k * 31 + j))
                }
                p.disc(fx, fy, r * 0.24, Ink.saffron.al(0.85))
            }

        default:
            break
        }
    }
}
