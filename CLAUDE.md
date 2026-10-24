# Match 3 for players with intellectual disabilities

An iOS match-3 game where nothing is hard to understand. Candy-themed: glossy candy icons
on a soft cream-to-pink background.

## Design rules (do not break these)

- **One gesture only**: swipe a tile toward a neighbor. No tap-to-select, no double tap, no long press.
- **Never lose**: no move limits, timers, lives or fail screens. A stuck board reshuffles silently. Playability is guaranteed, not probable: fresh boards and shuffles re-color at random until a move exists, and if that ever fails `Board.plantMove` writes an "A A B A" move in; `BoardTests` plays every level/assist/color-cap combination and the smallest boards with six colors to prove it.
- **Progress = steps**: a swipe's match is worth 1 step for three candies, 1.5 for four, 2 for five or more (`GameSession.stepValue`); a group that matches on its own in a cascade is worth half of that (`cascadeCredit`). `goalMatches` is the step count (3 to 15). Refills avoid free matches so levels do not play themselves, but big matches and chains are visibly rewarded.
- **No text or numbers in play, in any language**: the Play button is a play icon, the Good Job screen is a star, sounds and the jar. Nothing the player sees needs reading, so there is nothing to localize outside the caregiver panel. Progress is a filling bar that ends in the next level's new candy (`CandyArt.Preview`), never a counter or score. The candy glows and spins when the bar is full.
- **No objectives that need reading or reasoning**: no "collect 10 red", no blockers, no boosters. Special candies exist but are optional extras (`Power` in core): from level 10 (`GameSession.powerUpsFromLevel`) a match of four leaves a wrapped candy that bursts its 8 neighbors when matched, five in a line leaves a striped candy that clears its whole row and column (the stripe direction is only artwork). They match by color like any candy, are never needed to finish a level, hint like any move, and add one step to the bar when they go off, with their own sounds (`striped.caf`, `wrapped.caf`), a heavy haptic, a `ShockwaveView` ring and a board punch. Caregiver toggle `powerUpsEnabled` (read at level start).
- **Orientation**: all orientations. `LevelScreen` switches to a landscape layout (vertical bar + board) when width > height; other screens scale with the short side.
- **Flow**: Play button -> current level -> Good Job -> next level, forever. No world map, no menus. A round house button (bottom right of the level screen) returns to Play; the unfinished level is dropped. A caregiver session timer can end a session gently after a Good Job (good-night screen, back to Play).
- **Difficulty** grows only via board size, board shape and number of colors (`LevelConfig`). Levels start tiny (4x4, 3 colors, 3 matches), go non-square at level 2, grow slowly (each size lasts two or three levels through the 15-level opening table, then one size step every five levels) and introduce one shape at a time; shapes have minimum sizes (`BoardShape.fits`) so they never degenerate. Boards are never wider than 7 columns (candies get too small on a phone) but grow to 9 rows; `BoardFit` tells `AppFlow` how many rows the current screen can show at the 7-column candy size and levels are clamped to that when they start. `AssistPolicy` (core) quietly softens the next level after a struggle (fewer colors, smaller board, lower goal) and relaxes after smooth levels; stored as `assist` in Progress.
- **Feedback is gentle**: invalid swap = slide back + wiggle. No error sounds or red flashes.
- Respect the system Reduce Motion setting (`Motion.reduceMotion`). There is no in-app calm mode.

## Layout

