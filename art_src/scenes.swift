import Foundation
import CoreGraphics

// The finished plates: one per dish, one per cuisine, plus the visa pages,
// the guide boards and the passport's own paper.

struct DishSpec {
    var id: String
    var cuisine: String
    var vessel: String
    var main: String
    var extras: [String]
    var garnish: [String]
    var palette: String
}

/// The bitten border of an engraved plate, pressed into the paper.
func plateMark(_ p: Plate, inset: Double, seed: UInt64) {
    var rng = RNG(seed)
    let r = CGRect(x: inset, y: inset, width: p.w - inset * 2, height: p.h - inset * 2)
    var pts: [CGPoint] = []
    let steps = 44
    for i in 0..<steps {
        let t = Double(i) / Double(steps)
        let per = t * 4
        let j = rng.r(-1.4, 1.4)
        switch Int(per) {
        case 0: pts.append(CGPoint(x: Double(r.minX) + Double(r.width) * (per - 0), y: Double(r.minY) + j))
        case 1: pts.append(CGPoint(x: Double(r.maxX) + j, y: Double(r.minY) + Double(r.height) * (per - 1)))
        case 2: pts.append(CGPoint(x: Double(r.maxX) - Double(r.width) * (per - 2), y: Double(r.maxY) + j))
        default: pts.append(CGPoint(x: Double(r.minX) + j, y: Double(r.maxY) - Double(r.height) * (per - 3)))
        }
    }
    penStroke(p, pts + [pts[0]], weight: 2.2, colour: Ink.sepiaSoft.al(0.42),
              wobble: 0.8, taper: false, seed: seed &+ 3)
    penStroke(p, pts.map { CGPoint(x: $0.x + 3, y: $0.y - 3) } + [pts[0]],
              weight: 1.0, colour: Ink.paper.dk(0.06).al(0.5), wobble: 0.6, taper: false,
              seed: seed &+ 5)
}

/// The dining-room behind a plate: a muted wall band above, a cloth below,
/// both painted opaquely and tinted toward the dish palette.
private func tableSetting(_ p: Plate, seed: UInt64, paletteKey: String, horizon: Double) {
    var rng = RNG(seed)
    let chord = Paint.chord(paletteKey)

    // wall: deep, calm, tinted paper
    let wallTone = Ink.paperWarm.dk(0.075).mix(chord.body, 0.13)
    gouache(p, [pnt(-20, horizon), pnt(p.w + 20, horizon),
                pnt(p.w + 20, p.h + 20), pnt(-20, p.h + 20)],
            wallTone, unevenness: 0.05, edgeDark: 0.02, seed: seed &+ 3)

    // cloth: warm cream tinted toward the palette, with woven stripes
    let clothTone = Ink.paperWarm.lt(0.02).mix(chord.body, 0.10)
    gouache(p, [pnt(-20, -20), pnt(p.w + 20, -20),
                pnt(p.w + 20, horizon), pnt(-20, horizon)],
            clothTone, unevenness: 0.06, edgeDark: 0.02, seed: seed &+ 5)
    for k in 0..<2 {
        let y = horizon * (0.30 + Double(k) * 0.38) + rng.r(-8, 8)
        penStroke(p, [pnt(-10, y), pnt(p.w + 10, y + rng.r(-4, 4))],
                  weight: 2.6, colour: chord.body.al(0.35), wobble: 1.2,
                  taper: false, seed: seed &+ UInt64(k * 11))
        penStroke(p, [pnt(-10, y - 7), pnt(p.w + 10, y - 7 + rng.r(-4, 4))],
                  weight: 1.1, colour: chord.body.al(0.28), wobble: 1.0,
                  taper: false, seed: seed &+ UInt64(k * 13))
    }
    // the table edge line
    penStroke(p, [pnt(-10, horizon), pnt(p.w + 10, horizon + rng.r(-4, 4))],
              weight: 2.4, colour: Ink.sepia.al(0.5), wobble: 1.2, taper: false,
              seed: seed &+ 17)
}

