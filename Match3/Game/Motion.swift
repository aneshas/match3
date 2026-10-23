import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum Motion {
    static var reduceMotion: Bool {
        #if canImport(UIKit)
        return UIAccessibility.isReduceMotionEnabled
        #else
        return false
        #endif
    }
}

enum Haptics {
    static func matchMade(big: Bool = false) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: big ? .medium : .light).impactOccurred()
        #endif
    }

    static func levelDone() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
