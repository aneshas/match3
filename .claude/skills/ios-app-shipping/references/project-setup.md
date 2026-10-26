# Project setup

The shape that let one agent build, test and verify an iOS app with only the command line
most of the time.

## Layout

```
app/
  project.yml              # XcodeGen spec; the .xcodeproj is generated and git-ignored
  CLAUDE.md  ROADMAP.md  PUBLISH.md
  Packages/<App>Core/      # pure Swift: rules, state, no UIKit/SwiftUI imports
    Package.swift
    Sources/<App>Core/
    Tests/<App>CoreTests/  # XCTest; `swift test` once Xcode is installed
  <App>/                   # SwiftUI app target
    App/        AppFlow (screen state machine), DebugFlags, AppLinks
    Game|Model/ session/engine objects (@Observable), Settings, Progress (UserDefaults)
    UI/         screens and views, Art/ for code-drawn art
    Monetization/ UnlockStore protocol + StoreKit implementation
    Resources/  Assets.xcassets, Sounds, Music, Info.plist
  <App>UITests/            # XCUITest: real touches
  <App>.storekit           # local App Store for the Simulator (on the scheme's run action)
  Store/                   # listing texts, privacy policy, screenshots/, previews/, site/
  Tools/                   # render-art, compositors, preview builder
```

Why a separate core package: it compiles and tests with Command Line Tools alone, so logic
can be proven before Xcode is even installed, and it keeps the renderer swappable. Keep it
free of `import SwiftUI`.

## project.yml essentials

```yaml
name: App
options: { bundleIdPrefix: io.example, deploymentTarget: { iOS: "17.0" } }
packages: { AppCore: { path: Packages/AppCore } }
targets:
  App:
    type: application
    platform: iOS
    sources: [{ path: App, excludes: ["Resources/Info.plist"] }]
    dependencies: [{ package: AppCore }]
    info:
      path: App/Resources/Info.plist
      properties:
        CFBundleDisplayName: App Name
        UILaunchScreen: { UIColorName: LaunchBackground }   # no white flash at start
        ITSAppUsesNonExemptEncryption: false                 # no export question at upload
    settings:
      base:
        SWIFT_VERSION: "5.0"            # language mode 5 on purpose: no strict-concurrency churn
        TARGETED_DEVICE_FAMILY: "1,2"   # "1" for iPhone only (then no iPad screenshots)
        PRODUCT_NAME: AppName           # the .app name; keep it without spaces for scripts
        PRODUCT_BUNDLE_IDENTIFIER: io.example.appname
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: 1      # bump for every upload
        DEVELOPMENT_TEAM: XXXXXXXXXX
        CODE_SIGN_STYLE: Automatic
  AppUITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - AppUITests
      - { path: App.storekit, buildPhase: resources }   # so SKTestSession can load it
    dependencies: [{ target: App }]
    settings: { base: { TEST_TARGET_NAME: App } }
schemes:
  App:
    build: { targets: { App: all, AppUITests: [test] } }
    run:
      config: Debug
      storeKitConfiguration: App.storekit
      environmentVariables:           # Debug switches, disabled by default, one tick to use
        - { variable: APP_AUTOSTART, value: "1", isEnabled: false }
    test:
      config: Debug
      targets: [{ package: AppCore/AppCoreTests }, AppUITests]
```

Regenerate with `xcodegen generate` after every change; it is cheap and the project file
is never hand-edited. `.gitignore`: `*.xcodeproj`, `*.xcworkspace`, `xcuserdata/`,
`.build/`, `DerivedData/`, raw asset sources.

## Debug flags

A `DebugFlags` enum that reads `ProcessInfo.processInfo.environment` only under
`#if DEBUG`. Useful ones in every app: AUTOSTART (skip the first screen), AUTOPLAY (the app
drives itself, for attract mode and headless verification), LEVEL/SCREEN (jump somewhere),
MUTE (this launch only; never persist a mute into the simulator's defaults), PANEL (open the
settings sheet), UNLOCKED (behave as if bought), plus whatever the app's own state needs.
Prefix them with the app name so they cannot collide. Document every one in CLAUDE.md.

Launch args of the form `-key value` set UserDefaults for that launch (`simctl launch ...
-hasEverSwiped 1`); use them in UI tests and headless runs instead of writing the
simulator's defaults.

## Make the UI observable

- `.accessibilityIdentifier("tile.\(row).\(col)")` on anything a test must touch;
  `.accessibilityValue` for state a test must read (a tile's special kind).
- A Debug-only hidden label `debug.counters` whose text is a few space-separated numbers
  (`swipes N matches M points P`); tests parse it instead of inferring from pixels.
- `@Observable` state objects so screens refresh when a purchase or reset lands.
- Respect Reduce Motion through one `Motion.reduceMotion` accessor so every animation
  honors it the same way.

## Tests

- Core package: XCTest in `swift test`. Prove invariants exhaustively where cheap (every
  level/config combination) rather than sampling.
- UI tests: one class per concern (swipes, purchase, hidden panel, specials). Each launches
  with `launchEnvironment` flags and reads `debug.counters`. Keep them under 30 s each.
- Helper "tests" that only hold a screen open for screenshots are fine; skip them unless an
  env var is set (`XCTSkipUnless(ProcessInfo.processInfo.environment["HOLD"] != nil)`,
  passed as `TEST_RUNNER_HOLD=1` in xcodebuild's environment, not as a build setting).
