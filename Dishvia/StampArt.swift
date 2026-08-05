import SwiftUI

// A passport stamp, struck rather than drawn: the rubber never inks evenly, the
// rings break, the clerk never lands it square. Everything here is deterministic
// from the stamp's own seed, so an impression never changes once it is made.

struct StampDesign {
    var country: String
    var adjective: String
    var shape: String
    var motif: String
    var ink: Color
    var dateText: String
    var seed: UInt64

    init(cuisine: Cuisine, day: Int, seed: UInt64) {
        country = cuisine.country.uppercased()
        adjective = cuisine.adjective.uppercased()
        shape = cuisine.stampShape
        motif = cuisine.stampMotif
        ink = Book.stampInk(cuisine.stampInk)
        dateText = DayNumber.stampText(day)
        self.seed = seed
    }

    /// A preview impression, for the press screen before the stamp is committed.
    init(cuisine: Cuisine, previewDay: Int) {
        self.init(cuisine: cuisine, day: previewDay,
                  seed: seedValue(cuisine.id + "-preview-\(previewDay)"))
    }

    var isWide: Bool { shape == "banner" }
}

// MARK: - Outlines

enum StampOutline {

    static func path(_ shape: String, in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = rect.midX, cy = rect.midY

        switch shape {
        case "oval":
            p.addEllipse(in: CGRect(x: cx - w * 0.5, y: cy - h * 0.38, width: w, height: h * 0.76))

        case "rounded":
            p.addRoundedRect(in: CGRect(x: cx - w * 0.47, y: cy - h * 0.40,
                                        width: w * 0.94, height: h * 0.80),
                             cornerSize: CGSize(width: w * 0.10, height: w * 0.10))

        case "arch":
            let r = CGRect(x: cx - w * 0.42, y: cy - h * 0.44, width: w * 0.84, height: h * 0.88)
            p.move(to: CGPoint(x: r.minX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.36))
            p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.36),
                           control: CGPoint(x: cx, y: r.minY - r.height * 0.14))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.closeSubpath()

        case "shield":
            let r = CGRect(x: cx - w * 0.40, y: cy - h * 0.42, width: w * 0.80, height: h * 0.84)
            p.move(to: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.56))
            p.addQuadCurve(to: CGPoint(x: cx, y: r.maxY),
                           control: CGPoint(x: r.maxX, y: r.maxY - r.height * 0.06))
            p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.56),
                           control: CGPoint(x: r.minX, y: r.maxY - r.height * 0.06))
            p.closeSubpath()

        case "hex":
            let rx = w * 0.46, ry = h * 0.42
            for i in 0..<6 {
                let a = Double(i) / 6.0 * 2 * .pi - .pi / 2
                let pt = CGPoint(x: cx + CGFloat(cos(a)) * rx, y: cy + CGFloat(sin(a)) * ry)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()

        case "scallop":
            let r = min(w, h) * 0.44
            let lobes = 16
            for i in 0...(lobes * 4) {
                let t = Double(i) / Double(lobes * 4)
                let a = t * 2 * .pi - .pi / 2
                let wobble = 1.0 + 0.055 * cos(Double(lobes) * a)
                let pt = CGPoint(x: cx + CGFloat(cos(a) * Double(r) * wobble),
                                 y: cy + CGFloat(sin(a) * Double(r) * wobble))
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()

        case "banner":
            let r = CGRect(x: cx - w * 0.48, y: cy - h * 0.30, width: w * 0.96, height: h * 0.60)
            let notch = r.height * 0.32
            p.move(to: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX - notch, y: r.midY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX + notch, y: r.midY))
            p.closeSubpath()

        default: // circle
            let r = min(w, h) * 0.44
            p.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        }
        return p
    }

    /// The same outline pulled in, for the second ring.
    static func inset(_ shape: String, in rect: CGRect, by factor: CGFloat) -> Path {
        let inner = CGRect(x: rect.midX - rect.width * factor / 2,
                           y: rect.midY - rect.height * factor / 2,
                           width: rect.width * factor, height: rect.height * factor)
        return path(shape, in: inner)
    }
}

