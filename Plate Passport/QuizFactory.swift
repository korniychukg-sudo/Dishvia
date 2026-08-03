import Foundation

// Ten questions built out of the atlas itself, so the quiz grows with the
// content rather than being written out by hand.
struct QuizQuestion {
    let prompt: String
    let detail: String?
    let options: [String]
    let answer: Int
    let explanation: String
    let plateID: String?
}

enum QuizFactory {

    static func round(seed: UInt64) -> [QuizQuestion] {
        var roll = Roll(seed)
        var out: [QuizQuestion] = []
        var usedDishes = Set<String>()
        var kinds = [0, 1, 2, 3, 4, 0, 1, 2, 3, 4]
        // shuffle the order the kinds appear in
        for i in stride(from: kinds.count - 1, to: 0, by: -1) {
            kinds.swapAt(i, roll.int(0, i))
        }
        for kind in kinds {
            var made: QuizQuestion? = nil
            var attempts = 0
            while made == nil && attempts < 24 {
                attempts += 1
                made = build(kind: kind, roll: &roll, used: &usedDishes)
            }
            if made == nil { made = build(kind: 0, roll: &roll, used: &usedDishes) }
            if let q = made { out.append(q) }
        }
        return out
    }

    private static func pick<T>(_ list: [T], _ roll: inout Roll) -> T {
        list[roll.int(0, list.count - 1)]
    }

    private static func axisPrompt(_ axis: Int) -> String {
        switch axis {
        case 0: return "Which of these carries the most heat?"
        case 1: return "Which of these is the most sour?"
        case 2: return "Which of these is the sweetest?"
        case 3: return "Which of these has the deepest savour?"
        case 4: return "Which of these is the most herbal?"
        default: return "Which of these is the richest?"
        }
    }

    private static func shuffled(_ options: [String], answer: String,
                                 _ roll: inout Roll) -> (options: [String], index: Int) {
        var items = options
        for i in stride(from: items.count - 1, to: 0, by: -1) {
            items.swapAt(i, roll.int(0, i))
        }
        return (items, items.firstIndex(of: answer) ?? 0)
    }

    private static func build(kind: Int, roll: inout Roll,
                              used: inout Set<String>) -> QuizQuestion? {
        switch kind {

        case 0:   // which country does this plate come from
            let dish = pick(Catalog.dishes, &roll)
            guard !used.contains(dish.id), let home = Catalog.cuisineByID[dish.cuisineID]
            else { return nil }
            var names = [home.country]
            var guard0 = 0
            while names.count < 4 && guard0 < 40 {
                guard0 += 1
                let other = pick(Catalog.cuisines, &roll)
                if !names.contains(other.country) { names.append(other.country) }
            }
            guard names.count == 4 else { return nil }
            used.insert(dish.id)
            let s = shuffled(names, answer: home.country, &roll)
            return QuizQuestion(prompt: "Where does this plate come from?",
                                detail: dish.name,
                                options: s.options, answer: s.index,
                                explanation: "\(dish.name) is \(home.adjective).",
                                plateID: dish.id)

        case 1:   // which of these plates belongs to this country
            let home = pick(Catalog.cuisines, &roll)
            guard !used.contains("belongs-" + home.id) else { return nil }
            guard let mine = Catalog.dishesByCuisine[home.id], !mine.isEmpty else { return nil }
            used.insert("belongs-" + home.id)
            let dish = pick(mine, &roll)
            guard !used.contains(dish.id) else { return nil }
            var names = [dish.name]
            var guard1 = 0
            while names.count < 4 && guard1 < 60 {
                guard1 += 1
                let other = pick(Catalog.dishes, &roll)
                if other.cuisineID != home.id && !names.contains(other.name) {
                    names.append(other.name)
                }
            }
            guard names.count == 4 else { return nil }
            used.insert(dish.id)
            let s = shuffled(names, answer: dish.name, &roll)
            return QuizQuestion(prompt: "Which of these is \(home.adjective)?",
                                detail: nil,
                                options: s.options, answer: s.index,
                                explanation: "\(dish.name) comes from \(home.country).",
                                plateID: nil)

        case 2:   // which of these sits highest on one taste axis
            let axis = roll.int(0, 5)
            guard !used.contains("axis-\(axis)") else { return nil }
            var candidates: [Dish] = []
            var guard2 = 0
            while candidates.count < 4 && guard2 < 90 {
                guard2 += 1
                let d = pick(Catalog.dishes, &roll)
                let v = d.profile.values[axis]
                if !candidates.contains(where: { $0.name == d.name || $0.profile.values[axis] == v }) {
                    candidates.append(d)
                }
            }
            guard candidates.count == 4 else { return nil }
            guard let winner = candidates.max(by: { $0.profile.values[axis] < $1.profile.values[axis] })
            else { return nil }
            // only ask when the answer is not a coin toss
            let others = candidates.filter { $0.name != winner.name }
            guard let runnerUp = others.max(by: { $0.profile.values[axis] < $1.profile.values[axis] }),
                  winner.profile.values[axis] - runnerUp.profile.values[axis] >= 1 else { return nil }
            used.insert("axis-\(axis)")
            let s = shuffled(candidates.map { $0.name }, answer: winner.name, &roll)
            return QuizQuestion(prompt: axisPrompt(axis),
                                detail: nil,
                                options: s.options, answer: s.index,
                                explanation: "\(winner.name) sits at \(winner.profile.values[axis]) of 3 for \(Taste.axisNames[axis].lowercased()).",
                                plateID: nil)

        case 3:   // which region is this country in
            let home = pick(Catalog.cuisines, &roll)
            guard !used.contains("filed-" + home.id),
                  let region = Catalog.regionByID[home.regionID] else { return nil }
            used.insert("filed-" + home.id)
            var names = [region.name]
            var guard3 = 0
            while names.count < 4 && guard3 < 40 {
                guard3 += 1
                let other = pick(Catalog.regions, &roll)
                if !names.contains(other.name) { names.append(other.name) }
            }
            guard names.count == 4 else { return nil }
            let s = shuffled(names, answer: region.name, &roll)
            return QuizQuestion(prompt: "Which region does \(home.country) sit in?",
                                detail: nil,
                                options: s.options, answer: s.index,
                                explanation: "\(home.country) is filed under \(region.name).",
                                plateID: nil)

        default:  // which plate goes with this ingredient
            let dish = pick(Catalog.dishes, &roll)
            guard !used.contains(dish.id), let key = dish.ingredients.first,
                  !used.contains("builtOn-" + key) else { return nil }
            var names = [dish.name]
            var guard4 = 0
            while names.count < 4 && guard4 < 60 {
                guard4 += 1
                let other = pick(Catalog.dishes, &roll)
                if other.name != dish.name && !names.contains(other.name)
                    && !other.ingredients.contains(key) {
                    names.append(other.name)
                }
            }
            guard names.count == 4 else { return nil }
            used.insert(dish.id)
            used.insert("builtOn-" + key)
            let s = shuffled(names, answer: dish.name, &roll)
            return QuizQuestion(prompt: "Which of these is built on \(key)?",
                                detail: nil,
                                options: s.options, answer: s.index,
                                explanation: "\(dish.name) starts with \(key).",
                                plateID: nil)
        }
    }
}
