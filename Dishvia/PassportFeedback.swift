import SwiftUI
import AudioToolbox

/// The thud of the stamp and the rustle of a page. Nothing streams, nothing
/// records — these are the system's own short feedback signals.
enum Feedback {

    static func tap(_ store: PassportStore) {
        guard store.settings.haptics else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func press(_ store: PassportStore) {
        guard store.settings.haptics else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.55)
    }

    static func strike(_ store: PassportStore) {
        if store.settings.haptics {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        if store.settings.sound {
            AudioServicesPlaySystemSound(1104)
        }
    }

    static func issued(_ store: PassportStore) {
        if store.settings.haptics {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        if store.settings.sound {
            AudioServicesPlaySystemSound(1103)
        }
    }
}
