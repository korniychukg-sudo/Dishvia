import SwiftUI

// Every glyph in the app is drawn here. Nothing comes from the system set.

struct BookIcon: View {
    var size: CGFloat = 24
    var colour: Color = Book.ink

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var p = Path()
            p.move(to: CGPoint(x: w * 0.16, y: h * 0.20))
            p.addLine(to: CGPoint(x: w * 0.16, y: h * 0.84))
            p.addLine(to: CGPoint(x: w * 0.84, y: h * 0.84))
            p.addLine(to: CGPoint(x: w * 0.84, y: h * 0.20))
            p.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.28),
                           control: CGPoint(x: w * 0.67, y: h * 0.16))
            p.addQuadCurve(to: CGPoint(x: w * 0.16, y: h * 0.20),
                           control: CGPoint(x: w * 0.33, y: h * 0.16))
            ctx.stroke(p, with: .color(colour), style: StrokeStyle(lineWidth: max(1.3, w * 0.075),
                                                                   lineJoin: .round))
            var spine = Path()
            spine.move(to: CGPoint(x: w * 0.50, y: h * 0.28))
            spine.addLine(to: CGPoint(x: w * 0.50, y: h * 0.84))
            ctx.stroke(spine, with: .color(colour), style: StrokeStyle(lineWidth: max(1.0, w * 0.055)))
            var seal = Path()
            seal.addEllipse(in: CGRect(x: w * 0.60, y: h * 0.46, width: w * 0.18, height: w * 0.18))
            ctx.stroke(seal, with: .color(colour), style: StrokeStyle(lineWidth: max(1.0, w * 0.050)))
        }
        .frame(width: size, height: size)
    }
}

struct GlobeIcon: View {
    var size: CGFloat = 24
    var colour: Color = Book.ink

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let line = StrokeStyle(lineWidth: max(1.2, w * 0.070))
            var ring = Path()
            ring.addEllipse(in: CGRect(x: w * 0.14, y: h * 0.14, width: w * 0.72, height: h * 0.72))
            ctx.stroke(ring, with: .color(colour), style: line)
            var meridian = Path()
            meridian.addEllipse(in: CGRect(x: w * 0.36, y: h * 0.14, width: w * 0.28, height: h * 0.72))
            ctx.stroke(meridian, with: .color(colour), style: StrokeStyle(lineWidth: max(1.0, w * 0.052)))
            for y in [0.36, 0.50, 0.64] as [Double] {
                var lat = Path()
                let inset = y == 0.50 ? 0.14 : 0.22
                lat.move(to: CGPoint(x: w * inset, y: h * y))
                lat.addLine(to: CGPoint(x: w * (1 - inset), y: h * y))
                ctx.stroke(lat, with: .color(colour), style: StrokeStyle(lineWidth: max(1.0, w * 0.052)))
            }
        }
        .frame(width: size, height: size)
    }
}

struct VisaIcon: View {
    var size: CGFloat = 24
    var colour: Color = Book.ink

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var sheet = Path()
            sheet.addRoundedRect(in: CGRect(x: w * 0.18, y: h * 0.13, width: w * 0.58, height: h * 0.74),
                                 cornerSize: CGSize(width: w * 0.06, height: w * 0.06))
            ctx.stroke(sheet, with: .color(colour), style: StrokeStyle(lineWidth: max(1.2, w * 0.068)))
            for y in [0.30, 0.42, 0.54] as [Double] {
                var rule = Path()
                rule.move(to: CGPoint(x: w * 0.28, y: h * y))
                rule.addLine(to: CGPoint(x: w * 0.62, y: h * y))
                ctx.stroke(rule, with: .color(colour.opacity(0.75)),
                           style: StrokeStyle(lineWidth: max(0.9, w * 0.046)))
            }
            var seal = Path()
            seal.addEllipse(in: CGRect(x: w * 0.50, y: h * 0.54, width: w * 0.38, height: w * 0.38))
            ctx.stroke(seal, with: .color(colour), style: StrokeStyle(lineWidth: max(1.1, w * 0.058)))
            var star = Path()
            let c = CGPoint(x: w * 0.69, y: h * 0.54 + w * 0.19)
            for i in 0..<8 {
                let a = Double(i) / 8.0 * 2 * .pi
                star.move(to: c)
                star.addLine(to: CGPoint(x: c.x + CGFloat(cos(a)) * w * 0.11,
                                         y: c.y + CGFloat(sin(a)) * w * 0.11))
            }
            ctx.stroke(star, with: .color(colour.opacity(0.8)),
                       style: StrokeStyle(lineWidth: max(0.8, w * 0.038)))
        }
        .frame(width: size, height: size)
    }
}

