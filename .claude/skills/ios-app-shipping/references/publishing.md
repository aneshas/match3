# Publishing checklist

Keep this as `PUBLISH.md` in the repo, ticked as things happen, with "(you)" for the
user's steps and "(ask Claude)" for repo changes. The order below is the order things
block each other.

## 1. Apple Developer account (user)

- Apple ID with two-factor authentication that will be kept for years.
- Individual (fast, personal name as seller) or Organization (D-U-N-S number, up to two
  weeks, company as seller). Apps can move to an organization later.
- Enroll (99 USD/year); the Apple Developer app on an iPhone is usually approved within
  days. Sign in to Xcode and confirm the team id matches `project.yml`.
- Accept the Paid Apps agreement under Business (bank, tax forms, contact); without it the
  in-app purchase cannot be tested in TestFlight or sold.
- Apple Small Business Program: 15 % instead of 30 %; enroll before the first sale.

## 2. Name, identifiers, legal

See `naming-and-listing.md`. Outputs: final name and subtitle, bundle id and product id
settled, privacy policy and support pages hosted, every asset license in the repo.

## 3. Devices and testing

- Run the Release configuration once on a real device: Debug flags must do nothing.
- iPad: either test the landscape layout on one or ship iPhone-only
  (`TARGETED_DEVICE_FAMILY: "1"`).
- Accessibility pass with Reduce Motion, Increase Contrast, largest Dynamic Type,
  VoiceOver through the text parts.
- A session with the intended users; notes go to ROADMAP.
- Sandbox purchase test on the device (`storekit.md`).

## 4. App Store Connect record

- New App: platform, name, primary language, bundle id (registered at
  developer.apple.com or by Xcode), SKU (any string), full access.
- In-app purchase (`storekit.md`), attached to the first version.
- App information: subtitle, categories, content rights, age rating questionnaire,
  Accessibility Nutrition Label.
- Pricing and availability: Free, territories, "Available for volume purchase" so
  institutions can buy through Apple Business Manager and Apple School Manager.
- App privacy: "Data not collected".
- Version information: description, keywords, promotional text, What's New, support and
  marketing URLs, copyright. Screenshots and previews per slot (`store-assets.md`).
  Header and search assets. Review notes and contact; "sign-in not required".
- Export compliance is answered by `ITSAppUsesNonExemptEncryption: false` in the build.

## 5. Build and upload (user, Claude prepares)

- Bump `CURRENT_PROJECT_VERSION` for every upload (and the checked-in Info.plist if it
  carries `CFBundleVersion`); `xcodegen generate`.
- Xcode: "Any iOS Device (arm64)", Product > Archive, Organizer > Distribute App > App
  Store Connect. Or export the `.ipa` and use Transporter.
- TestFlight: internal testers first (no review), then play a session and test the
  purchase. External testers need a short review.
- Submit for review with the build and the in-app purchase attached; "Manually release"
  to control launch day.

## 6. After approval

- Release; buy the unlock once with a real account and refund via
  reportaproblem.apple.com if unwanted.
- Confirm the Small Business Program is active before the first sales.
- Reply to reviews; watch Xcode Organizer > Crashes (no third-party reporter needed).
- Next version: bump the build number, repeat step 5; keep ROADMAP as the plan.

## Open decisions section

End the file with a bullet list of what the user still has to decide (price, iPad,
licenses, account type). Remove bullets as decisions land and move them into the steps.
This list is what the user reads when they ask "what's left".
