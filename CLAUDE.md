# Match 3 for players with intellectual disabilities

An iOS match-3 game where nothing is hard to understand. Candy-themed: glossy candy icons
on a soft cream-to-pink background.

## Design rules (do not break these)

- **One gesture only**: swipe a tile toward a neighbor. No tap-to-select, no double tap, no long press.
- **Never lose**: no move limits, timers, lives or fail screens. A stuck board reshuffles silently.
- **No text or numbers in play**: the only words in the app are "Play" and "Good Job!". Progress is a filling bar with a star, never a counter or score.
- **No objectives that need reading or reasoning**: no "collect 10 red", no special pieces, no blockers, no boosters.
- **Flow**: Play button -> current level -> Good Job -> next level, forever. No world map, no menus, no settings in the prototype.
- **Difficulty** grows only via board size, board shape and number of colors (`LevelConfig`). Levels start tiny (4x4, 3 colors, 3 matches), go non-square at level 2, and introduce one shape at a time; shapes have minimum sizes (`BoardShape.fits`) so they never degenerate. `AssistPolicy` (core) quietly softens the next level after a struggle (fewer colors, smaller board, lower goal) and relaxes after smooth levels; stored as `assist` in Progress.
- **Feedback is gentle**: invalid swap = slide back + wiggle. No error sounds or red flashes.
- Respect the system Reduce Motion setting (`Motion.reduceMotion`).

## Layout

- `Packages/Match3Core` – pure Swift game rules, no UI. `Board` (swap, matches, gravity, shuffle), `BoardShape` (masks; every column must be vertically contiguous), `LevelConfig` (level number -> rows/cols/shape/colors/goal, deterministic), `SeededRandom`.
- `Match3/` – SwiftUI app. `AppFlow` is the screen state machine, `GameSession` runs one level and drives tile animations, `UI/` holds the screens, `Monetization/` holds the ad/IAP hook points (no SDKs yet; `NoOpAdPresenter`, interstitial every 5th level unless `RemoveAdsStore.adsRemoved`).
- `project.yml` – XcodeGen spec. The `.xcodeproj` is generated and git-ignored.

## Art

- Candy icons are Robert Brooks's paid "Match three candy" pack (gamedeveloperstudio license: commercial use OK, no attribution, no redistribution). They live only in `Match3/Resources/Assets.xcassets/Candy/<name>.imageset` as single-scale universal images. Do not publish the repo publicly with them in it.
- `CandyArt` maps tile colors to images. Each color has its own silhouette so pieces differ
  by shape as well as color: blue ball, yellow bean, red heart, green triangle, purple square,
  orange pear. The striped/wrapper variants are imported but unused (reserved for later).
- `Theme` holds all colors/gradients. `CandyBackground` is the shared animated backdrop.
- Code-drawn art lives in `Match3/UI/Art/` (jar, sleeping candy, hint arrow, app icon). `Tools/render-art.sh` renders them to PNG for review and writes the app icon; it needs only Command Line Tools. Any view that shows a candy image must go through `CandyArt.load` so the tool can swap in file loading.
- Swipe demo: `SwipeDemoView` (hand image `hand_point`, Kenney CC0) driven by `GameSession.demo`; shown until `Progress.hasEverSwiped`.
- Sounds: `Match3/Resources/Sounds/*.caf` (Kenney, CC0, license text alongside) played by `SoundPlayer`; "Good job!" is spoken by `AVSpeechSynthesizer`. Mute = UserDefaults `soundEnabled`.
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
UDID=<from: xcrun simctl list devices>
xcrun simctl boot $UDID; xcrun simctl install $UDID /tmp/match3-dd/Build/Products/Debug-iphonesimulator/Match3.app
SIMCTL_CHILD_MATCH3_AUTOSTART=1 SIMCTL_CHILD_MATCH3_AUTOPLAY=1 xcrun simctl launch $UDID io.kurrent.match3
xcrun simctl io $UDID screenshot --display=1 shot.png   # --display=1 is the main screen on the iPhone Duo device; the default is its cover display
```

Debug-only launch flags (see `DebugFlags.swift`, ignored in Release): `MATCH3_AUTOSTART=1` skips
the Play screen, `MATCH3_AUTOPLAY=1` plays valid moves by itself, `MATCH3_LEVEL=n` starts at level n, `MATCH3_FORGET_SWIPE=1` makes the swipe demo show again, `MATCH3_MUTE=1` silences that launch, `MATCH3_ASSIST=n` forces the assist level. Never persist a mute into the simulator's defaults: the same simulator is used for manual testing.
Saved progress lives in the app's UserDefaults key `currentLevel`.

Layout note: the iPhone Duo's folded cover screen reports a large one-sided horizontal
safe-area inset (84pt on the right). Screens that must look centered use
`.centeredOnScreen()` (ignores the horizontal safe area only); the progress bar deliberately
stays inside the safe area because the camera sits top-right.
