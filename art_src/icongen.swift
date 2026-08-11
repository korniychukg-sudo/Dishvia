import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func writePNG(_ p: Plate, _ path: String) {
    guard let img = p.ctx.makeImage(),
          let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL,
                                                     UTType.png.identifier as CFString, 1, nil)
    else { exit(1) }
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}

func warmBloom(_ p: Plate, cx: Double, cy: Double, radius: Double, tone: Col, strength: Double) {
    guard let g = CGGradient(colorsSpace: inkSpace,
                             colors: [cgc(tone.al(strength)), cgc(tone.al(0))] as CFArray,
                             locations: [0, 1]) else { return }
    p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
                             endCenter: CGPoint(x: cx, y: cy), endRadius: CGFloat(radius),
                             options: [])
}

func cornerVignette(_ p: Plate, strength: Double) {
    guard let g = CGGradient(colorsSpace: inkSpace,
                             colors: [cgc(Col(r: 0.30, g: 0.19, b: 0.11, a: 0)),
                                      cgc(Col(r: 0.30, g: 0.19, b: 0.11, a: strength))] as CFArray,
                             locations: [0.42, 1]) else { return }
    p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: p.w / 2, y: p.h / 2), startRadius: 0,
                             endCenter: CGPoint(x: p.w / 2, y: p.h / 2),
                             endRadius: CGFloat(p.w * 0.76), options: [.drawsAfterEndLocation])
}

func steamCurl(_ p: Plate, x: Double, y: Double, height: Double, sway: Double,
               colour: Col, weight: Double, seed: UInt64) {
    var pts: [CGPoint] = []
    let steps = 34
    for i in 0...steps {
        let t = Double(i) / Double(steps)
        let yy = y + height * t
        let xx = x + sin(t * 4.2 + sway) * height * 0.16 * (0.25 + t)
        pts.append(pnt(xx, yy))
    }
    penStroke(p, pts, weight: weight, colour: colour, wobble: 0.9, taper: true, seed: seed)
}

func struckStamp(_ p: Plate, cx: Double, cy: Double, radius: Double, tilt: Double,
                 colour: Col, seed: UInt64) {
    var rng = RNG(seed)
    var gap = 0.0
    while gap < 6.283185 {
        let span = rng.r(0.34, 0.80)
        var arc: [CGPoint] = []
        var a = gap
        while a < min(gap + span, 6.283185) {
            arc.append(pnt(cx + cos(a + tilt) * radius, cy + sin(a + tilt) * radius * 0.985))
            a += 0.035
        }
        if arc.count > 2 {
            penStroke(p, arc, weight: radius * 0.085, colour: colour.al(rng.r(0.55, 0.88)),
                      wobble: 1.5, taper: false, seed: seed &+ u64(Int(gap * 100)))
        }
        gap += span + rng.r(0.06, 0.20)
    }
    var inner: [CGPoint] = []
    var b = 0.0
    while b < 6.30 {
        inner.append(pnt(cx + cos(b + tilt) * radius * 0.74, cy + sin(b + tilt) * radius * 0.73))
        b += 0.05
    }
    penStroke(p, inner, weight: radius * 0.045, colour: colour.al(0.62),
              wobble: 1.3, taper: false, seed: seed &+ 17)
    for k in 0..<5 {
        let a = Double(k) / 5.0 * 6.283185 + tilt + 0.30
        penStroke(p, [pnt(cx + cos(a) * radius * 0.78, cy + sin(a) * radius * 0.77),
                      pnt(cx + cos(a) * radius * 0.94, cy + sin(a) * radius * 0.93)],
                  weight: radius * 0.055, colour: colour.al(rng.r(0.45, 0.75)),
                  wobble: 0.9, taper: false, seed: seed &+ UInt64(k * 5))
    }
    for k in 0..<8 {
        let a = Double(k) / 8.0 * 6.283185 + tilt
        let outer = radius * 0.40
        penStroke(p, [pnt(cx + cos(a) * radius * 0.10, cy + sin(a) * radius * 0.10),
                      pnt(cx + cos(a) * outer, cy + sin(a) * outer)],
                  weight: radius * 0.055, colour: colour.al(rng.r(0.50, 0.80)),
                  wobble: 0.8, taper: true, seed: seed &+ UInt64(90 + k))
    }
    for k in 0..<2 {
        let y = cy + (k == 0 ? -1.0 : 1.0) * radius * 0.545
        let half = radius * (k == 0 ? 0.44 : 0.38)
        var seg = -half
        while seg < half {
            let run = min(radius * rng.r(0.10, 0.20), half - seg)
            penStroke(p, [pnt(cx + seg * cos(tilt) - 0 * sin(tilt),
                              y + seg * sin(tilt)),
                          pnt(cx + (seg + run) * cos(tilt), y + (seg + run) * sin(tilt))],
                      weight: radius * 0.055, colour: colour.al(rng.r(0.40, 0.70)),
                      wobble: 0.7, taper: false, seed: seed &+ u64(Int(seg * 10) + k * 3))
            seg += run + radius * rng.r(0.04, 0.09)
        }
    }
    for _ in 0..<48 {
        let a = rng.d() * 6.283185
        let rr = radius * rng.r(0.55, 1.08)
        p.disc(cx + cos(a) * rr, cy + sin(a) * rr, radius * rng.r(0.008, 0.024),
               colour.al(rng.r(0.12, 0.34)))
    }
}

