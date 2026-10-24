# Roadmap

Tasks for the match-3 game for players with intellectual disabilities. Keep the design
rules in `CLAUDE.md` in mind for every item: one gesture, never lose, no reading required,
no pressure. Check items off as they ship.

Suggested order: sound, first-level swipe demo, adaptive difficulty, caregiver panel.

## 1. Making it easier to play

- [x] **Teach by doing.** Until the player's first successful swipe ever, a pointing hand (Kenney cursor, CC0) appears right after the board lands, presses on a candy and drags it to the neighbor while both candies pulse; it repeats every 3 s while the player stays idle. No text. `MATCH3_FORGET_SWIPE=1` resets it for testing.
- [x] **Escalating hint.** The same valid move is pulsed after 8 s, glows gold with a bigger pulse after 16 s, and gets a `HintArrowView` between the two candies after 24 s. Any touch resets it.
- [x] **Fewer colors for longer.** 3 colors through level 12, 4 through 24, 5 through 40, 6 after; size and shape carry the difficulty first. The caregiver color cap can hold it at 5 if testing shows 6 is too many.
- [x] **Introduce shapes gently.** Opening levels: 4x4, tall, wide, rounded corners, diamond, triangle, cross, heart; each shape has a minimum board size so it never collapses into a blob.
- [x] **Quiet adaptive difficulty.** `AssistPolicy` turns per-level stats (invalid swaps, hints, time per match) into an assist level 0–3; each step removes a color and lowers the goal, 2+ also trims a row and column. Smooth levels relax it back. Never shown. `MATCH3_ASSIST=n` forces it for testing.
- [x] **Bigger candies on small boards.** Boards up to 5x5 may use cells up to 150pt (others 110pt) and the board inset shrank now that the tray is gone, so opening boards fill the width on phones and grow on larger screens.
- [x] **iPad and landscape.** All orientations enabled. Landscape puts a vertical progress bar beside the board; Play lays logo and button side by side; Good Job and good-night scale with the short side. Verified by build only: the iPhone Duo cover screen in the simulator stays portrait, so check rotation on an iPad or the unfolded display.

## 2. Feedback and motivation

