import Foundation

/// Deterministic noise, so a stamp looks the same every time it is drawn and a
/// quiz round can be replayed from its seed.
struct Roll {
    private var state: UInt64
    init(_ seed: UInt64) { state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return state
    }
    mutating func unit() -> Double { Double(next() % 1_000_000) / 1_000_000.0 }
    mutating func between(_ a: Double, _ b: Double) -> Double { a + unit() * (b - a) }
    mutating func signed() -> Double { unit() * 2 - 1 }
    mutating func int(_ a: Int, _ b: Int) -> Int { a + Int(next() % UInt64(max(1, b - a + 1))) }
    mutating func chance(_ p: Double) -> Bool { unit() < p }
}

func seedValue(_ text: String) -> UInt64 {
    var h: UInt64 = 14_695_981_039_346_656_037
    for b in text.utf8 { h = (h ^ UInt64(b)) &* 1_099_511_628_211 }
    return h
}

// What the passport knows about the world: eight regions, twenty-four kitchens,
// one hundred and ninety-two dishes, and the six axes every dish is scored on.

struct Taste: Codable, Equatable {
    var heat: Int
    var sour: Int
    var sweet: Int
    var savour: Int
    var herbal: Int
    var rich: Int

    static let axisNames = ["Heat", "Sour", "Sweet", "Savour", "Herbal", "Rich"]
    static let zero = Taste(heat: 0, sour: 0, sweet: 0, savour: 0, herbal: 0, rich: 0)

    var values: [Int] { [heat, sour, sweet, savour, herbal, rich] }

    /// How far apart two plates taste. Used to suggest what to try next.
    func distance(to other: Taste) -> Double {
        var sum = 0.0
        for (a, b) in zip(values, other.values) {
            sum += Double((a - b) * (a - b))
        }
        return sum.squareRoot()
    }
}

struct Region: Identifiable {
    let id: String
    let name: String
    let note: String
}

struct Cuisine: Identifiable {
    let id: String
    let regionID: String
    let country: String
    let adjective: String
    let tagline: String
    let summary: String
    let staples: [String]
    let techniques: [String]
    let flavourBase: String
    let stampInk: String
    let stampShape: String
    let stampMotif: String
}

struct Dish: Identifiable {
    let id: String
    let cuisineID: String
    let name: String
    let nativeName: String
    let summary: String
    let tasteNote: String
    let eaten: String
    let ingredients: [String]
    let tags: [String]
    let profile: Taste
    let palette: String
}

// MARK: - Visas

/// What a visa asks of you before it will be issued.
enum VisaRule {
    case region(String, Int)      // n stamps anywhere in a region
    case tag(String, Int)         // n stamps carrying a tag
    case countries(Int)           // n different countries touched
    case complete(Int)            // n countries stamped in full
    case total(Int)               // n stamps altogether
}

struct Visa: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let rule: VisaRule
    let tint: String

    var requirement: Int {
        switch rule {
        case .region(_, let n), .tag(_, let n), .countries(let n),
             .complete(let n), .total(let n):
            return n
        }
    }
}

// MARK: - Progress

struct Rank {
    let title: String
    let stamps: Int
    let note: String
}

enum AwardRule {
    case stamps(Int)
    case countries(Int)
    case regions(Int)
    case completeCountries(Int)
    case visas(Int)
    case tag(String, Int)
    case notes(Int)
    case guidesRead(Int)
    case quizScore(Int)
    case oneDay(Int)            // n stamps carrying the same date
    case tasteBreadth(Int)      // n of the six axes reaching 3
}

struct Award: Identifiable {
    let id: String
    let title: String
    let detail: String
    let rule: AwardRule
}

// MARK: - Learning

struct Guide: Identifiable {
    let id: String
    let title: String
    let standfirst: String
    let paragraphs: [String]
}

struct Term: Identifiable {
    let id: String
    let word: String
    let meaning: String
}

// MARK: - Saved state

struct StampRecord: Codable, Identifiable, Equatable {
    var dishID: String
    var day: Int              // days since the epoch, so a stamp belongs to a date
    var rating: Int           // 0 = unrated, 1...3 forks
    var note: String
    var place: String
    var seed: UInt64          // fixes the ink spatter and the angle for good

    var id: String { dishID }

    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(day) * 86_400)
    }
}

struct PassportSettings: Codable {
    var sound: Bool = true
    var haptics: Bool = true
    var showNativeNames: Bool = true
}

struct SaveFile: Codable {
    var stamps: [StampRecord] = []
    var wishlist: [String] = []
    var visasIssued: [String] = []
    var awardsEarned: [String] = []
    var guidesRead: [String] = []
    var quizBest: Int = 0
    var quizRounds: Int = 0
    var onboarded: Bool = false
    var settings = PassportSettings()

    init() {}

    // Tolerant decoding, so a save written before a field existed still loads.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stamps = (try? c.decode([StampRecord].self, forKey: .stamps)) ?? []
        wishlist = (try? c.decode([String].self, forKey: .wishlist)) ?? []
        visasIssued = (try? c.decode([String].self, forKey: .visasIssued)) ?? []
        awardsEarned = (try? c.decode([String].self, forKey: .awardsEarned)) ?? []
        guidesRead = (try? c.decode([String].self, forKey: .guidesRead)) ?? []
        quizBest = (try? c.decode(Int.self, forKey: .quizBest)) ?? 0
        quizRounds = (try? c.decode(Int.self, forKey: .quizRounds)) ?? 0
        onboarded = (try? c.decode(Bool.self, forKey: .onboarded)) ?? false
        settings = (try? c.decode(PassportSettings.self, forKey: .settings)) ?? PassportSettings()
    }
}

// MARK: - Dates

enum DayNumber {
    static func today() -> Int {
        Int(Date().timeIntervalSince1970 / 86_400)
    }

    static func date(_ day: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(day) * 86_400)
    }

    static let stampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "dd MMM yyyy"
        return f
    }()

    static let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "d MMM"
        return f
    }()

    static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    static func stampText(_ day: Int) -> String {
        stampFormatter.string(from: date(day)).uppercased()
    }
}