// MARK: - Emblems

enum StampEmblem {

    /// Every emblem is drawn inside a unit box centred on `c` with radius `r`.
    static func path(_ motif: String, centre c: CGPoint, radius r: CGFloat) -> Path {
        var p = Path()
        func pt(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: c.x + CGFloat(x) * r, y: c.y + CGFloat(y) * r)
        }

        switch motif {
        case "sun":
            p.addEllipse(in: CGRect(x: c.x - r * 0.42, y: c.y - r * 0.42,
                                    width: r * 0.84, height: r * 0.84))
            for i in 0..<12 {
                let a = Double(i) / 12.0 * 2 * .pi
                p.move(to: pt(cos(a) * 0.60, sin(a) * 0.60))
                p.addLine(to: pt(cos(a) * (i % 2 == 0 ? 1.0 : 0.82),
                                 sin(a) * (i % 2 == 0 ? 1.0 : 0.82)))
            }

        case "star":
            for i in 0..<10 {
                let a = Double(i) / 10.0 * 2 * .pi - .pi / 2
                let rr = i % 2 == 0 ? 1.0 : 0.44
                let q = pt(cos(a) * rr, sin(a) * rr)
                if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
            }
            p.closeSubpath()

        case "wave":
            for lane in 0..<3 {
                let y = -0.45 + Double(lane) * 0.45
                p.move(to: pt(-1.0, y))
                for k in 1...24 {
                    let t = Double(k) / 24.0
                    p.addLine(to: pt(-1.0 + t * 2.0, y + sin(t * 6.283 * 1.6 + Double(lane)) * 0.16))
                }
            }

        case "leaf":
            p.move(to: pt(0, -1.0))
            p.addQuadCurve(to: pt(0, 1.0), control: pt(0.86, -0.10))
            p.addQuadCurve(to: pt(0, -1.0), control: pt(-0.86, -0.10))
            p.move(to: pt(0, -0.86))
            p.addLine(to: pt(0, 0.92))
            for k in 0..<5 {
                let t = -0.6 + Double(k) * 0.30
                p.move(to: pt(0, t))
                p.addLine(to: pt(0.42, t + 0.26))
                p.move(to: pt(0, t))
                p.addLine(to: pt(-0.42, t + 0.26))
            }

        case "grain":
            p.move(to: pt(0, 1.0))
            p.addLine(to: pt(0, -0.55))
            for k in 0..<5 {
                let y = -0.5 + Double(k) * 0.30
                p.move(to: pt(0, y))
                p.addQuadCurve(to: pt(0.46, y - 0.34), control: pt(0.40, y - 0.02))
                p.move(to: pt(0, y))
                p.addQuadCurve(to: pt(-0.46, y - 0.34), control: pt(-0.40, y - 0.02))
            }

        case "mountain":
            p.move(to: pt(-1.0, 0.66))
            p.addLine(to: pt(-0.30, -0.60))
            p.addLine(to: pt(0.05, -0.05))
            p.addLine(to: pt(0.38, -0.80))
            p.addLine(to: pt(1.0, 0.66))
            p.closeSubpath()
            p.move(to: pt(-0.52, 0.02))
            p.addLine(to: pt(-0.08, 0.02))

        case "fish":
            p.move(to: pt(-0.95, 0))
            p.addQuadCurve(to: pt(0.55, 0), control: pt(-0.20, -0.72))
            p.addQuadCurve(to: pt(-0.95, 0), control: pt(-0.20, 0.72))
            p.move(to: pt(0.55, 0))
            p.addLine(to: pt(1.0, -0.42))
            p.addLine(to: pt(0.88, 0))
            p.addLine(to: pt(1.0, 0.42))
            p.closeSubpath()
            p.addEllipse(in: CGRect(x: c.x - r * 0.62, y: c.y - r * 0.20,
                                    width: r * 0.20, height: r * 0.20))

        case "pot":
            p.move(to: pt(-0.72, -0.30))
            p.addLine(to: pt(0.72, -0.30))
            p.addQuadCurve(to: pt(0, 0.82), control: pt(0.62, 0.72))
            p.addQuadCurve(to: pt(-0.72, -0.30), control: pt(-0.62, 0.72))
            p.move(to: pt(-0.92, -0.30))
            p.addLine(to: pt(0.92, -0.30))
            p.move(to: pt(-0.30, -0.60))
            p.addQuadCurve(to: pt(-0.10, -0.95), control: pt(-0.46, -0.86))
            p.move(to: pt(0.24, -0.60))
            p.addQuadCurve(to: pt(0.44, -0.95), control: pt(0.08, -0.86))

        case "flame":
            p.move(to: pt(0, 1.0))
            p.addQuadCurve(to: pt(0, -1.0), control: pt(0.92, 0.10))
            p.addQuadCurve(to: pt(0, 1.0), control: pt(-0.92, 0.10))
            p.move(to: pt(0, 0.86))
            p.addQuadCurve(to: pt(0.06, -0.30), control: pt(0.46, 0.28))
            p.addQuadCurve(to: pt(0, 0.86), control: pt(-0.34, 0.30))

        case "arch":
            p.move(to: pt(-0.72, 1.0))
            p.addLine(to: pt(-0.72, -0.16))
            p.addQuadCurve(to: pt(0.72, -0.16), control: pt(0, -1.14))
            p.addLine(to: pt(0.72, 1.0))
            p.move(to: pt(-0.98, 1.0))
            p.addLine(to: pt(0.98, 1.0))
            p.move(to: pt(-0.40, 1.0))
            p.addLine(to: pt(-0.40, 0.18))
            p.move(to: pt(0.40, 1.0))
            p.addLine(to: pt(0.40, 0.18))

        case "knot":
            for lane in 0..<2 {
                let s: Double = lane == 0 ? 1 : -1
                p.move(to: pt(-0.95 * s, 0))
                p.addCurve(to: pt(0.95 * s, 0), control1: pt(-0.30 * s, -1.05),
                           control2: pt(0.30 * s, 1.05))
            }
            p.addEllipse(in: CGRect(x: c.x - r * 0.16, y: c.y - r * 0.16,
                                    width: r * 0.32, height: r * 0.32))

        case "bird":
            p.move(to: pt(-1.0, 0.10))
            p.addQuadCurve(to: pt(-0.05, -0.36), control: pt(-0.52, -0.60))
            p.addQuadCurve(to: pt(0.98, 0.06), control: pt(0.48, -0.62))
            p.move(to: pt(-0.05, -0.36))
            p.addQuadCurve(to: pt(0.10, 0.62), control: pt(0.34, 0.16))

        case "cup":
            p.move(to: pt(-0.62, -0.42))
            p.addLine(to: pt(0.52, -0.42))
            p.addQuadCurve(to: pt(-0.05, 0.62), control: pt(0.46, 0.56))
            p.addQuadCurve(to: pt(-0.62, -0.42), control: pt(-0.56, 0.56))
            p.move(to: pt(0.52, -0.24))
            p.addQuadCurve(to: pt(0.52, 0.24), control: pt(1.02, 0))
            p.move(to: pt(-0.72, 0.86))
            p.addLine(to: pt(0.72, 0.86))
            p.move(to: pt(-0.24, -0.66))
            p.addQuadCurve(to: pt(-0.08, -0.98), control: pt(-0.40, -0.90))
            p.move(to: pt(0.16, -0.66))
            p.addQuadCurve(to: pt(0.32, -0.98), control: pt(0, -0.90))

        case "key":
            p.addEllipse(in: CGRect(x: c.x - r * 0.72, y: c.y - r * 0.40,
                                    width: r * 0.72, height: r * 0.72))
            p.move(to: pt(0, -0.04))
            p.addLine(to: pt(0.96, -0.04))
            p.move(to: pt(0.62, -0.04))
            p.addLine(to: pt(0.62, 0.42))
            p.move(to: pt(0.86, -0.04))
            p.addLine(to: pt(0.86, 0.34))

        case "wheel":
            p.addEllipse(in: CGRect(x: c.x - r * 0.92, y: c.y - r * 0.92,
                                    width: r * 1.84, height: r * 1.84))
            p.addEllipse(in: CGRect(x: c.x - r * 0.26, y: c.y - r * 0.26,
                                    width: r * 0.52, height: r * 0.52))
            for i in 0..<8 {
                let a = Double(i) / 8.0 * 2 * .pi
                p.move(to: pt(cos(a) * 0.26, sin(a) * 0.26))
                p.addLine(to: pt(cos(a) * 0.90, sin(a) * 0.90))
            }

        case "crescent":
            p.move(to: pt(0.28, -0.92))
            p.addCurve(to: pt(0.28, 0.92), control1: pt(-0.86, -0.62), control2: pt(-0.86, 0.62))
            p.addCurve(to: pt(0.28, -0.92), control1: pt(-0.34, 0.52), control2: pt(-0.34, -0.52))
            p.closeSubpath()

        default:
            p.addEllipse(in: CGRect(x: c.x - r * 0.7, y: c.y - r * 0.7,
                                    width: r * 1.4, height: r * 1.4))
        }
        return p
    }
}

