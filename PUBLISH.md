# Publishing checklist

Everything that has to happen outside the code to get this game onto the App Store, in
order, starting from no Apple Developer account. "You" items need you (Apple ID, money,
legal decisions). "Ask Claude" items are repo changes I can make as soon as you give me
the input. Tick items here as they are done; this file is the single place that tracks
release readiness.

The app is called **Gummy Joy** (chosen 25 October 2026: "Jelly Joy", "Jelly Crush", "Jelly Pop" and "Bonbon" were taken or crowded, "Bonbon Crush" dropped over King's "Crush" trademarks); the subtitle is "Calm match-3 for special needs". Bundle id `io.anes.gummyjoy`, product id `io.anes.gummyjoy.unlock`.

## 1. Apple Developer account (you)

- [ ] **Apple ID with two-factor authentication** that you want to publish under. Use the one you will keep for years; the account cannot be moved to another Apple ID later.
- [ ] **Decide Individual vs Organization.** Individual: fastest, no paperwork, the App Store shows your personal name as the seller. Organization (e.g. a company): needs a D-U-N-S number (free, takes up to two weeks), a legal entity and authority to sign; the seller name is the company. For a one-person project Individual is fine; you can transfer the app to an organization account later.
- [ ] **Enroll** at <https://developer.apple.com/programs/enroll/> (99 USD/year, or local equivalent). Enrollment through the Apple Developer app on an iPhone is usually approved within a day or two; the website route can take longer.
- [ ] **Sign in to Xcode** with that Apple ID (Xcode > Settings > Accounts) and check the team shows as "Apple Development" with the paid program. `project.yml` currently carries team `59H75BATX8`; if the paid team is a different one, tell me the new ID (ask Claude).
- [ ] **Accept the agreements** in App Store Connect > Business (formerly Agreements, Tax, and Banking): the free Apple Developer Program License Agreement, and the **Paid Apps Agreement**, which needs bank account, tax forms (W-8BEN for non-US individuals) and contact details. Without the paid agreement the in-app purchase cannot be tested in TestFlight or sold.
- [ ] **Apple Small Business Program**: once the paid agreement is in place, enroll at <https://developer.apple.com/app-store/small-business-program/> to pay 15 % instead of 30 % commission. Takes a few days; enroll before the first sale.

## 2. Name, identifiers, legal (you, then ask Claude)

- [x] **Choose the app name**: Gummy Joy, subtitle "Calm match-3 for special needs". Fallbacks if App Store Connect rejects it: "Jelly Hug", "Jelly Calm", "Bonbon Calm".
- [x] **Bundle identifier**: `io.anes.gummyjoy` (cannot be changed after the first upload to App Store Connect). StoreKit product id: `io.anes.gummyjoy.unlock`.
- [x] **Name applied in the repo**: display name under the icon (`CFBundleDisplayName` "Gummy Joy"), product name (`GummyJoy.app`), bundle id, product id, StoreKit test file, store texts and privacy policy. The Xcode target, scheme, module and folders keep the working name `Match3` (internal only, nothing the store or the player sees).
- [ ] **Privacy policy page** (required, public URL, even though the app collects nothing). The text is ready in `Store/privacy-policy.md`; put it on your own site or a GitHub Pages page, add the support email, then give me the URL so the caregiver panel can link to it (`AppLinks.privacyPolicy`).
- [ ] **Support URL** (required): an email address on a simple page, or the same page as the privacy policy with a contact line.
- [ ] **Marketing URL** (optional).
- [ ] **Licenses of the assets**, so nothing can trip App Review or a rights claim:
  - Candy icons: Robert Brooks "Match three candy" pack, commercial use allowed, no attribution needed, no redistribution. Fine inside the app; keep the repo private.
  - Hand cursor and the original effect sounds: Kenney, CC0.
  - **Music loops (17 tracks) and the new effect sounds**: source and license still unknown to the repo. Tell me where they come from so I can add the license text; if any needs attribution, it goes on the privacy/support page and in the App Store description.
  - Code-drawn art and app icon: yours.

## 3. Devices and testing before the store (you + Claude)

- [ ] **Run on your iPhone Duo via Xcode** with the final build settings (Release scheme once, to make sure Debug-only flags are really gone).
- [ ] **iPad check.** The app targets iPhone and iPad (`TARGETED_DEVICE_FAMILY 1,2`), so App Review will run it on an iPad and iPad screenshots are mandatory. Landscape layout has never been seen on a real tablet. Either borrow an iPad / use the unfolded Duo and send me screenshots, or decide to ship iPhone-only for version 1 (ask Claude: one line in `project.yml`, and no iPad screenshots needed).
- [ ] **Accessibility pass** on the device: Reduce Motion on, Increase Contrast on, largest Dynamic Type (the caregiver panel is the only text), VoiceOver through the caregiver panel.
- [ ] **Sister test**: a few sessions with the intended player; note what confuses her and tell me.
- [ ] **In-app purchase test** on the device with a Sandbox tester account (App Store Connect > Users and Access > Sandbox > Testers; any unused email). Buy, delete the app, reinstall, Restore. Then check Family Sharing with a second sandbox account in the same sandbox family if you want.

## 4. App Store Connect setup (you)

- [ ] **Create the app record**: App Store Connect > Apps > "+" > New App. Platform iOS, name, primary language, bundle id (register it first at <https://developer.apple.com/account/resources/identifiers/list> or let Xcode do it), SKU (any string, e.g. `gummyjoy-001`), full access.
- [ ] **In-app purchase**: Apps > your app > In-App Purchases > "+": type Non-Consumable, reference name "All levels", **product id exactly as in the code** (`io.anes.gummyjoy.unlock`), price (suggested 9.99 USD tier, the roadmap argues for 7.99–12.99), localized display name "All levels" and description "Every level, forever. No ads, no timers, no losing.", a review screenshot (any screenshot of the caregiver panel's unlock section), **Family Sharing: on** (cannot be turned off again). Submit the IAP with the first app version.
- [ ] **App information**: subtitle, category Games > Puzzle (secondary: Family or Education), content rights (no third-party content: yes, the assets are licensed), age rating questionnaire (all "None" → 4+).
- [ ] **Pricing and availability**: Free, all countries (or your pick). Tick "Available for volume purchase" (Apple Business Manager / Apple School Manager) so care homes and schools can buy in bulk. If you want the app discoverable by institutions only via code, use "Custom app" distribution instead (not now).
- [ ] **Being found**: App Store search ranks the name, subtitle and keyword field (the description is not indexed), then ratings and downloads. The subtitle and keywords in `Store/listing.md` carry the terms caregivers type ("special needs", "autism", "disability", "seniors", "dementia", "kids"). Also fill in the **Accessibility Nutrition Label** on the product page (App Store Connect > App Information > Accessibility): tick Reduced Motion, Sufficient Contrast (high-contrast mode), Larger Text (caregiver panel), and VoiceOver only after the panel has been checked with it. Consider the Kids category only if you accept its rules (no external links without a parental gate, which we have; no third-party analytics or ads, which we have none of); it is a second storefront placement, not a ranking boost, and it puts an "age band" on the listing.
- [ ] **Ask friends and institutions for a few honest ratings** right after launch: with a brand-new app the ratings count is what moves it up for a search term.
- [ ] **App privacy**: "Data not collected" for every category. Keep it true: no analytics SDK, ever.
- [ ] **Version information**: description, keywords, promotional text, "What's New", copyright and the URL fields are in `Store/listing.md` (section "Product page fields"); paste them in. The support URL needs a hosted page first (`Store/site/`).
- [x] **Screenshots** in `Store/screenshots/`, six per size in upload order (Play, swipe, shaped board, Good Job, caregiver panel, high contrast), all PNG without alpha (App Store Connect rejects transparency, which is what the first batch had): `iphone-6.3/` 1206 x 2622 (**required**: at least one for "iPhone with Dynamic Island, medium"), `iphone-6.9/` 1320 x 2868 (large Dynamic Island; optional, falls back to 6.3"), `iphone-duo-outer/` 1398 x 2034 (optional until April 2027, earns the "optimized for iPhone Duo" badge), `ipad-13/` 2064 x 2752 (**required while iPad is supported**). Each is a simulator capture on the app's gradient with a one-line caption (`Tools/compose-screenshot.swift`; captures come from the headless Duo simulator, the only device type the installed runtime has, so the frames are composed rather than full-bleed). The in-app purchase review screenshot is `Store/screenshots/iap-all-levels-1024.png` (1024 x 1024, the panel's "All levels" section with the price). `Store/screenshots/product-page/` holds the landscape **header and search results assets** (`Tools/compose-banner.swift`: universal 16:9 5244 x 2950 PNG for both slots, header 21:9 3840 x 1646, search 3:2 3840 x 2560; text-free, no alpha). Redo them if the panel texts or the price change.
- [ ] **App preview video**: optional, skip for version 1.
- [ ] **App Review information**: contact name, phone, email. Notes for the reviewer are drafted in `Store/listing.md`.
- [ ] **Sign-in**: not required, say so in the review form.
- [ ] **Export compliance**: already answered in the build (`ITSAppUsesNonExemptEncryption = false`), so no questions at upload.

## 5. Build and upload (you, with Claude's prep)

- [x] **Version and build number**: `MARKETING_VERSION` 1.0 and `CURRENT_PROJECT_VERSION` 1 in `project.yml`. Bump the build number for every upload (ask Claude, or edit the line).
- [x] **App icon**: rendered opaque by `Tools/render-art.sh` (no alpha channel, square; iOS rounds the corners).
- [x] **Launch screen**: `UILaunchScreen` with the cream `LaunchBackground` color, so the start does not flash white.
- [x] **Release configuration builds** (checked on the simulator; Debug-only flags and the logo hold compile out).
- [ ] **Archive**: open `Match3.xcodeproj` in Xcode, pick "Any iOS Device (arm64)", Product > Archive. (`xcodegen generate` first if `project.yml` changed.) Signing is automatic with the team in `project.yml`.
- [ ] **Upload**: Window > Organizer > Distribute App > App Store Connect > Upload. Or export the `.ipa` and use the Transporter app.
- [ ] **TestFlight**: internal testing with your own Apple ID first (no review needed), then optionally external testers (short Apple review). Install on the Duo through the TestFlight app and play a session; test the purchase with the sandbox account.
- [ ] **Submit for review**: attach the build to version 1.0, make sure the IAP is attached, submit. Choose "Manually release this version" if you want to control launch day.

## 6. After approval

- [ ] **Release** (if manual).
- [ ] **Check the IAP is live** and buy it once with a real account, then refund yourself via <https://reportaproblem.apple.com> if you do not want to keep the charge.
- [ ] **Small Business Program** confirmed active (step 1), otherwise you pay 30 % on the first sales.
- [ ] **Respond to reviews** in App Store Connect; the audience's caregivers write detailed ones.
- [ ] **Crashes**: Xcode > Organizer > Crashes, or App Store Connect > TestFlight > Crashes. No third-party crash reporter.
- [ ] **Volume purchase**: once live, institutions buy through Apple Business Manager; mention it on the support page.
- [ ] **Next version**: bump build number, repeat step 5. Roadmap items live in `ROADMAP.md`.

## Open decisions (answer in chat, I update this file)

- iPad support in version 1, or iPhone-only.
- Price of the unlock.
- Source and license of the music and the new sounds.
- Own sounds for the rainbow candy, the bomb and combos (they reuse the striped/wrapped sounds layered with the big-match sound for now).
- Individual or Organization developer account.