func softShadow(_ p: Plate, cx: Double, cy: Double, rx: Double, ry: Double, tone: Col) {
    let rings = 22
    for i in stride(from: rings, through: 1, by: -1) {
        let t = Double(i) / Double(rings)
        p.ellipse(cx, cy, rx * t, ry * t, tone.al(0.030 * (1.15 - t)))
    }
}

func iconBowl(_ p: Plate, cx: Double, cy: Double, rimRX: Double, rimRY: Double,
              wallH: Double, baseScale: Double, chord: Chord, unit: Double,
              motif: RimMotif?, motifColour: Col, seed: UInt64) -> Bed {
    softShadow(p, cx: cx + rimRX * 0.16, cy: cy - wallH - rimRY * 0.50,
               rx: rimRX * 1.10, ry: rimRY * 0.62,
               tone: Col(r: 0.45, g: 0.34, b: 0.24))

    var wall: [CGPoint] = []
    for i in 0...36 {
        let a = Double.pi + Double(i) / 36.0 * Double.pi
        wall.append(pnt(cx + cos(a) * rimRX, cy + sin(a) * rimRY))
    }
    for i in stride(from: 36, through: 0, by: -1) {
        let a = Double.pi + Double(i) / 36.0 * Double.pi
        wall.append(pnt(cx + cos(a) * rimRX * baseScale,
                        cy - wallH + sin(a) * rimRY * baseScale * 0.8))
    }
    gouacheForm(p, wall, chord, depth: 1.05, seed: seed &+ 3)
    inkOver(p, wall, weight: unit * 0.0060, hatchShadow: true, seed: seed &+ 5)

    let fr = rimRX * baseScale * 0.58
    let footRing = ringPoints(cx, cy - wallH - rimRY * 0.26, fr, fr * 0.22, steps: 30)
    gouache(p, footRing, chord.shadow, seed: seed &+ 7)
    penStroke(p, footRing + [footRing[0]], weight: unit * 0.0038,
              colour: Ink.sepia.al(0.8), wobble: 0.6, taper: false, seed: seed &+ 9)

    let rim = ringPoints(cx, cy, rimRX, rimRY)
    gouache(p, rim, chord.body, unevenness: 0.06, seed: seed &+ 11)
    let interior = ringPoints(cx, cy, rimRX * 0.85, rimRY * 0.80)
    gouache(p, interior, chord.shadow.dk(0.12), unevenness: 0.05, seed: seed &+ 13)
    penStroke(p, rim + [rim[0]], weight: unit * 0.0066, colour: Ink.sepia,
              wobble: 0.8, taper: false, seed: seed &+ 15)

    if let motif = motif {
        rimBand(p, cx: cx, cy: cy, rx: rimRX, ry: rimRY,
                motif: motif, colour: motifColour, unit: unit, seed: seed &+ 17)
    }

    let clip = CGMutablePath()
    clip.addPath(polyPath(ringPoints(cx, cy, rimRX * 0.90, rimRY * 0.86)))
    clip.addRect(CGRect(x: cx - rimRX * 0.92, y: cy, width: rimRX * 1.84, height: unit * 0.30))

    return Bed(cx: cx, cy: cy, rx: rimRX * 0.80, ry: rimRY * 0.76, clip: clip,
               overdraw: {
                   var near: [CGPoint] = []
                   for i in 0...36 {
                       let a = Double.pi + Double(i) / 36.0 * Double.pi
                       near.append(pnt(cx + cos(a) * rimRX, cy + sin(a) * rimRY))
                   }
                   penStroke(p, near, weight: unit * 0.0072, colour: Ink.sepia,
                             wobble: 0.8, taper: false, seed: seed &+ 19)
               })
}

func pageRule(_ p: Plate, inset: Double, seed: UInt64) {
    let m = inset
    penContour(p, [pnt(m, m), pnt(p.w - m, m), pnt(p.w - m, p.h - m), pnt(m, p.h - m)],
               weight: p.w * 0.0046, colour: Ink.sepia.al(0.46), seed: seed &+ 3)
    let m2 = m + p.w * 0.018
    penContour(p, [pnt(m2, m2), pnt(p.w - m2, m2), pnt(p.w - m2, p.h - m2), pnt(m2, p.h - m2)],
               weight: p.w * 0.0020, colour: Paint.chord("ochre").shadow.al(0.55), seed: seed &+ 5)
    let d = p.w * 0.015
    for (cx, cy) in [(m, m), (p.w - m, m), (p.w - m, p.h - m), (m, p.h - m)] {
        let diamond = [pnt(cx, cy + d), pnt(cx + d, cy), pnt(cx, cy - d), pnt(cx - d, cy)]
        p.poly(diamond, Paint.chord("ochre").body.al(0.90))
        penContour(p, diamond, weight: p.w * 0.0020, colour: Ink.sepia.al(0.65),
                   seed: seed &+ u64(Int(cx)))
    }
}

