import SwiftUI

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
        maxColors = defaults.object(forKey: "maxColors") as? Int ?? 6
        sessionMinutes = defaults.object(forKey: "sessionMinutes") as? Int ?? 0
        highContrast = defaults.object(forKey: "highContrast") as? Bool ?? false
        musicEnabled = defaults.object(forKey: "musicEnabled") as? Bool ?? true
    }

    /// Caregiver session length in minutes; 0 = no limit. When it runs out the game ends
    /// gently after the next Good Job.
    var sessionMinutes: Int { didSet { defaults.set(sessionMinutes, forKey: "sessionMinutes") } }

    var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: "soundEnabled") } }
    /// Background music loops (separate from the effects).
    var musicEnabled: Bool { didSet { defaults.set(musicEnabled, forKey: "musicEnabled") } }
    var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: "hapticsEnabled") } }
    /// Caps the number of candy colors regardless of level (3...6).
    var maxColors: Int { didSet { defaults.set(maxColors, forKey: "maxColors") } }
    /// Thick dark outline around every candy, darker cells and a quieter backdrop.
    var highContrast: Bool { didSet { defaults.set(highContrast, forKey: "highContrast") } }

    /// High contrast is on when the caregiver asked for it, when iOS "Increase Contrast" is
    /// on, or when a Debug launch forces it. `systemIncreased` comes from the view's
    /// `\.colorSchemeContrast` environment so SwiftUI refreshes it live.
    func highContrastActive(systemIncreased: Bool) -> Bool {
        highContrast || systemIncreased || DebugFlags.highContrast
    }
}