/// The finished frame: double rule with corner diamonds, in ink and gilt ochre.
func plateFrame(_ p: Plate, inset: Double, seed: UInt64) {
    let m = inset
    let outer = [pnt(m, m), pnt(p.w - m, m), pnt(p.w - m, p.h - m), pnt(m, p.h - m)]
    penContour(p, outer, weight: 2.6, colour: Ink.sepia.al(0.72), seed: seed &+ 3)
    let m2 = m + min(p.w, p.h) * 0.014
    let innerR = [pnt(m2, m2), pnt(p.w - m2, m2), pnt(p.w - m2, p.h - m2), pnt(m2, p.h - m2)]
    penContour(p, innerR, weight: 1.0, colour: Paint.chord("ochre").shadow.al(0.65),
               seed: seed &+ 5)
    let d = min(p.w, p.h) * 0.016
    for (cx, cy) in [(m, m), (p.w - m, m), (p.w - m, p.h - m), (m, p.h - m)] {
        let diamond = [pnt(cx, cy + d), pnt(cx + d, cy), pnt(cx, cy - d), pnt(cx - d, cy)]
        p.poly(diamond, Paint.chord("ochre").body.al(0.85))
        penContour(p, diamond, weight: 1.0, colour: Ink.sepia.al(0.7), seed: seed &+ u64(Int(cx)))
    }
}

// MARK: - One dish

func renderDishPlate(_ spec: DishSpec, size: Int) -> Plate {
    let p = Plate(size, size)
    let seed = inkSeed(spec.id)
    var rng = RNG(seed)
    p.light = rng.r(2.1, 2.6)

    layPaper(p, seed: seed &+ 1, tone: Ink.paperWarm)
    tableSetting(p, seed: seed &+ 2, paletteKey: spec.palette, horizon: p.h * 0.64)

    let unit = Double(size) * 1.10
    let bed = vessel(p, kind: spec.vessel, cuisineKey: spec.cuisine,
                     paletteKey: spec.palette, seed: seed &+ 11,
                     cx: p.w * 0.5, cy: p.h * 0.40, unit: unit)

    if bed.upright {
        // A glass: fill with the palette body, strata, bubbles, food on top.
        let box = bed.clip.boundingBox
        let chord = Paint.chord(spec.palette)
        p.clip(bed.clip) {
            gouache(p, [pnt(Double(box.minX), Double(box.minY)),
                        pnt(Double(box.maxX), Double(box.minY)),
                        pnt(Double(box.maxX), Double(box.maxY)),
                        pnt(Double(box.minX), Double(box.maxY))],
                    chord.body, unevenness: 0.07, edgeDark: 0.04, seed: seed &+ 13)
            for k in 0..<2 {
                let y = Double(box.minY) + Double(box.height) * (0.30 + Double(k) * 0.30)
                gouache(p, [pnt(Double(box.minX), y), pnt(Double(box.maxX), y),
                            pnt(Double(box.maxX), y + Double(box.height) * 0.06),
                            pnt(Double(box.minX), y + Double(box.height) * 0.06)],
                        k == 0 ? chord.light : chord.shadow, unevenness: 0.04,
                        edgeDark: 0.03, seed: seed &+ UInt64(k * 17))
            }
            for k in 0..<14 {
                p.disc(Double(box.minX) + rng.d() * Double(box.width),
                       Double(box.minY) + rng.d() * Double(box.height),
                       Double(box.width) * rng.r(0.015, 0.04),
                       Paint.creamWhite.al(rng.r(0.25, 0.5)))
                _ = k
            }
        }
        let top = Bed(cx: Double(box.midX), cy: Double(box.maxY) - Double(box.height) * 0.16,
                      rx: Double(box.width) * 0.44, ry: Double(box.height) * 0.10,
                      clip: bed.clip)
        drawFood(p, spec.main, bed: top, paletteKey: spec.palette, seed: seed &+ 23, layer: 0)
        for (i, g) in spec.garnish.prefix(2).enumerated() {
            drawGarnish(p, g, bed: top, paletteKey: spec.palette, seed: seed &+ 41, index: i)
        }
    } else {
        // Liquids and grains are the bed the dish sits in, not a side dish:
        // they fill the vessel first, at full size. Solid extras sit behind.
        let baseKinds: Set<String> = ["brothSurface", "curryPool", "riceScatter", "porridge"]
        let bases = spec.extras.filter { baseKinds.contains($0) }
        let sides = spec.extras.filter { !baseKinds.contains($0) }
        for (i, e) in bases.prefix(2).enumerated() {
            drawFood(p, e, bed: bed, paletteKey: spec.palette,
                     seed: seed &+ UInt64(29 + i * 7), layer: 0)
        }
        for (i, e) in sides.prefix(2).enumerated() {
            drawFood(p, e, bed: bed, paletteKey: spec.palette,
                     seed: seed &+ UInt64(31 + i * 13), layer: i + 1)
        }
        drawFood(p, spec.main, bed: bed, paletteKey: spec.palette, seed: seed &+ 23, layer: 0)
        for (i, g) in spec.garnish.prefix(3).enumerated() {
            drawGarnish(p, g, bed: bed, paletteKey: spec.palette, seed: seed &+ 41, index: i)
        }
    }

    plateFrame(p, inset: Double(size) * 0.040, seed: seed &+ 97)
    return p
}

