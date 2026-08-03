import Foundation

// Generated. The eight authored regions, joined into one catalogue.

enum Catalog {

    static let regions: [Region] = [
        Region(id: "east-asia", name: "East Asia", note: "Rice, soy and the clean edge of a knife."),
        Region(id: "southeast-asia", name: "Southeast Asia", note: "Sour, sweet, salt and heat, balanced in one bite."),
        Region(id: "south-asia", name: "South Asia", note: "Spices bloomed in fat, and bread to carry them."),
        Region(id: "middle-east", name: "Middle East & Caucasus", note: "Grain, olive, sour fruit and the charcoal grill."),
        Region(id: "africa", name: "Africa", note: "Slow pots, sour grains and the pepper trade."),
        Region(id: "med-europe", name: "Mediterranean Europe", note: "Few ingredients, treated with enormous respect."),
        Region(id: "north-europe", name: "Northern & Eastern Europe", note: "Preserving winter, then celebrating the end of it."),
        Region(id: "americas", name: "The Americas", note: "Maize, chilli and three continents in one kitchen."),
    ]

    static let cuisines: [Cuisine] = ContentEastAsia.cuisines + ContentSoutheastAsia.cuisines + ContentSouthAsia.cuisines + ContentMiddleEast.cuisines + ContentAfrica.cuisines + ContentMedEurope.cuisines + ContentNorthEurope.cuisines + ContentAmericas.cuisines

    static let dishes: [Dish] = ContentEastAsia.dishes + ContentSoutheastAsia.dishes + ContentSouthAsia.dishes + ContentMiddleEast.dishes + ContentAfrica.dishes + ContentMedEurope.dishes + ContentNorthEurope.dishes + ContentAmericas.dishes

    static let dishByID: [String: Dish] = Dictionary(uniqueKeysWithValues: dishes.map { ($0.id, $0) })
    static let cuisineByID: [String: Cuisine] = Dictionary(uniqueKeysWithValues: cuisines.map { ($0.id, $0) })
    static let regionByID: [String: Region] = Dictionary(uniqueKeysWithValues: regions.map { ($0.id, $0) })

    static let dishesByCuisine: [String: [Dish]] = Dictionary(grouping: dishes, by: { $0.cuisineID })
    static let cuisinesByRegion: [String: [Cuisine]] = Dictionary(grouping: cuisines, by: { $0.regionID })

    static func dishes(inRegion regionID: String) -> [Dish] {
        let ids = Set((cuisinesByRegion[regionID] ?? []).map { $0.id })
        return dishes.filter { ids.contains($0.cuisineID) }
    }

    static func dishes(withTag tag: String) -> [Dish] {
        dishes.filter { $0.tags.contains(tag) }
    }
}
