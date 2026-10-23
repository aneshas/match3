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
                    Toggle("Vibration", isOn: $settings.hapticsEnabled)
                    Picker("Calm mode", selection: calmSelection) {
                        Text("Follow system Reduce Motion").tag(0)
                        Text("On").tag(1)
                        Text("Off").tag(2)
                    }
                    Text("Calm mode removes drifting candies, confetti and the pulsing button, and makes every animation shorter.")
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

    private var calmSelection: Binding<Int> {
        Binding(
            get: { settings.calmModeOverride.map { $0 ? 1 : 2 } ?? 0 },
            set: { settings.calmModeOverride = $0 == 0 ? nil : ($0 == 1) }
        )
    }
}
