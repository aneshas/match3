---
name: ios-app-shipping
description: End-to-end workflow for building a SwiftUI iOS app with Claude and taking it to the App Store without a human watching the simulator: XcodeGen project layout with a UI-free core package, Debug launch flags, driving a headless simulator with simctl (screenshots, contact sheets, video), XCUITests, StoreKit 2 one-time purchase with a local store file, asset and license hygiene, choosing an app name and bundle id, App Store screenshots at the exact sizes without alpha, product-page banners, the app preview video, listing texts, and the TestFlight and review checklist. Use this whenever the user wants to start, verify, test, screenshot, name, monetize, or publish an iOS or iPadOS app (game or not), asks how to see a SwiftUI change without opening Xcode, mentions App Store Connect, TestFlight, in-app purchase, screenshots, previews, or "how do we release this", even if they only ask about one step.
---

# Shipping an iOS app with Claude

This skill is the distilled workflow from building and releasing a SwiftUI app end to end,
including every step that happened outside the code. Read the phase you need; the
reference files hold the exact commands and sizes.

| Phase | Read |
|---|---|
| Project layout, Debug flags, testability | `references/project-setup.md` |
| Seeing and testing changes with no Xcode UI | `references/headless-simulator.md` |
| In-app purchase and its tests | `references/storekit.md` |
| Name, bundle id, licenses, store texts | `references/naming-and-listing.md` |
| Screenshots, banners, preview video | `references/store-assets.md` |
| App Store Connect, TestFlight, review | `references/publishing.md` |

Scripts in `scripts/` are the tools those phases use (compositors, preview builder,
contact sheets). They are Swift and shell, need only Command Line Tools plus ffmpeg for
video, and are meant to be copied into the project's `Tools/` and adapted.

## The working style that made this work

**One item, verify, commit, report, wait.** The user hands over one change at a time.
Implement it, prove it on the simulator or in a test, commit with a message that says
what changed and why, report in a few lines, then stop. Scope creep is what the user
notices first; a commit per item keeps every decision reversible.

**The repo's own notes are the memory.** Keep three living documents from day one and
update them in the same commit as the change they describe:

- `CLAUDE.md`: design rules the app must never break, layout, how to build, run and
  verify, every Debug flag, every quirk discovered about the simulator or tests. Write it
  for a future session that remembers nothing.
- `ROADMAP.md`: planned work with checkboxes; tick as items ship.
- `PUBLISH.md`: every manual step to the App Store, who does it (user or Claude), ticked
  as done, plus an "open decisions" list at the end. Store texts and assets live in
  `Store/`.

When the user says not to use memory for a project, this is the substitute, and it is the
better one: the notes travel with the code.

**Prove it, do not assume it.** A change is done when a screenshot, a test, or a probe of
the built artifact shows it. Headless verification is cheap once set up (see the
simulator reference), so there is no reason to report "should work".

**Report outcomes plainly.** If a test failed, show the line. If a step was skipped (a
two-finger gesture cannot be simulated, a license PDF is missing), say so and say what
would close the gap.

## Phase overview

1. **Set up** (`project-setup.md`): XcodeGen `project.yml`, a local Swift package for all
   logic with no UI imports (it builds and tests with Command Line Tools alone), the app
   target, a UI test target, a `.storekit` file on the scheme, Debug-only launch flags read
   from the environment, accessibility identifiers and a Debug-only counters label so UI
   tests and headless checks can read state. Swift 5 language mode avoids concurrency churn
   in a prototype.

2. **Verify headlessly** (`headless-simulator.md`): create a simulator that is yours alone,
   build with `-derivedDataPath` and `CODE_SIGNING_ALLOWED=NO`, uninstall before install,
   launch with `SIMCTL_CHILD_` environment flags, screenshot series into contact sheets,
   record video. Know the traps: `defaults` written with `simctl spawn` survive uninstall;
   the install sometimes silently keeps the old build; simctl calls hang and need a
   simulator restart; foldable devices paint a camera disc into captures.

3. **Test with real touches**: XCUITests for anything gesture-shaped (every column accepts
   a swipe, the hidden panel opens, the purchase flips the UI). Run one class at a time
   with `-only-testing`. A test that holds a screen open is also the way to capture states
   headless launches cannot reach, such as a loaded price.

4. **Monetize** (`storekit.md`): StoreKit 2, one non-consumable, entitlements as the truth
   with a UserDefaults cache, `Transaction.updates` for Ask to Buy and refunds,
   `AppStore.sync()` as restore, a parental gate if children use the app. `SKTestSession`
   in a UI test buys it without a sheet.

5. **Name and texts** (`naming-and-listing.md`): check App Store name availability by
   searching the store and knowing the trademarks in the category (anything with "Crush"
   or "Candy" belongs to King). Decide the bundle id before the first upload, since it can
   never change. Track every asset's license in the repo. Write subtitle and keywords for
   the words people type; the description is not indexed.

6. **Assets** (`store-assets.md`): screenshots at the exact required sizes, PNG without an
   alpha channel (App Store Connect rejects transparency), composed on the app's own
   colors with a caption each; the 1024-square in-app purchase review image; text-free
   header and search banners; a 15 to 30 second preview with a stereo audio track.

7. **Publish** (`publishing.md`): developer account, agreements, Small Business Program,
   the App Store Connect record, in-app purchase record, privacy "data not collected",
   Accessibility Nutrition Label, TestFlight with sandbox purchases, review notes that
   explain hidden gestures, build number bump per upload.

## Decisions worth making early

- **iPad or iPhone only.** Supporting iPad means iPad screenshots are mandatory and review
  runs the app on one. Drop it with one line in `project.yml` if nobody will test it.
- **Where debug conveniences live.** Environment flags are read only under `#if DEBUG`, so
  a Release build cannot be put in demo mode. Anything a tester needs on a device must
  therefore be reachable another way (a hidden gesture, a Debug-only panel toggle).
- **Hidden gestures.** A pass-through hit test breaks multi-finger recognizers: UIKit
  hit-tests the first finger alone, so it goes to the view below and the recognizer never
  sees two touches. Give the recognizer a view that owns every touch on it.
- **What gets committed.** Store PNGs and the preview video are release assets; commit
  them so they are reproducible, but keep raw sources (ogg music, render output) out via
  `.gitignore`. Never commit licensed art to a public repo.

## When the user asks about only one step

Answer that step from the matching reference and do the work; do not re-walk the whole
pipeline. If the step changes something release-related (name, bundle id, price, a
license, an asset), update `PUBLISH.md` in the same commit so the checklist stays true.
