import Foundation
import CoreGraphics

// Food, second edition. Opaque gouache heaped in a low three-quarter view:
// every archetype has height, occlusion is real (back painted first, front
// painted over it), and the accents stay vivid.

// MARK: - Shared shapes

/// A heap seen from the front: wide at the bed, domed on top.
func heapPoints(cx: Double, cy: Double, rx: Double, height: Double,
                rough: Double, seed: UInt64) -> [CGPoint] {
    var rng = RNG(seed)
    var pts: [CGPoint] = []
    for i in 0...26 {
        let t = Double(i) / 26.0
        let a = Double.pi + t * Double.pi          // base, left to right
        pts.append(pnt(cx + cos(a) * rx, cy + sin(a) * rx * 0.16))
    }
    for i in stride(from: 22, through: 4, by: -2) {
        let t = Double(i) / 26.0
        let x = cx - rx + 2 * rx * t
        let lift = sin(t * Double.pi)
        pts.append(pnt(x + rng.signed() * rx * rough,
                       cy + height * (0.55 + 0.45 * lift) + rng.signed() * height * rough))
    }
    return pts
}

/// A lump — one chunk, one dumpling, one ball — with a flatter base.
func lumpPoints(cx: Double, cy: Double, rx: Double, ry: Double,
                squash: Double, seed: UInt64) -> [CGPoint] {
    var rng = RNG(seed)
    var pts: [CGPoint] = []
    for i in 0..<22 {
        let a = Double(i) / 22.0 * 6.283185
        let vert = sin(a) > 0 ? 1.0 : squash
        let w = 1.0 + rng.signed() * 0.09
        pts.append(pnt(cx + cos(a) * rx * w, cy + sin(a) * ry * vert * w))
    }
    return pts
}

func inBed(_ p: Plate, _ bed: Bed, _ body: () -> Void) {
    p.clip(bed.clip, body)
}

// MARK: - Garnish

func drawGarnish(_ p: Plate, _ kind: String, bed: Bed, paletteKey: String,
                 seed: UInt64, index: Int) {
    let u = bed.rx * 0.92
    var rng = RNG(seed &+ UInt64(index * 733) &+ 17)

    // Garnish lands on the food, which rises above the bed centre.
    func spot() -> (Double, Double) {
        let a = rng.r(0, 6.283)
        let rr = pow(rng.d(), 0.6)
        return (bed.cx + cos(a) * bed.rx * 0.66 * rr,
                bed.cy + bed.ry * 0.4 + abs(sin(a)) * u * 0.34 * rr + rng.r(0, u * 0.16))
    }

    inBed(p, bed) {
        switch kind {
        case "herbSprigs":
            for k in 0..<rng.i(5, 8) {
                let (hx, hy) = spot()
                let dir = rng.r(0.6, 2.5)
                let len = u * rng.r(0.10, 0.17)
                penStroke(p, [pnt(hx, hy), pnt(hx + cos(dir) * len, hy + sin(dir) * len)],
                          weight: u * 0.012, colour: Paint.herbDark, wobble: 0.4,
                          taper: true, seed: seed &+ UInt64(k * 13))
                for j in 0..<4 {
                    let t = 0.3 + Double(j) * 0.22
                    let side: Double = j % 2 == 0 ? 1 : -1
                    dab(p, x: hx + cos(dir) * len * t + cos(dir + side * 1.5) * u * 0.020,
                        y: hy + sin(dir) * len * t + sin(dir + side * 1.5) * u * 0.020,
                        rx: u * 0.020, ry: u * 0.011, Paint.herbGreen,
                        tilt: dir + side * 0.8, seed: seed &+ UInt64(k * 31 + j))
                }
            }
        case "seedScatter":
            for k in 0..<60 {
                let (sx, sy) = spot()
                dab(p, x: sx, y: sy, rx: u * rng.r(0.006, 0.011), ry: u * 0.006,
                    Paint.charBrown.al(0.9), tilt: rng.r(0, 3.1), seed: seed &+ UInt64(k))
            }
        case "sesameDust":
            for k in 0..<80 {
                let (sx, sy) = spot()
                let dark = rng.chance(0.3)
                dab(p, x: sx, y: sy, rx: u * 0.008, ry: u * 0.0045,
                    dark ? Paint.charBrown : Paint.creamWhite,
                    tilt: rng.r(0, 3.1), seed: seed &+ UInt64(k))
            }
        case "chiliSlices":
            for k in 0..<rng.i(5, 8) {
                let (sx, sy) = spot()
                let r = u * rng.r(0.028, 0.045)
                dab(p, x: sx, y: sy, rx: r, ry: r * 0.62, Paint.chiliRed,
                    tilt: rng.r(0, 3.1), outline: u * 0.006, seed: seed &+ UInt64(k * 11))
                p.disc(sx, sy, r * 0.30, Paint.creamWhite.al(0.85))
            }
        case "scallionRings":
            for k in 0..<rng.i(7, 11) {
                let (sx, sy) = spot()
                let r = u * rng.r(0.020, 0.034)
                dab(p, x: sx, y: sy, rx: r, ry: r * 0.68, Paint.herbGreen,
                    tilt: rng.r(0, 3.1), outline: u * 0.005, seed: seed &+ UInt64(k * 7))
                p.disc(sx, sy, r * 0.38, Paint.creamWhite.al(0.75))
            }
        case "citrusWedge":
            let wx = bed.cx + bed.rx * 0.55
            let wy = bed.cy + bed.ry * 0.5
            let r = u * 0.15
            var wedge: [CGPoint] = [pnt(wx, wy)]
            for j in 0...12 {
                let t = 0.5 - 0.55 + Double(j) / 12.0 * 1.1
                wedge.append(pnt(wx + cos(t) * r, wy + sin(t) * r))
            }
            gouache(p, wedge, Paint.saffron.lt(0.15), seed: seed &+ 5)
            for j in 0..<5 {
                let t = -0.45 + Double(j) / 4.0 * 0.9
                penStroke(p, [pnt(wx, wy), pnt(wx + cos(t) * r * 0.9, wy + sin(t) * r * 0.9)],
                          weight: u * 0.008, colour: Paint.creamWhite.al(0.9),
                          wobble: 0.3, taper: true, seed: seed &+ UInt64(j * 11))
            }
            penContour(p, wedge, weight: u * 0.010, colour: Ink.sepia.al(0.8), seed: seed &+ 23)
        case "sauceDrizzle":
            for k in 0..<3 {
                var line: [CGPoint] = []
                let y0 = bed.cy + bed.ry * 0.5 + Double(k) * u * 0.07
                for j in 0...22 {
                    let t = Double(j) / 22.0
                    line.append(pnt(bed.cx - bed.rx * 0.7 + bed.rx * 1.4 * t,
                                    y0 + sin(t * 9 + Double(k)) * u * 0.05))
                }
                penStroke(p, line, weight: u * rng.r(0.014, 0.022),
                          colour: Paint.sauceDark.al(0.9), wobble: u * 0.004,
                          taper: true, seed: seed &+ UInt64(k * 17))
            }
        case "creamDollop":
            let dx = bed.cx + rng.r(-0.3, 0.3) * bed.rx
            let dy = bed.cy + bed.ry * 0.5 + u * 0.14
            let dollop = heapPoints(cx: dx, cy: dy, rx: u * 0.13, height: u * 0.11,
                                    rough: 0.10, seed: seed &+ 5)
            gouacheForm(p, dollop, Chord(shadow: Paint.creamWhite.dk(0.18),
                                         body: Paint.creamWhite,
                                         light: Col(r: 1, g: 0.99, b: 0.96)),
                        seed: seed &+ 7)
            penContour(p, dollop, weight: u * 0.009, colour: Ink.sepia.al(0.55), seed: seed &+ 9)
        case "nutCrumbs":
            for k in 0..<rng.i(14, 20) {
                let (nx, ny) = spot()
                dab(p, x: nx, y: ny, rx: u * rng.r(0.012, 0.024), ry: u * rng.r(0.008, 0.015),
                    Paint.chord("ochre").body.dk(rng.r(0, 0.2)), tilt: rng.r(0, 3.1),
                    outline: u * 0.004, seed: seed &+ UInt64(k * 13))
            }
        case "oliveScatter":
            for k in 0..<rng.i(4, 7) {
                let (ox, oy) = spot()
                let r = u * rng.r(0.024, 0.038)
                dab(p, x: ox, y: oy, rx: r, ry: r * 0.8,
                    rng.chance(0.5) ? Paint.herbDark : Paint.chord("plum").shadow,
                    outline: u * 0.005, seed: seed &+ UInt64(k * 11))
                p.disc(ox - r * 0.25, oy + r * 0.25, r * 0.22, Paint.creamWhite.al(0.5))
            }
        case "powderDust":
            for k in 0..<120 {
                let (dx, dy) = spot()
                p.disc(dx, dy, u * rng.r(0.003, 0.007),
                       (rng.chance(0.5) ? Paint.chiliRed : Paint.saffron).al(rng.r(0.3, 0.7)))
                _ = k
            }
        case "flowerPetals":
            for k in 0..<rng.i(4, 6) {
                let (fx, fy) = spot()
                let r = u * rng.r(0.024, 0.038)
                for j in 0..<5 {
                    let a = Double(j) / 5.0 * 6.283185 + Double(k)
                    dab(p, x: fx + cos(a) * r * 0.6, y: fy + sin(a) * r * 0.6,
                        rx: r * 0.42, ry: r * 0.26, Paint.chord("blush").light,
                        tilt: a, seed: seed &+ UInt64(k * 31 + j))
                }
                p.disc(fx, fy, r * 0.22, Paint.saffron)
            }
        default:
            break
        }
    }
}