// MARK: - A cuisine's table

/// Three of the country's dishes on one canvas, painted back to front.
func renderCuisineScene(id: String, specs: [DishSpec], size: (Int, Int)) -> Plate {
    let p = Plate(size.0, size.1)
    let seed = inkSeed("scene-" + id)
    p.light = 2.35
    let paletteKey = specs.first?.palette ?? "amber"

    layPaper(p, seed: seed &+ 1, tone: Ink.paperWarm)
    tableSetting(p, seed: seed &+ 2, paletteKey: paletteKey, horizon: p.h * 0.66)

    // back to front: far small, mid, near large — opaque paint occludes honestly
    let placements: [(Double, Double, Double)] = [(0.76, 0.56, 0.34), (0.26, 0.48, 0.42), (0.55, 0.26, 0.55)]
    for (i, spec) in specs.prefix(3).enumerated() {
        let (fx, fy, sc) = placements[i]
        let unit = Double(size.1) * sc * 1.9
        let dishSeed = inkSeed(spec.id)
        let bed = vessel(p, kind: spec.vessel, cuisineKey: spec.cuisine,
                         paletteKey: spec.palette, seed: dishSeed &+ 11,
                         cx: p.w * fx, cy: p.h * fy, unit: unit)
        if !bed.upright {
            drawFood(p, spec.main, bed: bed, paletteKey: spec.palette,
                     seed: dishSeed &+ 23, layer: 0)
            for (j, g) in spec.garnish.prefix(2).enumerated() {
                drawGarnish(p, g, bed: bed, paletteKey: spec.palette,
                            seed: dishSeed &+ 41, index: j)
            }
        } else {
            let box = bed.clip.boundingBox
            let chord = Paint.chord(spec.palette)
            p.clip(bed.clip) {
                gouache(p, [pnt(Double(box.minX), Double(box.minY)),
                            pnt(Double(box.maxX), Double(box.minY)),
                            pnt(Double(box.maxX), Double(box.maxY)),
                            pnt(Double(box.minX), Double(box.maxY))],
                        chord.body, unevenness: 0.06, seed: dishSeed &+ 13)
            }
        }
    }

    plateFrame(p, inset: Double(size.1) * 0.032, seed: seed &+ 97)
    return p
}

// MARK: - Visa pages

/// Engine-turned guilloche — the rosette that makes a document look official.
private func guilloche(_ p: Plate, cx: Double, cy: Double, r: Double,
                       petals: Int, ratio: Double, colour: Col, seed: UInt64) {
    var pts: [CGPoint] = []
    let steps = 1400
    for i in 0...steps {
        let t = Double(i) / Double(steps) * 6.283185 * Double(petals) * 0.5
        let rr = r * (0.62 + 0.38 * cos(t * ratio))
        pts.append(CGPoint(x: cx + cos(t) * rr, y: cy + sin(t) * rr * 0.92))
        if pts.count > 40 {
            penStroke(p, pts, weight: 0.9, colour: colour, wobble: 0.25, taper: false,
                      seed: seed &+ UInt64(i))
            pts = [pts[pts.count - 1]]
        }
    }
    if pts.count > 2 {
        penStroke(p, pts, weight: 0.9, colour: colour, wobble: 0.25, taper: false, seed: seed)
    }
}