- [x] **Background music.** 17 gentle loops cycle: a new one on every Play screen visit and every level, crossfaded, faded out quickly on Good Job. Caregiver toggle, quiet when another app plays audio.
- [x] **Sound as the main reward.** Match (two alternating plucks), big match, level done jingle, soft "bong" for invalid swaps, shuffle whoosh, Play tap. Mute lives in the caregiver panel.
- [x] **Match-to-bar sparkle.** A gold burst fires at the end of the fill (top of the fill in landscape) on every gain, alongside the pulse.
- [x] **Candy jar collection.** The jar sits on the Good Job screen under the text; a candy flies from the star into it, the jar bounces and shows one more (one candy per finished level). No rules, no unlocks. Not shown on the Play screen.
- [x] **No streaks.** (Checked: nothing in the app depends on dates except the caregiver's finished-levels count.) No daily streaks, no "come back tomorrow", nothing lost on days off. (Design rule; verify nothing added later breaks it.)
- [x] **Fixed celebration length.** `GoodJobScreen.duration` (5.5 s) is constant; the candy drop fits inside it.

## 3. Caregiver panel

- [x] **Hidden entry gesture.** Three fingers held 3 s on the Play screen (`ThreeFingerHold`); single-finger touches pass through to Play.
- [x] **Panel contents:** sound, vibration, color cap 3–6, start again from level 1 (with confirmation), stats (current level, finished last 7 days, total). Still to add here: purchase.
- [x] **Session timer.** Caregiver picks 5–60 minutes or no limit. When it runs out the current level finishes, Good Job plays, then `GoodNightScreen` (dimmed light, sleeping candy, twinkling stars, spoken "See you soon!") and back to Play. `MATCH3_SESSION_SECONDS=n` for testing.
- [x] **Guided Access reminder.** Note in the panel's Tips section.

## 4. Monetization

### What comparable apps do

- **Mainstream match-3 (Candy Crush, Royal Match, Toon Blast):** free, with money made from boosters, extra moves, lives and rewarded ads. Every one of those levers is a pressure mechanic this game has deliberately removed, so this model has nothing to sell here.
- **Kids' games (Toca Boca, Sago Mini, Dr. Panda):** historically paid up front with no ads, later moved to a family subscription bundling many apps. Apple's Kids Category rules also forbid behavioral ad tracking and require a parental gate before any purchase or external link.
- **Special-needs and therapy apps (Otsimo, Proloquo2Go, Avaz, MindMate):** either a high one-time price paid by families and institutions, or a subscription with a trial. Buyers are caregivers, not players, and they compare against therapy costs, so prices in the tens or hundreds are normal.
- **Common thread:** the player is never the customer. The caregiver decides, usually once, and values "no surprises" above everything.

### Options

| Model | Pros | Cons |
| --- | --- | --- |
| **A. Paid up front** (e.g. 4.99–9.99) | Simplest, no ads, nothing in the app can go wrong. Matches how you wanted to buy it. | No way to try first; most caregivers will not pay blind for an unknown app. Apple takes 15–30 %. |
| **C. Free to try, one-time unlock, no ads** | Try the first N levels free, then one purchase in the caregiver panel unlocks forever. Clean experience for the player; caregiver decides with full information. | Needs a parental gate and a clear "stop" moment that does not feel like failure. |
| **D. Subscription** | Recurring revenue, standard in special-needs apps. | Families and care homes dislike it for a single game; churn and refund handling; feels wrong for a game this small. |
| **E. Institutional licensing** (Apple Business/School Manager volume purchase, custom B2B) | Care homes, schools and day centers buy 10–50 licenses at once. | Needs outreach; works alongside C, not instead. |

### Recommendation

Go with **C now and E later**. Drop ads entirely unless downloads are huge and revenue from C disappoints.
Yes let's go with C

- **Free part:** the first 15–20 levels, playable forever and replayable. This is the whole "is it right for my sister" test a caregiver needs.
- **The stop moment:** when the free levels run out, the next Good Job screen ends with the candy jar and a single soft lock icon, no text, and the game returns to the Play screen, whose button now shows a lock. A caregiver unlocks or resets. Nothing looks like losing.
- **The purchase:** one non-consumable "Unlock all levels" in the caregiver panel only, behind the three-finger hold and a parental gate (e.g. "hold for 3 seconds" or a simple sum). Price around 7.99–12.99; this audience's caregivers are used to paying more for far less polished apps, and a low price signals "disposable". Enable Family Sharing so one buy covers the household.
- **Why not ads at all:** besides confusing the player, ad networks require privacy disclosures, consent prompts and age gating that collide with Apple's Kids Category rules if the app is listed there. The removal of ads is the cleanest story in the App Store listing: "No ads. No timers. No losing."
- **Optional, zero-risk extras:** a "Buy the developer a coffee" tip in the caregiver panel for people who already paid and want to say thanks; a visible note that institutions can buy in volume.
- **Apple Small Business Program:** enroll (under 1 M USD/year) to pay 15 % instead of 30 %.
- **App Store positioning:** list in Games > Puzzle, not the Kids Category, unless you are ready for its stricter review; the target group includes adults. Describe the audience plainly in the first two lines of the description.

### Tasks

- [x] **Free-level count:** 20 (`AppFlow.freeLevels`). `MATCH3_FREE_LEVELS=n` and `MATCH3_UNLOCKED=1` for testing.
- [x] **Lock behavior:** after the last free level Good Job plays fully, a soft lock settles on the jar, then back to Play, where the button shows a lock and does nothing until a caregiver unlocks all levels or starts again from level 1. No text.
- [x] **StoreKit 2 store** `StoreKitUnlockStore`: one non-consumable `io.kurrent.match3.unlock`, restore purchases, Ask to Buy handled. Still to do in App Store Connect: create the product with that ID and turn on Family Sharing. `Match3.storekit` is the local test store (price 9.99 placeholder).
- [x] **Parental gate** in the caregiver panel before the purchase button: a multiplication question (3–9 × 3–9) in an alert; wrong answers just return to the panel.
- [x] **Purchase screen** in the caregiver panel: price, what you get, restore button; the privacy policy link appears once `AppLinks.privacyPolicy` is set.
- [ ] **Tip jar** non-consumables (optional, caregiver panel only).
- [x] **Volume purchase**: the panel line is in. Still to tick in App Store Connect: "Available for volume purchase" (see PUBLISH.md).
- [ ] **Enroll in the Apple Small Business Program.**
- [x] **Privacy label and policy** with no tracking (policy text in `Store/privacy-policy.md`, label answers in `Store/listing.md`); keep it that way (no analytics SDK that fingerprints; if analytics are wanted, use Apple's or a first-party counter).
- [x] **Ads dropped entirely** (option C). The ad hook was removed; `UnlockStore` is the only monetization seam.

## 5. Accessibility details

- [x] **High contrast option.** Thicker dark outline around candies, darker cells. Caregiver toggle; also follows iOS Increase Contrast. `MATCH3_HIGH_CONTRAST=1` previews it.
- [x] **Keep layout fixed.** Star stays on the right for everyone; no layout customization.
- [x] **Haptics toggle** in the caregiver panel.

## 6. Assets to obtain

All art should match the existing candy set: glossy cartoon style, dark outline, 256x256
PNG with transparency (or larger, 512x512 is better for iPad). Keep file names lowercase
with underscores and drop them into `candy_game_2/` so the import script picks them up.

### Where the current candies come from (license check)

The candy set is Robert Brooks's **"Match three candy"** pack (`candy_game_2.zip`) from
[gamedeveloperstudio.itch.io](https://gamedeveloperstudio.itch.io/match-three-candy), $3.25+.
The [gamedeveloperstudio license](https://www.gamedeveloperstudio.com/license.php) allows
commercial use with no attribution, but **forbids redistributing the files** outside a built
app. Consequences:

- [x] Keep `candy_game_2/` and the asset catalog out of any public repository: `candy_game_2/` is not tracked; the repo must stay private because the catalog is.
- [ ] Keep the itch.io purchase receipt with the project.

### Found sources, per asset

Everything below is free. "CC0" means no attribution needed. Downloaded Kenney packs are
in the session scratchpad only; nothing has been added to the project yet.

| Asset | Source | License | Use these files / notes |
| --- | --- | --- | --- |
| Pointing hand for swipe demo | [Tapping finger](https://gamedeveloperstudio.itch.io/tapping-finger) by Robert Brooks (same artist as the candies) | gamedeveloperstudio license, name-your-price | Pressed + raised states, vector. Best style match. Fallback: Kenney [Cursor Pack](https://kenney.nl/assets/cursor-pack) `hand_point.png`, `hand_open.png`, `hand_closed.png` (PNG + SVG, Outline and Basic variants). |
| Hint arrow | `HintArrowView` (done, code-drawn) | n/a | Gold, outlined, nudges along its direction. Used by the escalating hint. |
| Sparkle particle | Kenney [Particle Pack](https://kenney.nl/assets/particle-pack) | CC0 | `star_01`…`star_09.png`, `spark_01`…`spark_07.png`, `twirl_01`…`03.png`, `light_01`…`03.png` in `PNG (Transparent)/`. White, tint in code. |
| Candy jar | Draw in code | n/a | No free jar in the candies' style was found. A glass jar is a rounded rect, a lid, two white highlight strokes, and the existing candy images inside; cheaper than hunting. If an image is wanted later: [SVG Repo jar icons](https://www.svgrepo.com/vectors/jar/filled/2) (check each icon's license, many are CC0/PD). |
| Waving / sleeping candy for session end | Reuse an existing candy + code-drawn closed eyes and "z z z", or Kenney `hand_open.png` waving | CC0 (Kenney) | No matching asset exists; code is the honest answer. SF Symbol `hand.wave.fill` is a fine fallback. |
| Gear, lock icons (caregiver panel) | SF Symbols `gearshape.fill`, `lock.fill`, `lock.open.fill` | Built into iOS | Only caregivers see them; style match is irrelevant. Robert Brooks's [Unlocking lock animation](https://gamedeveloperstudio.itch.io/unlocking-lock-animation) ($5) exists if an animated candy-style lock is ever wanted. |
| App icon 1024x1024 | Compose from the existing `jazzle.png` on the pink gradient | already owned | Can be generated with a short script (sips/ImageMagick) or in Figma. |
| High-contrast candy variants | The pack's vector source lets you re-export with a thicker stroke in Inkscape | already owned | Only if the code-drawn outline is not enough. |
| Match pop | [pop sounds 0](https://opengameart.org/content/pop-sounds-0) by EZduzziteh | CC0 | 9 WAV "poppy bubble" sounds. Also Kenney [Interface Sounds](https://kenney.nl/assets/interface-sounds) `pluck_001/002.ogg`, `glass_001`…`006.ogg`, `drop_001`…`004.ogg`. |
| Big match | Kenney Interface Sounds `confirmation_001`…`004.ogg`, or layer two pops | CC0 | |
| Invalid swap "boop" | Kenney Interface Sounds `bong_001.ogg` or the lowest `drop_00x.ogg` | CC0 | Avoid the pack's `error_*` files, they sound like alarms. |
| Candy landing | Kenney Interface Sounds `tick_001.ogg` / `click_00x.ogg` at low volume | CC0 | Optional; test for annoyance. |
| Level done | [Level Complete Splash](https://opengameart.org/node/157583) by GreyFrogGames | CC0 | MP3 + WAV. Alternative: Kenney [Music Jingles](https://kenney.nl/assets/music-jingles) `Pizzicato jingles/jingles_PIZZI00`…`16.ogg` or `Steel jingles/` (warm, short, 85 files, CC0). |
| Shuffle whoosh | Kenney Interface Sounds `maximize_00x.ogg` / `scroll_00x.ogg` | CC0 | |
| Play button tap | Kenney Interface Sounds `select_00x.ogg` / `click_00x.ogg` | CC0 | |
| Voice "Good job!" | iOS `AVSpeechSynthesizer` | built in, free | Speaks in the device language with no asset files. Record a human voice only if the synthetic one tests badly. Caregiver recording covers the personal version. |
| Background loop (optional) | [Heavenly Loop](https://opengameart.org/content/heavenly-loop) by isaiah658 | CC0 | Seamless, dreamy, OGG/FLAC. Also OGA's "CC0 – Calm / Relaxing Music" collection. Default off. |
| Font | [Fredoka](https://fonts.google.com/specimen/Fredoka) or [Baloo 2](https://fonts.google.com/specimen/Baloo+2) on Google Fonts | SIL OFL 1.1 | Both rounded, both allow bundling in an app. No text is rendered in play any more; a font would only matter for the caregiver panel. |

Conversion note: Kenney and OGA audio is OGG/WAV. Convert to `.caf` for iOS with
`afconvert -f caff -d LEI16 in.wav out.caf` (WAV) or via ffmpeg for OGG. Keep the Kenney
`License.txt` files next to the converted sounds for the record.

### Still to obtain (no free source found)

- [x] **Candy jar** – `JarView` (code-drawn, filled with the game's candies), shown on the Good Job screen with the drop-in animation.
- [x] **Sleeping candy** – `SleepyCandyView`, used by the session-timer good-night screen.
- [x] **App icon** – `AppIconView`, rendered by `Tools/render-art.sh` into the asset catalog.

### Localization strings (not assets, but to gather)

- [x] No words in play at all: the Play button is an icon and the Good Job screen has no text, so nothing needs translating for the player. Only the caregiver panel has text (English for now).

## 6b. Pacing (done)

- [x] **Progress counts swipes, not match groups.** Cascades are a bonus (burst + sound), so a level takes about `goal` swipes and length grows with level.
- [x] **Refill avoids free matches.** New candies pick a color that does not complete a line; cascades drop from ~1 per swap to occasional.
- [x] **Goal curve:** 3 swipes at level 1, about +2 every 3 levels, capped at 15.

- [x] **All of the candy pack in use**: the board rotates finishes level by level (plain, striped, wrapped), the ovals and wrapped ovals decorate the background and the rain.
- [x] **Board width cap** (after play testing on the phone): never more than 7 columns; later levels grow to 9 rows instead, clamped to what the screen shows at the 7-column candy size (`BoardFit`).
- [x] **Cascade bonus and match size** (added after play testing): three candies = 1 step, four = 1.5, five or more = 2; a group that matches on its own in a cascade is worth half of that. Swipes remain the main currency.

## 6c. Power-ups (idea, not scheduled)

The design rule is still "no objectives that need reading or reasoning", so any power-up
must be something the player never has to understand: it just happens, or it responds to
the one gesture they already know. Ideas, in order of how little they ask of the player:

- [ ] **Automatic big-match effect.** Matching 5 or more clears that whole row or column with fireworks. No new piece, no new gesture, no decision; the player only sees that a big match is a big deal. Lowest risk; could ship as the only power-up.
- [ ] **Wrapped candy.** A match of 4 leaves one wrapped candy (the pack's `*_wrapper` art) in place. Swiping it into any match bursts its neighbors too. Same gesture, visibly different piece, forgiving if ignored (it is still a normal candy of its color).
- [ ] **Striped candy.** A match of 5 leaves a striped candy (`*_horizontal` / `*_vertical`); when it is part of a match it clears its row or column. Classic, but it introduces "this piece does something" reasoning; test with real players first.
- [ ] **Rule**: a power-up is never required to finish a level, never times out, never costs anything, and the hint system must point at it like any other move.
- [ ] If any of these ship, stop the cosmetic finish rotation (`CandyArt.finish(for:)`) so stripes and wrappers mean one thing only.

## 7. Testing with real players

- [ ] Run 3–5 sessions with the intended players and a caregiver observing. Note: swipe success rate, time to first match, reactions to sounds and confetti, any sign of frustration.
- [ ] Tune swipe threshold, hint timings and animation speeds from those notes before adding more features.
