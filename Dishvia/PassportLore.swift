import Foundation

// The paperwork: which visas can be issued, what the ranks are called, and the
// awards struck along the way. Kept in small chunks — one long literal makes
// the Release optimiser sit and think for the better part of an hour.

enum Lore {

    // MARK: - Visas

    private static let regionVisas: [Visa] = [
        Visa(id: "east-asia", title: "Far East Entry",
             subtitle: "Six plates from East Asia, stamped and dated.",
             rule: .region("east-asia", 6), tint: "jade"),
        Visa(id: "southeast-asia", title: "Monsoon Transit",
             subtitle: "Six plates from Southeast Asia.",
             rule: .region("southeast-asia", 6), tint: "herb"),
        Visa(id: "south-asia", title: "Subcontinent Entry",
             subtitle: "Six plates from South Asia.",
             rule: .region("south-asia", 6), tint: "saffron"),
        Visa(id: "middle-east", title: "Levantine Passage",
             subtitle: "Six plates from the Middle East and Caucasus.",
             rule: .region("middle-east", 6), tint: "plum"),
    ]

    private static let regionVisasTwo: [Visa] = [
        Visa(id: "africa", title: "Continental Entry",
             subtitle: "Six plates from Africa.",
             rule: .region("africa", 6), tint: "rust"),
        Visa(id: "med-europe", title: "Mediterranean Entry",
             subtitle: "Six plates from southern Europe.",
             rule: .region("med-europe", 6), tint: "crimson"),
        Visa(id: "north-europe", title: "Northern Entry",
             subtitle: "Six plates from northern and eastern Europe.",
             rule: .region("north-europe", 6), tint: "jade"),
        Visa(id: "americas", title: "New World Entry",
             subtitle: "Six plates from the Americas.",
             rule: .region("americas", 6), tint: "amber"),
    ]

    private static let themeVisas: [Visa] = [
        Visa(id: "street", title: "Vendor's Pass",
             subtitle: "Ten dishes cooked in the open, for people standing up.",
             rule: .tag("street", 10), tint: "ochre"),
        Visa(id: "noodle", title: "The Noodle Road",
             subtitle: "Six dishes built on a strand of dough.",
             rule: .tag("noodle", 6), tint: "umber"),
        Visa(id: "bread", title: "Bread Basket",
             subtitle: "Eight dishes that begin with flour and a hot surface.",
             rule: .tag("bread", 8), tint: "ochre"),
        Visa(id: "rice", title: "The Rice Belt",
             subtitle: "Ten dishes standing on a grain.",
             rule: .tag("rice", 10), tint: "cream"),
    ]

    private static let themeVisasTwo: [Visa] = [
        Visa(id: "ferment", title: "Crock and Jar",
             subtitle: "Six dishes that needed salt and time before heat.",
             rule: .tag("fermented", 6), tint: "jade"),
        Visa(id: "chili", title: "The Chili Trail",
             subtitle: "Twelve dishes that carry real heat.",
             rule: .tag("chili", 12), tint: "crimson"),
        Visa(id: "sweet", title: "Sweet Tooth",
             subtitle: "Ten sweets, from four continents if you can manage it.",
             rule: .tag("sweet", 10), tint: "blush"),
        Visa(id: "sea", title: "Sea Harvest",
             subtitle: "Ten plates that came out of salt water.",
             rule: .tag("seafood", 10), tint: "jade"),
    ]

    private static let themeVisasThree: [Visa] = [
        Visa(id: "fire", title: "Fire and Smoke",
             subtitle: "Ten dishes finished over open heat.",
             rule: .tag("grilled", 10), tint: "rust"),
        Visa(id: "slowpot", title: "The Slow Pot",
             subtitle: "Ten dishes that were left alone for hours.",
             rule: .tag("braised", 10), tint: "umber"),
        Visa(id: "breakfast", title: "First Meal",
             subtitle: "Ten ways the world starts the day.",
             rule: .tag("breakfast", 10), tint: "saffron"),
        Visa(id: "feast", title: "Feast Day",
             subtitle: "Twenty dishes reserved for an occasion.",
             rule: .tag("feast", 20), tint: "plum"),
    ]

    static let visas: [Visa] =
        regionVisas + regionVisasTwo + themeVisas + themeVisasTwo + themeVisasThree

    // MARK: - Ranks

    static let ranks: [Rank] = [
        Rank(title: "Armchair Traveller", stamps: 0,
             note: "The book is new and the pages are empty."),
        Rank(title: "Day Tripper", stamps: 6,
             note: "Far enough from home to notice the difference."),
        Rank(title: "Border Crosser", stamps: 16,
             note: "More than one kitchen now looks familiar."),
        Rank(title: "Frequent Flyer", stamps: 32,
             note: "You order without reading the whole menu."),
        Rank(title: "Seasoned Voyager", stamps: 54,
             note: "You can taste where a dish sits on a map."),
        Rank(title: "Old Hand", stamps: 82,
             note: "You know which stall has the queue for a reason."),
        Rank(title: "Grand Tourist", stamps: 120,
             note: "The passport needs a second volume."),
        Rank(title: "Circumnavigator", stamps: 164,
             note: "There is very little left you have not put in your mouth."),
    ]

    static func rank(forStamps n: Int) -> Rank {
        var found = ranks[0]
        for r in ranks where n >= r.stamps { found = r }
        return found
    }