func renderVisaPlate(id: String, tint: String, petals: Int, size: (Int, Int)) -> Plate {
    let p = Plate(size.0, size.1)
    let seed = inkSeed("visa-" + id)
    var rng = RNG(seed)
    p.light = 2.3
    let colour = Ink.wash(tint)

    layPaper(p, seed: seed &+ 1, tone: Ink.paperWarm)

    // a pale security tint over the whole page
    let full = [CGPoint(x: 0, y: 0), CGPoint(x: p.w, y: 0),
                CGPoint(x: p.w, y: p.h), CGPoint(x: 0, y: p.h)]
    wash(p, full, colour.lt(0.42), strength: 0.14, bleed: 10, seed: seed &+ 3)

    // the big rosette, and two smaller ones in opposite corners
    guilloche(p, cx: p.w * 0.5, cy: p.h * 0.5, r: min(p.w, p.h) * 0.40,
              petals: petals, ratio: Double(petals) * 0.72,
              colour: colour.dk(0.28).al(0.72), seed: seed &+ 5)
    guilloche(p, cx: p.w * 0.5, cy: p.h * 0.5, r: min(p.w, p.h) * 0.27,
              petals: max(6, petals - 1), ratio: Double(petals) * 1.15,
              colour: colour.dk(0.34).al(0.55), seed: seed &+ 6)
    guilloche(p, cx: p.w * 0.13, cy: p.h * 0.80, r: min(p.w, p.h) * 0.14,
              petals: max(5, petals - 2), ratio: Double(petals) * 0.5,
              colour: colour.dk(0.20).al(0.60), seed: seed &+ 7)
    guilloche(p, cx: p.w * 0.87, cy: p.h * 0.20, r: min(p.w, p.h) * 0.14,
              petals: max(5, petals - 3), ratio: Double(petals) * 0.55,
              colour: colour.dk(0.20).al(0.60), seed: seed &+ 9)

    // a double ruled frame with corner ornaments
    for (i, ins) in [0.045, 0.062].enumerated() {
        let m = min(p.w, p.h) * ins
        let box = [CGPoint(x: m, y: m), CGPoint(x: p.w - m, y: m),
                   CGPoint(x: p.w - m, y: p.h - m), CGPoint(x: m, y: p.h - m)]
        penContour(p, box, weight: i == 0 ? 3.0 : 1.2, colour: Ink.sepia.al(0.72),
                   seed: seed &+ UInt64(i * 13))
    }
    let m = min(p.w, p.h) * 0.045
    for (sx, sy) in [(m, m), (p.w - m, m), (p.w - m, p.h - m), (m, p.h - m)] {
        for k in 0..<3 {
            let rr = min(p.w, p.h) * (0.018 + Double(k) * 0.011)
            let ring = ellipsePoints(cx: sx, cy: sy, rx: rr, ry: rr, steps: 26)
            penStroke(p, ring + [ring[0]], weight: 1.0 - Double(k) * 0.2,
                      colour: colour.dk(0.20).al(0.55), wobble: 0.4, taper: false,
                      seed: seed &+ u64(Int(sx) &+ k))
        }
    }

    // ruled lines where a clerk would write, left blank
    for k in 0..<4 {
        let y = p.h * (0.20 + Double(k) * 0.075)
        penBroken(p, [CGPoint(x: p.w * 0.12, y: y), CGPoint(x: p.w * 0.62, y: y)],
                  weight: 1.4, colour: Ink.sepiaSoft.al(0.55), pieces: 2, gap: 0.06,
                  wobble: 0.8, seed: seed &+ UInt64(k * 11))
    }
    // the officer's endorsement box in the upper left
    let boxW = min(p.w, p.h) * 0.26
    let stampBox = [CGPoint(x: p.w * 0.12, y: p.h * 0.62),
                    CGPoint(x: p.w * 0.12 + boxW, y: p.h * 0.62),
                    CGPoint(x: p.w * 0.12 + boxW, y: p.h * 0.62 + boxW * 0.62),
                    CGPoint(x: p.w * 0.12, y: p.h * 0.62 + boxW * 0.62)]
    penContour(p, stampBox, weight: 1.8, colour: Ink.sepiaSoft.al(0.6), seed: seed &+ 21)
    hatch(p, polyPath(stampBox), angle: 0.6, spacing: min(p.w, p.h) * 0.028, weight: 0.9,
          colour: colour.dk(0.20).al(0.30), coverage: 0.7, seed: seed &+ 23)
    // perforation down one edge
    var y = p.h * 0.10
    while y < p.h * 0.92 {
        p.disc(p.w * 0.955, y, min(p.w, p.h) * 0.007, Ink.paper.dk(0.22).al(0.7))
        y += min(p.w, p.h) * 0.030
    }
    _ = rng.d()
    plateMark(p, inset: min(p.w, p.h) * 0.020, seed: seed &+ 97)
    return p
}

