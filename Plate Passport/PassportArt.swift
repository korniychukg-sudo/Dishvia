import SwiftUI

/// The plates live in a folder reference, so `UIImage(named:)` never sees them —
/// they have to be found by path and cached.
enum Plates {

    private static var cache = NSCache<NSString, UIImage>()

    static func image(_ folder: String, _ name: String) -> UIImage? {
        let key = "\(folder)/\(name)" as NSString
        if let hit = cache.object(forKey: key) { return hit }
        guard let path = Bundle.main.path(forResource: name, ofType: "jpg",
                                          inDirectory: "Art/\(folder)"),
              let img = UIImage(contentsOfFile: path) else { return nil }
        cache.setObject(img, forKey: key)
        return img
    }

    static func dish(_ id: String) -> UIImage? { image("dish", id) }
    static func cuisine(_ id: String) -> UIImage? { image("cuisine", id) }
    static func visa(_ id: String) -> UIImage? { image("visa", id) }
    static func guide(_ id: String) -> UIImage? { image("guide", id) }
    static func paper(_ name: String) -> UIImage? { image("paper", name) }

    static func flush() { cache.removeAllObjects() }
}

/// A plate drawn into a fixed frame. Both dimensions are always constrained, so
/// an aspect-filled image can never inflate the layout around it.
struct PlateImage: View {
    let folder: String
    let name: String
    var corner: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            Group {
                if let img = Plates.image(folder, name) {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Book.paperDeep
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Book.ink.opacity(0.16), lineWidth: 1)
        )
    }
}

/// A full-bleed paper backdrop. Wrapped in a layout-neutral container so the
/// aspect-filled image cannot widen its parent.
struct PaperBackdrop: View {
    var name: String = "page0"
    var tint: Double = 1.0

    var body: some View {
        Color.clear
            .overlay(
                Group {
                    if let img = Plates.paper(name) {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .opacity(tint)
                    } else {
                        Book.paper
                    }
                }
            )
            .clipped()
            .background(Book.paper)
            .ignoresSafeArea()
    }
}
