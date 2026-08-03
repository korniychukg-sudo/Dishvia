import SwiftUI

// The handbook that travels with the passport: twelve chapters, a glossary of
// thirty-two terms, and a customs quiz drawn from the plates themselves.

struct LearnView: View {
    @EnvironmentObject var store: PassportStore
    @State private var mode = 0
    @State private var quizRunning = false

    var body: some View {
        ZStack {
            PaperBackdrop(name: "page3", tint: 0.42)

            VStack(spacing: 0) {
                TopBar(title: "Handbook",
                       subtitle: "\(store.save.guidesRead.count) of \(Handbook.guides.count) chapters read")

                HStack(spacing: 0) {
                    ForEach(Array(["Chapters", "Glossary"].enumerated()), id: \.offset) { i, label in
                        Button {
                            Feedback.tap(store)
                            mode = i
                        } label: {
                            Text(label)
                                .font(Type.label(12))
                                .tracking(1.0)
                                .foregroundColor(mode == i ? Book.paper : Book.inkSoft)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(mode == i ? Book.ink : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Book.ink.opacity(0.07))
                )
                .padding(.horizontal, Metric.gutter)
                .padding(.top, 12)
                .frame(maxWidth: Metric.pageMax)
                .frame(maxWidth: .infinity)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if mode == 0 {
                            quizCard
                            chapterList
                        } else {
                            glossaryList
                        }
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .frame(maxWidth: Metric.pageMax)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $quizRunning) {
            QuizView().environmentObject(store)
        }
    }

    private var quizCard: some View {
        PaperCard(tint: Book.paperDeep) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("CUSTOMS QUIZ")
                            .font(Type.label(9.5))
                            .tracking(1.6)
                            .foregroundColor(Book.inkFaint)
                        Text("Ten questions, fresh each round")
                            .font(Type.heading(17))
                            .foregroundColor(Book.ink)
                    }
                    Spacer(minLength: 6)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(store.quizBest)/10")
                            .font(.system(size: 21, weight: .semibold, design: .serif))
                            .foregroundColor(Book.ink)
                        Text("BEST")
                            .font(Type.label(8.5))
                            .tracking(1.3)
                            .foregroundColor(Book.inkFaint)
                    }
                }
                Text("Where a plate comes from, what goes in it, and which of two dishes carries more heat. Drawn from the whole atlas.")
                    .font(Type.body(13))
                    .foregroundColor(Book.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                WideButton(title: "Take the quiz", tint: Book.ink) {
                    Feedback.tap(store)
                    quizRunning = true
                }
            }
        }
    }

    private var chapterList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(text: "Chapters")
            VStack(spacing: 10) {
                ForEach(Array(Handbook.guides.enumerated()), id: \.element.id) { index, guide in
                    NavigationLink(destination: GuideView(guide: guide, number: index + 1)) {
                        PaperCard {
                            HStack(spacing: 12) {
                                PlateImage(folder: "guide", name: guide.id, corner: 9)
                                    .frame(width: 96, height: 62)
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(String(format: "%02d", index + 1))
                                            .font(Type.mono(11))
                                            .foregroundColor(Book.inkFaint)
                                        Text(guide.title)
                                            .font(Type.heading(16))
                                            .foregroundColor(Book.ink)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Text(guide.standfirst)
                                        .font(Type.body(12))
                                        .foregroundColor(Book.inkSoft)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                                if store.isGuideRead(guide.id) {
                                    TickMark(size: 13, colour: Book.wash("herb"))
                                } else {
                                    ChevronMark()
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var glossaryList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(text: "Glossary", trailing: "\(Handbook.glossary.count) terms")
            PaperCard {
                VStack(spacing: 0) {
                    ForEach(Array(Handbook.glossary.enumerated()), id: \.element.id) { i, term in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(term.word)
                                .font(Type.heading(15.5))
                                .foregroundColor(Book.ink)
                            Text(term.meaning)
                                .font(Type.serif(14))
                                .foregroundColor(Book.inkSoft)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 9)
                        if i < Handbook.glossary.count - 1 {
                            Rectangle().fill(Book.ink.opacity(0.09)).frame(height: 1)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - One chapter

struct GuideView: View {
    let guide: Guide
    let number: Int
    @EnvironmentObject var store: PassportStore
    @Environment(\.presentationMode) private var presentation

    var body: some View {
        ZStack {
            PaperBackdrop(name: "page0", tint: 0.5)

            VStack(spacing: 0) {
                TopBar(title: guide.title,
                       subtitle: "Chapter \(number)",
                       onBack: { presentation.wrappedValue.dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        PlateImage(folder: "guide", name: guide.id, corner: 12)
                            .aspectRatio(1180.0 / 740.0, contentMode: .fit)

                        Text(guide.standfirst)
                            .font(Type.heading(18))
                            .foregroundColor(Book.ink)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Rectangle().fill(Book.ink.opacity(0.14)).frame(height: 1)

                        ForEach(Array(guide.paragraphs.enumerated()), id: \.offset) { _, para in
                            Text(para)
                                .font(Type.serif(15.5))
                                .foregroundColor(Book.ink)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if !store.isGuideRead(guide.id) {
                            WideButton(title: "Mark as read", filled: false, tint: Book.ink) {
                                Feedback.tap(store)
                                store.markGuideRead(guide.id)
                            }
                            .padding(.top, 4)
                        } else {
                            HStack(spacing: 6) {
                                TickMark(size: 13, colour: Book.wash("herb"))
                                Text("Read")
                                    .font(Type.label(11))
                                    .tracking(1.2)
                                    .foregroundColor(Book.wash("herb"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 14)
                    .padding(.bottom, 32)
                    .frame(maxWidth: Metric.pageMax)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
    }
}
