import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum Motion {
    /// True when animations should be minimal: caregiver calm mode or system Reduce Motion.
    @MainActor static var reduceMotion: Bool { Settings.shared.calmMode }
}

enum Haptics {
    @MainActor static func matchMade(big: Bool = false) {
        guard Settings.shared.hapticsEnabled else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: big ? .medium : .light).impactOccurred()
        #endif
    }

    @MainActor static func levelDone() {
        guard Settings.shared.hapticsEnabled else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
