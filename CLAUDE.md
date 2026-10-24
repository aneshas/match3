# Match 3 for players with intellectual disabilities

An iOS match-3 game where nothing is hard to understand. Candy-themed: glossy candy icons
on a soft cream-to-pink background.

## Design rules (do not break these)

- **One gesture only**: swipe a tile toward a neighbor. No tap-to-select, no double tap, no long press.
- **Never lose**: no move limits, timers, lives or fail screens. A stuck board reshuffles silently.
- **Progress = swipes**: the bar advances one step per successful swap (`goalMatches` is a swipe count, 3 to 15). Cascades burst and sound but never fill the bar; refills avoid free matches so levels do not play themselves.
- **No text or numbers in play**: the only words in the app are "Play" and "Good Job!". Progress is a filling bar with a star, never a counter or score.
- **No objectives that need reading or reasoning**: no "collect 10 red", no special pieces, no blockers, no boosters.
- **Orientation**: all orientations. `LevelScreen` switches to a landscape layout (vertical bar + board) when width > height; other screens scale with the short side.
- **Flow**: Play button -> current level -> Good Job -> next level, forever. No world map, no menus. A round house button (bottom right of the level screen) returns to Play; the unfinished level is dropped. A caregiver session timer can end a session gently after a Good Job (good-night screen, back to Play).
- **Difficulty** grows only via board size, board shape and number of colors (`LevelConfig`). Levels start tiny (4x4, 3 colors, 3 matches), go non-square at level 2, and introduce one shape at a time; shapes have minimum sizes (`BoardShape.fits`) so they never degenerate. `AssistPolicy` (core) quietly softens the next level after a struggle (fewer colors, smaller board, lower goal) and relaxes after smooth levels; stored as `assist` in Progress.
- **Feedback is gentle**: invalid swap = slide back + wiggle. No error sounds or red flashes.
- Respect the system Reduce Motion setting (`Motion.reduceMotion`). There is no in-app calm mode.

## Layout

- `Packages/Match3Core` – pure Swift game rules, no UI. `Board` (swap, matches, gravity, shuffle), `BoardShape` (masks; every column must be vertically contiguous), `LevelConfig` (level number -> rows/cols/shape/colors/goal, deterministic), `SeededRandom`.
- `Match3/` – SwiftUI app. `AppFlow` is the screen state machine (`Progress` and `UnlockStore` are `@Observable`, so lock/unlock state refreshes live), `GameSession` runs one level and drives tile animations, `UI/` holds the screens, `Monetization/` holds `UnlockStore` (one-time unlock of all levels; stub until StoreKit lands). No ads, ever. The first `AppFlow.freeLevels` levels are free; after that Good Job shows a lock on the jar and the Play button turns into a lock until a caregiver unlocks or resets to level 1.
- `project.yml` – XcodeGen spec. The `.xcodeproj` is generated and git-ignored.

## Art

- Candy icons are Robert Brooks's paid "Match three candy" pack (gamedeveloperstudio license: commercial use OK, no attribution, no redistribution). They live only in `Match3/Resources/Assets.xcassets/Candy/<name>.imageset` as single-scale universal images. Do not publish the repo publicly with them in it.
- `CandyArt` maps tile colors to images. Each color has its own silhouette so pieces differ
  by shape as well as color: blue ball, yellow bean, red heart, green triangle, purple square,
  orange pear. The striped/wrapper variants are imported but unused (reserved for later).
- `Theme` holds all colors/gradients. `CandyBackground` is the shared animated backdrop.
- Code-drawn art lives in `Match3/UI/Art/` (jar, sleeping candy, hint arrow, app icon). `Tools/render-art.sh` renders them to PNG for review and writes the app icon; it needs only Command Line Tools. Any view that shows a candy image must go through `CandyArt.load` so the tool can swap in file loading.
- Caregiver panel: `CaregiverPanel` (sheet over Play, opened by `ThreeFingerHold`; in Debug builds also by holding the logo 3 s with one finger, for the Simulator), edits `Settings` (sound, haptics, high contrast, color cap, session length) and can reset `Progress`. High contrast (`Settings.highContrastActive`, also on under iOS Increase Contrast) gives `TileView` a dark rim traced from the candy's own silhouette, cocoa cells in `BoardView` and fades the background candies. `Motion.reduceMotion` follows the system Reduce Motion setting only.
- Swipe demo: `SwipeDemoView` (hand image `hand_point`, Kenney CC0) driven by `GameSession.demo`; shown until `Progress.hasEverSwiped`.
- Sounds: `Match3/Resources/Sounds/*.caf` played by `SoundPlayer`; "Good job!" is spoken by `AVSpeechSynthesizer`. Mute = UserDefaults `soundEnabled`. Sources live in `sounds/` at the repo root (Kenney CC0 for the short effects, license text alongside the `.caf` files; `level_done_0`/`level_done_1` were supplied by the owner and always play layered together via `playLevelDone`). Convert with ffmpeg to mono 44.1 kHz Int16 `.caf`, trimming silence at -55 dB and peak-normalizing (about -1 dB for effects, -4 dB for each level-done layer so the sum has headroom).
- Animations are procedural (no sprite sheets): entrance drop-in, swap lift, pop + particle
  `BurstView`, spring falls, reshuffle twirl, level-complete wave, progress shimmer/pulse,
  Good Job sunburst + candy rain, floating candies. All honor Reduce Motion via `Motion`.

