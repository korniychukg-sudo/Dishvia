import SwiftUI

// The customs desk: ten generated questions, each explained after you answer.

struct QuizView: View {
    @EnvironmentObject var store: PassportStore
    @Environment(\.presentationMode) private var presentation

    @State private var questions: [QuizQuestion] = []
    @State private var index = 0
    @State private var chosen: Int? = nil
    @State private var score = 0
    @State private var finished = false

    var body: some View {
        ZStack {
            PaperBackdrop(name: "page1", tint: 0.30)

            VStack(spacing: 0) {
                header

                if finished {
                    resultPane
                } else if index < questions.count {
                    questionPane(questions[index])
                } else {
                    Spacer()
                }
            }
        }
        .onAppear {
            if questions.isEmpty {
                questions = QuizFactory.round(seed: seedValue("quiz-\(Date().timeIntervalSince1970)"))
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CUSTOMS QUIZ")
                    .font(Type.label(10))
                    .tracking(1.8)
                    .foregroundColor(Book.inkFaint)
                Text(finished ? "Finished"
                              : "Question \(min(index + 1, max(questions.count, 1))) of \(max(questions.count, 1))")
                    .font(Type.heading(19))
                    .foregroundColor(Book.ink)
            }
            Spacer()
            Text("\(score)")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundColor(Book.ink)
            Button {
                finish()
            } label: {
                CloseMark(size: 15)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Book.ink.opacity(0.07)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    private func questionPane(_ q: QuizQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let plate = q.plateID {
                    PlateImage(folder: "dish", name: plate, corner: 12)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 300)
                        .frame(maxWidth: .infinity)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(q.prompt)
                        .font(Type.heading(20))
                        .foregroundColor(Book.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let detail = q.detail {
                        Text(detail)
                            .font(Type.serif(16))
                            .foregroundColor(Book.inkSoft)
                    }
                }

                VStack(spacing: 9) {
                    ForEach(Array(q.options.enumerated()), id: \.offset) { i, option in
                        optionRow(q, i, option)
                    }
                }

                if chosen != nil {
                    PaperCard(tint: Book.paperDeep) {
                        Text(q.explanation)
                            .font(Type.serif(14.5))
                            .foregroundColor(Book.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    WideButton(title: index == questions.count - 1 ? "See the result" : "Next question",
                               tint: Book.ink) {
                        advance()
                    }
                }
            }
            .padding(.horizontal, Metric.gutter)
            .padding(.bottom, 34)
            .frame(maxWidth: Metric.pageMax)
            .frame(maxWidth: .infinity)
        }
    }

    private func optionRow(_ q: QuizQuestion, _ i: Int, _ option: String) -> some View {
        let picked = chosen == i
        let correct = q.answer == i
        let revealed = chosen != nil
        let tint: Color = revealed ? (correct ? Book.wash("herb")
                                              : (picked ? Book.stampRed : Book.inkFaint))
                                   : Book.ink
        return Button {
            guard chosen == nil else { return }
            chosen = i
            if correct {
                score += 1
                Feedback.tap(store)
            } else {
                Feedback.press(store)
            }
        } label: {
            HStack(spacing: 10) {
                Text(option)
                    .font(Type.serif(15.5))
                    .foregroundColor(revealed && !correct && !picked ? Book.inkFaint : Book.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                if revealed && correct { TickMark(size: 14, colour: Book.wash("herb")) }
                if revealed && picked && !correct { CloseMark(size: 13, colour: Book.stampRed) }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(revealed && correct ? Book.wash("herb").opacity(0.12) : Book.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(tint.opacity(revealed ? 0.55 : 0.18), lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }

    private var resultPane: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("\(score) of \(questions.count)")
                .font(.system(size: 44, weight: .bold, design: .serif))
                .foregroundColor(Book.ink)
            Text(verdict)
                .font(Type.serif(16))
                .foregroundColor(Book.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .fixedSize(horizontal: false, vertical: true)
            if score > store.quizBest {
                Text("A NEW BEST")
                    .font(Type.label(11))
                    .tracking(1.8)
                    .foregroundColor(Book.gilt)
            }
            Spacer()
            VStack(spacing: 10) {
                WideButton(title: "Another round", tint: Book.ink) {
                    questions = QuizFactory.round(seed: seedValue("quiz-\(Date().timeIntervalSince1970)-again"))
                    index = 0; chosen = nil; score = 0; finished = false
                }
                WideButton(title: "Close", filled: false, tint: Book.ink) {
                    presentation.wrappedValue.dismiss()
                }
            }
            .padding(.horizontal, Metric.gutter)
            .padding(.bottom, 34)
            .frame(maxWidth: Metric.pageMax)
            .frame(maxWidth: .infinity)
        }
    }

    private var verdict: String {
        switch score {
        case 10: return "Nothing to declare. You know the atlas."
        case 8...9: return "Waved straight through."
        case 5...7: return "A few questions at the desk, then through."
        case 2...4: return "The officer is going through your bag."
        default: return "Read a chapter or two and come back."
        }
    }

    private func advance() {
        if index >= questions.count - 1 {
            finish()
        } else {
            index += 1
            chosen = nil
        }
    }

    private func finish() {
        guard !finished else {
            presentation.wrappedValue.dismiss()
            return
        }
        finished = true
        store.recordQuiz(score: score)
    }
}
