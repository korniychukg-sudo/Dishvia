import SwiftUI

// The furniture: cards cut from the same paper, ruled headings, a taste radar
// and the banner that tells you a visa has come through.

struct PaperCard<Content: View>: View {
    var tint: Color = Book.card
    var corner: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(tint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Book.ink.opacity(0.14), lineWidth: 1)
            )
    }
}

struct SectionHeading: View {
    let text: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(text.uppercased())
                .font(Type.label(11))
                .tracking(1.6)
                .foregroundColor(Book.inkSoft)
            LeaderRule()
            if let trailing = trailing {
                Text(trailing)
                    .font(Type.label(11))
                    .tracking(1.0)
                    .foregroundColor(Book.inkFaint)
            }
        }
    }
}

struct TagPill: View {
    let text: String
    var tint: Color = Book.inkSoft
    var strong: Bool = false

    var body: some View {
        Text(text)
            .font(Type.label(10))
            .tracking(0.8)
            .foregroundColor(strong ? Book.paper : tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(strong ? tint : tint.opacity(0.10))
            )
            .overlay(
                Capsule().stroke(tint.opacity(strong ? 0 : 0.35), lineWidth: 1)
            )
    }
}

/// A ruled bar. Reads as a form field being filled in rather than a loading bar.
struct RuledProgress: View {
    let value: Int
    let target: Int
    var tint: Color = Book.ink

    var body: some View {
        GeometryReader { geo in
            let fraction = target > 0 ? min(1.0, Double(value) / Double(target)) : 0
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Book.ink.opacity(0.08))
                Capsule()
                    .fill(tint.opacity(0.75))
                    .frame(width: max(fraction > 0 ? 6 : 0, geo.size.width * fraction))
            }
        }
        .frame(height: 7)
    }
}

struct RatingForks: View {
    let rating: Int
    var size: CGFloat = 15
    var colour: Color = Book.ink

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                ForkMark(size: size, filled: i < rating, colour: colour)
            }
        }
    }
}

/// Six axes, drawn as a plotted specimen chart rather than a filled blob.
struct TasteRadar: View {
    let values: [Double]        // 0...3 on each axis
    var compare: [Double]? = nil
    var tint: Color = Book.ink
    var showLabels: Bool = true

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2 + (showLabels ? 2 : 0)
            let r = min(size.width, size.height) / 2 - (showLabels ? 26 : 6)
            guard r > 8 else { return }

            func point(_ i: Int, _ v: Double) -> CGPoint {
                let a = Double(i) / 6.0 * 2 * .pi - .pi / 2
                let rr = r * CGFloat(max(0.04, min(1.0, v / 3.0)))
                return CGPoint(x: cx + CGFloat(cos(a)) * rr, y: cy + CGFloat(sin(a)) * rr)
            }

            // the graticule
            for step in 1...3 {
                var web = Path()
                for i in 0...6 {
                    let p = point(i % 6, Double(step))
                    if i == 0 { web.move(to: p) } else { web.addLine(to: p) }
                }
                ctx.stroke(web, with: .color(Book.inkFaint.opacity(step == 3 ? 0.45 : 0.20)),
                           style: StrokeStyle(lineWidth: step == 3 ? 1.1 : 0.8))
            }
            for i in 0..<6 {
                var spoke = Path()
                spoke.move(to: CGPoint(x: cx, y: cy))
                spoke.addLine(to: point(i, 3))
                ctx.stroke(spoke, with: .color(Book.inkFaint.opacity(0.22)),
                           style: StrokeStyle(lineWidth: 0.8))
            }

            if let compare = compare, compare.count == 6 {
                var other = Path()
                for i in 0...6 {
                    let p = point(i % 6, compare[i % 6])
                    if i == 0 { other.move(to: p) } else { other.addLine(to: p) }
                }
                ctx.stroke(other, with: .color(Book.inkFaint.opacity(0.75)),
                           style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
            }

            var shape = Path()
            for i in 0...6 {
                let p = point(i % 6, values.count == 6 ? values[i % 6] : 0)
                if i == 0 { shape.move(to: p) } else { shape.addLine(to: p) }
            }
            ctx.fill(shape, with: .color(tint.opacity(0.14)))
            ctx.stroke(shape, with: .color(tint.opacity(0.85)),
                       style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))