struct IconRecipe {
    var name: String
    var bowl: Chord
    var palette: String
    var motif: RimMotif?
    var motifTone: Col
    var stampTone: Col
    var ruled: Bool
    var bloom: Col
}

func renderIcon(_ side: Int, _ recipe: IconRecipe) -> Plate {
    let p = Plate(side, side)
    let seed = inkSeed("dishvia-icon-" + recipe.name)
    p.light = 2.34
    let W = p.w

    layPaper(p, seed: seed &+ 1, tone: Ink.paperWarm)
    warmBloom(p, cx: W * 0.50, cy: W * 0.50, radius: W * 0.58,
              tone: recipe.bloom, strength: 0.34)

    if recipe.ruled { pageRule(p, inset: W * 0.082, seed: seed &+ 71) }

    struckStamp(p, cx: W * 0.742, cy: W * 0.688, radius: W * 0.146, tilt: -0.35,
                colour: recipe.stampTone, seed: seed &+ 5)
    struckStamp(p, cx: W * 0.238, cy: W * 0.742, radius: W * 0.100, tilt: 0.62,
                colour: recipe.stampTone.mix(Col(r: 0.220, g: 0.318, b: 0.478), 0.85).al(0.55),
                seed: seed &+ 9)

    let unit = W
    let bed = iconBowl(p, cx: W * 0.500, cy: W * 0.462,
                       rimRX: W * 0.330, rimRY: W * 0.112,
                       wallH: W * 0.202, baseScale: 0.47,
                       chord: recipe.bowl, unit: unit,
                       motif: recipe.motif, motifColour: recipe.motifTone, seed: seed &+ 11)

    drawFood(p, "curryPool", bed: bed, paletteKey: recipe.palette, seed: seed &+ 19, layer: 0)
    drawFood(p, "stewChunks", bed: bed, paletteKey: recipe.palette, seed: seed &+ 23, layer: 0)
    drawGarnish(p, "herbSprigs", bed: bed, paletteKey: recipe.palette, seed: seed &+ 41, index: 0)
    drawGarnish(p, "chiliSlices", bed: bed, paletteKey: recipe.palette, seed: seed &+ 43, index: 1)
    bed.overdraw()

    for (i, dx) in [-0.120, -0.032, 0.048].enumerated() {
        steamCurl(p, x: bed.cx + W * dx, y: bed.cy + bed.ry * 0.9,
                  height: W * (0.135 + Double(i) * 0.026), sway: Double(i) * 2.1,
                  colour: Ink.sepiaSoft.al(0.11), weight: W * 0.0125,
                  seed: seed &+ UInt64(60 + i * 7))
    }

    cornerVignette(p, strength: 0.30)
    return p
}

let stampRed = Col(r: 0.639, g: 0.239, b: 0.212)
let stampBlue = Col(r: 0.220, g: 0.318, b: 0.478)

func iconRecipe(_ key: String) -> IconRecipe {
    let crimsonShadow: Col = Paint.chord("crimson").shadow
    let creamLight: Col = Paint.chord("cream").light
    let saffronLight: Col = Paint.chord("saffron").light
    let ochreLight: Col = Paint.chord("ochre").light

    switch key {
    case "clayruled":
        return IconRecipe(name: "clayruled", bowl: Paint.terracotta, palette: "crimson",
                          motif: RimMotif.doubleLine, motifTone: crimsonShadow,
                          stampTone: stampRed, ruled: true, bloom: saffronLight)
    case "jade":
        return IconRecipe(name: "jade", bowl: Chord(0.298, 0.478, 0.416), palette: "saffron",
                          motif: RimMotif.dashes, motifTone: creamLight,
                          stampTone: stampRed, ruled: true, bloom: ochreLight)
    case "indigo":
        return IconRecipe(name: "indigo", bowl: Chord(0.286, 0.353, 0.510), palette: "amber",
                          motif: RimMotif.doubleLine, motifTone: creamLight,
                          stampTone: stampRed, ruled: true, bloom: saffronLight)
    default:
        return IconRecipe(name: "clay", bowl: Paint.terracotta, palette: "crimson",
                          motif: RimMotif.doubleLine, motifTone: crimsonShadow,
                          stampTone: stampRed, ruled: false, bloom: saffronLight)
    }
}

@main
struct IconTool {
    static func main() {
        let argv = CommandLine.arguments
        let key = argv.count > 1 ? argv[1] : "clay"
        let outPath = argv.count > 2 ? argv[2] : "AppIcon-1024.png"
        writePNG(renderIcon(1024, iconRecipe(key)), outPath)
        print("wrote \(key) -> \(outPath)")
    }
}
