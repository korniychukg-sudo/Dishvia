import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: PassportStore
    @State private var tab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Book.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case 0:
                        NavigationView { PassportView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { AtlasView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { VisasView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView { JournalView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { LearnView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                tabBar
            }

            if let news = store.pendingNews.first {
                NewsBanner(item: news) { store.clearNews() }
                    .padding(.bottom, 96)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear { Feedback.issued(store) }
            }
        }
        .animation(.easeOut(duration: 0.28), value: store.pendingNews.count)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Passport") { c in AnyView(BookIcon(size: 23, colour: c)) }
            tabButton(1, "Atlas") { c in AnyView(GlobeIcon(size: 23, colour: c)) }
            tabButton(2, "Visas") { c in AnyView(VisaIcon(size: 23, colour: c)) }
            tabButton(3, "Journal") { c in AnyView(JournalIcon(size: 23, colour: c)) }
            tabButton(4, "Handbook") { c in AnyView(HandbookIcon(size: 23, colour: c)) }
        }
        .padding(.top, 9)
        .padding(.bottom, 3)
        .background(
            Book.card
                .overlay(Rectangle().fill(Book.ink.opacity(0.14)).frame(height: 1),
                         alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ index: Int, _ label: String,
                           _ icon: @escaping (Color) -> AnyView) -> some View {
        let active = tab == index
        let colour = active ? Book.ink : Book.inkFaint.opacity(0.75)
        return Button {
            if tab != index { Feedback.tap(store) }
            tab = index
        } label: {
            VStack(spacing: 4) {
                icon(colour)
                Text(label)
                    .font(Type.label(9.5))
                    .tracking(0.5)
                    .foregroundColor(colour)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
