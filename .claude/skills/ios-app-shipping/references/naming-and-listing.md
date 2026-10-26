# Name, identifiers, licenses, listing texts

## Choosing the name

The App Store name must be unique worldwide and is the strongest search field. Process
that worked:

1. Propose five to eight short names with a feeling, not a feature list.
2. For each favourite, search the App Store on the web (`site:apps.apple.com "<name>"`)
   and read the hits. Three outcomes: the exact name exists (rejected by App Store Connect,
   move on); the two words are shared by a crowd of similar apps (allowed, but the app
   would be the sixth result for its own name, move on); nothing close (candidate).
3. Know the category's trademarks. In casual games King owns "Candy" and "Crush" for
   games; Apple accepts many "... Crush" apps, but a complaint after launch means a
   rename. Flag it and let the user decide; record the decision in PUBLISH.md.
4. The App Store Connect "New App" form is the only definitive check. Keep two fallbacks.

Display name under the icon truncates at about 12 characters.

## Renaming the app in the repo

Only the user-visible things need to change; Xcode target, scheme, module and folders can
keep their working name forever (nothing the store or the player sees uses them):

- `project.yml`: `CFBundleDisplayName`, `PRODUCT_NAME` (the .app name; no spaces),
  `PRODUCT_BUNDLE_IDENTIFIER`; the checked-in Info.plist if it carries the display name.
- The StoreKit product id in code and in the `.storekit` file.
- Store texts, privacy policy, CLAUDE.md, PUBLISH.md, the headless commands (bundle id,
  .app path), the simulator's leftover installs (`simctl uninstall` the old id).
- Rebuild, run the purchase UI test (twice, see storekit.md), screenshot the home screen
  to see the name under the icon.

The bundle id cannot change after the first upload to App Store Connect; the product id
is independent but should be settled at the same time.

## Licenses

Every third-party asset gets its license text next to it in the repo (`LICENSE-<source>`
in the asset folder) and a line in PUBLISH.md. Ask the user where unknown assets came
from before release; if a source is a store page without the license text, ask for the
PDF or text that came with the download. Attribution requirements go on the support page
and in the description. Paid icon packs usually forbid redistribution: keep the repo
private and say so in CLAUDE.md.

Sound conversion that worked: ffmpeg to mono 44.1 kHz Int16 `.caf`, silence trimmed,
peak-normalized; music to AAC 96 kbps `.m4a` loudness-normalized with `loudnorm` to a
quiet target, discovered from the bundle so adding a track is dropping in a file.

## Listing texts (`Store/listing.md`)

| Field | Limit | Notes |
|---|---|---|
| Name | 30 | The chosen name only; no taglines, Apple rejects keyword stuffing. |
| Subtitle | 30 | Indexed for search: the words the audience types ("for special needs", "for seniors"). |
| Keywords | 100 | Comma-separated, no spaces after commas, no words already in name or subtitle, no plurals of them. Avoid dated or offensive terms nobody searches. |
| Promotional text | 170 | Editable without a new build. One line that says what is different. |
| Description | 4000 | Not indexed. Lead with who it is for and what it never does (ads, timers, text), then how it works, then the caregiver or admin features, then the purchase and the free part, then accessibility. |
| What's New | 4000 | "First release." |
| Copyright | 200 | `2026 Full Name` |
| Support URL | required | A public page with a contact; `Store/site/index.html` is a hostable template. |
| Privacy policy URL | required | Even for "data not collected". `Store/site/privacy.html`. |
| Review notes | | Explain hidden gestures, where the purchase is, that no sign-in exists. |

Apple indexes name, subtitle and keywords, then ranks by ratings and downloads. Early
honest ratings from the people the app is for do more than any keyword.

## Age rating and privacy

All questionnaire answers "None" gives 4+. App privacy: "Data not collected" when there
is no analytics SDK; keep it true forever. Fill in the Accessibility Nutrition Label
(Reduced Motion, Sufficient Contrast, Larger Text, VoiceOver only after checking).