struct JournalIcon: View {
    var size: CGFloat = 24
    var colour: Color = Book.ink

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var sheet = Path()
            sheet.addRoundedRect(in: CGRect(x: w * 0.16, y: h * 0.16, width: w * 0.56, height: h * 0.68),
                                 cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.stroke(sheet, with: .color(colour), style: StrokeStyle(lineWidth: max(1.2, w * 0.068)))
            for y in [0.34, 0.48, 0.62] as [Double] {
                var rule = Path()
                rule.move(to: CGPoint(x: w * 0.26, y: h * y))
                rule.addLine(to: CGPoint(x: w * 0.56, y: h * y))
                ctx.stroke(rule, with: .color(colour.opacity(0.7)),
                           style: StrokeStyle(lineWidth: max(0.9, w * 0.044)))
            }
            var pen = Path()
            pen.move(to: CGPoint(x: w * 0.60, y: h * 0.80))
            pen.addLine(to: CGPoint(x: w * 0.88, y: h * 0.34))
            pen.addLine(to: CGPoint(x: w * 0.80, y: h * 0.28))
            pen.addLine(to: CGPoint(x: w * 0.52, y: h * 0.74))
            pen.closeSubpath()
            ctx.stroke(pen, with: .color(colour), style: StrokeStyle(lineWidth: max(1.1, w * 0.056),
                                                                     lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct HandbookIcon: View {
    var size: CGFloat = 24
    var colour: Color = Book.ink

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var left = Path()
            left.move(to: CGPoint(x: w * 0.50, y: h * 0.28))
            left.addQuadCurve(to: CGPoint(x: w * 0.12, y: h * 0.24),
                              control: CGPoint(x: w * 0.30, y: h * 0.18))
            left.addLine(to: CGPoint(x: w * 0.12, y: h * 0.78))
            left.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.82),
                              control: CGPoint(x: w * 0.30, y: h * 0.74))
            var right = Path()
            right.move(to: CGPoint(x: w * 0.50, y: h * 0.28))
            right.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.24),
                               control: CGPoint(x: w * 0.70, y: h * 0.18))
            right.addLine(to: CGPoint(x: w * 0.88, y: h * 0.78))
            right.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.82),
                               control: CGPoint(x: w * 0.70, y: h * 0.74))
            let line = StrokeStyle(lineWidth: max(1.2, w * 0.066), lineJoin: .round)
            ctx.stroke(left, with: .color(colour), style: line)
            ctx.stroke(right, with: .color(colour), style: line)
            var spine = Path()
            spine.move(to: CGPoint(x: w * 0.50, y: h * 0.28))
            spine.addLine(to: CGPoint(x: w * 0.50, y: h * 0.82))
            ctx.stroke(spine, with: .color(colour.opacity(0.7)),
                       style: StrokeStyle(lineWidth: max(0.9, w * 0.046)))
        }
        .frame(width: size, height: size)
    }
}

