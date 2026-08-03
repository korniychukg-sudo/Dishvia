import SwiftUI

// Twenty visas. Eight are earned by covering a region, twelve by eating a
// particular way. Each one is a full engraved page once it is issued.

struct VisasView: View {
    @EnvironmentObject var store: PassportStore
    @State private var selected: Visa? = nil

    var body: some View {
        ZStack {
            PaperBackdrop(name: "page1", tint: 0.4)

            VStack(spacing: 0) {
                TopBar(title: "Visas",
                       subtitle: "\(store.visasIssuedCount) of \(Lore.visas.count) issued") {
                    NavigationLink(destination: AwardsView()) {
                        Text("AWARDS")
                            .font(Type.label(10))
                            .tracking(1.2)
                            .foregroundColor(Book.inkSoft)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Book.ink.opacity(0.07)))
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        section("Regional", Array(Lore.visas.prefix(8)))
                        section("By the way you eat", Array(Lore.visas.dropFirst(8)))
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .frame(maxWidth: Metric.pageMax)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selected) { visa in
            VisaDetailView(visa: visa).environmentObject(store)
        }
    }

    private func section(_ title: String, _ list: [Visa]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12),
                            count: Metric.isPad ? 3 : 2)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeading(text: title,
                           trailing: "\(list.filter { store.isIssued($0) }.count)/\(list.count)")
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(list) { visa in
                    Button {
                        Feedback.tap(store)
                        selected = visa
                    } label: {
                        visaTile(visa)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func visaTile(_ visa: Visa) -> some View {
        let issued = store.isIssued(visa)
        let progress = min(store.progress(for: visa), visa.requirement)
        return VStack(alignment: .leading, spacing: 7) {
            ZStack {
                PlateImage(folder: "visa", name: visa.id, corner: 9)
                    .aspectRatio(980.0 / 620.0, contentMode: .fit)
                    .saturation(issued ? 1 : 0.12)
                    .opacity(issued ? 1 : 0.42)
                if !issued {
                    VStack(spacing: 3) {
                        Text("\(progress)/\(visa.requirement)")
                            .font(Type.mono(15))
                            .foregroundColor(Book.ink)
                        Text("PLATES")
                            .font(Type.label(8.5))
                            .tracking(1.4)
                            .foregroundColor(Book.inkFaint)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Book.card.opacity(0.92))
                    )
                }
            }
            Text(visa.title)
                .font(Type.serif(14.5))
                .foregroundColor(issued ? Book.ink : Book.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if issued {
                HStack(spacing: 4) {
                    TickMark(size: 10, colour: Book.wash("herb"))
                    Text("ISSUED")
                        .font(Type.label(9))
                        .tracking(1.2)
                        .foregroundColor(Book.wash("herb"))
                }
            } else {
                RuledProgress(value: progress, target: visa.requirement,
                              tint: Book.wash(visa.tint))
            }
        }
    }
}

extension Visa: Equatable {
    static func == (a: Visa, b: Visa) -> Bool { a.id == b.id }
}

// MARK: - One visa

struct VisaDetailView: View {
    let visa: Visa
    @EnvironmentObject var store: PassportStore
    @Environment(\.presentationMode) private var presentation

    var body: some View {
        ZStack {
            PaperBackdrop(name: "page0", tint: 0.6)

            VStack(spacing: 0) {
                TopBar(title: visa.title,
                       subtitle: store.isIssued(visa) ? "Issued" : "Pending") {
                    Button { presentation.wrappedValue.dismiss() } label: {
                        CloseMark(size: 15)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Book.ink.opacity(0.07)))
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        PlateImage(folder: "visa", name: visa.id, corner: 12)
                            .aspectRatio(980.0 / 620.0, contentMode: .fit)
                            .saturation(store.isIssued(visa) ? 1 : 0.15)
                            .opacity(store.isIssued(visa) ? 1 : 0.55)

                        Text(visa.subtitle)
                            .font(Type.serif(15.5))
                            .foregroundColor(Book.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        PaperCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("PROGRESS")
                                        .font(Type.label(9.5))
                                        .tracking(1.5)
                                        .foregroundColor(Book.inkFaint)
                                    Spacer()
                                    Text("\(min(store.progress(for: visa), visa.requirement)) of \(visa.requirement)")
                                        .font(Type.mono(13))
                                        .foregroundColor(Book.ink)
                                }
                                RuledProgress(value: store.progress(for: visa),
                                              target: visa.requirement,
                                              tint: Book.wash(visa.tint))
                            }
                        }

                        qualifying
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 14)
                    .padding(.bottom, 30)
                    .frame(maxWidth: Metric.pageMax)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var candidates: [Dish] {
        switch visa.rule {
        case .region(let id, _): return Catalog.dishes(inRegion: id)
        case .tag(let tag, _):   return Catalog.dishes(withTag: tag)
        default:                 return []
        }
    }

    private var qualifying: some View {
        let list = candidates.filter { !store.isStamped($0.id) }.prefix(12)
        return Group {
            if list.isEmpty {
                PaperCard {
                    Text(store.isIssued(visa)
                         ? "This visa is in the book. Nothing further is needed."
                         : "Nothing left to stamp for this one.")
                        .font(Type.serif(14.5))
                        .foregroundColor(Book.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeading(text: "Still to try", trailing: "\(candidates.filter { !store.isStamped($0.id) }.count) left")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(list)) { dish in
                                VStack(alignment: .leading, spacing: 5) {
                                    PlateImage(folder: "dish", name: dish.id, corner: 9)
                                        .frame(width: 104, height: 104)
                                    Text(dish.name)
                                        .font(Type.body(11.5))
                                        .foregroundColor(Book.ink)
                                        .lineLimit(2)
                                        .frame(width: 104, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
}

// MARK: - Awards

struct AwardsView: View {
    @EnvironmentObject var store: PassportStore
    @Environment(\.presentationMode) private var presentation

    var body: some View {
        ZStack {
            PaperBackdrop(name: "page3", tint: 0.4)

            VStack(spacing: 0) {
                TopBar(title: "Awards",
                       subtitle: "\(store.awardsEarnedCount) of \(Lore.awards.count) struck",
                       onBack: { presentation.wrappedValue.dismiss() })

                ScrollView {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 12),
                                        count: Metric.isPad ? 3 : 2)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Lore.awards) { award in
                            awardTile(award)
                        }
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .frame(maxWidth: Metric.pageMax)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func awardTile(_ award: Award) -> some View {
        let earned = store.isEarned(award)
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(earned ? Book.cover : Book.ink.opacity(0.05))
                Circle()
                    .stroke(earned ? Book.gilt : Book.inkFaint.opacity(0.35),
                            style: StrokeStyle(lineWidth: earned ? 1.6 : 1, dash: earned ? [] : [3, 4]))
                    .padding(4)
                AwardEmblem(seed: seedValue(award.id),
                            colour: earned ? Book.gilt : Book.inkFaint.opacity(0.5))
                    .padding(16)
            }
            .frame(height: 96)

            Text(award.title)
                .font(Type.serif(14))
                .foregroundColor(earned ? Book.ink : Book.inkSoft)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(award.detail)
                .font(Type.body(11))
                .foregroundColor(Book.inkFaint)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Book.card.opacity(earned ? 1 : 0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Book.ink.opacity(0.12), lineWidth: 1)
        )
    }
}

/// A struck-brass rosette, different for every award and drawn from its name.
struct AwardEmblem: View {
    let seed: UInt64
    var colour: Color = Book.gilt

    var body: some View {
        Canvas { ctx, size in
            var roll = Roll(seed)
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = min(size.width, size.height) / 2
            let points = roll.int(5, 9)
            let inner = roll.between(0.38, 0.62)

            var star = Path()
            for i in 0..<(points * 2) {
                let a = Double(i) / Double(points * 2) * 2 * .pi - .pi / 2
                let rr = Double(r) * (i % 2 == 0 ? 1.0 : inner)
                let p = CGPoint(x: c.x + CGFloat(cos(a) * rr), y: c.y + CGFloat(sin(a) * rr))
                if i == 0 { star.move(to: p) } else { star.addLine(to: p) }
            }
            star.closeSubpath()
            ctx.stroke(star, with: .color(colour),
                       style: StrokeStyle(lineWidth: max(1.1, r * 0.075), lineJoin: .round))

            let rings = roll.int(1, 2)
            for k in 0..<rings {
                let rr = Double(r) * (0.30 + Double(k) * 0.16)
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - CGFloat(rr), y: c.y - CGFloat(rr),
                                                  width: CGFloat(rr * 2), height: CGFloat(rr * 2))),
                           with: .color(colour.opacity(0.8)),
                           style: StrokeStyle(lineWidth: max(0.9, r * 0.05)))
            }

            let pips = roll.int(3, 6)
            for i in 0..<pips {
                let a = Double(i) / Double(pips) * 2 * .pi + roll.between(0, 1)
                let rr = Double(r) * 0.16
                let p = CGPoint(x: c.x + CGFloat(cos(a) * Double(r) * 0.20),
                                y: c.y + CGFloat(sin(a) * Double(r) * 0.20))
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - CGFloat(rr) / 2, y: p.y - CGFloat(rr) / 2,
                                                width: CGFloat(rr), height: CGFloat(rr))),
                         with: .color(colour.opacity(0.9)))
            }
        }
    }
}
