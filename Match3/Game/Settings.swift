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
    }

    /// Caregiver session length in minutes; 0 = no limit. When it runs out the game ends
    /// gently after the next Good Job.
    var sessionMinutes: Int { didSet { defaults.set(sessionMinutes, forKey: "sessionMinutes") } }

    var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: "soundEnabled") } }
    var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: "hapticsEnabled") } }
    /// Caps the number of candy colors regardless of level (3...6).
    var maxColors: Int { didSet { defaults.set(maxColors, forKey: "maxColors") } }
}
