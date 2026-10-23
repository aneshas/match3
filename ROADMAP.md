# Roadmap

Tasks for the match-3 game for players with intellectual disabilities. Keep the design
rules in `CLAUDE.md` in mind for every item: one gesture, never lose, no reading required,
no pressure. Check items off as they ship.

Suggested order: sound, first-level swipe demo, adaptive difficulty, caregiver panel.

## 1. Making it easier to play

- [ ] **Teach by doing.** On level 1 the hint pulses immediately and an animated hand demonstrates the swipe once. No tutorial text. If the player does nothing for 20 s, the hand repeats.
- [ ] **Forgiving swipes.** Accept a swipe that starts slightly outside the tile, keep dominant-axis handling for diagonal drags, ignore a second finger. Tap-and-hold does nothing.
- [ ] **Escalating hint.** Pulse after 8 s, brighter glow after 16 s, then a short arrow drawn between the two candies. The player should never be stuck for long.
- [ ] **Fewer colors for longer.** Keep 3 colors well past level 5; let shape and size carry difficulty first. Add the 4th color much later. Decide after testing whether to cap at 5 colors.
- [x] **Introduce shapes gently.** Opening levels: 4x4, tall, wide, rounded corners, diamond, triangle, cross, heart; each shape has a minimum board size so it never collapses into a blob.
- [ ] **Quiet adaptive difficulty.** Track invalid swaps and hints used per level. Many of either -> next level drops a color or shrinks. Fast levels -> grow. No visible "easy mode".
- [ ] **Bigger candies on small boards.** Below 6x6, let the board fill more of the screen.
- [ ] **iPad and landscape** with the same single-screen layout.

## 2. Feedback and motivation

- [ ] **Sound as the main reward.** Match, big match, level done, soft "boop" for invalid swaps. Mute lives in the caregiver panel only. (Assets: see section 6.)
- [ ] **Voice "Good job!"** on the celebration screen in the device language.
- [ ] **Caregiver voice recording.** One-time option in the caregiver panel to record their own "Good job!" which replaces the stock voice.
- [ ] **Match-to-bar sparkle.** A tiny burst at the progress bar on every match so the player sees "match -> bar grows" each time.
- [ ] **Candy jar collection.** After each Good Job a candy drops into a jar shown on the Play screen. The jar fills over weeks. No rules, no unlocks.
- [ ] **No streaks.** No daily streaks, no "come back tomorrow", nothing lost on days off. (Design rule; verify nothing added later breaks it.)
- [ ] **Fixed celebration length.** Good Job screen always lasts the same time.

## 3. Caregiver panel

- [ ] **Hidden entry gesture.** Hold three fingers for 3 s on the Play screen (something a player will not do by accident).
- [ ] **Panel contents:** sound on/off, haptics on/off, calm mode, color-count cap, level reset, session timer, remove-ads purchase, simple stats (levels played this week, total).
- [ ] **Calm mode.** Turns off background drift, confetti, breathing button, sunburst. Defaults on when system Reduce Motion is on. Relevant for overstimulation and photosensitive epilepsy.
- [ ] **Session timer.** Caregiver sets e.g. 15 min. The game ends gently at the next Good Job with a "see you later" animation (wave, no text) and returns to the Play screen.
- [ ] **Guided Access reminder.** Short note in the panel on enabling iOS Guided Access to keep the player in the app.

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
| **B. Free + ads + remove-ads purchase** (current prototype) | Free to try, familiar model. | An interstitial is the single most confusing thing this player can see. Ad revenue from an audience that does not click is tiny. Ad SDKs add tracking and privacy disclosure burden. |
| **C. Free to try, one-time unlock, no ads** | Try the first N levels free, then one purchase in the caregiver panel unlocks forever. Clean experience for the player; caregiver decides with full information. | Needs a parental gate and a clear "stop" moment that does not feel like failure. |
| **D. Subscription** | Recurring revenue, standard in special-needs apps. | Families and care homes dislike it for a single game; churn and refund handling; feels wrong for a game this small. |
| **E. Institutional licensing** (Apple Business/School Manager volume purchase, custom B2B) | Care homes, schools and day centers buy 10–50 licenses at once. | Needs outreach; works alongside C, not instead. |

### Recommendation

Go with **C now and E later**. Drop ads entirely unless downloads are huge and revenue from C disappoints.