            for i in 0..<6 {
                let p = point(i, values.count == 6 ? values[i] : 0)
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 2.6, y: p.y - 2.6, width: 5.2, height: 5.2)),
                         with: .color(tint))
            }

            if showLabels {
                for i in 0..<6 {
                    let a = Double(i) / 6.0 * 2 * .pi - .pi / 2
                    let lp = CGPoint(x: cx + CGFloat(cos(a)) * (r + 16),
                                     y: cy + CGFloat(sin(a)) * (r + 14))
                    var label = ctx.resolve(
                        Text(Taste.axisNames[i].uppercased())
                            .font(.system(size: 9, weight: .semibold)))
                    label.shading = .color(Book.inkSoft)
                    ctx.draw(label, at: lp, anchor: .center)
                }
            }
        }
    }
}

/// The banner that drops in when a visa is issued or an award struck.
struct NewsBanner: View {
    let item: PassportStore.NewsItem
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().stroke(Book.gilt, lineWidth: 1.6).frame(width: 34, height: 34)
                if item.kind == "visa" {
                    VisaIcon(size: 18, colour: Book.gilt)
                } else {
                    TickMark(size: 16, colour: Book.gilt)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.kind == "visa" ? "Visa issued" : "Award struck")
                    .font(Type.label(10))
                    .tracking(1.4)
                    .foregroundColor(Book.giltSoft)
                Text(item.title)
                    .font(Type.heading(16))
                    .foregroundColor(Book.paper)
            }
            Spacer(minLength: 6)
            Button(action: onDismiss) {
                CloseMark(size: 14, colour: Book.giltSoft)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Book.cover)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Book.gilt.opacity(0.55), lineWidth: 1)
        )
        .padding(.horizontal, 14)
    }
}

/// The app's own header, so no system navigation bar is ever shown.
struct TopBar<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var onBack: (() -> Void)? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            if let onBack = onBack {
                Button(action: onBack) {
                    BackMark(size: 18)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Book.ink.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Type.heading(20))
                    .foregroundColor(Book.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let subtitle = subtitle {
                    Text(subtitle.uppercased())
                        .font(Type.label(10))
                        .tracking(1.3)
                        .foregroundColor(Book.inkFaint)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Book.paper.opacity(0.94))
        .overlay(
            Rectangle()
                .fill(Book.ink.opacity(0.12))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

extension TopBar where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, onBack: (() -> Void)? = nil) {
        self.init(title: title, subtitle: subtitle, onBack: onBack, trailing: { EmptyView() })
    }
}

struct WideButton: View {
    let title: String
    var filled: Bool = true
    var tint: Color = Book.ink
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: { if enabled { action() } }) {
            Text(title)
                .font(Type.heading(16))
                .foregroundColor(filled ? Book.paper : tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(filled ? tint : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(tint.opacity(filled ? 0 : 0.5), lineWidth: 1.2)
                )
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0.4)
    }
}

/// A month of stamping, laid out as a grid of days.
struct MonthGrid: View {
    let label: String
    let days: [Int: Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Type.label(11))
                .tracking(1.2)
                .foregroundColor(Book.inkSoft)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 10)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(1...31, id: \.self) { day in
                    let count = days[day] ?? 0
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(count == 0 ? Book.ink.opacity(0.06)
                                         : Book.ink.opacity(0.22 + Double(min(count, 4)) * 0.16))
                        .frame(height: 16)
                        .overlay(
                            Text("\(day)")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(count == 0 ? Book.inkFaint.opacity(0.7) : Book.paper)
                        )
                }
            }
        }
    }
}

/// A row that reads like a line in a register.
struct RegisterRow<Trailing: View>: View {
    let title: String
    var detail: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Type.serif(16))
                    .foregroundColor(Book.ink)
                if let detail = detail {
                    Text(detail)
                        .font(Type.body(12))
                        .foregroundColor(Book.inkFaint)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 6)
            trailing
        }
        .padding(.vertical, 9)
    }
}
