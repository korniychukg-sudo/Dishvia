import SwiftUI

/// Press and hold until the stamp comes down. Let go early and it lifts again.
struct StampPressView: View {
    let dish: Dish
    let cuisine: Cuisine

    @EnvironmentObject var store: PassportStore
    @Environment(\.presentationMode) private var presentation

    @State private var charge: Double = 0        // 0 hovering, 1 pressed home
    @State private var struckAt: Int? = nil
    @State private var inkSpread: Double = 0
    @State private var pending: DispatchWorkItem? = nil

    private let travel: Double = 0.85            // seconds from hover to strike

    private var design: StampDesign {
        if let day = struckAt, let record = store.stamp(for: dish.id) {
            return StampDesign(cuisine: cuisine, day: day, seed: record.seed)
        }
        return StampDesign(cuisine: cuisine, previewDay: DayNumber.today())
    }

    var body: some View {
        ZStack {
            PaperBackdrop(name: "endpaper", tint: 1.0)

            VStack(spacing: 0) {
                header
                Spacer(minLength: 0)
                stage
                Spacer(minLength: 0)
                footer
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(struckAt == nil ? "READY TO STAMP" : "ENTERED IN THE BOOK")
                    .font(Type.label(10))
                    .tracking(1.8)
                    .foregroundColor(Book.inkFaint)
                Text(dish.name)
                    .font(Type.title(23))
                    .foregroundColor(Book.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(cuisine.country)
                    .font(Type.serif(14))
                    .foregroundColor(Book.inkSoft)
            }
            Spacer(minLength: 8)
            Button {
                cancelPending()
                presentation.wrappedValue.dismiss()
            } label: {
                CloseMark(size: 15)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Book.ink.opacity(0.07)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.top, 20)
    }

    // MARK: - The page and the stamp

    private var stage: some View {
        let side: CGFloat = Metric.isPad ? 300 : 232
        return ZStack {
            // the ruled square on the page where the impression belongs
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Book.inkFaint.opacity(0.30), style: StrokeStyle(lineWidth: 1, dash: [5, 6]))
                .frame(width: side + 30, height: side + 30)

            // ink pushed out from under the rubber at the moment of contact
            Circle()
                .stroke(design.ink.opacity(max(0, 0.35 * (1 - inkSpread))), lineWidth: 2.5)
                .frame(width: side * (0.55 + inkSpread * 0.95))
                .scaleEffect(1)

            if struckAt != nil {
                StampMark(design: design, strength: 1)
                    .frame(width: side, height: side)
            } else {
                // The shadow of the rubber block, drawn as its own soft ellipse.
                // Shadowing the stamp itself would trace every stroke and spike.
                Ellipse()
                    .fill(Book.ink.opacity(0.16 + 0.10 * charge))
                    .frame(width: side * (0.86 - 0.10 * charge),
                           height: side * (0.30 - 0.06 * charge))
                    .blur(radius: 22 * (1 - charge) + 8)
                    .offset(y: side * 0.16)

                StampMark(design: design, strength: 0.28 + charge * 0.72)
                    .frame(width: side, height: side)
                    .scaleEffect(1.22 - 0.22 * charge)
                    .offset(y: -26 * (1 - charge))
            }
        }
        .frame(height: side + 60)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in beginPress() }
                .onEnded { _ in endPress() }
        )
        .allowsHitTesting(struckAt == nil)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 14) {
            if struckAt == nil {
                VStack(spacing: 9) {
                    ZStack(alignment: .leading) {
                        Capsule().fill(Book.ink.opacity(0.09))
                        Capsule()
                            .fill(design.ink.opacity(0.7))
                            .frame(width: max(0, 220 * charge))
                    }
                    .frame(width: 220, height: 8)
                    Text(charge > 0.02 ? "Hold it down" : "Press and hold to strike")
                        .font(Type.label(11))
                        .tracking(1.2)
                        .foregroundColor(Book.inkSoft)
                }
            } else {
                VStack(spacing: 10) {
                    Text(DayNumber.stampText(struckAt ?? DayNumber.today()))
                        .font(Type.mono(14))
                        .foregroundColor(Book.inkSoft)
                    Text("Rate it and write a note back on the plate.")
                        .font(Type.body(13))
                        .foregroundColor(Book.inkFaint)
                        .multilineTextAlignment(.center)
                    WideButton(title: "Close the book", tint: Book.ink) {
                        presentation.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: 260)
                }
            }
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Press handling

    private func beginPress() {
        guard struckAt == nil, pending == nil else { return }
        Feedback.press(store)
        withAnimation(.linear(duration: travel)) { charge = 1 }
        let work = DispatchWorkItem { strike() }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + travel, execute: work)
    }

    private func endPress() {
        guard struckAt == nil else { return }
        cancelPending()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { charge = 0 }
    }

    private func cancelPending() {
        pending?.cancel()
        pending = nil
    }

    private func strike() {
        guard struckAt == nil else { return }
        pending = nil
        let day = DayNumber.today()
        store.addStamp(dishID: dish.id, day: day)
        Feedback.strike(store)
        withAnimation(.easeOut(duration: 0.18)) { struckAt = day }
        inkSpread = 0
        withAnimation(.easeOut(duration: 0.55)) { inkSpread = 1 }
    }
}
