import Foundation

// The kitchen half of the passport: every dish carries a real, home-cookable
// recipe. Cook it, then stamp it — the stamp finally has something to earn.

struct RecipeIngredient {
    let amount: String
    let item: String
}

struct Recipe: Identifiable {
    let dishID: String
    let serves: Int
    let prepMinutes: Int
    let cookMinutes: Int
    let difficulty: Int          // 1 easy · 2 moderate · 3 a project
    let ingredients: [RecipeIngredient]
    let steps: [String]
    let note: String
    let shortcut: String

    var id: String { dishID }

    var totalMinutes: Int { prepMinutes + cookMinutes }

    var difficultyName: String {
        switch difficulty {
        case 1: return "Easy"
        case 2: return "Moderate"
        default: return "A project"
        }
    }

    var timeText: String {
        let total = totalMinutes
        if total < 60 { return "\(total) min" }
        let h = total / 60, m = total % 60
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }
}
