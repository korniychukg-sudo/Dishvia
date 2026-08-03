import SwiftUI

@main
struct PlatePassportApp: App {
    @StateObject private var store = PassportStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if store.save.onboarded {
                    RootView()
                } else {
                    OnboardingView { store.markOnboarded() }
                }
            }
            .environmentObject(store)
            .preferredColorScheme(.light)
            .onAppear { store.reconcileOnLaunch() }
            .onChange(of: scenePhase) { phase in
                if phase != .active { store.persist() }
            }
        }
    }
}
