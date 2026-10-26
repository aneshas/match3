# In-app purchase with StoreKit 2

One non-consumable unlock is the simplest honest model for an app without ads or
subscriptions. This is the implementation shape and how to test it at every stage.

## Implementation

- A protocol (`isUnlocked`, `displayPrice`, `isBusy`, `purchase()`, `restore()`) so the UI
  never imports StoreKit and a stub can drive previews and tests.
- The StoreKit 2 implementation:
  - `Product.products(for: [id])` at init; `displayPrice` nil until it loads, and the Buy
    button is disabled while nil (that is what a tester sees when the product is not set up
    in App Store Connect yet).
  - Current entitlements are the truth (`Transaction.currentEntitlements`, verified, no
    `revocationDate`); a UserDefaults cache keeps the unlock instant at launch and offline.
  - Listen to `Transaction.updates` for Ask to Buy approvals, family sharing and refunds,
    and `finish()` every transaction.
  - `purchase()` returns an outcome enum: unlocked, pending (Ask to Buy), cancelled,
    unavailable, failed(message). The UI shows pending as "waiting for approval".
  - `restore()` is `AppStore.sync()` followed by re-reading entitlements.
  - A Debug flag (`APP_UNLOCKED=1`) behaves as if bought, for headless runs.
- Family Sharing: enable it on the product in App Store Connect (irreversible) and nothing
  else; entitlements cover family members.
- If children may hold the device, put Buy behind a parental gate (a multiplication
  question in an alert) and keep the purchase UI inside a hidden settings panel. Apple's
  Kids rules also require this for external links.

## Local store file

`App.storekit` at the repo root with the product (id, type NonConsumable, price,
localization, `familyShareable: true`). Set it on the scheme's run action so Xcode runs
show a price; add it to the UI test target's resources so `SKTestSession` can load it.
Headless `simctl launch` has no store attached, so the Buy button stays disabled there;
use the UI test below to see or screenshot a price.

## UI test of the purchase

```swift
let session = try SKTestSession(configurationFileNamed: "App")   // the .storekit name
session.disableDialogs = true
session.clearTransactions()
let app = XCUIApplication()
app.launchEnvironment = ["APP_MUTE": "1", "APP_PANEL": "1"]
app.launch()
// scroll to the buy row, assert its label contains the price, tap, answer the gate,
// assert the unlocked state, terminate, relaunch, assert it survived.
```

Clear the simulator's cache key before and after (`simctl spawn $UDID defaults delete
<bundle id> allLevelsUnlocked`). The first run after a bundle-id or `.storekit` change
fails with "price not shown"; the test daemon still holds the old configuration and the
second run passes. Say so in CLAUDE.md so nobody debugs it twice.

## App Store Connect side

- Create the in-app purchase under the app: non-consumable, reference name, product id
  exactly as in the code, price tier, localized display name and description, a review
  screenshot (1024 x 1024 of the panel with the Buy row), Family Sharing on. Status must
  reach "Ready to Submit" for TestFlight to load it; submit it with the first version.
- The Paid Apps agreement (banking, tax) must be active or no product loads anywhere
  outside the simulator.

## Testing on TestFlight

TestFlight builds talk to the sandbox: the sheet says "[Environment: Sandbox]" and nothing
is charged. Buy from the panel, confirm with the tester's own Apple Account, kill and
relaunch, then delete and reinstall and tap Restore. To buy again, clear purchase history
under Settings > App Store > Sandbox Account (older iOS: Settings > Developer), then delete
the app so its cache is gone. Ask to Buy and Family Sharing need sandbox tester accounts
from App Store Connect > Users and Access > Sandbox, signed in under that same Settings
section, with Ask to Buy enabled on a child tester or two testers in a sandbox family.

## Free part design

If part of the app is free, decide what resetting progress does. A caregiver reset that
starts over should not extend the free part forever: keep a lifetime counter that the
reset does not clear, and lock when either the free count or the lifetime cap is reached.
Expose the counters in the settings panel so the rule is visible.