// MARK: - Guide boards

/// An atlas plate: a few specimens on a ruled board, each with its ticket line.
func renderGuideBoard(id: String, items: [String], palettes: [String], size: (Int, Int)) -> Plate {
    let p = Plate(size.0, size.1)
    let seed = inkSeed("guide-" + id)
    var rng = RNG(seed)
    p.light = 2.25
    layPaper(p, seed: seed &+ 1, tone: Ink.paper)

    // the board the specimens rest on
    let boardTop = p.h * 0.30
    washBand(p, from: 0, to: boardTop, Ink.wood.lt(0.35), strength: 0.20, seed: seed &+ 3)
    penBroken(p, [CGPoint(x: 0, y: boardTop), CGPoint(x: p.w, y: boardTop + rng.r(-5, 5))],
              weight: 2.0, colour: Ink.sepiaSoft.al(0.45), pieces: 4, gap: 0.05,
              wobble: 1.4, seed: seed &+ 5)

    let n = max(1, items.count)
    for (i, item) in items.enumerated() {
        let cx = p.w * (Double(i) + 0.5) / Double(n)
        let cy = p.h * 0.56
        let r = min(p.w / Double(n), p.h) * 0.34
        let clipRing = CGMutablePath()
        clipRing.addPath(polyPath(ellipsePoints(cx: cx, cy: cy, rx: r, ry: r * 0.60, steps: 40)))
        clipRing.addRect(CGRect(x: cx - r * 0.95, y: cy, width: r * 1.9, height: r * 0.9))
        let bed = Bed(cx: cx, cy: cy, rx: r * 0.82, ry: r * 0.34, clip: clipRing)
        let palKey = palettes.isEmpty ? "amber" : palettes[i % palettes.count]
        groundShadow(p, at: cx, y: cy - r * 0.30, width: r * 1.5,
                     tone: Col(r: 0.70, g: 0.62, b: 0.51), seed: seed &+ UInt64(i * 7))
        drawFood(p, item, bed: bed, paletteKey: palKey, seed: seed &+ UInt64(i * 101), layer: 0)
        // the ticket: a leader line down to a ruled label the app writes over
        penStroke(p, [CGPoint(x: cx, y: cy - r * 0.95), CGPoint(x: cx, y: p.h * 0.16)],
                  weight: 1.1, colour: Ink.sepiaSoft.al(0.55), wobble: 0.5, taper: false,
                  seed: seed &+ UInt64(i * 13))
        penStroke(p, [CGPoint(x: cx - r * 0.55, y: p.h * 0.14), CGPoint(x: cx + r * 0.55, y: p.h * 0.14)],
                  weight: 1.6, colour: Ink.sepia.al(0.7), wobble: 0.5, taper: false,
                  seed: seed &+ UInt64(i * 17))
        for k in 0..<3 {
            let rr = r * (0.06 + Double(k) * 0.02)
            let dot = ellipsePoints(cx: cx, cy: p.h * 0.14, rx: rr, ry: rr, steps: 14)
            penStroke(p, dot + [dot[0]], weight: 0.8, colour: Ink.sepiaSoft.al(0.4),
                      wobble: 0.3, taper: false, seed: seed &+ UInt64(i * 23 + k))
        }
    }
    plateFrame(p, inset: min(p.w, p.h) * 0.028, seed: seed &+ 97)
    return p
}