/// The fork used as a rating mark.
struct ForkMark: View {
    var size: CGFloat = 16
    var filled: Bool = true
    var colour: Color = Book.ink

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var p = Path()
            for i in 0..<3 {
                let x = w * (0.32 + Double(i) * 0.18)
                p.move(to: CGPoint(x: x, y: h * 0.14))
                p.addLine(to: CGPoint(x: x, y: h * 0.40))
            }
            p.move(to: CGPoint(x: w * 0.32, y: h * 0.40))
            p.addQuadCurve(to: CGPoint(x: w * 0.68, y: h * 0.40),
                           control: CGPoint(x: w * 0.50, y: h * 0.56))
            p.move(to: CGPoint(x: w * 0.50, y: h * 0.50))
            p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.88))
            ctx.stroke(p, with: .color(colour.opacity(filled ? 1 : 0.26)),
                       style: StrokeStyle(lineWidth: max(1.1, w * 0.085),
                                          lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

/// A small chevron for rows that push a detail screen.
struct ChevronMark: View {
    var size: CGFloat = 12
    var colour: Color = Book.inkFaint

    var body: some View {
        Canvas { ctx, s in
            var p = Path()
            p.move(to: CGPoint(x: s.width * 0.34, y: s.height * 0.18))
            p.addLine(to: CGPoint(x: s.width * 0.70, y: s.height * 0.50))
            p.addLine(to: CGPoint(x: s.width * 0.34, y: s.height * 0.82))
            ctx.stroke(p, with: .color(colour),
                       style: StrokeStyle(lineWidth: max(1.2, s.width * 0.14),
                                          lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct CloseMark: View {
    var size: CGFloat = 16
    var colour: Color = Book.ink

    var body: some View {
        Canvas { ctx, s in
            var p = Path()
            p.move(to: CGPoint(x: s.width * 0.24, y: s.height * 0.24))
            p.addLine(to: CGPoint(x: s.width * 0.76, y: s.height * 0.76))
            p.move(to: CGPoint(x: s.width * 0.76, y: s.height * 0.24))
            p.addLine(to: CGPoint(x: s.width * 0.24, y: s.height * 0.76))
            ctx.stroke(p, with: .color(colour),
                       style: StrokeStyle(lineWidth: max(1.4, s.width * 0.11), lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

struct BackMark: View {
    var size: CGFloat = 18
    var colour: Color = Book.ink

    var body: some View {
        Canvas { ctx, s in
            var p = Path()
            p.move(to: CGPoint(x: s.width * 0.62, y: s.height * 0.18))
            p.addLine(to: CGPoint(x: s.width * 0.28, y: s.height * 0.50))
            p.addLine(to: CGPoint(x: s.width * 0.62, y: s.height * 0.82))
            p.move(to: CGPoint(x: s.width * 0.30, y: s.height * 0.50))
            p.addLine(to: CGPoint(x: s.width * 0.82, y: s.height * 0.50))
            ctx.stroke(p, with: .color(colour),
                       style: StrokeStyle(lineWidth: max(1.4, s.width * 0.095),
                                          lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct TickMark: View {
    var size: CGFloat = 14
    var colour: Color = Book.ink

    var body: some View {
        Canvas { ctx, s in
            var p = Path()
            p.move(to: CGPoint(x: s.width * 0.20, y: s.height * 0.54))
            p.addLine(to: CGPoint(x: s.width * 0.42, y: s.height * 0.76))
            p.addLine(to: CGPoint(x: s.width * 0.80, y: s.height * 0.26))
            ctx.stroke(p, with: .color(colour),
                       style: StrokeStyle(lineWidth: max(1.5, s.width * 0.13),
                                          lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

/// The luggage-tag mark used for the want-to-try list.
struct TagMark: View {
    var size: CGFloat = 16
    var filled: Bool = false
    var colour: Color = Book.ink

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var p = Path()
            p.move(to: CGPoint(x: w * 0.22, y: h * 0.62))
            p.addLine(to: CGPoint(x: w * 0.46, y: h * 0.86))
            p.addLine(to: CGPoint(x: w * 0.84, y: h * 0.48))
            p.addLine(to: CGPoint(x: w * 0.80, y: h * 0.16))
            p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.14))
            p.closeSubpath()
            if filled {
                ctx.fill(p, with: .color(colour))
            }
            ctx.stroke(p, with: .color(colour),
                       style: StrokeStyle(lineWidth: max(1.2, w * 0.075), lineJoin: .round))
            let hole = CGRect(x: w * 0.62, y: h * 0.30, width: w * 0.13, height: w * 0.13)
            ctx.stroke(Path(ellipseIn: hole),
                       with: .color(filled ? Book.paper : colour),
                       style: StrokeStyle(lineWidth: max(1.0, w * 0.055)))
            var string = Path()
            string.move(to: CGPoint(x: w * 0.68, y: h * 0.34))
            string.addQuadCurve(to: CGPoint(x: w * 0.30, y: h * 0.20),
                                control: CGPoint(x: w * 0.42, y: h * 0.42))
            ctx.stroke(string, with: .color(colour.opacity(0.8)),
                       style: StrokeStyle(lineWidth: max(0.9, w * 0.045)))
        }
        .frame(width: size, height: size)
    }
}

/// A short row of leader dots, used to separate a label from its value.
struct LeaderRule: View {
    var colour: Color = Book.inkFaint

    var body: some View {
        Canvas { ctx, s in
            var p = Path()
            p.move(to: CGPoint(x: 0, y: s.height / 2))
            p.addLine(to: CGPoint(x: s.width, y: s.height / 2))
            ctx.stroke(p, with: .color(colour.opacity(0.5)),
                       style: StrokeStyle(lineWidth: 1, dash: [1.5, 3]))
        }
        .frame(height: 6)
    }
}
