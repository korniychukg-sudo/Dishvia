import Foundation

// Generated. All 192 recipes, indexed by the dish they belong to.

enum RecipeBook {
    static let all: [Recipe] =
        RecipesEastAsia.all + RecipesSoutheastAsia.all + RecipesSouthAsia.all +
        RecipesMiddleEast.all + RecipesAfrica.all + RecipesMedEurope.all +
        RecipesNorthEurope.all + RecipesAmericas.all

    static let byDish: [String: Recipe] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.dishID, $0) })
}
