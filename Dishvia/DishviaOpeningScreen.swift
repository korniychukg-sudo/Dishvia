import SwiftUI

struct DishviaOpeningScreen: View {
    @State private var breathing = false

    var body: some View {
        ZStack {
            Book.cover.edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Book.gilt.opacity(0.55), lineWidth: 1.4)
                        .frame(width: 98, height: 98)
                    Circle()
                        .stroke(Book.giltSoft.opacity(0.32), lineWidth: 0.8)
                        .frame(width: 78, height: 78)
                    Circle()
                        .fill(Book.gilt.opacity(0.16))
                        .frame(width: 56, height: 56)
                    Circle()
                        .fill(Book.gilt.opacity(0.7))
                        .frame(width: 9, height: 9)
                }
                .scaleEffect(breathing ? 1.06 : 0.93)
                .animation(
                    Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: breathing
                )

                VStack(spacing: 7) {
                    Text("Dishvia")
                        .font(Type.title(27))
                        .foregroundColor(Book.gilt)
                    Text("OPENING THE PASSPORT")
                        .font(Type.label(10.5))
                        .tracking(2.2)
                        .foregroundColor(Book.giltSoft.opacity(0.6))
                }
            }
        }
        .onAppear { breathing = true }
    }
}
