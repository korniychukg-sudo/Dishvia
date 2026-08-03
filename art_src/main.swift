import Foundation
import CoreGraphics

// Renders every plate in the app. Usage:
//   platepassport-art <content-dir> <output-Art-dir> [only]

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("usage: art <content-dir> <out-dir> [only]\n".data(using: .utf8)!)
    exit(2)
}
let contentDir = args[1]
let outDir = args[2]
let only = args.count > 3 ? args[3] : ""

let fm = FileManager.default
for sub in ["dish", "cuisine", "visa", "guide", "paper"] {
    try? fm.createDirectory(atPath: outDir + "/" + sub, withIntermediateDirectories: true)
}

func shouldRun(_ tag: String) -> Bool { only.isEmpty || only == tag }

// MARK: - Load the authored content

let regionFiles = ["east-asia", "southeast-asia", "south-asia", "middle-east",
                   "africa", "med-europe", "north-europe", "americas"]

struct Loaded {
    var cuisineID: String
    var specs: [DishSpec]
}

var loaded: [Loaded] = []
var allSpecs: [DishSpec] = []

for rf in regionFiles {
    let url = URL(fileURLWithPath: contentDir + "/" + rf + ".json")
    guard let data = try? Data(contentsOf: url),
          let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let cuisines = root["cuisines"] as? [[String: Any]] else {
        FileHandle.standardError.write("could not read \(rf)\n".data(using: .utf8)!)
        exit(3)
    }
    for c in cuisines {
        let cid = c["id"] as? String ?? "x"
        var specs: [DishSpec] = []
        for d in (c["dishes"] as? [[String: Any]] ?? []) {
            let pl = d["plate"] as? [String: Any] ?? [:]
            let spec = DishSpec(id: d["id"] as? String ?? "x",
                                cuisine: cid,
                                vessel: pl["vessel"] as? String ?? "plate",
                                main: pl["main"] as? String ?? "stewChunks",
                                extras: pl["extras"] as? [String] ?? [],
                                garnish: pl["garnish"] as? [String] ?? [],
                                palette: pl["palette"] as? String ?? "amber")
            specs.append(spec)
            allSpecs.append(spec)
        }
        loaded.append(Loaded(cuisineID: cid, specs: specs))
    }
}

let t0 = Date()
var written = 0

// MARK: - Dish plates

if only == "sample" {
    // One plate from a spread of vessels, for eyeballing before a full run.
    var seen = Set<String>()
    var picks: [DishSpec] = []
    for s in allSpecs where !seen.contains(s.vessel) {
        seen.insert(s.vessel); picks.append(s)
    }
    for s in picks {
        renderDishPlate(s, size: 820).write(outDir + "/dish", s.id)
        print("sample: \(s.id)  [\(s.vessel) / \(s.main)]")
    }
    print("sampled \(picks.count) vessels")
    exit(0)
}

if shouldRun("dish") {
    for spec in allSpecs {
        let p = renderDishPlate(spec, size: 820)
        p.write(outDir + "/dish", spec.id)
        written += 1
    }
    print("dish plates: \(allSpecs.count)")
}

// MARK: - Cuisine scenes

if shouldRun("cuisine") {
    for l in loaded {
        // three dishes with different vessels, so the table is not three bowls
        var picked: [DishSpec] = []
        var usedVessels = Set<String>()
        for s in l.specs where !usedVessels.contains(s.vessel) && s.vessel != "glass" {
            picked.append(s); usedVessels.insert(s.vessel)
            if picked.count == 3 { break }
        }
        while picked.count < 3, let extra = l.specs.first(where: { s in !picked.contains { $0.id == s.id } }) {
            picked.append(extra)
        }
        let p = renderCuisineScene(id: l.cuisineID, specs: picked, size: (1280, 820))
        p.write(outDir + "/cuisine", l.cuisineID)
        written += 1
    }
    print("cuisine scenes: \(loaded.count)")
}

// MARK: - Visa pages

let visas: [(String, String, Int)] = [
    ("east-asia", "indigo-jade", 11), ("southeast-asia", "herb", 9), ("south-asia", "saffron", 13),
    ("middle-east", "plum", 10), ("africa", "rust", 12), ("med-europe", "crimson", 9),
    ("north-europe", "jade", 14), ("americas", "amber", 11),
    ("street", "ochre", 8), ("noodle", "umber", 10), ("bread", "ochre", 12),
    ("rice", "cream", 9), ("ferment", "jade", 13), ("chili", "crimson", 8),
    ("sweet", "blush", 11), ("sea", "jade", 10), ("fire", "rust", 9),
    ("slowpot", "umber", 12), ("breakfast", "saffron", 10), ("feast", "plum", 13),
]

if shouldRun("visa") {
    for (id, tint, petals) in visas {
        let key = tint == "indigo-jade" ? "jade" : tint
        let p = renderVisaPlate(id: id, tint: key, petals: petals, size: (980, 620))
        p.write(outDir + "/visa", id)
        written += 1
    }
    print("visa plates: \(visas.count)")
}

// MARK: - Guide boards

let boardGuides: [(String, [String], [String])] = [
    ("bread", ["flatbread", "loafSlices", "pancakeStack", "pastryTart"], ["ochre", "cream", "amber", "rust"]),
    ("noodles", ["noodleNest", "dumplings", "springRolls"], ["amber", "cream", "ochre"]),
    ("fermentation", ["pickleFan", "cubes", "porridge"], ["jade", "cream", "umber"]),
    ("rice", ["riceMound", "riceScatter", "rollSlices"], ["cream", "saffron", "jade"]),
    ("fire", ["grillMarks", "skewers", "meatSlab"], ["char", "rust", "crimson"]),
    ("slow-pot", ["stewChunks", "curryPool", "dropBalls"], ["umber", "saffron", "rust"]),
    ("street", ["friedPieces", "tacoFolds", "wrappedParcel"], ["ochre", "amber", "cream"]),
    ("tea-coffee", ["brothSurface", "scoop", "dropBalls"], ["umber", "cream", "char"]),
    ("five-tastes", ["pickleFan", "dropBalls", "cubes", "scoop", "curryPool"],
     ["jade", "amber", "cream", "blush", "crimson"]),
]
let routeGuides = ["spice-routes", "chili", "feast-days"]

if shouldRun("guide") {
    for (id, items, pals) in boardGuides {
        let p = renderGuideBoard(id: id, items: items, palettes: pals, size: (1180, 740))
        p.write(outDir + "/guide", id)
        written += 1
    }
    for id in routeGuides {
        let p = renderRouteMap(id: id, size: (1180, 740))
        p.write(outDir + "/guide", id)
        written += 1
    }
    print("guide plates: \(boardGuides.count + routeGuides.count)")
}

// MARK: - Passport paper and cover

if shouldRun("paper") {
    for i in 0..<4 {
        let p = renderPassportPage(index: i, size: (900, 1250))
        p.write(outDir + "/paper", "page\(i)")
        written += 1
    }
    let cover = renderCover(size: (900, 1250))
    cover.write(outDir + "/paper", "cover")
    written += 1
    let endpaper = renderPassportPage(index: 5, size: (900, 1250))
    endpaper.write(outDir + "/paper", "endpaper")
    written += 1
    print("paper: 6")
}

print(String(format: "wrote %d plates in %.1fs", written, Date().timeIntervalSince(t0)))