    static func nextRank(forStamps n: Int) -> Rank? {
        ranks.first { $0.stamps > n }
    }

    // MARK: - Awards

    private static let awardsFirst: [Award] = [
        Award(id: "first-stamp", title: "First Impression",
              detail: "Strike your first stamp.", rule: .stamps(1)),
        Award(id: "ten-stamps", title: "Ten Plates In",
              detail: "Ten stamps in the book.", rule: .stamps(10)),
        Award(id: "forty-stamps", title: "Well Travelled",
              detail: "Forty stamps in the book.", rule: .stamps(40)),
        Award(id: "hundred-stamps", title: "The Century",
              detail: "One hundred stamps in the book.", rule: .stamps(100)),
        Award(id: "all-stamps", title: "Nothing Left Untried",
              detail: "Every dish in the passport, stamped.", rule: .stamps(192)),
        Award(id: "five-countries", title: "Five Borders",
              detail: "Taste something from five different countries.", rule: .countries(5)),
    ]

    private static let awardsSecond: [Award] = [
        Award(id: "fifteen-countries", title: "Fifteen Borders",
              detail: "Taste something from fifteen different countries.", rule: .countries(15)),
        Award(id: "all-countries", title: "Every Flag",
              detail: "At least one plate from all twenty-four countries.", rule: .countries(24)),
        Award(id: "four-regions", title: "Four Quarters",
              detail: "Stamps from four different regions.", rule: .regions(4)),
        Award(id: "all-regions", title: "The Whole Atlas",
              detail: "Stamps from all eight regions.", rule: .regions(8)),
        Award(id: "one-complete", title: "Cleaned the Plate",
              detail: "Stamp every dish of one country.", rule: .completeCountries(1)),
        Award(id: "five-complete", title: "Five Kitchens Mastered",
              detail: "Stamp every dish of five countries.", rule: .completeCountries(5)),
    ]

    private static let awardsThird: [Award] = [
        Award(id: "first-visa", title: "Papers in Order",
              detail: "Have your first visa issued.", rule: .visas(1)),
        Award(id: "eight-visas", title: "A Thick Passport",
              detail: "Eight visas issued.", rule: .visas(8)),
        Award(id: "all-visas", title: "Full Documentation",
              detail: "All twenty visas issued.", rule: .visas(20)),
        Award(id: "chili-hand", title: "Asbestos Palate",
              detail: "Fifteen dishes that carry real heat.", rule: .tag("chili", 15)),
        Award(id: "sweet-hand", title: "Pudding Course",
              detail: "Fifteen sweets.", rule: .tag("sweet", 15)),
        Award(id: "veg-hand", title: "Green Passport",
              detail: "Twenty vegetarian dishes.", rule: .tag("vegetarian", 20)),
    ]

    private static let awardsFourth: [Award] = [
        Award(id: "notes-ten", title: "The Diarist",
              detail: "Write a note on ten entries.", rule: .notes(10)),
        Award(id: "notes-forty", title: "The Chronicler",
              detail: "Write a note on forty entries.", rule: .notes(40)),
        Award(id: "guides-six", title: "Read the Handbook",
              detail: "Read six chapters of the handbook.", rule: .guidesRead(6)),
        Award(id: "guides-all", title: "Handbook Finished",
              detail: "Read all twelve chapters.", rule: .guidesRead(12)),
        Award(id: "quiz-eight", title: "Knows the Map",
              detail: "Score eight or better in the customs quiz.", rule: .quizScore(8)),
        Award(id: "quiz-perfect", title: "Nothing to Declare",
              detail: "A perfect ten in the customs quiz.", rule: .quizScore(10)),
    ]

    private static let awardsFifth: [Award] = [
        Award(id: "one-day-three", title: "A Long Lunch",
              detail: "Three stamps carrying the same date.", rule: .oneDay(3)),
        Award(id: "one-day-six", title: "The Crawl",
              detail: "Six stamps carrying the same date.", rule: .oneDay(6)),
        Award(id: "taste-three", title: "Broad Palate",
              detail: "Reach the top of three taste axes.", rule: .tasteBreadth(3)),
        Award(id: "taste-six", title: "The Complete Tongue",
              detail: "Reach the top of all six taste axes.", rule: .tasteBreadth(6)),
    ]

    static let awards: [Award] =
        awardsFirst + awardsSecond + awardsThird + awardsFourth + awardsFifth

    // MARK: - Tags

    static let tagNames: [String: String] = [
        "street": "Street", "home": "Everyday", "feast": "Feast", "breakfast": "Breakfast",
        "sweet": "Sweet", "noodle": "Noodle", "rice": "Rice", "bread": "Bread",
        "fermented": "Fermented", "grilled": "Grilled", "braised": "Braised",
        "fried": "Fried", "raw": "Raw", "seafood": "Seafood", "vegetarian": "Vegetarian",
        "soup": "Soup", "snack": "Snack", "dumpling": "Dumpling", "chili": "Chili",
        "dairy": "Dairy",
    ]

    static func tagName(_ tag: String) -> String { tagNames[tag] ?? tag.capitalized }

    /// The tags worth offering as filters, in a sensible reading order.
    static let filterTags: [String] = [
        "street", "home", "feast", "breakfast", "sweet", "vegetarian", "seafood",
        "noodle", "rice", "bread", "soup", "dumpling", "grilled", "braised", "fried",
        "fermented", "chili", "raw", "dairy", "snack",
    ]
}
