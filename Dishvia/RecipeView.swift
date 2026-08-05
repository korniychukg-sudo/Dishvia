import SwiftUI

// The recipe page: gather the ingredients, tick the steps off as you cook,
// and when the plate is real, stamp it. The passport earns its ink here.

struct RecipeView: View {
    let dish: Dish
    let recipe: Recipe

    @EnvironmentObject var store: PassportStore
    @Environment(\.presentationMode) private var presentation
    @State private var gathered: Set<Int> = []
    @State private var done: Set<Int> = []
    @State private var pressing = false

    private var cuisine: Cuisine { Catalog.cuisineByID[dish.cuisineID] ?? Catalog.cuisines[0] }

    var body: some View {
        ZStack {
            PaperBackdrop(name: "page2", tint: 0.4)

            VStack(spacing: 0) {
                TopBar(title: dish.name,
                       subtitle: "The home version",
                       onBack: { presentation.wrappedValue.dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        ingredientList
                        stepList
                        wisdom
                        cookedAction
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

    // MARK: - Header

    private var header: some View {
        PaperCard {
            HStack(spacing: 0) {
                fact("SERVES", "\(recipe.serves)")
                divider
                fact("TIME", recipe.timeText)
                divider
                fact("EFFORT", recipe.difficultyName)
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(Book.ink.opacity(0.12)).frame(width: 1, height: 34)
    }

    private func fact(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Type.heading(16))
                .foregroundColor(Book.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(Type.label(9))
                .tracking(1.4)
                .foregroundColor(Book.inkFaint)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ingredients

    private var ingredientList: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeading(text: "Gather",
                           trailing: "\(gathered.count)/\(recipe.ingredients.count)")
            PaperCard {
                VStack(spacing: 0) {
                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { i, ing in
                        Button {
                            Feedback.tap(store)
                            if gathered.contains(i) { gathered.remove(i) } else { gathered.insert(i) }
                        } label: {
                            HStack(spacing: 11) {
                                ZStack {
                                    Circle()
                                        .stroke(gathered.contains(i) ? Book.wash("herb") : Book.inkFaint.opacity(0.5),
                                                lineWidth: 1.4)
                                    if gathered.contains(i) {
                                        TickMark(size: 11, colour: Book.wash("herb"))
                                    }
                                }
                                .frame(width: 21, height: 21)
                                Text(ing.amount)
                                    .font(Type.mono(12.5))
                                    .foregroundColor(Book.inkSoft)
                                    .frame(width: 86, alignment: .leading)
                                Text(ing.item)
                                    .font(Type.serif(14.5))
                                    .foregroundColor(gathered.contains(i) ? Book.inkFaint : Book.ink)
                                    .strikethrough(gathered.contains(i), color: Book.inkFaint)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 7)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if i < recipe.ingredients.count - 1 {
                            Rectangle().fill(Book.ink.opacity(0.07)).frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Steps

    private var stepList: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeading(text: "Cook", trailing: "\(done.count)/\(recipe.steps.count)")
            VStack(spacing: 10) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { i, step in
                    Button {
                        Feedback.tap(store)
                        if done.contains(i) { done.remove(i) } else { done.insert(i) }
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(done.contains(i) ? Book.wash("herb") : Book.ink.opacity(0.07))
                                if done.contains(i) {
                                    TickMark(size: 12, colour: Book.paper)
                                } else {
                                    Text("\(i + 1)")
                                        .font(Type.mono(12))
                                        .foregroundColor(Book.inkSoft)
                                }
                            }
                            .frame(width: 26, height: 26)
                            Text(step)
                                .font(Type.serif(14.5))
                                .foregroundColor(done.contains(i) ? Book.inkFaint : Book.ink)
                                .lineSpacing(2)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Book.card.opacity(done.contains(i) ? 0.55 : 1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Book.ink.opacity(0.12), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Notes

    private var wisdom: some View {
        VStack(alignment: .leading, spacing: 10) {
            PaperCard(tint: Book.paperDeep) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("THE THING THAT MATTERS")
                        .font(Type.label(9.5))
                        .tracking(1.6)
                        .foregroundColor(Book.inkFaint)
                    Text(recipe.note)
                        .font(Type.serif(14.5))
                        .foregroundColor(Book.ink)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            PaperCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HONEST SHORTCUT")
                        .font(Type.label(9.5))
                        .tracking(1.6)
                        .foregroundColor(Book.inkFaint)
                    Text(recipe.shortcut)
                        .font(Type.serif(14))
                        .foregroundColor(Book.inkSoft)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - The point of it all

    private var cookedAction: some View {
        Group {
            if store.isStamped(dish.id) {
                HStack(spacing: 7) {
                    TickMark(size: 13, colour: Book.wash("herb"))
                    Text("Already in the book")
                        .font(Type.label(11))
                        .tracking(1.2)
                        .foregroundColor(Book.wash("herb"))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            } else {
                VStack(spacing: 7) {
                    WideButton(title: "I cooked it — stamp the plate", tint: Book.stampRed) {
                        Feedback.tap(store)
                        pressing = true
                    }
                    Text("Eaten is eaten, whether a kitchen in \(cuisine.country) made it or yours did.")
                        .font(Type.body(12))
                        .foregroundColor(Book.inkFaint)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
        }
    }
}
