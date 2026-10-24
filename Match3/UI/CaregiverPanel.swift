import SwiftUI
import Match3Core

/// Settings for the adult looking after the player. Plain system UI and plain words are
/// fine here: the player never sees this screen.
struct CaregiverPanel: View {
    @Environment(AppFlow.self) private var flow
    @Environment(\.dismiss) private var dismiss
    @State private var settings = Settings.shared
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Play") {
                    Toggle("Sounds", isOn: $settings.soundEnabled)
                    Toggle("Music", isOn: $settings.musicEnabled)
                        .onChange(of: settings.musicEnabled) { MusicPlayer.shared.refresh() }
                    Toggle("Vibration", isOn: $settings.hapticsEnabled)
                    Toggle("High contrast", isOn: $settings.highContrast)
                    Text("Thick dark outlines around the candies, darker cells and a plainer background. Also on whenever iOS Increase Contrast is on.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Session") {
                    Picker("Session length", selection: $settings.sessionMinutes) {
                        Text("No limit").tag(0)
                        ForEach([5, 10, 15, 20, 30, 45, 60], id: \.self) { Text("\($0) minutes").tag($0) }
                    }
                    Text("When the time is up the game finishes the current level, celebrates, shows a sleeping candy and returns to the Play screen.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Difficulty") {
                    Stepper("Most colors at once: \(settings.maxColors)", value: $settings.maxColors, in: 3...TileColor.maxCount)
                    Text("Levels still grow in size and shape. Lower this if telling candies apart is the hard part.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Progress") {
                    LabeledContent("Current level", value: "\(flow.currentLevel)")
                    LabeledContent("Levels finished, last 7 days", value: "\(flow.levelsFinishedLastWeek)")
                    LabeledContent("Levels finished, total", value: "\(flow.completedLevels)")
                    Button("Start again from level 1", role: .destructive) { confirmReset = true }
                }

                Section("Tips") {
                    Text("To keep the player inside this game, turn on Guided Access in iOS Settings > Accessibility, then triple-click the side button while the game is open.")
                        .font(.footnote)
                    Text("Open this panel by holding three fingers on the Play screen for three seconds.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Caregiver settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Start again from level 1?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Start again", role: .destructive) { flow.resetProgress() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The jar empties and the next game starts at level 1.")
            }
        }
    }
}