/// A hatched route map — for the guides that are about how food travelled.
func renderRouteMap(id: String, size: (Int, Int)) -> Plate {
    let p = Plate(size.0, size.1)
    let seed = inkSeed("route-" + id)
    var rng = RNG(seed)
    p.light = 2.2
    layPaper(p, seed: seed &+ 1, tone: Ink.paperWarm)

    // three landmasses, hatched at their coasts
    for k in 0..<3 {
        let cx = p.w * [0.24, 0.58, 0.86][k]
        let cy = p.h * [0.42, 0.66, 0.34][k]
        let land = blob(cx: cx, cy: cy, rx: p.w * rng.r(0.14, 0.22), ry: p.h * rng.r(0.18, 0.30),
                        rough: 0.28, steps: 34, seed: seed &+ UInt64(k * 13))
        wash(p, land, Ink.ochre.lt(0.30), strength: 0.24, bleed: 7, seed: seed &+ UInt64(k * 17))
        penContour(p, land, weight: 2.0, seed: seed &+ UInt64(k * 19))
        // the coastal hatching of an old chart
        for j in 1...3 {
            let out = land.map { pt -> CGPoint in
                let dx = Double(pt.x) - cx, dy = Double(pt.y) - cy
                let l = max(1e-6, (dx * dx + dy * dy).squareRoot())
                let g = 1.0 + Double(j) * 0.035
                return CGPoint(x: cx + dx / l * l * g, y: cy + dy / l * l * g)
            }
            penBroken(p, out + [out[0]], weight: 0.8,
                      colour: Ink.sepiaSoft.al(0.34 - Double(j) * 0.08),
                      pieces: 6, gap: 0.05, wobble: 1.0, seed: seed &+ UInt64(k * 31 + j))
        }
    }
    // the routes: dotted arcs with a heading arrow
    for k in 0..<4 {
        let a = CGPoint(x: p.w * rng.r(0.14, 0.34), y: p.h * rng.r(0.28, 0.62))
        let b = CGPoint(x: p.w * rng.r(0.62, 0.90), y: p.h * rng.r(0.30, 0.72))
        var arc: [CGPoint] = []
        for j in 0...40 {
            let t = Double(j) / 40.0
            let x = Double(a.x) + (Double(b.x) - Double(a.x)) * t
            let y = Double(a.y) + (Double(b.y) - Double(a.y)) * t + sin(.pi * t) * p.h * rng.r(0.06, 0.14)
            arc.append(CGPoint(x: x, y: y))
        }
        let dashed = resample(arc, count: 46)
        for j in stride(from: 0, to: dashed.count - 1, by: 2) {
            penStroke(p, [dashed[j], dashed[j + 1]], weight: 1.6,
                      colour: Ink.crimson.dk(0.10).al(0.65), wobble: 0.4, taper: false,
                      seed: seed &+ UInt64(k * 41 + j))
        }
        let tip = dashed[dashed.count - 1], prev = dashed[dashed.count - 4]
        let ang = atan2(Double(tip.y - prev.y), Double(tip.x - prev.x))
        for s in [-0.5, 0.5] {
            penStroke(p, [tip, CGPoint(x: Double(tip.x) - cos(ang + s) * p.w * 0.020,
                                       y: Double(tip.y) - sin(ang + s) * p.w * 0.020)],
                      weight: 1.8, colour: Ink.crimson.dk(0.10).al(0.75), wobble: 0.3,
                      taper: false, seed: seed &+ u64(Int(s * 100)))
        }
    }
    // a compass rose
    let ccx = p.w * 0.11, ccy = p.h * 0.86, cr = min(p.w, p.h) * 0.075
    for k in 0..<8 {
        let a = Double(k) / 8.0 * 6.283185
        let long = k % 2 == 0
        penStroke(p, [CGPoint(x: ccx, y: ccy),
                      CGPoint(x: ccx + cos(a) * cr * (long ? 1.0 : 0.6),
                              y: ccy + sin(a) * cr * (long ? 1.0 : 0.6))],
                  weight: long ? 2.0 : 1.1, colour: Ink.sepia.al(0.8), wobble: 0.4,
                  taper: true, seed: seed &+ UInt64(k))
    }
    let ring = ellipsePoints(cx: ccx, cy: ccy, rx: cr * 1.12, ry: cr * 1.12, steps: 30)
    penStroke(p, ring + [ring[0]], weight: 1.3, colour: Ink.sepia.al(0.7),
              wobble: 0.5, taper: false, seed: seed &+ 71)

    plateMark(p, inset: min(p.w, p.h) * 0.028, seed: seed &+ 97)
    return p
}

