import SwiftUI

// Everything the passport covers, browsable two ways: by kitchen, or as one
// long list of plates you can sieve by what they are.

struct AtlasView: View {
    @EnvironmentObject var store: PassportStore
    @State private var mode = 0
    @State private var query = ""
    @State private var tag: String? = nil
    @State private var onlyUnstamped = false

    var body: some View {
        ZStack {
            PaperBackdrop(name: "page2", tint: 0.45)

            VStack(spacing: 0) {
                TopBar(title: "Atlas",
                       subtitle: "\(Catalog.cuisines.count) kitchens · \(Catalog.dishes.count) plates")

                modeSwitch
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 12)

                if mode == 1 { filterBar }

                ScrollView {
                    if mode == 0 {
                        countryList
                    } else {
                        dishList
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Controls

    private var modeSwitch: some View {
        HStack(spacing: 0) {
            ForEach(Array(["Kitchens", "Plates"].enumerated()), id: \.offset) { i, label in
                Button {
                    Feedback.tap(store)
                    mode = i
                } label: {
                    Text(label)
                        .font(Type.label(12))
                        .tracking(1.0)
                        .foregroundColor(mode == i ? Book.paper : Book.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(mode == i ? Book.ink : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Book.ink.opacity(0.07))
        )
        .frame(maxWidth: Metric.pageMax)
        .frame(maxWidth: .infinity)
    }

    private var filterBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("Search plates", text: $query)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(Type.serif(15))
                    .foregroundColor(Book.ink)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Book.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(Book.ink.opacity(0.14), lineWidth: 1)
                    )
                Button {
                    Feedback.tap(store)
                    onlyUnstamped.toggle()
                } label: {
                    Text(onlyUnstamped ? "UNSTAMPED" : "ALL")
                        .font(Type.label(10))
                        .tracking(1.0)
                        .foregroundColor(onlyUnstamped ? Book.paper : Book.inkSoft)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(onlyUnstamped ? Book.ink : Book.ink.opacity(0.07))
                        )
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Lore.filterTags, id: \.self) { t in
                        Button {
                            Feedback.tap(store)
                            tag = (tag == t) ? nil : t
                        } label: {
                            TagPill(text: Lore.tagName(t).uppercased(),
                                    tint: Book.inkSoft, strong: tag == t)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.top, 10)
        .frame(maxWidth: Metric.pageMax)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Kitchens

    private var countryList: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Catalog.regions) { region in
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeading(text: region.name,
                                   trailing: "\(store.stampCount(inRegion: region.id))/\(Catalog.dishes(inRegion: region.id).count)")
                    ForEach(Catalog.cuisinesByRegion[region.id] ?? []) { cuisine in
                        NavigationLink(destination: CuisineView(cuisine: cuisine)) {
                            countryRow(cuisine)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.top, 16)
        .padding(.bottom, 28)
        .frame(maxWidth: Metric.pageMax)
        .frame(maxWidth: .infinity)
    }

    private func countryRow(_ cuisine: Cuisine) -> some View {
        let total = Catalog.dishesByCuisine[cuisine.id]?.count ?? 0
        let done = store.stampCount(inCuisine: cuisine.id)
        return PaperCard {
            HStack(spacing: 12) {
                PlateImage(folder: "cuisine", name: cuisine.id, corner: 9)
                    .frame(width: 104, height: 72)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(cuisine.country)
                            .font(Type.heading(17))
                            .foregroundColor(Book.ink)
                        if store.isComplete(cuisineID: cuisine.id) {
                            TickMark(size: 12, colour: Book.wash("herb"))
                        }
                    }
                    Text(cuisine.tagline)
                        .font(Type.body(12.5))
                        .foregroundColor(Book.inkSoft)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 7) {
                        RuledProgress(value: done, target: total)
                            .frame(width: 78)
                        Text("\(done)/\(total)")
                            .font(Type.mono(11))
                            .foregroundColor(Book.inkFaint)
                    }
                }
                Spacer(minLength: 0)
                ChevronMark()
            }
        }
    }

    // MARK: - Plates

    private var filteredDishes: [Dish] {
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        return Catalog.dishes.filter { dish in
            if onlyUnstamped && store.isStamped(dish.id) { return false }
            if let tag = tag, !dish.tags.contains(tag) { return false }
            guard !needle.isEmpty else { return true }
            if dish.name.lowercased().contains(needle) { return true }
            if dish.nativeName.lowercased().contains(needle) { return true }
            let country = Catalog.cuisineByID[dish.cuisineID]?.country.lowercased() ?? ""
            if country.contains(needle) { return true }
            return dish.ingredients.contains { $0.lowercased().contains(needle) }
        }
    }

    private var dishList: some View {
        let list = filteredDishes
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12),
                            count: Metric.isPad ? 3 : 2)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(list.count) plates")
                    .font(Type.label(10))
                    .tracking(1.2)
                    .foregroundColor(Book.inkFaint)
                Spacer()
                if tag != nil || onlyUnstamped || !query.isEmpty {
                    Button {
                        query = ""; tag = nil; onlyUnstamped = false
                    } label: {
                        Text("CLEAR")
                            .font(Type.label(10))
                            .tracking(1.2)
                            .foregroundColor(Book.stampRed)
                    }
                    .buttonStyle(.plain)
                }
            }

            if list.isEmpty {
                PaperCard {
                    Text("Nothing matches that. Try a different word or clear the filters.")
                        .font(Type.serif(14))
                        .foregroundColor(Book.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(list) { dish in
                        NavigationLink(destination: DishView(dish: dish)) {
                            dishTile(dish)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .frame(maxWidth: Metric.pageMax)
        .frame(maxWidth: .infinity)
    }

    private func dishTile(_ dish: Dish) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                PlateImage(folder: "dish", name: dish.id, corner: 10)
                    .aspectRatio(1, contentMode: .fit)
                if store.isStamped(dish.id) {
                    ZStack {
                        Circle().fill(Book.card)
                        TickMark(size: 11, colour: Book.wash("herb"))
                    }
                    .frame(width: 22, height: 22)
                    .padding(6)
                }
            }
            Text(dish.name)
                .font(Type.serif(14))
                .foregroundColor(Book.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(Catalog.cuisineByID[dish.cuisineID]?.country ?? "")
                .font(Type.label(9.5))
                .tracking(1.0)
                .foregroundColor(Book.inkFaint)
        }
    }
}

// MARK: - One kitchen

struct CuisineView: View {
    let cuisine: Cuisine
    @EnvironmentObject var store: PassportStore
    @Environment(\.presentationMode) private var presentation

    private var dishes: [Dish] { Catalog.dishesByCuisine[cuisine.id] ?? [] }

    var body: some View {
        ZStack {
            PaperBackdrop(name: "page3", tint: 0.45)

            VStack(spacing: 0) {
                TopBar(title: cuisine.country,
                       subtitle: Catalog.regionByID[cuisine.regionID]?.name,
                       onBack: { presentation.wrappedValue.dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        PlateImage(folder: "cuisine", name: cuisine.id, corner: 14)
                            .aspectRatio(1280.0 / 820.0, contentMode: .fit)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(cuisine.tagline)
                                .font(Type.heading(18))
                                .foregroundColor(Book.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(cuisine.summary)
                                .font(Type.serif(15))
                                .foregroundColor(Book.ink)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        kitchenCard
                        stampRow
                        dishGrid
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

    private var kitchenCard: some View {
        PaperCard(tint: Book.paperDeep) {
            VStack(alignment: .leading, spacing: 11) {
                block("Flavour base", cuisine.flavourBase)
                Rectangle().fill(Book.ink.opacity(0.10)).frame(height: 1)
                VStack(alignment: .leading, spacing: 4) {
                    Text("STAPLES")
                        .font(Type.label(9.5))
                        .tracking(1.5)
                        .foregroundColor(Book.inkFaint)
                    FlowRow(items: cuisine.staples) { item in
                        TagPill(text: item, tint: Book.inkSoft)
                    }
                }
                Rectangle().fill(Book.ink.opacity(0.10)).frame(height: 1)
                VStack(alignment: .leading, spacing: 4) {
                    Text("HOW THEY COOK")
                        .font(Type.label(9.5))
                        .tracking(1.5)
                        .foregroundColor(Book.inkFaint)
                    ForEach(cuisine.techniques, id: \.self) { t in
                        HStack(alignment: .top, spacing: 7) {
                            Circle().fill(Book.inkFaint).frame(width: 4, height: 4)
                                .padding(.top, 6)
                            Text(t)
                                .font(Type.serif(14))
                                .foregroundColor(Book.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func block(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(Type.label(9.5))
                .tracking(1.5)
                .foregroundColor(Book.inkFaint)
            Text(text)
                .font(Type.serif(14.5))
                .foregroundColor(Book.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var stampRow: some View {
        let done = store.stampCount(inCuisine: cuisine.id)
        return PaperCard {
            HStack(spacing: 14) {
                ZStack {
                    if done > 0 {
                        StampMark(design: StampDesign(cuisine: cuisine, previewDay: DayNumber.today()),
                                  strength: 1, showDate: false)
                    } else {
                        StampSlot(shape: cuisine.stampShape)
                    }
                }
                .frame(width: 78, height: 78)
                VStack(alignment: .leading, spacing: 5) {
                    Text(done == 0 ? "No impression yet"
                                   : (done == dishes.count ? "Country complete"
                                                           : "\(done) of \(dishes.count) plates"))
                        .font(Type.heading(16))
                        .foregroundColor(Book.ink)
                    RuledProgress(value: done, target: dishes.count,
                                  tint: Book.stampInk(cuisine.stampInk))
                    Text(done == 0
                         ? "Stamp any plate below to open the page."
                         : "Every plate you stamp strikes the \(cuisine.country) mark again.")
                        .font(Type.body(12))
                        .foregroundColor(Book.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var dishGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12),
                            count: Metric.isPad ? 3 : 2)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeading(text: "The eight plates")
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(dishes) { dish in
                    NavigationLink(destination: DishView(dish: dish)) {
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                PlateImage(folder: "dish", name: dish.id, corner: 10)
                                    .aspectRatio(1, contentMode: .fit)
                                if store.isStamped(dish.id) {
                                    ZStack {
                                        Circle().fill(Book.card)
                                        TickMark(size: 11, colour: Book.wash("herb"))
                                    }
                                    .frame(width: 22, height: 22)
                                    .padding(6)
                                }
                            }
                            Text(dish.name)
                                .font(Type.serif(14))
                                .foregroundColor(Book.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
