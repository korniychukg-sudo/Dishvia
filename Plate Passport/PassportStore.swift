import SwiftUI
import Combine

/// Everything the passport remembers, and everything it works out from that.
final class PassportStore: ObservableObject {

    @Published private(set) var save = SaveFile()
    /// Visas and awards earned since the last screen the user looked at.
    @Published var pendingNews: [NewsItem] = []

    struct NewsItem: Identifiable, Equatable {
        let id: String
        let kind: String        // "visa" or "award"
        let title: String
        let detail: String
    }

    private let key = "plate.passport.save.v1"

    init() {
        load()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(SaveFile.self, from: data) else { return }
        save = decoded
    }

    func persist() {
        guard let data = try? JSONEncoder().encode(save) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func resetEverything() {
        save = SaveFile()
        save.onboarded = true
        persist()
        objectWillChange.send()
    }

    // MARK: - Settings and onboarding

    var settings: PassportSettings { save.settings }

    func markOnboarded() {
        save.onboarded = true
        persist()
    }

    func setSound(_ on: Bool) { save.settings.sound = on; persist() }
    func setHaptics(_ on: Bool) { save.settings.haptics = on; persist() }
    func setNativeNames(_ on: Bool) { save.settings.showNativeNames = on; persist() }

    // MARK: - Stamps

    private(set) var stampIndex: [String: StampRecord] = [:]

    func stamp(for dishID: String) -> StampRecord? {
        save.stamps.first { $0.dishID == dishID }
    }

    func isStamped(_ dishID: String) -> Bool {
        save.stamps.contains { $0.dishID == dishID }
    }

    var stamps: [StampRecord] { save.stamps }

    var stampCount: Int { save.stamps.count }

    /// Most recent first — the order the journal reads in.
    var stampsByRecency: [StampRecord] {
        save.stamps.sorted { a, b in
            if a.day != b.day { return a.day > b.day }
            return a.dishID < b.dishID
        }
    }

    @discardableResult
    func addStamp(dishID: String, day: Int = DayNumber.today()) -> StampRecord {
        if let existing = stamp(for: dishID) { return existing }
        let record = StampRecord(dishID: dishID, day: day, rating: 0, note: "", place: "",
                                 seed: seedValue(dishID + "-\(day)"))
        save.stamps.append(record)
        save.wishlist.removeAll { $0 == dishID }   // eaten — off the list
        persist()
        collectNews()
        return record
    }

    // MARK: - Want-to-try list

    func isWished(_ dishID: String) -> Bool { save.wishlist.contains(dishID) }

    func toggleWish(_ dishID: String) {
        if let i = save.wishlist.firstIndex(of: dishID) {
            save.wishlist.remove(at: i)
        } else if !isStamped(dishID) {
            save.wishlist.append(dishID)
        }
        persist()
    }

    var wishlistDishes: [Dish] {
        save.wishlist.compactMap { Catalog.dishByID[$0] }
    }

    var wishCount: Int { save.wishlist.count }

    // MARK: - Palate match

    /// How close a cuisine's average plate sits to your own palate, 0-100.
    /// Meaningless until a few stamps exist, so nil below five.
    func palateMatch(cuisineID: String) -> Int? {
        guard stampCount >= 5,
              let dishes = Catalog.dishesByCuisine[cuisineID], !dishes.isEmpty else { return nil }
        let mine = palate
        var avg = [Double](repeating: 0, count: 6)
        for d in dishes {
            for (i, v) in d.profile.values.enumerated() { avg[i] += Double(v) }
        }
        avg = avg.map { $0 / Double(dishes.count) }
        var dist = 0.0
        for (a, b) in zip(mine, avg) { dist += (a - b) * (a - b) }
        // maximum possible distance on six 0-3 axes
        let worst = (Double(6) * 9.0).squareRoot()
        let score = 100.0 * (1.0 - dist.squareRoot() / worst)
        return Int(score.rounded())
    }

    /// The three kitchens whose average table best fits the palate so far.
    var bestMatchedCuisines: [(cuisine: Cuisine, match: Int)] {
        guard stampCount >= 5 else { return [] }
        return Catalog.cuisines
            .compactMap { c in palateMatch(cuisineID: c.id).map { (c, $0) } }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { ($0.0, $0.1) }
    }

    /// The visas a stamp on this dish would advance — shown after the strike.
    func visasAdvanced(by dishID: String) -> [(visa: Visa, remaining: Int)] {
        guard let dish = Catalog.dishByID[dishID],
              let cuisine = Catalog.cuisineByID[dish.cuisineID] else { return [] }
        return Lore.visas.compactMap { visa in
            let counts: Bool
            switch visa.rule {
            case .region(let id, _): counts = cuisine.regionID == id
            case .tag(let tag, _):   counts = dish.tags.contains(tag)
            default:                 counts = true
            }
            guard counts, !isIssued(visa) else { return nil }
            return (visa, max(0, visa.requirement - progress(for: visa)))
        }
        .sorted { $0.remaining < $1.remaining }
    }

    func updateStamp(dishID: String, rating: Int? = nil, note: String? = nil, place: String? = nil) {
        guard let i = save.stamps.firstIndex(where: { $0.dishID == dishID }) else { return }
        if let rating = rating { save.stamps[i].rating = rating }
        if let note = note { save.stamps[i].note = note }
        if let place = place { save.stamps[i].place = place }
        persist()
        collectNews()
    }

    func removeStamp(dishID: String) {
        save.stamps.removeAll { $0.dishID == dishID }
        persist()
    }

    // MARK: - Counting

    func stampCount(inRegion regionID: String) -> Int {
        let ids = Set((Catalog.cuisinesByRegion[regionID] ?? []).map { $0.id })
        return save.stamps.filter { rec in
            guard let d = Catalog.dishByID[rec.dishID] else { return false }
            return ids.contains(d.cuisineID)
        }.count
    }

    func stampCount(inCuisine cuisineID: String) -> Int {
        save.stamps.filter { Catalog.dishByID[$0.dishID]?.cuisineID == cuisineID }.count
    }

    func stampCount(withTag tag: String) -> Int {
        save.stamps.filter { Catalog.dishByID[$0.dishID]?.tags.contains(tag) ?? false }.count
    }

    var countriesTouched: Int {
        Set(save.stamps.compactMap { Catalog.dishByID[$0.dishID]?.cuisineID }).count
    }

    var regionsTouched: Int {
        let cuisines = Set(save.stamps.compactMap { Catalog.dishByID[$0.dishID]?.cuisineID })
        return Set(cuisines.compactMap { Catalog.cuisineByID[$0]?.regionID }).count
    }

    var countriesCompleted: Int {
        Catalog.cuisines.filter { c in
            let total = Catalog.dishesByCuisine[c.id]?.count ?? 0
            return total > 0 && stampCount(inCuisine: c.id) == total
        }.count
    }

    func isComplete(cuisineID: String) -> Bool {
        let total = Catalog.dishesByCuisine[cuisineID]?.count ?? 0
        return total > 0 && stampCount(inCuisine: cuisineID) == total
    }

    // MARK: - Palate

    /// The average of everything stamped, on each of the six axes.
    var palate: [Double] {
        guard !save.stamps.isEmpty else { return [0, 0, 0, 0, 0, 0] }
        var sums = [Double](repeating: 0, count: 6)
        var n = 0.0
        for rec in save.stamps {
            guard let d = Catalog.dishByID[rec.dishID] else { continue }
            for (i, v) in d.profile.values.enumerated() { sums[i] += Double(v) }
            n += 1
        }
        guard n > 0 else { return sums }
        return sums.map { $0 / n }
    }

    /// The strongest single plate on each axis — what the palate has actually reached.
    var reach: [Int] {
        var top = [Int](repeating: 0, count: 6)
        for rec in save.stamps {
            guard let d = Catalog.dishByID[rec.dishID] else { continue }
            for (i, v) in d.profile.values.enumerated() { top[i] = max(top[i], v) }
        }
        return top
    }

    /// A dish unlike anything stamped so far, for the "try next" prompt.
    var stretchSuggestion: Dish? {
        let stamped = Set(save.stamps.map { $0.dishID })
        let remaining = Catalog.dishes.filter { !stamped.contains($0.id) }
        guard !remaining.isEmpty else { return nil }
        guard !save.stamps.isEmpty else { return remaining.first }
        let mine = palate
        let target = Taste(heat: Int(mine[0].rounded()), sour: Int(mine[1].rounded()),
                           sweet: Int(mine[2].rounded()), savour: Int(mine[3].rounded()),
                           herbal: Int(mine[4].rounded()), rich: Int(mine[5].rounded()))
        return remaining.max { a, b in
            a.profile.distance(to: target) < b.profile.distance(to: target)
        }
    }

    // MARK: - Dish of the day

    var dishOfTheDay: Dish {
        let day = DayNumber.today()
        var roll = Roll(seedValue("plate-of-the-day-\(day)"))
        let index = Int(roll.next() % UInt64(max(1, Catalog.dishes.count)))
        return Catalog.dishes[index]
    }

    // MARK: - Visas

    func progress(for visa: Visa) -> Int {
        switch visa.rule {
        case .region(let id, _):     return stampCount(inRegion: id)
        case .tag(let tag, _):       return stampCount(withTag: tag)
        case .countries:             return countriesTouched
        case .complete:              return countriesCompleted
        case .total:                 return stampCount
        }
    }

    func isIssued(_ visa: Visa) -> Bool {
        progress(for: visa) >= visa.requirement
    }

    var visasIssuedCount: Int { Lore.visas.filter { isIssued($0) }.count }

    // MARK: - Awards

    func isEarned(_ award: Award) -> Bool {
        switch award.rule {
        case .stamps(let n):            return stampCount >= n
        case .countries(let n):         return countriesTouched >= n
        case .regions(let n):           return regionsTouched >= n
        case .completeCountries(let n): return countriesCompleted >= n
        case .visas(let n):             return visasIssuedCount >= n
        case .tag(let tag, let n):      return stampCount(withTag: tag) >= n
        case .notes(let n):             return save.stamps.filter { !$0.note.isEmpty }.count >= n
        case .guidesRead(let n):        return save.guidesRead.count >= n
        case .quizScore(let n):         return save.quizBest >= n
        case .oneDay(let n):
            var byDay: [Int: Int] = [:]
            for s in save.stamps { byDay[s.day, default: 0] += 1 }
            return (byDay.values.max() ?? 0) >= n
        case .tasteBreadth(let n):      return reach.filter { $0 >= 3 }.count >= n
        }
    }

    var awardsEarnedCount: Int { Lore.awards.filter { isEarned($0) }.count }

    // MARK: - News

    /// Works out what has just been earned and queues it for a banner.
    private func collectNews() {
        var fresh: [NewsItem] = []

        for visa in Lore.visas where isIssued(visa) && !save.visasIssued.contains(visa.id) {
            save.visasIssued.append(visa.id)
            fresh.append(NewsItem(id: "visa-" + visa.id, kind: "visa",
                                  title: visa.title, detail: "Visa issued"))
        }
        for award in Lore.awards where isEarned(award) && !save.awardsEarned.contains(award.id) {
            save.awardsEarned.append(award.id)
            fresh.append(NewsItem(id: "award-" + award.id, kind: "award",
                                  title: award.title, detail: award.detail))
        }
        if !fresh.isEmpty {
            persist()
            pendingNews.append(contentsOf: fresh)
        }
    }

    func clearNews() { pendingNews.removeAll() }

    /// Called once at launch so a save made before an award existed still counts.
    func reconcileOnLaunch() {
        for visa in Lore.visas where isIssued(visa) && !save.visasIssued.contains(visa.id) {
            save.visasIssued.append(visa.id)
        }
        for award in Lore.awards where isEarned(award) && !save.awardsEarned.contains(award.id) {
            save.awardsEarned.append(award.id)
        }
        persist()
    }

    // MARK: - Learning

    func markGuideRead(_ id: String) {
        guard !save.guidesRead.contains(id) else { return }
        save.guidesRead.append(id)
        persist()
        collectNews()
    }

    func isGuideRead(_ id: String) -> Bool { save.guidesRead.contains(id) }

    func recordQuiz(score: Int) {
        save.quizRounds += 1
        if score > save.quizBest { save.quizBest = score }
        persist()
        collectNews()
    }

    var quizBest: Int { save.quizBest }
    var quizRounds: Int { save.quizRounds }

    // MARK: - Journal helpers

    /// Stamps grouped by the month they belong to, most recent month first.
    var stampMonths: [(label: String, days: [Int: Int])] {
        var buckets: [String: [Int: Int]] = [:]
        var order: [String] = []
        let cal = Calendar(identifier: .gregorian)
        for s in stampsByRecency {
            let date = DayNumber.date(s.day)
            let label = DayNumber.monthFormatter.string(from: date)
            if buckets[label] == nil { buckets[label] = [:]; order.append(label) }
            let dayOfMonth = cal.component(.day, from: date)
            buckets[label]?[dayOfMonth, default: 0] += 1
        }
        return order.map { ($0, buckets[$0] ?? [:]) }
    }
}
