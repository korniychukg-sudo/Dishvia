import SwiftUI

// One palette for the whole book: toned paper, a sepia pen, buckram and gilt,
// plus the twelve washes the plates are hand-coloured with. The app never
// follows the device theme — a passport looks the same in any light.

enum Book {
    static let paper       = Color(red: 0.941, green: 0.906, blue: 0.835)
    static let paperDeep   = Color(red: 0.898, green: 0.855, blue: 0.769)
    static let paperEdge   = Color(red: 0.824, green: 0.776, blue: 0.686)
    static let card        = Color(red: 0.965, green: 0.941, blue: 0.882)

    static let ink         = Color(red: 0.180, green: 0.129, blue: 0.086)
    static let inkSoft     = Color(red: 0.318, green: 0.259, blue: 0.196)
    static let inkFaint    = Color(red: 0.514, green: 0.455, blue: 0.384)

    static let cover       = Color(red: 0.153, green: 0.180, blue: 0.161)
    static let coverLight  = Color(red: 0.235, green: 0.271, blue: 0.243)
    static let gilt        = Color(red: 0.769, green: 0.639, blue: 0.373)
    static let giltSoft    = Color(red: 0.847, green: 0.749, blue: 0.545)

    static let stampRed    = Color(red: 0.639, green: 0.239, blue: 0.212)
    static let stampBlue   = Color(red: 0.220, green: 0.318, blue: 0.478)

    /// The washes, keyed the way the dish database names them.
    static func wash(_ key: String) -> Color {
        switch key {
        case "amber":   return Color(red: 0.804, green: 0.612, blue: 0.310)
        case "rust":    return Color(red: 0.663, green: 0.400, blue: 0.251)
        case "crimson": return Color(red: 0.647, green: 0.259, blue: 0.239)
        case "herb":    return Color(red: 0.420, green: 0.510, blue: 0.337)
        case "cream":   return Color(red: 0.760, green: 0.690, blue: 0.545)
        case "umber":   return Color(red: 0.451, green: 0.337, blue: 0.239)
        case "saffron": return Color(red: 0.812, green: 0.616, blue: 0.208)
        case "jade":    return Color(red: 0.365, green: 0.541, blue: 0.478)
        case "plum":    return Color(red: 0.478, green: 0.322, blue: 0.427)
        case "ochre":   return Color(red: 0.741, green: 0.573, blue: 0.290)
        case "char":    return Color(red: 0.302, green: 0.267, blue: 0.243)
        case "blush":   return Color(red: 0.769, green: 0.510, blue: 0.463)
        default:        return Color(red: 0.804, green: 0.612, blue: 0.310)
        }
    }

    /// The inks a country's stamp is struck in.
    static func stampInk(_ key: String) -> Color {
        switch key {
        case "indigo": return Color(red: 0.180, green: 0.259, blue: 0.435)
        case "crimson": return Color(red: 0.612, green: 0.208, blue: 0.196)
        case "olive":  return Color(red: 0.376, green: 0.400, blue: 0.239)
        case "violet": return Color(red: 0.392, green: 0.278, blue: 0.443)
        case "rust":   return Color(red: 0.612, green: 0.353, blue: 0.204)
        case "teal":   return Color(red: 0.180, green: 0.412, blue: 0.412)
        case "sepia":  return Color(red: 0.373, green: 0.278, blue: 0.192)
        case "plum":   return Color(red: 0.451, green: 0.212, blue: 0.310)
        case "forest": return Color(red: 0.196, green: 0.365, blue: 0.271)
        case "ochre":  return Color(red: 0.612, green: 0.463, blue: 0.184)
        default:       return Color(red: 0.180, green: 0.259, blue: 0.435)
        }
    }
}

enum Type {
    static func title(_ size: CGFloat = 26) -> Font { .system(size: size, weight: .semibold, design: .serif) }
    static func heading(_ size: CGFloat = 19) -> Font { .system(size: size, weight: .semibold, design: .serif) }
    static func serif(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .regular, design: .serif) }
    static func body(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .regular) }
    static func label(_ size: CGFloat = 11) -> Font { .system(size: size, weight: .semibold) }
    static func mono(_ size: CGFloat = 12) -> Font { .system(size: size, weight: .medium, design: .monospaced) }
}

enum Metric {
    static var isPad: Bool { UIScreen.main.bounds.width >= 700 }
    static var pageMax: CGFloat { isPad ? 660 : 560 }
    static var gutter: CGFloat { isPad ? 26 : 18 }
}