// MARK: - The passport's own paper

/// A blank passport leaf: security tint, watermark rosette, ruled foot.
func renderPassportPage(index: Int, size: (Int, Int)) -> Plate {
    let p = Plate(size.0, size.1)
    let seed = inkSeed("page-\(index)")
    p.light = 2.3
    layPaper(p, seed: seed &+ 1, tone: index % 2 == 0 ? Ink.paperWarm : Ink.paper)

    let tints = [Ink.amber, Ink.jade, Ink.plum, Ink.glaze]
    let colour = tints[index % tints.count]
    let full = [CGPoint(x: 0, y: 0), CGPoint(x: p.w, y: 0),
                CGPoint(x: p.w, y: p.h), CGPoint(x: 0, y: p.h)]
    wash(p, full, colour.lt(0.55), strength: 0.10, bleed: 12, seed: seed &+ 3)

    // A fine lace rather than a spiky star: at full-screen size a low petal
    // count reads as scribble, so the lobes stay small and closely spaced.
    guilloche(p, cx: p.w * 0.5, cy: p.h * 0.52, r: min(p.w, p.h) * 0.30,
              petals: 26 + index * 3, ratio: 22.0 + Double(index) * 2,
              colour: colour.dk(0.10).al(0.11), seed: seed &+ 5)
    guilloche(p, cx: p.w * 0.5, cy: p.h * 0.52, r: min(p.w, p.h) * 0.19,
              petals: 20 + index * 2, ratio: 17.0 + Double(index),
              colour: colour.dk(0.14).al(0.09), seed: seed &+ 6)

    // the faint grid a passport prints so stamps sit straight
    var y = p.h * 0.06
    while y < p.h * 0.95 {
        penBroken(p, [CGPoint(x: p.w * 0.06, y: y), CGPoint(x: p.w * 0.94, y: y)],
                  weight: 0.8, colour: Ink.sepiaSoft.al(0.10), pieces: 3, gap: 0.08,
                  wobble: 0.6, seed: seed &+ u64(Int(y)))
        y += p.h * 0.055
    }
    let m = min(p.w, p.h) * 0.035
    let box = [CGPoint(x: m, y: m), CGPoint(x: p.w - m, y: m),
               CGPoint(x: p.w - m, y: p.h - m), CGPoint(x: m, y: p.h - m)]
    penContour(p, box, weight: 1.6, colour: Ink.sepiaSoft.al(0.45), seed: seed &+ 13)
    return p
}

