import AVFoundation
import Foundation

/// Background music: one loop per screen. Every Play screen visit and every new level
/// moves on to the next track in the cycle, crossfading from the one before. The music
/// sits well under the effects and never has to be noticed.
///
/// Tracks are every `.m4a` in the bundle (see `Match3/Resources/Music`), in name order,
/// starting from a random one each launch. Honors the caregiver "Music" toggle, the Debug
/// mute flag and the silent switch (ambient session), and stays quiet when another app is
/// already playing audio.
@MainActor
final class MusicPlayer {
    static let shared = MusicPlayer()

    /// Playback level under the effects.
    private let volume: Float = 0.4
    private let tracks: [URL]
    private var cursor: Int
    private var current: AVAudioPlayer?
    private var fadingOut: AVAudioPlayer?
    /// True between the first start and `stop()`: whether music is wanted right now.
    private var wanted = false

    var isEnabled: Bool {
        if DebugFlags.mute { return false }
        return Settings.shared.musicEnabled
    }

    private init() {
        let urls = Bundle.main.urls(forResourcesWithExtension: "m4a", subdirectory: nil) ?? []
        tracks = urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
        cursor = tracks.isEmpty ? 0 : Int.random(in: 0..<tracks.count)
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt).flatMap(AVAudioSession.InterruptionType.init),
                  type == .ended else { return }
            Task { @MainActor in self?.resume() }
        }
    }

    /// Move to the next track in the cycle (new level, back to the Play screen).
    func next() {
        wanted = true
        guard !tracks.isEmpty else { return }
        cursor = (cursor + 1) % tracks.count
        start(tracks[cursor])
    }

    /// Start the current track if nothing is playing yet (app launch).
    func ensurePlaying() {
        wanted = true
        guard current == nil, !tracks.isEmpty else { return }
        start(tracks[cursor])
    }

    /// Lower the music while the level-done sounds and celebration play.
    func duck() {
        current?.setVolume(volume * 0.45, fadeDuration: 0.4)
    }

    /// Fade out and forget (good-night screen).
    func stop() {
        wanted = false
        fadeOutCurrent()
    }

    /// Caregiver toggle flipped or the app came back: make reality match the settings.
    func refresh() {
        if isEnabled {
            if wanted, current == nil { ensurePlaying() }
        } else {
            fadeOutCurrent()
        }
    }

    func pause() { current?.pause() }

    func resume() {
        guard isEnabled else { return }
        if let current, !current.isPlaying {
            current.play()
        } else {
            refresh()
        }
    }

    private func start(_ url: URL) {
        guard isEnabled else { fadeOutCurrent(); return }
        // Someone else's music or podcast wins; the game stays quiet.
        guard !AVAudioSession.sharedInstance().isOtherAudioPlaying else { fadeOutCurrent(); return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.numberOfLoops = -1
        player.volume = 0
        player.prepareToPlay()
        fadeOutCurrent()
        player.play()
        player.setVolume(volume, fadeDuration: 1.5)
        current = player
    }

    private func fadeOutCurrent() {
        guard let old = current else { return }
        current = nil
        fadingOut?.stop()
        fadingOut = old
        old.setVolume(0, fadeDuration: 1.0)
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1100))
            guard let self, self.fadingOut === old else { return }
            old.stop()
            self.fadingOut = nil
        }
    }
}
