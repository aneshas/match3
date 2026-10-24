import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum Motion {
    /// True when animations should be minimal: the system Reduce Motion setting.
    @MainActor static var reduceMotion: Bool {
        #if canImport(UIKit)
        return UIAccessibility.isReduceMotionEnabled
        #else
        return false
        #endif
    }
}

enum Haptics {
    @MainActor static func matchMade(big: Bool = false) {
        guard Settings.shared.hapticsEnabled else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: big ? .medium : .light).impactOccurred()
        #endif
    }

    /// A special candy going off: heavier than any match.
    @MainActor static func powerUp() {
        guard Settings.shared.hapticsEnabled else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        #endif
    }

    @MainActor static func levelDone() {
        guard Settings.shared.hapticsEnabled else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