## Roadmap

Planned features, asset shopping list and testing plan live in `ROADMAP.md`. Check items off there as they ship.

## Build / run / test

```sh
brew install xcodegen            # once
xcodegen generate                # creates Match3.xcodeproj
open Match3.xcodeproj            # run the Match3 scheme on an iPhone simulator

# Core logic only (works without Xcode, Command Line Tools are enough):
cd Packages/Match3Core && swift build

# Tests (need Xcode for XCTest):
cd Packages/Match3Core && swift test
# or from the project: xcodebuild -scheme Match3 -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Swift language mode is 5 on purpose (prototype; avoids strict-concurrency churn). iOS 17+.

### Headless simulator verification

Xcode 27.1 on this machine ships without Simulator.app, so drive the simulator with `simctl`:

```sh
xcodebuild -project Match3.xcodeproj -scheme Match3 -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/match3-dd CODE_SIGNING_ALLOWED=NO build
UDID=<the "match3-test (Claude)" device from: xcrun simctl list devices>   # never the device Xcode uses for manual testing
xcrun simctl boot $UDID; xcrun simctl install $UDID /tmp/match3-dd/Build/Products/Debug-iphonesimulator/Match3.app
SIMCTL_CHILD_MATCH3_AUTOSTART=1 SIMCTL_CHILD_MATCH3_AUTOPLAY=1 xcrun simctl launch $UDID io.kurrent.match3
xcrun simctl io $UDID screenshot --display=1 shot.png   # --display=1 is the main screen on the iPhone Duo device; the default is its cover display
```

Debug-only launch flags (see `DebugFlags.swift`, ignored in Release): `MATCH3_AUTOSTART=1` skips
the Play screen, `MATCH3_AUTOPLAY=1` plays valid moves by itself, `MATCH3_LEVEL=n` starts at level n, `MATCH3_FORGET_SWIPE=1` makes the swipe demo show again, `MATCH3_MUTE=1` silences that launch, `MATCH3_ASSIST=n` forces the assist level, `MATCH3_PANEL=1` opens the caregiver panel, `MATCH3_SESSION_SECONDS=n` ends the session after n seconds, `MATCH3_FREE_LEVELS=n` sets the free-level count, `MATCH3_UNLOCKED=1` simulates the purchase, `MATCH3_HIGH_CONTRAST=1` forces the high-contrast look. Never persist a mute into the simulator's defaults: the same simulator is used for manual testing.
Saved progress lives in the app's UserDefaults key `currentLevel`.
The simulator sometimes paints the Duo's cover camera as a solid black disc at the top right of screenshots (over the progress star). It is not drawn by the app; ignore it.

Layout note: the iPhone Duo's folded cover screen reports a large one-sided horizontal
safe-area inset (84pt on the right). SwiftUI hit-testing stops at the safe-area edge, so
`RootView` ignores the safe area entirely and re-applies only the top/bottom insets as
padding; the insets are published as `\.screenInsets` for views that must keep clear of
the camera (the progress bar). Never use `ignoresSafeArea` on a child to "center" content.

UI tests: `Match3UITests` drives real touches (`xcodebuild ... -only-testing:Match3UITests test`);
`SwipeTests` checks every column accepts a swipe and that a caregiver reset unlocks Play without a relaunch (that test expects the simulator's saved level to be past the free count; the runner sets `currentLevel` first). Tiles carry `tile.<row>.<col>` identifiers
and `debug.counters` exposes swipe/match counts in Debug builds.
