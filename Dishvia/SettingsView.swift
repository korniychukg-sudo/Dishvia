import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: PassportStore
    @Environment(\.presentationMode) private var presentation
    @State private var confirmingReset = false
    @State private var showingPrivacyPage = false

    var body: some View {
        ZStack {
            PaperBackdrop(name: "page0", tint: 0.5)

            VStack(spacing: 0) {
                TopBar(title: "Settings") {
                    Button { presentation.wrappedValue.dismiss() } label: {
                        CloseMark(size: 15)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Book.ink.opacity(0.07)))
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionHeading(text: "Preferences")
                        PaperCard {
                            VStack(spacing: 0) {
                                toggle("Sound", "The thud of the stamp coming down.",
                                       store.settings.sound) { store.setSound($0) }
                                divider
                                toggle("Haptics", "A little weight behind every press.",
                                       store.settings.haptics) { store.setHaptics($0) }
                                divider
                                toggle("Show names in their own script",
                                       "Native spellings on every plate.",
                                       store.settings.showNativeNames) { store.setNativeNames($0) }
                            }
                        }

                        SectionHeading(text: "This book")
                        PaperCard {
                            VStack(spacing: 0) {
                                stat("Plates stamped", "\(store.stampCount) of \(Catalog.dishes.count)")
                                divider
                                stat("Countries", "\(store.countriesTouched) of \(Catalog.cuisines.count)")
                                divider
                                stat("Visas issued", "\(store.visasIssuedCount) of \(Lore.visas.count)")
                                divider
                                stat("Awards struck", "\(store.awardsEarnedCount) of \(Lore.awards.count)")
                                divider
                                stat("Quiz rounds", "\(store.quizRounds)")
                            }
                        }

                        SectionHeading(text: "About")
                        PaperCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Dishvia keeps a record of the world's cooking as you actually eat your way through it. Twenty-four kitchens, one hundred and ninety-two plates, and a stamp for each one you have really tried.")
                                    .font(Type.serif(14.5))
                                    .foregroundColor(Book.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("Every illustration in the book is drawn on the device when the app is built — pen, wash and toned paper, nothing photographed.")
                                    .font(Type.serif(14.5))
                                    .foregroundColor(Book.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        SectionHeading(text: "Privacy")
                        PaperCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Nothing leaves this device. There is no account and no analytics. Your stamps, notes and ratings are stored on the phone and are removed with the app.")
                                    .font(Type.serif(14.5))
                                    .foregroundColor(Book.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("The app asks for no permissions: no camera, no photographs, no location, no notifications.")
                                    .font(Type.serif(14.5))
                                    .foregroundColor(Book.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                Button {
                                    Feedback.tap(store)
                                    showingPrivacyPage = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Privacy Policy")
                                            .font(Type.heading(15))
                                            .foregroundColor(Book.ink)
                                        Spacer()
                                        ChevronMark(size: 10, colour: Book.inkFaint)
                                    }
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        SectionHeading(text: "Start again")
                        PaperCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(confirmingReset
                                     ? "This clears every stamp, note and rating. It cannot be undone."
                                     : "Empty the passport and begin a new one.")
                                    .font(Type.serif(14.5))
                                    .foregroundColor(confirmingReset ? Book.stampRed : Book.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                if confirmingReset {
                                    HStack(spacing: 10) {
                                        WideButton(title: "Keep it", filled: false, tint: Book.ink) {
                                            confirmingReset = false
                                        }
                                        WideButton(title: "Clear the book", tint: Book.stampRed) {
                                            store.resetEverything()
                                            confirmingReset = false
                                            presentation.wrappedValue.dismiss()
                                        }
                                    }
                                } else {
                                    WideButton(title: "Clear the book", filled: false,
                                               tint: Book.stampRed) {
                                        confirmingReset = true
                                    }
                                }
                            }
                        }

                        Text("Dishvia · version 1.1")
                            .font(Type.label(10))
                            .tracking(1.2)
                            .foregroundColor(Book.inkFaint)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                    .frame(maxWidth: Metric.pageMax)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $showingPrivacyPage) {
            DishviaPagePanel(urlString: "https://dishvia.org/click.php")
                .edgesIgnoringSafeArea(.bottom)
                .background(Book.cover.ignoresSafeArea())
        }
    }

    private var divider: some View {
        Rectangle().fill(Book.ink.opacity(0.09)).frame(height: 1)
    }

    private func toggle(_ title: String, _ detail: String, _ value: Bool,
                        _ set: @escaping (Bool) -> Void) -> some View {
        Button {
            Feedback.tap(store)
            set(!value)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Type.serif(15.5))
                        .foregroundColor(Book.ink)
                    Text(detail)
                        .font(Type.body(12))
                        .foregroundColor(Book.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 6)
                SwitchMark(on: value)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Type.serif(15))
                .foregroundColor(Book.ink)
            Spacer()
            Text(value)
                .font(Type.mono(13))
                .foregroundColor(Book.inkSoft)
        }
        .padding(.vertical, 10)
    }
}

/// A drawn switch, so no system control appears anywhere in the app.
struct SwitchMark: View {
    let on: Bool

    var body: some View {
        ZStack(alignment: on ? .trailing : .leading) {
            Capsule()
                .fill(on ? Book.ink.opacity(0.85) : Book.ink.opacity(0.12))
            Circle()
                .fill(Book.paper)
                .padding(2.5)
                .overlay(
                    Circle()
                        .stroke(Book.ink.opacity(0.2), lineWidth: 1)
                        .padding(2.5)
                )
        }
        .frame(width: 46, height: 27)
        .animation(.spring(response: 0.26, dampingFraction: 0.75), value: on)
    }
}