- `Packages/Match3Core` – pure Swift game rules, no UI. `Board` (swap, matches, gravity, shuffle), `BoardShape` (masks; every column must be vertically contiguous), `LevelConfig` (level number -> rows/cols/shape/colors/goal, deterministic), `SeededRandom`.
- `Match3/` – SwiftUI app. `AppFlow` is the screen state machine (`Progress` and `UnlockStore` are `@Observable`, so lock/unlock state refreshes live), `GameSession` runs one level and drives tile animations, `UI/` holds the screens, `Monetization/` holds `UnlockStore`: `StoreKitUnlockStore` (StoreKit 2, one non-consumable `io.anes.match3.unlock`, entitlements are the truth with a UserDefaults cache, listens to `Transaction.updates` for Ask to Buy / family / refunds; `restore()` = `AppStore.sync()`). The caregiver panel shows price, Buy (behind a parental gate: a multiplication alert) and Restore. `Match3.storekit` at the repo root is the local App Store for the Simulator (set on the scheme's run action, so headless `simctl` launches have no products and the Buy button stays disabled). No ads, ever. The first `AppFlow.freeLevels` levels are free; after that Good Job shows a lock on the jar and the Play button turns into a lock until a caregiver unlocks or resets to level 1.
- `project.yml` – XcodeGen spec. The `.xcodeproj` is generated and git-ignored.

## Art

- Candy icons are Robert Brooks's paid "Match three candy" pack (gamedeveloperstudio license: commercial use OK, no attribution, no redistribution). They live only in `Match3/Resources/Assets.xcassets/Candy/<name>.imageset` as single-scale universal images. Do not publish the repo publicly with them in it.
- `CandyArt` maps tile colors to images through a per-level `Palette`: each level plays a
  random mix of candy types (7 silhouettes x 6 colors) with distinct colors and distinct shapes,
  seeded by the level number, and every level has at least one type the previous level did not
  (`Palette.random(level:count:avoiding:)`, slot 0). `AppFlow` prepares the next level's palette
  while the current one is played and its newcomer is the candy at the end of the progress bar,
  so the promise is kept. Board effects take their particle color from the palette. The classic
  six (`tileImages`) are used off-board (Play screen, jar, sleepy candy). The pack's finishes mark
  the special candies (`Power.finish`): wrapper = wrapped, stripes = striped; plain candies are
  always plain. `SweepView` is the striped flash, `ShockwaveView` the ring.
- `Theme` holds all colors/gradients. `CandyBackground` is the shared animated backdrop.
- Code-drawn art lives in `Match3/UI/Art/` (jar, sleeping candy, hint arrow, app icon). `Tools/render-art.sh` renders them to PNG for review and writes the app icon; it needs only Command Line Tools. Any view that shows a candy image must go through `CandyArt.load` so the tool can swap in file loading.
- Caregiver panel: `CaregiverPanel` (sheet over Play, opened by `ThreeFingerHold`; in Debug builds also by holding the logo 3 s with one finger, for the Simulator), edits `Settings` (sound, haptics, high contrast, color cap, session length) and can reset `Progress`. High contrast (`Settings.highContrastActive`, also on under iOS Increase Contrast) gives `TileView` a dark rim traced from the candy's own silhouette, cocoa cells in `BoardView` and fades the background candies. `Motion.reduceMotion` follows the system Reduce Motion setting only.
- Swipe demo: `SwipeDemoView` (hand image `hand_point`, Kenney CC0) driven by `GameSession.demo`; shown until `Progress.hasEverSwiped`.
- Sounds: `Match3/Resources/Sounds/*.caf` played by `SoundPlayer`; the Good Job screen is not spoken (the level-done sounds carry it), only "See you soon!" on the good-night screen uses `AVSpeechSynthesizer`. Mute = UserDefaults `soundEnabled`. Sources live in `sounds/` at the repo root (Kenney CC0 for the short effects, license text alongside the `.caf` files; `level_done_0`/`level_done_1` were supplied by the owner and always play layered together via `playLevelDone`; `striped`/`wrapped` are the special-candy sounds). Convert with ffmpeg to mono 44.1 kHz Int16 `.caf`, trimming silence at -55 dB and peak-normalizing (about -1 dB for effects, -4 dB for each level-done layer so the sum has headroom).
- Music: `Match3/Resources/Music/*.m4a` (AAC 96 kbps, loudness-normalized to -20 LUFS with ffmpeg `loudnorm`; sources are the `.ogg` loops in `music/` at the repo root) played by `MusicPlayer` at low volume. `AppFlow.screen` drives it: every Play screen visit and every new level moves to the next track with a crossfade, Good Job fades it out in 0.3 s so the level-done sounds play alone, good-night fades it out slowly. Caregiver toggle `musicEnabled`; silent when another app plays audio. Tracks are discovered from the bundle, so adding a loop is just dropping in an `.m4a`.
- Animations are procedural (no sprite sheets): entrance drop-in, swap lift, pop + particle
  `BurstView`, spring falls, reshuffle twirl, level-complete wave, progress shimmer/pulse,
  Good Job sunburst + candy rain, floating candies. All honor Reduce Motion via `Motion`.

## Roadmap

Planned features, asset shopping list and testing plan live in `ROADMAP.md`. Check items off there as they ship. Store texts (privacy policy, description, keywords, review notes) live in `Store/`; `AppLinks` holds the public URLs the caregiver panel links to. Every manual step to reach the App Store (account, name, App Store Connect, screenshots, upload) is tracked in `PUBLISH.md`; keep it current when anything release-related changes (bundle id, product id, assets, licenses).

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
xcrun simctl boot $UDID; xcrun simctl uninstall $UDID io.anes.match3; xcrun simctl install $UDID /tmp/match3-dd/Build/Products/Debug-iphonesimulator/Match3.app
# Uninstall first: `simctl install` over an existing app sometimes silently keeps the old build.
# When in doubt compare `stat` of the built binary with `xcrun simctl get_app_container $UDID io.anes.match3`.
SIMCTL_CHILD_MATCH3_AUTOSTART=1 SIMCTL_CHILD_MATCH3_AUTOPLAY=1 xcrun simctl launch $UDID io.anes.match3
xcrun simctl io $UDID screenshot --display=1 shot.png   # --display=1 is the main screen on the iPhone Duo device; the default is its cover display
```

Debug-only launch flags (see `DebugFlags.swift`, ignored in Release): `MATCH3_AUTOSTART=1` skips
the Play screen, `MATCH3_AUTOPLAY=1` plays valid moves by itself, `MATCH3_LEVEL=n` starts at level n, `MATCH3_FORGET_SWIPE=1` makes the swipe demo show again, `MATCH3_MUTE=1` silences that launch, `MATCH3_ASSIST=n` forces the assist level, `MATCH3_PANEL=1` opens the caregiver panel, `MATCH3_SESSION_SECONDS=n` ends the session after n seconds, `MATCH3_FREE_LEVELS=n` sets the free-level count, `MATCH3_UNLOCKED=1` simulates the purchase, `MATCH3_HIGH_CONTRAST=1` forces the high-contrast look, `MATCH3_POWER_DEMO=1` plants a wrapped and a striped candy on every fresh board. Never persist a mute into the simulator's defaults: the same simulator is used for manual testing.
Saved progress lives in the app's UserDefaults key `currentLevel`.
The simulator sometimes paints the Duo's cover camera as a solid black disc at the top right of screenshots (over the end of the progress bar). It is not drawn by the app; ignore it.

Layout note: the iPhone Duo's folded cover screen reports a large one-sided horizontal
safe-area inset (84pt on the right). SwiftUI hit-testing stops at the safe-area edge, so
`RootView` ignores the safe area entirely and re-applies only the top/bottom insets as
padding; the insets are published as `\.screenInsets` for views that must keep clear of
the camera (the progress bar). Never use `ignoresSafeArea` on a child to "center" content.

UI tests: `Match3UITests` drives real touches (`xcodebuild ... -only-testing:Match3UITests test`);
`PowerTests` launches with `MATCH3_POWER_DEMO` and autoplay and checks a special candy goes off (`debug.counters` reads `swipes N matches M points P powers T`, P in half steps). `PurchaseTests` buys the unlock through `SKTestSession` (local store, no sheet; clear the simulator's `allLevelsUnlocked` default before and after). `SwipeTests` checks every column accepts a swipe and that a caregiver reset unlocks Play without a relaunch (that test expects the simulator's saved level to be past the free count; the runner sets `currentLevel` first). Tiles carry `tile.<row>.<col>` identifiers
and `debug.counters` exposes swipe/match counts in Debug builds.
