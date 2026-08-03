import SwiftUI

struct DishView: View {
    let dish: Dish
    @EnvironmentObject var store: PassportStore
    @Environment(\.presentationMode) private var presentation
    @State private var pressing = false

    private var cuisine: Cuisine { Catalog.cuisineByID[dish.cuisineID] ?? Catalog.cuisines[0] }
    private var record: StampRecord? { store.stamp(for: dish.id) }

    var body: some View {
        ZStack {
            PaperBackdrop(name: "page1", tint: 0.45)

            VStack(spacing: 0) {
                TopBar(title: dish.name,
                       subtitle: cuisine.country,
                       onBack: { presentation.wrappedValue.dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        plate
                        heading
                        tagRow
                        prose
                        ingredients
                        radar
                        if let record = record {
                            EntryEditor(dish: dish, record: record)
                        } else {
                            stampAction
                        }
                        relatedRow
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 14)
                    .padding(.bottom, 34)
                    .frame(maxWidth: Metric.pageMax)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $pressing) {
            StampPressView(dish: dish, cuisine: cuisine)
                .environmentObject(store)
        }
    }

    // MARK: - Pieces

    private var plate: some View {
        ZStack(alignment: .topTrailing) {
            PlateImage(folder: "dish", name: dish.id, corner: 14)
                .aspectRatio(1, contentMode: .fit)
            if let record = record {
                StampMark(design: StampDesign(cuisine: cuisine, day: record.day, seed: record.seed))
                    .frame(width: 108, height: 108)
                    .padding(10)
            }
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 4) {
            if store.settings.showNativeNames && !dish.nativeName.isEmpty {
                Text(dish.nativeName)
                    .font(Type.serif(17))
                    .foregroundColor(Book.inkSoft)
            }
            NavigationLink(destination: CuisineView(cuisine: cuisine)) {
                HStack(spacing: 6) {
                    Text("\(cuisine.adjective) · \(Catalog.regionByID[cuisine.regionID]?.name ?? "")")
                        .font(Type.label(11))
                        .tracking(1.1)
                        .foregroundColor(Book.wash(dish.palette))
                    ChevronMark(size: 9, colour: Book.wash(dish.palette))
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var tagRow: some View {
        HStack(spacing: 6) {
            ForEach(dish.tags, id: \.self) { tag in
                TagPill(text: Lore.tagName(tag).uppercased(), tint: Book.inkSoft)
            }
            Spacer(minLength: 0)
        }
    }

    private var prose: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(dish.summary)
                .font(Type.serif(15.5))
                .foregroundColor(Book.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            PaperCard(tint: Book.paperDeep) {
                VStack(alignment: .leading, spacing: 10) {
                    labelled("On the tongue", dish.tasteNote)
                    Rectangle().fill(Book.ink.opacity(0.10)).frame(height: 1)
                    labelled("How it is eaten", dish.eaten)
                }
            }
        }
    }

    private func labelled(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(Type.label(9.5))
                .tracking(1.5)
                .foregroundColor(Book.inkFaint)
            Text(text)
                .font(Type.serif(14.5))
                .foregroundColor(Book.ink)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var ingredients: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeading(text: "What is in it")
            FlowRow(items: dish.ingredients) { item in
                TagPill(text: item, tint: Book.wash(dish.palette))
            }
        }
    }

    private var radar: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeading(text: "Taste", trailing: store.stampCount > 0 ? "dashed: your palate" : nil)
            PaperCard {
                HStack(spacing: 14) {
                    TasteRadar(values: dish.profile.values.map(Double.init),
                               compare: store.stampCount > 0 ? store.palate : nil,
                               tint: Book.wash(dish.palette))
                        .frame(width: 148, height: 148)
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(Taste.axisNames.enumerated()), id: \.offset) { i, name in
                            HStack(spacing: 6) {
                                Text(name)
                                    .font(Type.body(12))
                                    .foregroundColor(Book.inkSoft)
                                    .frame(width: 48, alignment: .leading)
                                HStack(spacing: 3) {
                                    ForEach(0..<3, id: \.self) { step in
                                        RoundedRectangle(cornerRadius: 1.5)
                                            .fill(step < dish.profile.values[i]
                                                  ? Book.wash(dish.palette)
                                                  : Book.ink.opacity(0.10))
                                            .frame(width: 13, height: 6)
                                    }
                                }
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var stampAction: some View {
        VStack(spacing: 10) {
            WideButton(title: "Stamp this plate", tint: Book.stampRed) {
                Feedback.tap(store)
                pressing = true
            }
            Button {
                Feedback.tap(store)
                store.toggleWish(dish.id)
            } label: {
                HStack(spacing: 8) {
                    TagMark(size: 17, filled: store.isWished(dish.id),
                            colour: store.isWished(dish.id) ? Book.wash("herb") : Book.inkSoft)
                    Text(store.isWished(dish.id) ? "On your list" : "Add to my list")
                        .font(Type.heading(15))
                        .foregroundColor(store.isWished(dish.id) ? Book.wash("herb") : Book.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke((store.isWished(dish.id) ? Book.wash("herb") : Book.inkSoft)
                            .opacity(0.45), lineWidth: 1.2)
                )
            }
            .buttonStyle(.plain)
            Text("Stamp it once you have actually eaten it.")
                .font(Type.body(12))
                .foregroundColor(Book.inkFaint)
        }
        .frame(maxWidth: .infinity)
    }

    private var relatedRow: some View {
        let others = (Catalog.dishesByCuisine[dish.cuisineID] ?? [])
            .filter { $0.id != dish.id }
            .prefix(6)
        return VStack(alignment: .leading, spacing: 9) {
            SectionHeading(text: "More from \(cuisine.country)")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(others)) { other in
                        NavigationLink(destination: DishView(dish: other)) {
                            VStack(alignment: .leading, spacing: 5) {
                                PlateImage(folder: "dish", name: other.id, corner: 9)
                                    .frame(width: 108, height: 108)
                                Text(other.name)
                                    .font(Type.body(11.5))
                                    .foregroundColor(Book.ink)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: 108, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - The entry once it has been stamped

struct EntryEditor: View {
    let dish: Dish
    let record: StampRecord
    @EnvironmentObject var store: PassportStore
    @State private var note: String = ""
    @State private var place: String = ""
    @State private var loaded = false

    var body: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("STAMPED")
                            .font(Type.label(9.5))
                            .tracking(1.6)
                            .foregroundColor(Book.inkFaint)
                        Text(DayNumber.stampFormatter.string(from: record.date))
                            .font(Type.mono(14))
                            .foregroundColor(Book.ink)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(1...3, id: \.self) { value in
                            Button {
                                Feedback.tap(store)
                                store.updateStamp(dishID: dish.id,
                                                  rating: record.rating == value ? 0 : value)
                            } label: {
                                ForkMark(size: 21, filled: value <= record.rating)
                                    .padding(3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Rectangle().fill(Book.ink.opacity(0.10)).frame(height: 1)

                field("Where", text: $place, placeholder: "A city, a stall, a kitchen") {
                    store.updateStamp(dishID: dish.id, place: place)
                }
                field("Note", text: $note, placeholder: "What you thought of it") {
                    store.updateStamp(dishID: dish.id, note: note)
                }
            }
        }
        .onAppear {
            guard !loaded else { return }
            note = record.note
            place = record.place
            loaded = true
        }
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String,
                       commit: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(Type.label(9.5))
                .tracking(1.5)
                .foregroundColor(Book.inkFaint)
            TextField(placeholder, text: text, onEditingChanged: { editing in
                if !editing { commit() }
            }, onCommit: commit)
                .textFieldStyle(PlainTextFieldStyle())
                .font(Type.serif(15))
                .foregroundColor(Book.ink)
                .padding(.vertical, 7)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Book.paperDeep.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Book.ink.opacity(0.12), lineWidth: 1)
                )
        }
    }
}

/// A wrapping row of pills, since iOS 15 has no flow layout.
struct FlowRow<Item: Hashable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows().enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    /// Three to a line on a phone, four on a pad — close enough to a flow, and
    /// it never needs a measurement pass.
    private func rows() -> [[Item]] {
        let perRow = Metric.isPad ? 4 : 3
        var out: [[Item]] = []
        var current: [Item] = []
        for item in items {
            current.append(item)
            if current.count == perRow { out.append(current); current = [] }
        }
        if !current.isEmpty { out.append(current) }
        return out
    }
}