/// The cover: buckram, a blind-stamped rule and a pressed emblem.
func renderCover(size: (Int, Int)) -> Plate {
    let p = Plate(size.0, size.1)
    let seed = inkSeed("cover")
    var rng = RNG(seed)
    p.light = 2.2

    let cloth = Col(r: 0.243, g: 0.208, b: 0.180)
    p.fillAll(cloth)
    // buckram grain
    for _ in 0..<Int(p.w * p.h / 900) {
        let x = rng.d() * p.w, y = rng.d() * p.h
        p.rect(x, y, rng.r(1, 5), rng.r(0.7, 1.6), cloth.lt(rng.r(0.02, 0.10)).al(rng.r(0.2, 0.6)))
    }
    for _ in 0..<Int(p.w * p.h / 2600) {
        let x = rng.d() * p.w, y = rng.d() * p.h
        p.rect(x, y, rng.r(0.7, 1.6), rng.r(1, 5), cloth.dk(rng.r(0.05, 0.18)).al(rng.r(0.2, 0.5)))
    }
    // a worn bloom in the middle and darkness at the edges
    if let g = CGGradient(colorsSpace: inkSpace,
                          colors: [cgc(cloth.lt(0.10).al(0.35)), cgc(cloth.al(0))] as CFArray,
                          locations: [0, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: p.w * 0.5, y: p.h * 0.58),
                                 startRadius: 0, endCenter: CGPoint(x: p.w * 0.5, y: p.h * 0.58),
                                 endRadius: p.w * 0.72, options: [])
    }
    if let g = CGGradient(colorsSpace: inkSpace,
                          colors: [cgc(cloth.dk(0.5).al(0)), cgc(cloth.dk(0.5).al(0.65))] as CFArray,
                          locations: [0.55, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: p.w * 0.5, y: p.h * 0.5),
                                 startRadius: 0, endCenter: CGPoint(x: p.w * 0.5, y: p.h * 0.5),
                                 endRadius: max(p.w, p.h) * 0.70, options: [.drawsAfterEndLocation])
    }

    let gold = Col(r: 0.784, g: 0.663, b: 0.400)
    let m = min(p.w, p.h) * 0.070
    let box = [CGPoint(x: m, y: m), CGPoint(x: p.w - m, y: m),
               CGPoint(x: p.w - m, y: p.h - m), CGPoint(x: m, y: p.h - m)]
    penContour(p, box, weight: 3.2, colour: gold.al(0.80), seed: seed &+ 5)
    penContour(p, box.map { CGPoint(x: $0.x + CGFloat(m * 0.12), y: $0.y + CGFloat(m * 0.12)) },
               weight: 1.2, colour: gold.al(0.50), seed: seed &+ 7)

    // pressed emblem: a plate seen edge-on inside a wreath of rules
    let cx = p.w * 0.5, cy = p.h * 0.62, r = min(p.w, p.h) * 0.18
    for k in 0..<3 {
        let ring = ellipsePoints(cx: cx, cy: cy, rx: r * (1.0 + Double(k) * 0.10),
                                 ry: r * (1.0 + Double(k) * 0.10) * 0.98, steps: 60)
        penStroke(p, ring + [ring[0]], weight: k == 0 ? 2.6 : 1.2,
                  colour: gold.al(0.72 - Double(k) * 0.16), wobble: 0.5, taper: false,
                  seed: seed &+ UInt64(k * 11))
    }
    let dish = ellipsePoints(cx: cx, cy: cy, rx: r * 0.66, ry: r * 0.24, steps: 40)
    penStroke(p, dish + [dish[0]], weight: 2.2, colour: gold.al(0.85),
              wobble: 0.4, taper: false, seed: seed &+ 13)
    let well = ellipsePoints(cx: cx, cy: cy + r * 0.03, rx: r * 0.44, ry: r * 0.15, steps: 32)
    penStroke(p, well + [well[0]], weight: 1.3, colour: gold.al(0.60),
              wobble: 0.4, taper: false, seed: seed &+ 17)
    // rays behind it
    for k in 0..<24 {
        let a = Double(k) / 24.0 * 6.283185
        penStroke(p, [CGPoint(x: cx + cos(a) * r * 1.24, y: cy + sin(a) * r * 1.22),
                      CGPoint(x: cx + cos(a) * r * (k % 2 == 0 ? 1.44 : 1.34),
                              y: cy + sin(a) * r * (k % 2 == 0 ? 1.42 : 1.32))],
                  weight: k % 2 == 0 ? 1.6 : 0.9, colour: gold.al(0.50),
                  wobble: 0.3, taper: true, seed: seed &+ UInt64(k))
    }
    return p
}
