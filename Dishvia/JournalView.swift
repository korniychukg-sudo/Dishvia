import SwiftUI

// What the book adds up to: the shape of your palate, the months you ate in,
// and every entry in the order it was made.

struct JournalView: View {
    @EnvironmentObject var store: PassportStore

    var body: some View {
        ZStack {
            PaperBackdrop(name: "page2", tint: 0.42)

            VStack(spacing: 0) {
                TopBar(title: "Journal",
                       subtitle: "\(store.stampCount) entries")

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if store.stampCount == 0 {
                            emptyState
                        } else {
                            palateCard
                            if !store.bestMatchedCuisines.isEmpty {
                                matchesCard
                            }
                            monthsCard
                            entries
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

    private var emptyState: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Nothing entered yet")
                    .font(Type.heading(18))
                    .foregroundColor(Book.ink)
                Text("Once you stamp a plate it lands here with its date, and the journal starts working out what your palate actually looks like.")
                    .font(Type.serif(14.5))
                    .foregroundColor(Book.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Palate

    private var palateCard: some View {
        let values = store.palate
        let strongest = values.enumerated().max { $0.element < $1.element }
        let weakest = values.enumerated().min { $0.element < $1.element }
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeading(text: "Your palate", trailing: "\(store.stampCount) plates")
            PaperCard {
                HStack(spacing: 16) {
                    TasteRadar(values: values, tint: Book.stampBlue)
                        .frame(width: 156, height: 156)
                    VStack(alignment: .leading, spacing: 8) {
                        if let s = strongest {
                            palateLine("Strongest", Taste.axisNames[s.offset], s.element)
                        }
                        if let w = weakest {
                            palateLine("Least explored", Taste.axisNames[w.offset], w.element)
                        }
                        Rectangle().fill(Book.ink.opacity(0.10)).frame(height: 1)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("REACHED THE TOP OF")
                                .font(Type.label(9))
                                .tracking(1.4)
                                .foregroundColor(Book.inkFaint)
                            Text("\(store.reach.filter { $0 >= 3 }.count) of 6 axes")
                                .font(Type.serif(15))
                                .foregroundColor(Book.ink)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func palateLine(_ label: String, _ axis: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(Type.label(9))
                .tracking(1.4)
                .foregroundColor(Book.inkFaint)
            HStack(spacing: 6) {
                Text(axis)
                    .font(Type.serif(15))
                    .foregroundColor(Book.ink)
                Text(String(format: "%.1f", value))
                    .font(Type.mono(12))
                    .foregroundColor(Book.inkSoft)
            }
        }
    }

    // MARK: - Matched kitchens

    private var matchesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(text: "Your kind of table")
            PaperCard {
                VStack(spacing: 0) {
                    ForEach(Array(store.bestMatchedCuisines.enumerated()), id: \.element.cuisine.id) { i, item in
                        NavigationLink(destination: CuisineView(cuisine: item.cuisine)) {
                            HStack(spacing: 12) {
                                Text(String(format: "%02d", i + 1))
                                    .font(Type.mono(12))
                                    .foregroundColor(Book.inkFaint)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.cuisine.country)
                                        .font(Type.heading(16))
                                        .foregroundColor(Book.ink)
                                    Text(item.cuisine.tagline)
                                        .font(Type.body(12))
                                        .foregroundColor(Book.inkSoft)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 6)
                                Text("\(item.match)%")
                                    .font(.system(size: 19, weight: .semibold, design: .serif))
                                    .foregroundColor(item.match >= 80 ? Book.wash("herb") : Book.ink)
                                ChevronMark()
                            }
                            .padding(.vertical, 9)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if i < store.bestMatchedCuisines.count - 1 {
                            Rectangle().fill(Book.ink.opacity(0.09)).frame(height: 1)
                        }
                    }
                }
            }
            Text("How close each kitchen's average table sits to the palate your stamps describe.")
                .font(Type.body(11.5))
                .foregroundColor(Book.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Months

    private var monthsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(text: "When you ate")
            PaperCard {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(store.stampMonths.prefix(4).enumerated()), id: \.offset) { _, month in
                        MonthGrid(label: month.label, days: month.days)
                    }
                }
            }
        }
    }

    // MARK: - Entries

    private var entries: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(text: "Entries")
            VStack(spacing: 10) {
                ForEach(store.stampsByRecency) { record in
                    if let dish = Catalog.dishByID[record.dishID],
                       let cuisine = Catalog.cuisineByID[dish.cuisineID] {
                        NavigationLink(destination: DishView(dish: dish)) {
                            entryRow(dish: dish, cuisine: cuisine, record: record)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func entryRow(dish: Dish, cuisine: Cuisine, record: StampRecord) -> some View {
        PaperCard {
            HStack(alignment: .top, spacing: 12) {
                PlateImage(folder: "dish", name: dish.id, corner: 9)
                    .frame(width: 78, height: 78)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(dish.name)
                            .font(Type.heading(16))
                            .foregroundColor(Book.ink)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(DayNumber.shortFormatter.string(from: record.date))
                            .font(Type.mono(11))
                            .foregroundColor(Book.inkFaint)
                    }
                    Text(cuisine.country + (record.place.isEmpty ? "" : " · " + record.place))
                        .font(Type.body(12))
                        .foregroundColor(Book.inkSoft)
                        .lineLimit(1)
                    if record.rating > 0 {
                        RatingForks(rating: record.rating, size: 13)
                    }
                    if !record.note.isEmpty {
                        Text(record.note)
                            .font(Type.serif(13))
                            .foregroundColor(Book.inkSoft)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 1)
                    }
                }
                StampMark(design: StampDesign(cuisine: cuisine, day: record.day, seed: record.seed),
                          showDate: false)
                    .frame(width: 52, height: 52)
            }
        }
    }
}