// MARK: - The thirty archetypes

func drawFood(_ p: Plate, _ kind: String, bed: Bed, paletteKey: String,
              seed: UInt64, layer: Int) {
    let u = bed.rx * 0.92
    var rng = RNG(seed &+ UInt64(layer * 101))
    let chord = Paint.chord(paletteKey)

    // Layered food: extras go behind (higher y, smaller), main in front.
    let ox = layer == 0 ? 0.0 : rng.r(-0.4, 0.4) * bed.rx
    let oy = layer == 0 ? 0.0 : bed.ry * 0.8 + rng.r(0, bed.ry * 0.5)
    let cx = bed.cx + ox
    let cy = bed.cy + oy
    let sc = layer == 0 ? 1.0 : 0.55

    inBed(p, bed) {
        switch kind {

        case "noodleNest":
            let rx = bed.rx * 0.82 * sc
            let mound = heapPoints(cx: cx, cy: cy - bed.ry * 0.30, rx: rx, height: u * 0.20 * sc,
                                   rough: 0.05, seed: seed &+ 3)
            gouache(p, mound, chord.body, seed: seed &+ 5)
            p.clip(polyPath(mound)) {
                for k in 0..<46 {
                    var strand: [CGPoint] = []
                    let y0 = cy - bed.ry * 0.30 + rng.r(-u * 0.02, u * 0.20)
                    let amp = u * rng.r(0.02, 0.05)
                    let ph = rng.r(0, 6.283)
                    for j in 0...14 {
                        let t = Double(j) / 14.0
                        strand.append(pnt(cx - rx + 2 * rx * t,
                                          y0 + sin(t * 7 + ph) * amp))
                    }
                    penStroke(p, strand, weight: u * rng.r(0.026, 0.040),
                              colour: (k % 3 == 0 ? chord.light : chord.shadow)
                                  .al(rng.r(0.6, 0.95)),
                              wobble: u * 0.004, taper: true, seed: seed &+ UInt64(k * 7))
                }
            }
            inkOver(p, mound, weight: u * 0.014, seed: seed &+ 9)
            // a lifted twist of noodles on top
            var lift: [CGPoint] = []
            for j in 0...12 {
                let t = Double(j) / 12.0
                lift.append(pnt(cx - rx * 0.3 + rx * 0.6 * t,
                                cy - bed.ry * 0.30 + u * 0.20 + sin(t * .pi) * u * 0.09))
            }
            penStroke(p, lift, weight: u * 0.024, colour: chord.light, wobble: u * 0.004,
                      taper: true, seed: seed &+ 11)
            penStroke(p, lift.map { CGPoint(x: $0.x, y: $0.y - CGFloat(u * 0.018)) },
                      weight: u * 0.020, colour: chord.body, wobble: u * 0.004,
                      taper: true, seed: seed &+ 13)

        case "brothSurface":
            let pool = ringPoints(cx, cy, bed.rx * 0.95 * sc, bed.ry * 0.90 * sc)
            gouache(p, pool, chord.shadow, unevenness: 0.05, seed: seed &+ 3)
            let inner = ringPoints(cx, cy + bed.ry * 0.06, bed.rx * 0.80, bed.ry * 0.70)
            gouache(p, inner, chord.body, unevenness: 0.06, edgeDark: 0.05, seed: seed &+ 5)
            // fat beads catching the light
            for k in 0..<12 {
                let a = rng.r(0, 6.283)
                let rr = rng.r(0.1, 0.8)
                let x = cx + cos(a) * bed.rx * 0.6 * rr
                let y = cy + sin(a) * bed.ry * 0.5 * rr
                p.disc(x, y, u * rng.r(0.012, 0.028), Paint.saffron.al(0.75))
                p.disc(x, y, u * rng.r(0.005, 0.010), chord.light.al(0.9))
                _ = k
            }
            // steam: two pale curls rising
            for k in 0..<2 {
                var curl: [CGPoint] = []
                let x0 = cx + (Double(k) - 0.5) * bed.rx * 0.5
                for j in 0...12 {
                    let t = Double(j) / 12.0
                    curl.append(pnt(x0 + sin(t * 4 + Double(k)) * u * 0.05,
                                    cy + bed.ry + t * u * 0.42))
                }
                penStroke(p, curl, weight: u * 0.016, colour: Paint.creamWhite.al(0.5),
                          wobble: u * 0.006, taper: true, seed: seed &+ UInt64(k * 17))
            }

        case "riceMound":
            let mound = heapPoints(cx: cx, cy: cy, rx: bed.rx * 0.72 * sc,
                                   height: u * 0.28 * sc, rough: 0.04, seed: seed &+ 3)
            gouacheForm(p, mound, Chord(shadow: Paint.creamWhite.dk(0.22),
                                        body: Paint.creamWhite,
                                        light: Col(r: 0.99, g: 0.97, b: 0.93)),
                        seed: seed &+ 5)
            p.clip(polyPath(mound)) {
                for k in 0..<160 {
                    let a = rng.r(0, 6.283)
                    let rr = pow(rng.d(), 0.6)
                    dab(p, x: cx + cos(a) * bed.rx * 0.62 * rr,
                        y: cy + u * 0.16 + sin(a) * u * 0.17 * rr,
                        rx: u * 0.014, ry: u * 0.006,
                        (rng.chance(0.6) ? Paint.creamWhite.dk(0.10) : Paint.creamWhite.dk(0.20)),
                        tilt: rng.r(0, 3.1), seed: seed &+ UInt64(k))
                }
            }
            inkOver(p, mound, weight: u * 0.013, seed: seed &+ 9)

        case "riceScatter":
            let spread = ringPoints(cx, cy + bed.ry * 0.1, bed.rx * 0.88 * sc, bed.ry * 0.80 * sc)
            gouache(p, spread, Paint.creamWhite.dk(0.06), unevenness: 0.06, seed: seed &+ 3)
            p.clip(polyPath(spread)) {
                for k in 0..<200 {
                    let a = rng.r(0, 6.283)
                    let rr = pow(rng.d(), 0.5)
                    dab(p, x: cx + cos(a) * bed.rx * 0.8 * rr,
                        y: cy + bed.ry * 0.1 + sin(a) * bed.ry * 0.7 * rr,
                        rx: u * 0.015, ry: u * 0.006,
                        rng.chance(0.18) ? chord.body : Paint.creamWhite.dk(rng.r(0.04, 0.16)),
                        tilt: rng.r(0, 3.1), seed: seed &+ UInt64(k))
                }
            }
            penContour(p, spread, weight: u * 0.010, colour: Ink.sepia.al(0.5), seed: seed &+ 7)

        case "flatbread":
            // a folded flatbread: back half standing, front half lying
            let rx = bed.rx * 0.80 * sc
            let back = lumpPoints(cx: cx, cy: cy + u * 0.10, rx: rx * 0.9, ry: u * 0.26,
                                  squash: 0.25, seed: seed &+ 3)
            gouacheForm(p, back, Chord(shadow: chord.shadow, body: chord.body.lt(0.06),
                                       light: chord.light), seed: seed &+ 5)
            inkOver(p, back, weight: u * 0.013, seed: seed &+ 7)
            let front = lumpPoints(cx: cx, cy: cy - u * 0.02, rx: rx, ry: u * 0.14,
                                   squash: 0.4, seed: seed &+ 9)
            gouacheForm(p, front, chord, seed: seed &+ 11)
            inkOver(p, front, weight: u * 0.013, seed: seed &+ 13)
            // char blisters on both
            for (i, region) in [back, front].enumerated() {
                p.clip(polyPath(region)) {
                    for k in 0..<14 {
                        let a = rng.r(0, 6.283)
                        let rr = pow(rng.d(), 0.7)
                        dab(p, x: cx + cos(a) * rx * 0.7 * rr,
                            y: cy + Double(i == 0 ? 1 : -1) * u * 0.05 + sin(a) * u * 0.10 * rr,
                            rx: u * rng.r(0.012, 0.030), ry: u * rng.r(0.008, 0.018),
                            Paint.charBrown.al(rng.r(0.5, 0.85)), tilt: rng.r(0, 3.1),
                            seed: seed &+ UInt64(i * 40 + k))
                    }
                }
            }

        case "loafSlices":
            for k in 0..<3 {
                let lean = Double(k) - 1.0
                let sx = cx + lean * bed.rx * 0.42 * sc
                let sy = cy + Double(2 - k) * u * 0.05
                let slice = lumpPoints(cx: sx, cy: sy + u * 0.16, rx: bed.rx * 0.26 * sc,
                                       ry: u * 0.24, squash: 0.30, seed: seed &+ UInt64(k * 13))
                gouacheForm(p, slice, Chord(shadow: Paint.creamWhite.dk(0.25),
                                            body: Paint.creamWhite.dk(0.05),
                                            light: Paint.creamWhite.lt(0.1)),
                            seed: seed &+ UInt64(k * 17))
                // the crust arc
                var crust: [CGPoint] = []
                for j in 0...14 {
                    let a = Double.pi * 0.06 + Double(j) / 14.0 * Double.pi * 0.88
                    crust.append(pnt(sx + cos(a) * bed.rx * 0.26 * sc,
                                     sy + u * 0.16 + sin(a) * u * 0.24))
                }
                penStroke(p, crust, weight: u * 0.030, colour: chord.shadow,
                          wobble: u * 0.004, taper: false, seed: seed &+ UInt64(k * 5))
                p.clip(polyPath(slice)) {
                    for j in 0..<16 {
                        p.disc(sx + rng.r(-0.7, 0.7) * bed.rx * 0.22,
                               sy + u * 0.16 + rng.r(-0.7, 0.7) * u * 0.18,
                               u * rng.r(0.006, 0.014), Paint.creamWhite.dk(0.28).al(0.5))
                        _ = j
                    }
                }
                inkOver(p, slice, weight: u * 0.011, hatchShadow: false, seed: seed &+ UInt64(k * 19))
            }

        case "dumplings":
            let n = rng.i(4, 5)
            for k in 0..<n {
                let t = Double(k) / Double(max(1, n - 1))
                let back = k % 2 == 1
                let dx = cx - bed.rx * 0.58 + bed.rx * 1.16 * t + rng.r(-0.04, 0.04) * bed.rx
                let dy = cy - bed.ry * 0.25 + (back ? u * 0.18 : 0) + rng.r(-0.02, 0.02) * u
                let r = u * (back ? 0.22 : 0.27) * sc
                let body = lumpPoints(cx: dx, cy: dy + r * 0.5, rx: r, ry: r * 0.85,
                                      squash: 0.35, seed: seed &+ UInt64(k * 13))
                gouacheForm(p, body, Chord(shadow: Paint.creamWhite.dk(0.14).mix(Paint.chord("ochre").body, 0.18),
                                           body: Paint.creamWhite,
                                           light: Paint.creamWhite.lt(0.10)),
                            depth: 0.7, seed: seed &+ UInt64(k * 17))
                for j in 0..<5 {
                    let px = dx - r * 0.5 + Double(j) * r * 0.25
                    penStroke(p, [pnt(px, dy + r * 1.15), pnt(px + r * 0.12, dy + r * 0.62)],
                              weight: u * 0.011, colour: Ink.sepiaSoft.al(0.8),
                              wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 31 + j))
                }
                penContour(p, body, weight: u * 0.012, colour: Ink.sepia.al(0.75),
                           seed: seed &+ UInt64(k * 19))
            }

        case "skewers":
            for k in 0..<rng.i(2, 3) {
                let lane = Double(k) - 0.5
                let sy = cy + lane * u * 0.16 + u * 0.06
                let x0 = cx - bed.rx * (0.9 - Double(k) * 0.06)
                let x1 = cx + bed.rx * (0.9 - Double(k) * 0.04)
                penStroke(p, [pnt(x0 - u * 0.10, sy - lane * u * 0.03),
                              pnt(x1 + u * 0.12, sy + lane * u * 0.05)],
                          weight: u * 0.020, colour: Paint.woodBoard.shadow,
                          wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 7))
                for j in 0..<4 {
                    let t = 0.14 + Double(j) * 0.24
                    let bx = x0 + (x1 - x0) * t
                    let r = u * 0.13 * sc
                    let piece = lumpPoints(cx: bx, cy: sy + r * 0.3, rx: r,
                                           ry: r * 0.82, squash: 0.5,
                                           seed: seed &+ UInt64(k * 41 + j))
                    gouacheForm(p, piece,
                                j % 2 == 0 ? chord
                                           : Chord(shadow: chord.shadow.dk(0.12),
                                                   body: chord.body.dk(0.14),
                                                   light: chord.light.dk(0.10)),
                                seed: seed &+ UInt64(k * 53 + j))
                    // char kiss on the underside
                    penBroken(p, [pnt(bx - r * 0.6, sy - r * 0.25),
                                  pnt(bx + r * 0.6, sy - r * 0.30)],
                              weight: u * 0.014, colour: Paint.charBrown.al(0.8),
                              pieces: 2, gap: 0.2, wobble: 0.5, seed: seed &+ UInt64(j))
                    inkOver(p, piece, weight: u * 0.011, seed: seed &+ UInt64(k * 61 + j))
                }
            }

        case "stewChunks":
            let pool = ringPoints(cx, cy, bed.rx * 0.92 * sc, bed.ry * 0.85 * sc)
            gouache(p, pool, chord.shadow, unevenness: 0.06, seed: seed &+ 3)
            for k in 0..<6 {
                let a = Double(k) / 6.0 * 6.283 + rng.r(-0.3, 0.3)
                let rr = rng.r(0.15, 0.62)
                let bx = cx + cos(a) * bed.rx * 0.55 * rr
                let by = cy + sin(a) * bed.ry * 0.45 * rr + u * 0.04
                let r = u * rng.r(0.12, 0.16) * sc
                let piece = lumpPoints(cx: bx, cy: by + r * 0.3, rx: r, ry: r * 0.8,
                                       squash: 0.45, seed: seed &+ UInt64(k * 19))
                gouacheForm(p, piece,
                            k % 3 == 0 ? Chord(shadow: Paint.herbDark,
                                               body: Paint.herbGreen,
                                               light: Paint.herbGreen.lt(0.25))
                                       : Chord(shadow: chord.shadow.dk(0.06),
                                               body: chord.body.lt(0.10),
                                               light: chord.light),
                            seed: seed &+ UInt64(k * 29))
                inkOver(p, piece, weight: u * 0.011, seed: seed &+ UInt64(k * 37))
            }

        case "curryPool":
            let pool = ringPoints(cx, cy, bed.rx * 0.92 * sc, bed.ry * 0.86 * sc)
            gouache(p, pool, chord.body, unevenness: 0.09, seed: seed &+ 3)
            // the split fat rim and a cream swirl
            penStroke(p, ringPoints(cx, cy, bed.rx * 0.80, bed.ry * 0.70, steps: 40)
                        + [pnt(cx + bed.rx * 0.80, cy)],
                      weight: u * 0.018, colour: Paint.saffron.al(0.75),
                      wobble: u * 0.006, taper: false, seed: seed &+ 5)
            var swirl: [CGPoint] = []
            for j in 0...24 {
                let t = Double(j) / 24.0
                let a = t * 4.6
                let r = bed.rx * (0.08 + t * 0.5)
                swirl.append(pnt(cx + cos(a) * r, cy + sin(a) * r * 0.55))
            }
            penStroke(p, swirl, weight: u * 0.020, colour: Paint.creamWhite.al(0.85),
                      wobble: u * 0.004, taper: true, seed: seed &+ 7)
            penContour(p, pool, weight: u * 0.012, colour: Ink.sepia.al(0.7), seed: seed &+ 9)

        case "wholeFish":
            let L = bed.rx * 0.88 * sc
            let H = u * 0.23 * sc
            var body: [CGPoint] = []
            for j in 0...30 {
                let t = Double(j) / 30.0
                body.append(pnt(cx - L + 2 * L * t, cy + u * 0.08 + H * sin(Double.pi * t)))
            }
            for j in stride(from: 30, through: 0, by: -1) {
                let t = Double(j) / 30.0
                body.append(pnt(cx - L + 2 * L * t, cy + u * 0.08 - H * 0.85 * sin(Double.pi * t)))
            }
            gouacheForm(p, body, chord, seed: seed &+ 3)
            // tail and fin painted over
            let tail = [pnt(cx - L * 0.98, cy + u * 0.08),
                        pnt(cx - L * 1.26, cy + u * 0.08 + H * 0.95),
                        pnt(cx - L * 1.14, cy + u * 0.08),
                        pnt(cx - L * 1.26, cy + u * 0.08 - H * 0.85)]
            gouache(p, tail, chord.shadow, seed: seed &+ 5)
            penContour(p, tail, weight: u * 0.010, colour: Ink.sepia.al(0.85), seed: seed &+ 7)
            p.clip(polyPath(body)) {
                // scale arcs in the shadow tone
                var x = cx - L * 0.5
                while x < cx + L * 0.8 {
                    var yy = cy + u * 0.08 - H * 0.7
                    while yy < cy + u * 0.08 + H * 0.8 {
                        var arc: [CGPoint] = []
                        for j in 0...6 {
                            let a = Double.pi * 0.2 + Double(j) / 6.0 * Double.pi * 0.6
                            arc.append(pnt(x + cos(a) * u * 0.045, yy + sin(a) * u * 0.035))
                        }
                        penStroke(p, arc, weight: u * 0.007,
                                  colour: chord.shadow.al(0.55), wobble: 0.3,
                                  taper: true, seed: seed &+ u64(Int(x + yy)))
                        yy += u * 0.055
                    }
                    x += u * 0.05
                }
                // grill bars across
                for k in 0..<4 {
                    let gx = cx - L * 0.5 + Double(k) * L * 0.38
                    penStroke(p, [pnt(gx, cy + u * 0.08 - H), pnt(gx + L * 0.08, cy + u * 0.08 + H)],
                              weight: u * 0.020, colour: Paint.charBrown.al(0.65),
                              wobble: u * 0.003, taper: false, seed: seed &+ UInt64(k * 11))
                }
            }
            inkOver(p, body, weight: u * 0.013, seed: seed &+ 9)
            // head details
            penStroke(p, [pnt(cx + L * 0.55, cy + u * 0.08 + H * 0.7),
                          pnt(cx + L * 0.48, cy + u * 0.08),
                          pnt(cx + L * 0.56, cy + u * 0.08 - H * 0.6)],
                      weight: u * 0.012, colour: Ink.sepia, wobble: 0.4, taper: true,
                      seed: seed &+ 13)
            p.disc(cx + L * 0.76, cy + u * 0.08 + H * 0.25, u * 0.030, Paint.creamWhite)
            p.disc(cx + L * 0.76, cy + u * 0.08 + H * 0.25, u * 0.016, Ink.sepia)

        case "shellfish":
            // prawns curled over each other, one shell behind
            let shellX = cx - bed.rx * 0.45
            let shellY = cy + u * 0.16
            var fan: [CGPoint] = [pnt(shellX, shellY)]
            for j in 0...12 {
                let a = Double.pi * 0.15 + Double(j) / 12.0 * Double.pi * 0.7
                fan.append(pnt(shellX + cos(a) * u * 0.27, shellY + sin(a) * u * 0.24))
            }
            gouacheForm(p, fan, Chord(shadow: Paint.chord("blush").shadow,
                                      body: Paint.chord("blush").body.lt(0.1),
                                      light: Paint.chord("blush").light),
                        seed: seed &+ 3)
            for j in 0...6 {
                let a = Double.pi * 0.18 + Double(j) / 6.0 * Double.pi * 0.64
                penStroke(p, [pnt(shellX, shellY),
                              pnt(shellX + cos(a) * u * 0.21, shellY + sin(a) * u * 0.19)],
                          weight: u * 0.008, colour: Ink.sepia.al(0.6), wobble: 0.3,
                          taper: true, seed: seed &+ UInt64(j * 13))
            }
            for k in 0..<3 {
                let px = cx - bed.rx * 0.1 + Double(k) * bed.rx * 0.38
                let py = cy + Double(k % 2) * u * 0.10
                var curl: [CGPoint] = []
                for j in 0...16 {
                    let a = Double.pi * 1.1 - Double(j) / 16.0 * Double.pi * 1.35
                    let r = u * (0.20 - Double(j) * 0.005)
                    curl.append(pnt(px + cos(a) * r, py + u * 0.12 + sin(a) * r * 0.9))
                }
                penStroke(p, curl, weight: u * 0.055, colour: Paint.chord("blush").body,
                          wobble: u * 0.003, taper: true, seed: seed &+ UInt64(k * 19))
                penStroke(p, curl, weight: u * 0.020, colour: Paint.chord("blush").light,
                          wobble: u * 0.002, taper: true, seed: seed &+ UInt64(k * 23))
                for j in 1...5 {
                    let idx = j * 2
                    if idx < curl.count - 1 {
                        penStroke(p, [curl[idx], CGPoint(x: curl[idx].x, y: curl[idx].y - CGFloat(u * 0.03))],
                                  weight: u * 0.008, colour: Paint.chord("rust").body.al(0.8),
                                  wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 31 + j))
                    }
                }
            }

        case "saladHeap":
            let mound = heapPoints(cx: cx, cy: cy, rx: bed.rx * 0.78 * sc,
                                   height: u * 0.26 * sc, rough: 0.12, seed: seed &+ 3)
            gouache(p, mound, Paint.herbGreen.dk(0.08), unevenness: 0.10, seed: seed &+ 5)
            p.clip(polyPath(mound)) {
                for k in 0..<26 {
                    let a = rng.r(0, 6.283)
                    let rr = pow(rng.d(), 0.6)
                    let lx = cx + cos(a) * bed.rx * 0.62 * rr
                    let ly = cy + u * 0.15 + sin(a) * u * 0.16 * rr
                    let leafTone = [Paint.herbGreen, Paint.herbGreen.lt(0.2),
                                    Paint.herbDark, chord.body][rng.i(0, 3)]
                    dab(p, x: lx, y: ly, rx: u * rng.r(0.045, 0.08),
                        ry: u * rng.r(0.02, 0.045), leafTone, tilt: rng.r(0, 3.1),
                        outline: u * 0.005, seed: seed &+ UInt64(k * 17))
                }
            }
            inkOver(p, mound, weight: u * 0.012, seed: seed &+ 7)

        case "rollSlices":
            let n = 5
            for k in 0..<n {
                let back = k >= 3
                let t = back ? Double(k - 3) : Double(k)
                let count = back ? 2.0 : 3.0
                let dx = cx - bed.rx * 0.55 + bed.rx * 1.1 * (t + 0.5) / count
                let dy = cy + (back ? u * 0.22 : 0.0)
                let r = u * (back ? 0.17 : 0.21) * sc
                // standing cylinder slice: pale disc, dark wrapper ring, centre
                let face = ringPoints(dx, dy + r, r, r * 0.94, steps: 24)
                gouache(p, face, Paint.creamWhite.dk(0.04), seed: seed &+ UInt64(k * 13))
                penStroke(p, face + [face[0]], weight: u * 0.024,
                          colour: Paint.herbDark.dk(0.25), wobble: u * 0.003,
                          taper: false, seed: seed &+ UInt64(k * 17))
                dab(p, x: dx, y: dy + r, rx: r * 0.42, ry: r * 0.40, chord.body,
                    outline: u * 0.006, seed: seed &+ UInt64(k * 19))
                for j in 0..<8 {
                    let a = Double(j) / 8.0 * 6.283
                    dab(p, x: dx + cos(a) * r * 0.66, y: dy + r + sin(a) * r * 0.62,
                        rx: u * 0.012, ry: u * 0.006, Paint.creamWhite.dk(0.14),
                        tilt: a, seed: seed &+ UInt64(k * 29 + j))
                }
            }

        case "wrappedParcel":
            let L = bed.rx * 0.66 * sc
            let H = u * 0.26 * sc
            let parcel = lumpPoints(cx: cx, cy: cy + H * 0.5, rx: L, ry: H,
                                    squash: 0.4, seed: seed &+ 3)
            gouacheForm(p, parcel, Paint.leafGreen, seed: seed &+ 5)
            // tie and fold lines
            penStroke(p, [pnt(cx - L * 0.05, cy - H * 0.3), pnt(cx + L * 0.02, cy + H * 1.35)],
                      weight: u * 0.014, colour: Paint.bamboo.shadow, wobble: 0.5,
                      taper: false, seed: seed &+ 7)
            for j in 0..<4 {
                let t = -0.6 + Double(j) * 0.4
                penStroke(p, [pnt(cx + t * L, cy + H * 1.3), pnt(cx + t * L + L * 0.14, cy - H * 0.1)],
                          weight: u * 0.009, colour: Paint.leafGreen.shadow.al(0.8),
                          wobble: 0.4, taper: true, seed: seed &+ UInt64(j * 11))
            }
            inkOver(p, parcel, weight: u * 0.013, seed: seed &+ 9)
            // filling spilling from the open end
            let open = ringPoints(cx + L * 0.82, cy + H * 0.5, H * 0.5, H * 0.62, steps: 18)
            gouache(p, open, chord.body, seed: seed &+ 11)
            penContour(p, open, weight: u * 0.010, colour: Ink.sepia.al(0.8), seed: seed &+ 13)

        case "layeredSlice":
            let hw = bed.rx * 0.50 * sc
            let hh = u * 0.46 * sc
            let strata = 5
            for k in 0..<strata {
                let y0 = cy + Double(k) / Double(strata) * hh
                let y1 = cy + Double(k + 1) / Double(strata) * hh
                let quad = [pnt(cx - hw, y0), pnt(cx + hw, y0),
                            pnt(cx + hw, y1), pnt(cx - hw, y1)]
                gouache(p, quad, k % 2 == 0 ? chord.body : Paint.creamWhite.dk(0.05),
                        unevenness: 0.05, seed: seed &+ UInt64(k * 13))
            }
            // the top crust and a dusting
            gouache(p, [pnt(cx - hw, cy + hh), pnt(cx + hw, cy + hh),
                        pnt(cx + hw * 0.96, cy + hh + u * 0.04),
                        pnt(cx - hw * 0.96, cy + hh + u * 0.04)],
                    chord.shadow, seed: seed &+ 31)
            let whole = [pnt(cx - hw, cy), pnt(cx + hw, cy),
                         pnt(cx + hw, cy + hh + u * 0.04), pnt(cx - hw, cy + hh + u * 0.04)]
            inkOver(p, whole, weight: u * 0.013, hatchShadow: false, seed: seed &+ 33)
            for k in 0..<10 {
                p.disc(cx + rng.r(-0.9, 0.9) * hw, cy + hh + u * rng.r(0.05, 0.10),
                       u * rng.r(0.004, 0.008), Paint.creamWhite.al(0.9))
                _ = k
            }

        case "grillMarks":
            let hw = bed.rx * 0.78 * sc
            let hh = u * 0.26 * sc
            let slab = lumpPoints(cx: cx, cy: cy + hh * 0.4, rx: hw, ry: hh,
                                  squash: 0.45, seed: seed &+ 3)
            gouacheForm(p, slab, chord, depth: 1.1, seed: seed &+ 5)
            p.clip(polyPath(slab)) {
                for k in 0..<5 {
                    let t = -0.7 + Double(k) * 0.35
                    penStroke(p, [pnt(cx + t * hw - hw * 0.25, cy - hh * 0.5),
                                  pnt(cx + t * hw + hw * 0.25, cy + hh * 1.3)],
                              weight: u * 0.032, colour: Paint.charBrown.al(0.85),
                              wobble: u * 0.003, taper: false, seed: seed &+ UInt64(k * 11))
                }
            }
            inkOver(p, slab, weight: u * 0.014, seed: seed &+ 7)
            // juice pooling at the base
            let juice = ringPoints(cx + hw * 0.2, cy - hh * 0.15, hw * 0.5, u * 0.030, steps: 20)
            gouache(p, juice, Paint.sauceDark.al(0.85), edgeDark: 0.04, seed: seed &+ 9)

        case "friedPieces":
            let n = rng.i(5, 6)
            for k in 0..<n {
                let t = Double(k) / Double(max(1, n - 1))
                let back = k % 2 == 1
                let fx = cx - bed.rx * 0.6 + bed.rx * 1.2 * t
                let fy = cy + (back ? u * 0.18 : 0) + rng.r(0, u * 0.04)
                let r = u * rng.r(0.14, 0.18) * sc
                var piece: [CGPoint] = []
                for j in 0..<18 {
                    let a = Double(j) / 18.0 * 6.283185
                    let knob = 1.0 + 0.16 * sin(a * 5 + Double(k)) + rng.r(-0.06, 0.06)
                    let vert = sin(a) > 0 ? 1.0 : 0.6
                    piece.append(pnt(fx + cos(a) * r * knob, fy + r * 0.5 + sin(a) * r * knob * vert))
                }
                gouacheForm(p, piece, Chord(shadow: Paint.chord("ochre").shadow,
                                            body: Paint.chord("ochre").body,
                                            light: Paint.saffron.lt(0.15)),
                            seed: seed &+ UInt64(k * 17))
                p.clip(polyPath(piece)) {
                    for j in 0..<10 {
                        p.disc(fx + rng.r(-0.7, 0.7) * r, fy + r * 0.5 + rng.r(-0.6, 0.7) * r,
                               u * rng.r(0.004, 0.009), Paint.chord("umber").body.al(0.6))
                        _ = j
                    }
                }
                inkOver(p, piece, weight: u * 0.011, seed: seed &+ UInt64(k * 23))
            }

        case "eggDish":
            let white = lumpPoints(cx: cx, cy: cy + u * 0.05, rx: bed.rx * 0.62 * sc,
                                   ry: u * 0.13, squash: 0.5, seed: seed &+ 3)
            gouacheForm(p, white, Chord(shadow: Paint.creamWhite.dk(0.16),
                                        body: Paint.creamWhite,
                                        light: Col(r: 1, g: 0.99, b: 0.97)),
                        depth: 0.6, seed: seed &+ 5)
            inkOver(p, white, weight: u * 0.011, hatchShadow: false, seed: seed &+ 7)
            let yr = u * 0.14 * sc
            let yolk = ringPoints(cx - bed.rx * 0.05, cy + u * 0.10, yr, yr * 0.72, steps: 22)
            gouacheForm(p, yolk, Chord(shadow: Paint.chord("amber").body,
                                       body: Paint.saffron,
                                       light: Paint.saffron.lt(0.25)),
                        seed: seed &+ 9)
            penContour(p, yolk, weight: u * 0.009, colour: Ink.sepia.al(0.7), seed: seed &+ 11)
            p.disc(cx - bed.rx * 0.05 - yr * 0.3, cy + u * 0.10 + yr * 0.25,
                   yr * 0.20, Paint.creamWhite.al(0.9))

        case "porridge":
            let mound = heapPoints(cx: cx, cy: cy, rx: bed.rx * 0.80 * sc,
                                   height: u * 0.17 * sc, rough: 0.05, seed: seed &+ 3)
            gouacheForm(p, mound, Chord(shadow: chord.shadow.lt(0.05),
                                        body: chord.body.lt(0.14),
                                        light: chord.light.lt(0.1)),
                        depth: 0.7, seed: seed &+ 5)
            p.clip(polyPath(mound)) {
                for k in 0..<5 {
                    var drag: [CGPoint] = []
                    let y0 = cy + u * rng.r(0.04, 0.18)
                    for j in 0...14 {
                        let t = Double(j) / 14.0
                        drag.append(pnt(cx - bed.rx * 0.7 + bed.rx * 1.4 * t,
                                        y0 + sin(t * 5 + Double(k)) * u * 0.02))
                    }
                    penStroke(p, drag, weight: u * 0.018,
                              colour: chord.shadow.al(rng.r(0.3, 0.5)),
                              wobble: u * 0.004, taper: true, seed: seed &+ UInt64(k * 11))
                }
            }
            inkOver(p, mound, weight: u * 0.012, seed: seed &+ 7)
            // a butter pool on top
            let melt = ringPoints(cx, cy + u * 0.20, u * 0.10, u * 0.035, steps: 16)
            gouache(p, melt, Paint.saffron.al(0.9), edgeDark: 0.06, seed: seed &+ 9)

        case "tacoFolds":
            for k in 0..<rng.i(2, 3) {
                let back = k == 1
                let tx = cx + (Double(k) - 0.5) * bed.rx * 0.52
                let ty = cy + (back ? u * 0.16 : 0)
                let r = u * (back ? 0.26 : 0.31) * sc
                // the folded shell: a U seen from the end
                var shell: [CGPoint] = []
                for j in 0...16 {
                    let a = Double.pi + Double(j) / 16.0 * Double.pi
                    shell.append(pnt(tx + cos(a) * r, ty + r * 0.55 + sin(a) * r * 1.05))
                }
                for j in stride(from: 16, through: 0, by: -1) {
                    let a = Double.pi + Double(j) / 16.0 * Double.pi
                    shell.append(pnt(tx + cos(a) * r * 0.82, ty + r * 0.55 + sin(a) * r * 0.80))
                }
                gouacheForm(p, shell, Chord(shadow: Paint.chord("ochre").shadow,
                                            body: Paint.chord("ochre").body.lt(0.06),
                                            light: Paint.chord("ochre").light),
                            seed: seed &+ UInt64(k * 19))
                // filling above the fold line
                for j in 0..<7 {
                    let fx = tx + rng.r(-0.6, 0.6) * r
                    let fy = ty + r * 0.55 + rng.r(0.0, 0.35) * r
                    let tone = [chord.body, Paint.herbGreen, Paint.chiliRed,
                                Paint.creamWhite][rng.i(0, 3)]
                    dab(p, x: fx, y: fy, rx: u * rng.r(0.025, 0.045),
                        ry: u * rng.r(0.015, 0.028), tone, tilt: rng.r(0, 3.1),
                        outline: u * 0.004, seed: seed &+ UInt64(k * 41 + j))
                }
                inkOver(p, shell, weight: u * 0.012, hatchShadow: false,
                        seed: seed &+ UInt64(k * 23))
            }

        case "pancakeStack":
            let n = 4
            for k in 0..<n {
                let ry = u * 0.068
                let cyk = cy + Double(k) * ry * 1.5
                let rx = bed.rx * (0.62 - Double(k) * 0.02) * sc
                let disc = lumpPoints(cx: cx, cy: cyk + ry, rx: rx, ry: ry * 1.6,
                                      squash: 0.55, seed: seed &+ UInt64(k * 13))
                gouacheForm(p, disc, Chord(shadow: Paint.chord("ochre").shadow,
                                           body: Paint.chord("ochre").body.lt(Double(k) * 0.02),
                                           light: Paint.chord("ochre").light),
                            depth: 0.6, seed: seed &+ UInt64(k * 17))
                penContour(p, disc, weight: u * 0.010, colour: Ink.sepia.al(0.7),
                           seed: seed &+ UInt64(k * 19))
            }
            // syrup sliding down the stack
            var syr: [CGPoint] = []
            let topY = cy + Double(n - 1) * u * 0.055 * 1.5 + u * 0.09
            for j in 0...10 {
                let t = Double(j) / 10.0
                syr.append(pnt(cx - bed.rx * 0.2 + sin(t * 5) * u * 0.03, topY - t * u * 0.20))
            }
            penStroke(p, syr, weight: u * 0.024, colour: Paint.sauceDark.al(0.85),
                      wobble: u * 0.003, taper: true, seed: seed &+ 31)
            let melt = ringPoints(cx, topY, u * 0.07, u * 0.025, steps: 14)
            gouache(p, melt, Paint.saffron, edgeDark: 0.05, seed: seed &+ 33)

        case "pastryTart":
            let rx = bed.rx * 0.72 * sc
            let ry = u * 0.15 * sc
            // crimped wall
            var wall: [CGPoint] = []
            for j in 0...30 {
                let a = Double.pi + Double(j) / 30.0 * Double.pi
                let crimp = 1.0 + 0.05 * sin(Double(j) * 2.1)
                wall.append(pnt(cx + cos(a) * rx * crimp, cy + sin(a) * ry))
            }
            for j in stride(from: 30, through: 0, by: -1) {
                let a = Double.pi + Double(j) / 30.0 * Double.pi
                wall.append(pnt(cx + cos(a) * rx * 0.98, cy + u * 0.10 + sin(a) * ry * 0.9))
            }
            gouacheForm(p, wall, Chord(shadow: Paint.chord("ochre").shadow,
                                       body: Paint.chord("ochre").body,
                                       light: Paint.chord("ochre").light),
                        seed: seed &+ 3)
            inkOver(p, wall, weight: u * 0.011, seed: seed &+ 5)
            // the filling face
            let fill = ringPoints(cx, cy + u * 0.10, rx * 0.86, ry * 0.85, steps: 30)
            gouache(p, fill, chord.body, unevenness: 0.08, seed: seed &+ 7)
            penStroke(p, fill + [fill[0]], weight: u * 0.010, colour: Ink.sepia.al(0.7),
                      wobble: 0.4, taper: false, seed: seed &+ 9)
            for k in 0..<6 {
                let a = rng.r(0, 6.283)
                let rr = rng.r(0.2, 0.8)
                dab(p, x: cx + cos(a) * rx * 0.6 * rr, y: cy + u * 0.10 + sin(a) * ry * 0.6 * rr,
                    rx: u * rng.r(0.025, 0.045), ry: u * rng.r(0.015, 0.028),
                    chord.shadow, tilt: rng.r(0, 3.1), outline: u * 0.004,
                    seed: seed &+ UInt64(k * 31))
            }

        case "scoop":
            for k in 0..<2 {
                let sxp = cx + (Double(k) - 0.5) * bed.rx * 0.42
                let syp = cy + Double(k) * u * 0.05
                let r = u * 0.21 * sc
                let ball = lumpPoints(cx: sxp, cy: syp + r * 0.6, rx: r, ry: r * 0.95,
                                      squash: 0.5, seed: seed &+ UInt64(k * 13))
                gouacheForm(p, ball,
                            k == 0 ? chord : Chord(shadow: chord.shadow.lt(0.15),
                                                   body: chord.body.lt(0.22),
                                                   light: chord.light.lt(0.15)),
                            seed: seed &+ UInt64(k * 17))
                var ridge: [CGPoint] = []
                for j in 0...10 {
                    let t = Double(j) / 10.0
                    let ang = Double.pi * 0.2 + t * Double.pi * 1.2
                    ridge.append(pnt(sxp + cos(ang) * r * (0.3 + t * 0.5),
                                     syp + r * 0.6 + sin(ang) * r * (0.3 + t * 0.5) * 0.9))
                }
                penStroke(p, ridge, weight: u * 0.013, colour: chord.shadow.al(0.7),
                          wobble: u * 0.003, taper: true, seed: seed &+ UInt64(k * 23))
                inkOver(p, ball, weight: u * 0.011, hatchShadow: false, seed: seed &+ UInt64(k * 29))
            }

        case "cornCob":
            let L = bed.rx * 0.78 * sc
            let H = u * 0.16 * sc
            let cob = lumpPoints(cx: cx, cy: cy + H, rx: L, ry: H, squash: 0.8, seed: seed &+ 3)
            gouacheForm(p, cob, Chord(shadow: Paint.chord("amber").body,
                                      body: Paint.saffron,
                                      light: Paint.saffron.lt(0.2)),
                        seed: seed &+ 5)
            p.clip(polyPath(cob)) {
                var row = 0
                var yy = cy + H * 0.2
                while yy < cy + H * 1.9 {
                    var xx = cx - L
                    while xx < cx + L {
                        dab(p, x: xx + Double(row % 2) * u * 0.018, y: yy,
                            rx: u * 0.019, ry: u * 0.014,
                            Paint.saffron.dk(Double(row % 3) * 0.04),
                            outline: u * 0.0035, seed: seed &+ u64(Int(xx + yy)))
                        xx += u * 0.038
                    }
                    yy += u * 0.030
                    row += 1
                }
            }
            inkOver(p, cob, weight: u * 0.012, seed: seed &+ 7)
            // husk leaves pulled back
            for side in [-1.0, 1.0] {
                let husk = [pnt(cx + side * L * 0.95, cy + H),
                            pnt(cx + side * L * 1.35, cy + H * 1.6),
                            pnt(cx + side * L * 1.30, cy + H * 0.3)]
                gouache(p, husk, Paint.leafGreen.body, seed: seed &+ u64(Int(side * 41)))
                penContour(p, husk, weight: u * 0.009, colour: Ink.sepia.al(0.7),
                           seed: seed &+ u64(Int(side * 47)))
            }

        case "pickleFan":
            for k in 0..<6 {
                let t = Double(k) / 5.0 - 0.5
                let sxp = cx + t * bed.rx * 1.0 * sc
                let syp = cy + u * 0.05 - abs(t) * u * 0.05
                let r = u * 0.135 * sc
                dab(p, x: sxp, y: syp + r * 0.5, rx: r * 0.8, ry: r,
                    k % 2 == 0 ? chord.body : chord.light, tilt: t * 0.4,
                    outline: u * 0.007, seed: seed &+ UInt64(k * 13))
                dab(p, x: sxp, y: syp + r * 0.5, rx: r * 0.4, ry: r * 0.55,
                    Paint.creamWhite.al(0.6), tilt: t * 0.4, seed: seed &+ UInt64(k * 17))
            }

        case "cubes":
            let n = rng.i(6, 8)
            for k in 0..<n {
                let back = k % 2 == 1
                let t = Double(k) / Double(max(1, n - 1))
                let bx = cx - bed.rx * 0.6 + bed.rx * 1.2 * t + rng.r(-0.03, 0.03) * bed.rx
                let by = cy + (back ? u * 0.16 : 0)
                let s = u * rng.r(0.10, 0.13) * sc
                let top = [pnt(bx, by + s * 1.5), pnt(bx + s, by + s * 1.1),
                           pnt(bx, by + s * 0.7), pnt(bx - s, by + s * 1.1)]
                let leftF = [top[3], top[2], pnt(bx, by), pnt(bx - s, by + s * 0.4)]
                let rightF = [top[2], top[1], pnt(bx + s, by + s * 0.4), pnt(bx, by)]
                gouache(p, leftF, chord.body.dk(0.06), seed: seed &+ UInt64(k * 7))
                gouache(p, rightF, chord.shadow, seed: seed &+ UInt64(k * 11))
                gouache(p, top, chord.light, seed: seed &+ UInt64(k * 13))
                for face in [top, leftF, rightF] {
                    penContour(p, face, weight: u * 0.008, colour: Ink.sepia.al(0.8),
                               seed: seed &+ UInt64(k * 19))
                }
            }

        case "meatSlab":
            // the joint behind, three carved slices fanned in front
            let joint = lumpPoints(cx: cx - bed.rx * 0.25, cy: cy + u * 0.22,
                                   rx: bed.rx * 0.48 * sc, ry: u * 0.24, squash: 0.5,
                                   seed: seed &+ 3)
            gouacheForm(p, joint, Chord(shadow: chord.shadow.dk(0.08),
                                        body: chord.body.dk(0.08),
                                        light: chord.light.dk(0.04)),
                        depth: 1.1, seed: seed &+ 5)
            inkOver(p, joint, weight: u * 0.013, seed: seed &+ 7)
            for k in 0..<3 {
                let sxp = cx + bed.rx * (0.05 + Double(k) * 0.21)
                let syp = cy + u * (0.06 - Double(k) * 0.01)
                let slice = lumpPoints(cx: sxp, cy: syp + u * 0.10, rx: bed.rx * 0.21 * sc,
                                       ry: u * 0.13, squash: 0.42, seed: seed &+ UInt64(k * 13))
                gouacheForm(p, slice, Chord(shadow: chord.body.dk(0.05),
                                            body: chord.body.lt(0.16),
                                            light: chord.light.lt(0.10)),
                            depth: 0.6, seed: seed &+ UInt64(k * 17))
                p.clip(polyPath(slice)) {
                    for j in 0..<4 {
                        let yy = syp + u * (0.03 + Double(j) * 0.045)
                        penBroken(p, [pnt(sxp - bed.rx * 0.16, yy), pnt(sxp + bed.rx * 0.16, yy)],
                                  weight: u * 0.007, colour: Paint.creamWhite.al(0.6),
                                  pieces: 2, gap: 0.15, wobble: 0.4,
                                  seed: seed &+ UInt64(k * 31 + j))
                    }
                }
                penContour(p, slice, weight: u * 0.009, colour: Ink.sepia.al(0.75),
                           seed: seed &+ UInt64(k * 23))
            }

        case "dropBalls":
            let n = rng.i(4, 5)
            for k in 0..<n {
                let back = k % 2 == 1
                let t = Double(k) / Double(max(1, n - 1))
                let bx = cx - bed.rx * 0.55 + bed.rx * 1.1 * t
                let by = cy + (back ? u * 0.17 : 0)
                let r = u * rng.r(0.15, 0.175) * sc
                let ball = lumpPoints(cx: bx, cy: by + r * 0.6, rx: r, ry: r * 0.92,
                                      squash: 0.5, seed: seed &+ UInt64(k * 13))
                gouacheForm(p, ball, chord, seed: seed &+ UInt64(k * 17))
                p.clip(polyPath(ball)) {
                    for j in 0..<6 {
                        p.disc(bx + rng.r(-0.6, 0.6) * r, by + r * 0.6 + rng.r(-0.5, 0.6) * r,
                               u * rng.r(0.004, 0.008), chord.shadow.al(0.5))
                        _ = j
                    }
                }
                inkOver(p, ball, weight: u * 0.011, seed: seed &+ UInt64(k * 23))
            }

        case "springRolls":
            // two lying crossed, one leaning on them
            for k in 0..<3 {
                let lean = k == 2
                let ang = lean ? 0.55 : (k == 0 ? 0.10 : -0.14)
                let rcx = cx + (lean ? bed.rx * 0.05 : (Double(k) - 0.5) * bed.rx * 0.16)
                let rcy = cy + (lean ? u * 0.16 : Double(k) * u * 0.05)
                let L = bed.rx * 0.60 * sc
                let H = u * 0.095 * sc
                var tube: [CGPoint] = []
                for j in 0...14 {
                    let t = Double(j) / 14.0 * 2 - 1
                    tube.append(pnt(rcx + t * L * cos(ang) - H * sin(ang),
                                    rcy + H + t * L * sin(ang) + H * cos(ang)))
                }
                for j in stride(from: 14, through: 0, by: -1) {
                    let t = Double(j) / 14.0 * 2 - 1
                    tube.append(pnt(rcx + t * L * cos(ang) + H * sin(ang),
                                    rcy + H + t * L * sin(ang) - H * cos(ang)))
                }
                gouacheForm(p, tube, Chord(shadow: Paint.chord("ochre").shadow,
                                           body: Paint.chord("ochre").body.lt(0.08),
                                           light: Paint.chord("ochre").light.lt(0.05)),
                            seed: seed &+ UInt64(k * 19))
                p.clip(polyPath(tube)) {
                    for j in 0..<8 {
                        p.disc(rcx + rng.r(-0.8, 0.8) * L, rcy + H + rng.r(-0.8, 0.8) * H,
                               u * rng.r(0.003, 0.007), Paint.chord("umber").body.al(0.5))
                        _ = j
                    }
                }
                inkOver(p, tube, weight: u * 0.010, hatchShadow: false, seed: seed &+ UInt64(k * 23))
                // cut end
                let endC = ringPoints(rcx + L * cos(ang), rcy + H + L * sin(ang),
                                      H * 0.6, H * 0.95, steps: 12)
                gouache(p, endC, Paint.herbGreen, seed: seed &+ UInt64(k * 29))
                penContour(p, endC, weight: u * 0.007, colour: Ink.sepia.al(0.8),
                           seed: seed &+ UInt64(k * 31))
            }

        default:
            let mound = heapPoints(cx: cx, cy: cy, rx: bed.rx * 0.7 * sc,
                                   height: u * 0.3 * sc, rough: 0.08, seed: seed &+ 3)
            gouacheForm(p, mound, chord, seed: seed &+ 5)
            inkOver(p, mound, weight: u * 0.012, seed: seed &+ 7)
        }
    }

    if layer == 0 { bed.overdraw() }
}
