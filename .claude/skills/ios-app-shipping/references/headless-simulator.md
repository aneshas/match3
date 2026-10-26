# Headless simulator verification

Xcode's Simulator.app may be absent or in use by the user. Everything below needs only
`xcodebuild` and `xcrun simctl`, and lets an agent see its own changes.

## One-time: a simulator of your own

```sh
xcrun simctl list devicetypes | grep iPhone          # what the installed runtime supports
xcrun simctl list runtimes
UDID=$(xcrun simctl create "app-test (Claude)" <device type id> <runtime id>)
xcrun simctl boot $UDID; xcrun simctl bootstatus $UDID -b
```

Never use the device the user runs manually: tests reset its state and a hung call freezes
it. If `create` says "Incompatible device", the runtime only ships for some device types;
list `supportedDeviceTypes` in `simctl list runtimes -j` and pick one of those.

## Build, install, launch, look

```sh
xcodebuild -project App.xcodeproj -scheme App -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/app-dd \
  CODE_SIGNING_ALLOWED=NO build 2>&1 | grep -E "error|BUILD"
APP=/tmp/app-dd/Build/Products/Debug-iphonesimulator/AppName.app
xcrun simctl uninstall $UDID io.example.appname   # install over an old build sometimes keeps the old one
xcrun simctl install $UDID $APP
SIMCTL_CHILD_APP_MUTE=1 SIMCTL_CHILD_APP_AUTOSTART=1 xcrun simctl launch $UDID io.example.appname
sleep 5; xcrun simctl io $UDID screenshot shot.png      # add --display=1 on multi-display devices
xcrun simctl terminate $UDID io.example.appname
```

Environment for the app goes through `SIMCTL_CHILD_` prefixes. `-key value` arguments after
the bundle id set UserDefaults for that launch.

When in doubt whether the new build is running: compare `stat` of the built binary with
`xcrun simctl get_app_container $UDID io.example.appname`.

## Reading the result

Screenshots are the proof. Habits that paid off:

- **Series, not single shots.** Animations, blinking artifacts and timing make one frame
  misleading. Take 6 to 40 frames at 0.2 to 1 s and build a contact sheet
  (`scripts/sheet.swift`: `sheet <dir> <count>` tiles `gj_1.png ... gj_N.png` into
  `sheet.png` with numbers). Read the sheet with the image viewer, then open the one frame
  that matters at full size.
- **Thumbnails for review.** `sips -Z 500 in.png --out small.png` before viewing; full-size
  captures waste context.
- **Probe pixels instead of eyeballing** when a check repeats: a 20-line Swift script with
  `NSBitmapImageRep.colorAt` answers "is the bar pink at (140,207)" or "how many near-black
  pixels in this corner" deterministically (`scripts/probe.swift`, `scripts/px.swift`).
- **Crops**: `sips -c <h> <w> --cropOffset <y> <x> in.png --out corner.png`.

## Video

```sh
xcrun simctl io $UDID recordVideo --codec h264 --force raw.mp4 &   # Ctrl-C (SIGINT) stops it
REC=$!; sleep 2; <launch>; sleep 34; kill -INT $REC; sleep 4
```

Output is the display's native size at up to 60 fps; no app audio is captured. The
`--mask` option only concerns rounded display corners.

## Traps (each cost an hour once)

- **`simctl spawn $UDID defaults write <bundle id> ...` survives an uninstall.** Delete such
  keys afterwards or a later test runs against stale state (a saved level past the free
  count locked the Play button for a whole session). `defaults read` through spawn may not
  show what the app wrote; the app's own container is the truth.
- **Multi-display devices**: the foldable iPhone reports two displays of the same size when
  folded; the inner one is black unless powered on, and powering it on does not move the
  app there. Screenshots need `--display=1` for the main one.
- **The camera disc**: the foldable's cover camera is painted as a black disc at the top
  right of captures, intermittently in screenshots and in every frame of a video. For
  screenshots take a series and keep a disc-free frame (`probe` the corner); for video
  patch the region from a clean screenshot (`scripts/preview-clean.swift`).
- **Hung simctl.** A `screenshot`, `terminate` or `launch` call can hang forever and every
  later call queues behind it. `pkill -f "simctl <verb> $UDID"`, then
  `simctl shutdown` and `boot`. Do not keep retrying on top of the hang.
- **Launch output matters.** `launch ... >/dev/null` hid a failed launch once; print the
  pid line.
- **Safe-area insets on odd devices.** One-sided insets break SwiftUI hit-testing at the
  edge; the root view ignored the safe area and re-applied insets as padding. Check swipes
  on every column with a UI test rather than assuming.
- **Timing.** Give the app 3 to 5 s after launch before the first screenshot; entrance
  animations and autoplay need it.

## UI tests headlessly

```sh
xcodebuild -project App.xcodeproj -scheme App -sdk iphonesimulator -destination id=$UDID \
  -derivedDataPath /tmp/app-dd CODE_SIGNING_ALLOWED=NO \
  -only-testing:AppUITests/SwipeTests test 2>&1 | grep -E "Test Case.*(passed|failed)|TEST (SUCCEEDED|FAILED)|error:"
```

`CODE_SIGNING_ALLOWED=NO` is required with `-destination id=` or the runner fails to sign.
`build-for-testing` once, then `test-without-building` for quick reruns. Environment for
the test runner itself needs the `TEST_RUNNER_` prefix on xcodebuild's environment (not as
a `KEY=VALUE` build setting). A test that fails only on the first run after a bundle-id or
`.storekit` change is the StoreKit test daemon holding the old configuration; the second
run passes.

To capture a screen only a UI test can reach (a loaded price), let the test hold it
(`sleep(15)`) and take `simctl io screenshot` from a parallel shell during the hold.

## Release build check

Build once with `-configuration Release` and confirm the Debug-only paths are gone (grep
the binary for a flag name, or just launch and see the flags do nothing). A hidden gesture
that only worked in Debug because its fallback was a Debug-only SwiftUI gesture is exactly
the bug this catches.
