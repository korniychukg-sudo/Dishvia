import SwiftUI

// The book itself: the cover page with your rank on it, today's plate, and one
// leaf per region that fills up with impressions.

struct PassportView: View {
    @EnvironmentObject var store: PassportStore
    @State private var showSettings = false

    var body: some View {
        ZStack {
            PaperBackdrop(name: "page0", tint: 0.55)

            VStack(spacing: 0) {
                TopBar(title: "Plate Passport",
                       subtitle: "\(store.stampCount) of \(Catalog.dishes.count) plates") {
                    Button { showSettings = true } label: {
                        VStack(spacing: 2.5) {
                            ForEach(0..<3, id: \.self) { _ in
                                Capsule().fill(Book.ink).frame(width: 17, height: 1.8)
                            }
                        }
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Book.ink.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        coverCard
                        plateOfTheDay
                        if let stretch = store.stretchSuggestion, store.stampCount >= 3 {
                            stretchCard(stretch)
                        }
                        SectionHeading(text: "Your pages", trailing: "\(store.regionsTouched)/8 opened")
                        VStack(spacing: 12) {
                            ForEach(Catalog.regions) { region in
                                NavigationLink(destination: RegionPageView(region: region)) {
                                    regionLeaf(region)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                    .frame(maxWidth: Metric.pageMax)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(store)
        }
    }

    // MARK: - Cover

    private var coverCard: some View {
        let rank = Lore.rank(forStamps: store.stampCount)
        let next = Lore.nextRank(forStamps: store.stampCount)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("BEARER'S STANDING")
                        .font(Type.label(9.5))
                        .tracking(1.8)
                        .foregroundColor(Book.giltSoft.opacity(0.85))
                    Text(rank.title)
                        .font(Type.title(25))
                        .foregroundColor(Book.paper)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(store.stampCount)")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundColor(Book.gilt)
                    Text("STAMPS")
                        .font(Type.label(9))
                        .tracking(1.6)
                        .foregroundColor(Book.giltSoft.opacity(0.8))
                }
            }

            Text(rank.note)
                .font(Type.serif(14))
                .foregroundColor(Book.paper.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)

            if let next = next {
                VStack(alignment: .leading, spacing: 5) {
                    RuledProgress(value: store.stampCount, target: next.stamps, tint: Book.gilt)
                    Text("\(next.stamps - store.stampCount) more to \(next.title)")
                        .font(Type.label(10))
                        .tracking(0.8)
                        .foregroundColor(Book.giltSoft.opacity(0.8))
                }
            }

            HStack(spacing: 0) {
                tally("\(store.countriesTouched)", "countries")
                tally("\(store.regionsTouched)", "regions")
                tally("\(store.visasIssuedCount)", "visas")
                tally("\(store.awardsEarnedCount)", "awards")
            }
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Book.cover)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Book.gilt.opacity(0.45), lineWidth: 1.2)
                .padding(4)
        )
    }

    private func tally(_ value: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundColor(Book.paper)
            Text(label.uppercased())
                .font(Type.label(8.5))
                .tracking(1.1)
                .foregroundColor(Book.giltSoft.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Today

    private var plateOfTheDay: some View {
        let dish = store.dishOfTheDay
        let cuisine = Catalog.cuisineByID[dish.cuisineID]
        return NavigationLink(destination: DishView(dish: dish)) {
            PaperCard {
                HStack(spacing: 13) {
                    PlateImage(folder: "dish", name: dish.id)
                        .frame(width: 92, height: 92)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PLATE OF THE DAY")
                            .font(Type.label(9.5))
                            .tracking(1.6)
                            .foregroundColor(Book.inkFaint)
                        Text(dish.name)
                            .font(Type.heading(18))
                            .foregroundColor(Book.ink)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(cuisine?.country ?? "")
                            .font(Type.body(13))
                            .foregroundColor(Book.inkSoft)
                        if store.isStamped(dish.id) {
                            HStack(spacing: 4) {
                                TickMark(size: 11, colour: Book.wash("herb"))
                                Text("Already in the book")
                                    .font(Type.label(10))
                                    .foregroundColor(Book.wash("herb"))
                            }
                            .padding(.top, 1)
                        }
                    }
                    Spacer(minLength: 0)
                    ChevronMark()
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func stretchCard(_ dish: Dish) -> some View {
        NavigationLink(destination: DishView(dish: dish)) {
            PaperCard(tint: Book.paperDeep) {
                HStack(spacing: 13) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FURTHEST FROM YOUR PALATE")
                            .font(Type.label(9.5))
                            .tracking(1.5)
                            .foregroundColor(Book.inkFaint)
                        Text(dish.name)
                            .font(Type.heading(17))
                            .foregroundColor(Book.ink)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Nothing you have stamped tastes like this.")
                            .font(Type.body(12.5))
                            .foregroundColor(Book.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    TasteRadar(values: dish.profile.values.map(Double.init),
                               compare: store.palate,
                               tint: Book.wash(dish.palette),
                               showLabels: false)
                        .frame(width: 74, height: 74)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Region leaf

    private func regionLeaf(_ region: Region) -> some View {
        let cuisines = Catalog.cuisinesByRegion[region.id] ?? []
        let total = Catalog.dishes(inRegion: region.id).count
        let done = store.stampCount(inRegion: region.id)
        return PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(region.name)
                            .font(Type.heading(18))
                            .foregroundColor(Book.ink)
                        Text(region.note)
                            .font(Type.body(12.5))
                            .foregroundColor(Book.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 6)
                    Text("\(done)/\(total)")
                        .font(Type.mono(13))
                        .foregroundColor(Book.inkSoft)
                    ChevronMark()
                }
                RuledProgress(value: done, target: total)
                HStack(spacing: 8) {
                    ForEach(cuisines) { cuisine in
                        let count = store.stampCount(inCuisine: cuisine.id)
                        ZStack {
                            if count > 0 {
                                StampMark(design: StampDesign(cuisine: cuisine,
                                                              previewDay: DayNumber.today()),
                                          strength: 1, showDate: false)
                            } else {
                                StampSlot(shape: cuisine.stampShape)
                            }
                        }
                        .frame(height: 58)
                        .frame(maxWidth: .infinity)
                        .opacity(count > 0 ? 1 : 0.5)
                    }
                }
            }
        }
    }
}

// MARK: - A single region's leaf

struct RegionPageView: View {
    let region: Region
    @EnvironmentObject var store: PassportStore
    @Environment(\.presentationMode) private var presentation

    private var dishes: [Dish] { Catalog.dishes(inRegion: region.id) }

    var body: some View {
        ZStack {
            PaperBackdrop(name: pageName, tint: 0.62)

            VStack(spacing: 0) {
                TopBar(title: region.name,
                       subtitle: "\(store.stampCount(inRegion: region.id)) of \(dishes.count) stamped",
                       onBack: { presentation.wrappedValue.dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(region.note)
                            .font(Type.serif(15))
                            .foregroundColor(Book.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)

                        ForEach(Catalog.cuisinesByRegion[region.id] ?? []) { cuisine in
                            countryBlock(cuisine)
                        }
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 14)
                    .padding(.bottom, 30)
                    .frame(maxWidth: Metric.pageMax)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var pageName: String {
        let index = Catalog.regions.firstIndex { $0.id == region.id } ?? 0
        return "page\(index % 4)"
    }

    private func countryBlock(_ cuisine: Cuisine) -> some View {
        let list = Catalog.dishesByCuisine[cuisine.id] ?? []
        let done = store.stampCount(inCuisine: cuisine.id)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10),
                            count: Metric.isPad ? 3 : 2)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                NavigationLink(destination: CuisineView(cuisine: cuisine)) {
                    HStack(spacing: 6) {
                        Text(cuisine.country)
                            .font(Type.heading(17))
                            .foregroundColor(Book.ink)
                        ChevronMark(size: 10)
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                if store.isComplete(cuisineID: cuisine.id) {
                    TagPill(text: "COMPLETE", tint: Book.wash("herb"), strong: true)
                } else {
                    Text("\(done)/\(list.count)")
                        .font(Type.mono(12))
                        .foregroundColor(Book.inkFaint)
                }
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(list) { dish in
                    NavigationLink(destination: DishView(dish: dish)) {
                        StampCell(dish: dish, cuisine: cuisine,
                                  record: store.stamp(for: dish.id))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 4)
    }
}

/// One square on the page: either a struck impression or the space for one.
struct StampCell: View {
    let dish: Dish
    let cuisine: Cuisine
    let record: StampRecord?

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                if let record = record {
                    StampMark(design: StampDesign(cuisine: cuisine, day: record.day,
                                                  seed: record.seed))
                } else {
                    StampSlot(shape: cuisine.stampShape)
                }
            }
            .frame(height: 96)

            Text(dish.name)
                .font(Type.body(11.5))
                .foregroundColor(record == nil ? Book.inkFaint : Book.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 28, alignment: .top)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(record == nil ? Color.clear : Book.card.opacity(0.55))
        )
    }
}