- **Free part:** the first 15–20 levels, playable forever and replayable. This is the whole "is it right for my sister" test a caregiver needs.
- **The stop moment:** when the free levels run out, the next Good Job screen ends with the candy jar and a single soft lock icon, no text, and the game returns to the Play screen, which still works and replays the last free levels. Nothing is taken away, nothing looks like losing.
- **The purchase:** one non-consumable "Unlock all levels" in the caregiver panel only, behind the three-finger hold and a parental gate (e.g. "hold for 3 seconds" or a simple sum). Price around 7.99–12.99; this audience's caregivers are used to paying more for far less polished apps, and a low price signals "disposable". Enable Family Sharing so one buy covers the household.
- **Why not ads at all:** besides confusing the player, ad networks require privacy disclosures, consent prompts and age gating that collide with Apple's Kids Category rules if the app is listed there. The removal of ads is the cleanest story in the App Store listing: "No ads. No timers. No losing."
- **Optional, zero-risk extras:** a "Buy the developer a coffee" tip in the caregiver panel for people who already paid and want to say thanks; a visible note that institutions can buy in volume.
- **Apple Small Business Program:** enroll (under 1 M USD/year) to pay 15 % instead of 30 %.
- **App Store positioning:** list in Games > Puzzle, not the Kids Category, unless you are ready for its stricter review; the target group includes adults. Describe the audience plainly in the first two lines of the description.

### Tasks

- [ ] **Decide the free-level count** (15–20) and make it a constant in `AppFlow`.
- [ ] **Lock behavior** after the last free level: Good Job plays fully, then a soft lock icon appears on the jar, then back to Play. Play replays the last free level. No text.
- [ ] **StoreKit 2 store** implementing `RemoveAdsStore` renamed to something like `UnlockStore`: one non-consumable, restore purchases, Family Sharing enabled in App Store Connect.
- [ ] **Parental gate** in the caregiver panel before the purchase button.
- [ ] **Purchase screen** in the caregiver panel: price, what you get ("all levels, forever"), restore button, link to privacy policy.
- [ ] **Tip jar** non-consumables (optional, caregiver panel only).
- [ ] **Volume purchase** enabled in App Store Connect; one line in the panel: "Institutions: available via Apple Business Manager".
- [ ] **Enroll in the Apple Small Business Program.**
- [ ] **Privacy label and policy** with no tracking; keep it that way (no analytics SDK that fingerprints; if analytics are wanted, use Apple's or a first-party counter).
- [ ] **Keep `AdPresenter`** as a no-op hook, so ads can be reconsidered later without touching game flow. If ads are ever enabled: only on the Good Job screen after the celebration, none in the first 10 levels, never rewarded ads, non-personalized only.

## 5. Accessibility details

- [ ] **VoiceOver labels** on candies ("red heart") and the board, mainly for caregivers who help.
- [ ] **High contrast option.** Thicker dark outline around candies, darker cells.
- [ ] **Keep layout fixed.** Star stays on the right for everyone; no layout customization.
- [ ] **Haptics toggle** in the caregiver panel.

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

- [ ] Keep `candy_game_2/` and the asset catalog out of any public repository (private repo or `.gitignore` them and keep a private copy).
- [ ] Keep the itch.io purchase receipt with the project.

### Found sources, per asset

Everything below is free. "CC0" means no attribution needed. Downloaded Kenney packs are
in the session scratchpad only; nothing has been added to the project yet.

| Asset | Source | License | Use these files / notes |
| --- | --- | --- | --- |
| Pointing hand for swipe demo | [Tapping finger](https://gamedeveloperstudio.itch.io/tapping-finger) by Robert Brooks (same artist as the candies) | gamedeveloperstudio license, name-your-price | Pressed + raised states, vector. Best style match. Fallback: Kenney [Cursor Pack](https://kenney.nl/assets/cursor-pack) `hand_point.png`, `hand_open.png`, `hand_closed.png` (PNG + SVG, Outline and Basic variants). |
| Hint arrow | `HintArrowView` (done, code-drawn) | n/a | Gold, outlined, nudges along its direction. Not wired in until the escalating hint exists. |
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
| Font | [Fredoka](https://fonts.google.com/specimen/Fredoka) or [Baloo 2](https://fonts.google.com/specimen/Baloo+2) on Google Fonts | SIL OFL 1.1 | Both rounded, both allow bundling in an app. Only "Play" and "Good Job!" are rendered. |

Conversion note: Kenney and OGA audio is OGG/WAV. Convert to `.caf` for iOS with
`afconvert -f caff -d LEI16 in.wav out.caf` (WAV) or via ffmpeg for OGG. Keep the Kenney
`License.txt` files next to the converted sounds for the record.

### Still to obtain (no free source found)

- [x] **Candy jar** – `JarView` (code-drawn, filled with the game's candies). Shown on the Play screen with one candy per finished level; the drop-in animation after Good Job is still open.
- [x] **Sleeping candy** – `SleepyCandyView` (closed eyes, blush, drifting Zs). Not wired in until the session timer exists.
- [x] **App icon** – `AppIconView`, rendered by `Tools/render-art.sh` into the asset catalog.

### Localization strings (not assets, but to gather)

- [ ] "Play" and "Good Job!" in each target language, checked with a native speaker for the simplest everyday wording.

## 7. Testing with real players

- [ ] Run 3–5 sessions with the intended players and a caregiver observing. Note: swipe success rate, time to first match, reactions to sounds and confetti, any sign of frustration.
- [ ] Tune swipe threshold, hint timings and animation speeds from those notes before adding more features.