// MARK: - The impression

struct StampMark: View {
    let design: StampDesign
    /// 0 = nothing on the paper, 1 = fully struck.
    var strength: Double = 1
    var showDate: Bool = true

    var body: some View {
        Canvas { context, size in
            guard strength > 0.001 else { return }
            var roll = Roll(design.seed)
            let rect = CGRect(origin: .zero, size: size)
            let unit = min(size.width, size.height)
            let ink = design.ink
            let alpha = 0.52 + 0.40 * strength

            // The clerk's wrist: a couple of degrees off square, always.
            let tilt = roll.between(-7.5, 7.5)
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.rotate(by: .degrees(tilt))
            context.translateBy(x: -size.width / 2, y: -size.height / 2)

            let outer = StampOutline.path(design.shape, in: rect)
            let inner = StampOutline.inset(design.shape, in: rect, by: 0.84)

            // Rings, struck as broken arcs so no line is unbroken rubber.
            drawBroken(context, outer, width: unit * 0.030, ink: ink, alpha: alpha,
                       roll: &roll, gaps: 5)
            drawBroken(context, inner, width: unit * 0.013, ink: ink, alpha: alpha * 0.88,
                       roll: &roll, gaps: 4)

            if design.isWide {
                drawWide(context, size: size, unit: unit, ink: ink, alpha: alpha, roll: &roll)
            } else {
                drawStandard(context, size: size, unit: unit, ink: ink, alpha: alpha, roll: &roll)
            }

            // Where the pad was overloaded, and where it was dry.
            for _ in 0..<26 {
                let a = roll.between(0, 6.283)
                let rr = roll.between(0.05, 0.52)
                let x = size.width * (0.5 + cos(a) * rr)
                let y = size.height * (0.5 + sin(a) * rr)
                let s = unit * roll.between(0.004, 0.016)
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: s, height: s)),
                             with: .color(ink.opacity(alpha * roll.between(0.15, 0.55))))
            }
        }
        .opacity(0.90)
        .drawingGroup()
    }

    // MARK: pieces

    private func drawBroken(_ context: GraphicsContext, _ path: Path, width: CGFloat,
                            ink: Color, alpha: Double, roll: inout Roll, gaps: Int) {
        let dashUnit = max(6.0, Double(path.boundingRect.width) * 0.9)
        var pattern: [CGFloat] = []
        for _ in 0..<gaps {
            pattern.append(CGFloat(roll.between(dashUnit * 0.20, dashUnit * 0.55)))
            pattern.append(CGFloat(roll.between(dashUnit * 0.006, dashUnit * 0.022)))
        }
        context.stroke(path, with: .color(ink.opacity(alpha)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round,
                                          lineJoin: .round, dash: pattern,
                                          dashPhase: CGFloat(roll.between(0, 40))))
    }

    /// Long country names have to shrink hard: the narrow shapes (oval, scallop,
    /// shield) give a lot less width than a plain circle does.
    private func fitted(_ text: String, base: CGFloat) -> CGFloat {
        let n = max(3, text.count)
        if n <= 6 { return base }
        return base * CGFloat(6.0 / Double(n)) * 1.04
    }

    private func drawStandard(_ context: GraphicsContext, size: CGSize, unit: CGFloat,
                              ink: Color, alpha: Double, roll: inout Roll) {
        let cx = size.width / 2

        var country = context.resolve(
            Text(design.country)
                .font(.system(size: fitted(design.country, base: unit * 0.135),
                              weight: .heavy, design: .serif))
                .tracking(unit * 0.012))
        country.shading = .color(ink.opacity(alpha))
        context.draw(country, at: CGPoint(x: cx, y: size.height * 0.265), anchor: .center)

        // rules above and below the emblem
        for y in [0.365, 0.705] as [Double] {
            var rule = Path()
            rule.move(to: CGPoint(x: size.width * 0.28, y: size.height * y))
            rule.addLine(to: CGPoint(x: size.width * 0.72, y: size.height * y))
            context.stroke(rule, with: .color(ink.opacity(alpha * 0.7)),
                           style: StrokeStyle(lineWidth: unit * 0.009, lineCap: .round))
        }

        let emblem = StampEmblem.path(design.motif,
                                      centre: CGPoint(x: cx, y: size.height * 0.525),
                                      radius: unit * 0.115)
        context.stroke(emblem, with: .color(ink.opacity(alpha * 0.92)),
                       style: StrokeStyle(lineWidth: unit * 0.017, lineCap: .round,
                                          lineJoin: .round))

        if showDate {
            var date = context.resolve(
                Text(design.dateText)
                    .font(.system(size: unit * 0.072, weight: .bold, design: .monospaced)))
            date.shading = .color(ink.opacity(alpha * 0.95))
            context.draw(date, at: CGPoint(x: cx, y: size.height * 0.775), anchor: .center)
        }
        _ = roll.unit()
    }

    private func drawWide(_ context: GraphicsContext, size: CGSize, unit: CGFloat,
                          ink: Color, alpha: Double, roll: inout Roll) {
        let emblem = StampEmblem.path(design.motif,
                                      centre: CGPoint(x: size.width * 0.27, y: size.height * 0.5),
                                      radius: unit * 0.105)
        context.stroke(emblem, with: .color(ink.opacity(alpha * 0.92)),
                       style: StrokeStyle(lineWidth: unit * 0.016, lineCap: .round,
                                          lineJoin: .round))

        var country = context.resolve(
            Text(design.country)
                .font(.system(size: fitted(design.country, base: unit * 0.118),
                              weight: .heavy, design: .serif))
                .tracking(unit * 0.010))
        country.shading = .color(ink.opacity(alpha))
        context.draw(country, at: CGPoint(x: size.width * 0.62, y: size.height * 0.425),
                     anchor: .center)

        if showDate {
            var date = context.resolve(
                Text(design.dateText)
                    .font(.system(size: unit * 0.066, weight: .bold, design: .monospaced)))
            date.shading = .color(ink.opacity(alpha * 0.95))
            context.draw(date, at: CGPoint(x: size.width * 0.62, y: size.height * 0.605),
                         anchor: .center)
        }
        _ = roll.unit()
    }
}

/// The dotted footprint a stamp will one day occupy.
struct StampSlot: View {
    let shape: String

    var body: some View {
        Canvas { context, size in
            let path = StampOutline.path(shape, in: CGRect(origin: .zero, size: size))
            context.stroke(path, with: .color(Book.inkFaint.opacity(0.34)),
                           style: StrokeStyle(lineWidth: 1.2, lineCap: .round,
                                              dash: [4, 5]))
        }
    }
}
