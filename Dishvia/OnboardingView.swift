import SwiftUI

struct OnboardingView: View {
    let onDone: () -> Void
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("A passport for the world's cooking",
         "Twenty-four kitchens, one hundred and ninety-two plates. Every one drawn in pen and wash on toned paper, and every one waiting for a stamp.",
         "cover"),
        ("Eat it first. Then stamp it.",
         "Find the plate you have actually eaten, press and hold, and the country's mark comes down on the page with the date on it. Rate it, note where you were, and it is in the book for good.",
         "page1"),
        ("The book adds up",
         "Cover a region and a visa is issued. Eat your way through the street food of six countries and another one is. The journal works out the shape of your palate, and a handbook explains why any of it tastes the way it does.",
         "page2"),
    ]

    var body: some View {
        ZStack {
            PaperBackdrop(name: pages[page].2, tint: page == 0 ? 1.0 : 0.75)
            if page == 0 {
                Color.black.opacity(0.35).ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 14) {
                    Text("DISHVIA")
                        .font(Type.label(11))
                        .tracking(2.6)
                        .foregroundColor(page == 0 ? Book.gilt : Book.inkFaint)

                    Text(pages[page].0)
                        .font(Type.title(30))
                        .foregroundColor(page == 0 ? Book.paper : Book.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(pages[page].1)
                        .font(Type.serif(16))
                        .foregroundColor(page == 0 ? Book.paper.opacity(0.85) : Book.inkSoft)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 26)
                .frame(maxWidth: 520, alignment: .leading)

                Spacer()

                HStack(spacing: 7) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? (page == 0 ? Book.gilt : Book.ink)
                                            : (page == 0 ? Book.giltSoft.opacity(0.35)
                                                         : Book.ink.opacity(0.2)))
                            .frame(width: i == page ? 20 : 7, height: 7)
                    }
                }
                .padding(.bottom, 18)

                WideButton(title: page == pages.count - 1 ? "Open the book" : "Next",
                           tint: page == 0 ? Book.gilt : Book.ink) {
                    if page == pages.count - 1 {
                        onDone()
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) { page += 1 }
                    }
                }
                .padding(.horizontal, 26)
                .frame(maxWidth: 480)
                .padding(.bottom, 12)

                Button(action: onDone) {
                    Text("Skip")
                        .font(Type.label(11))
                        .tracking(1.4)
                        .foregroundColor(page == 0 ? Book.giltSoft.opacity(0.8) : Book.inkFaint)
                }
                .buttonStyle(.plain)
                .opacity(page == pages.count - 1 ? 0 : 1)
                .padding(.bottom, 30)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    if value.translation.width < -40 && page < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.25)) { page += 1 }
                    } else if value.translation.width > 40 && page > 0 {
                        withAnimation(.easeInOut(duration: 0.25)) { page -= 1 }
                    }
                }
        )
    }
}
