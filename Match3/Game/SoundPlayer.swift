import AVFoundation
import Foundation

/// Plays the game's short sounds and speaks "Good job!". Sounds are the main reward for
/// this audience, so they are warm and short, and nothing here is ever startling.
///
/// Respects the caregiver mute (`soundEnabled` in UserDefaults, default on) and the device
/// silent switch (ambient audio session category), and mixes with other audio.
@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    enum Sound: String, CaseIterable {
        case match, matchAlt = "match_alt", matchBig = "match_big"
        case invalid, shuffle, tap, levelDone = "level_done"
    }

    var isEnabled: Bool {
        if DebugFlags.mute { return false }
        return Settings.shared.soundEnabled
    }

    private var players: [Sound: [AVAudioPlayer]] = [:]
    private let synthesizer = AVSpeechSynthesizer()
    private var alternate = false

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        for sound in Sound.allCases { preload(sound) }
    }

    /// A couple of players per sound so quick cascades can overlap.
    private func preload(_ sound: Sound) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "caf") else { return }
        players[sound] = (0..<3).compactMap { _ in
            let p = try? AVAudioPlayer(contentsOf: url)
            p?.prepareToPlay()
            return p
        }
    }

    func play(_ sound: Sound, volume: Float = 1) {
        guard isEnabled, let pool = players[sound] else { return }
        let player = pool.first { !$0.isPlaying } ?? pool[0]
        player.volume = volume
        player.currentTime = 0
        player.play()
    }

    /// Match sounds alternate between two plucks so a cascade does not sound robotic.
    func playMatch(big: Bool) {
        if big {
            play(.matchBig)
        } else {
            play(alternate ? .matchAlt : .match)
            alternate.toggle()
        }
    }

    /// Speaks in the device language. No audio asset needed; a recorded caregiver voice can
    /// replace this later.
    func sayGoodJob() { say(String(localized: "Good job!")) }

    /// Spoken at the end of a timed session.
    func saySeeYouSoon() { say(String(localized: "See you soon!")) }

    private func say(_ text: String) {
        guard isEnabled else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.1
        synthesizer.speak(utterance)
    }
}
