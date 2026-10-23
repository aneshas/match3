import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Caregiver-controlled options. Nothing here is reachable from the play path; the panel
/// that edits them hides behind a three-finger hold on the Play screen.
@MainActor
@Observable
final class Settings {
    static let shared = Settings()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        soundEnabled = defaults.object(forKey: "soundEnabled") as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: "hapticsEnabled") as? Bool ?? true
        calmModeOverride = defaults.object(forKey: "calmMode") as? Bool
        maxColors = defaults.object(forKey: "maxColors") as? Int ?? 6
    }

    var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: "soundEnabled") } }
    var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: "hapticsEnabled") } }
    /// Caps the number of candy colors regardless of level (3...6).
    var maxColors: Int { didSet { defaults.set(maxColors, forKey: "maxColors") } }

    /// nil = follow the system Reduce Motion setting.
    var calmModeOverride: Bool? {
        didSet {
            if let v = calmModeOverride { defaults.set(v, forKey: "calmMode") } else { defaults.removeObject(forKey: "calmMode") }
        }
    }

    /// Calm mode turns off drifting candies, confetti, the breathing button and the sunburst,
    /// and shortens every animation. Defaults to the system Reduce Motion setting.
    var calmMode: Bool {
        if let v = calmModeOverride { return v }
        #if canImport(UIKit)
        return UIAccessibility.isReduceMotionEnabled
        #else
        return false
        #endif
    }
}
