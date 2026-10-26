# App Store assets

All of these come from headless simulator captures plus small Swift compositors in
`scripts/`. Apple's specification pages are the authority and change yearly; the numbers
below were current in October 2026.

## Hard rules that caused rejections

- **No alpha channel.** App Store Connect rejects any PNG with transparency, including a
  fully opaque image that merely has an alpha channel. `sips -g hasAlpha file.png` must say
  `no`. The compositors write through a `noneSkipLast` CGContext for that reason.
- **Exact pixel sizes.** The slot decides the size, not the device the capture came from.
- **The required slots**: one iPhone set for "Dynamic Island, medium" (6.3": 1206 x 2622 or
  1179 x 2556) and, if the app runs on iPad, "iPad 13"" (2064 x 2752 or 2048 x 2732).
  Larger iPhones (6.9": 1320 x 2868) are optional and fall back. The foldable iPhone
  (1398 x 2034 outer, 2007 x 2853 inner) is optional until it becomes required for apps
  built with newer SDKs; uploading it earns a badge.
- Up to 10 screenshots per slot, JPEG or PNG.

## Composed screenshots

Device-native captures rarely match a slot's aspect ratio when the simulator runtime only
offers one device type, and composed shots look like store listings anyway. Recipe:

1. Capture each state as a series (`headless-simulator.md`) and pick clean frames: first
   screen, the core interaction, a later state, the celebration, the settings or admin
   panel, an accessibility mode.
2. `scripts/compose-screenshot.swift` (`swiftc -O` it once):
   `compose <out.png> <w> <h> <capture.png> "<caption>" [cropX cropY cropW cropH]`.
   It draws the app's gradient, soft colored discs, a bold rounded caption at the top, and
   the capture scaled to fit below with rounded corners and a shadow, then writes an
   opaque PNG and prints the rectangle it used (for video composition). Set the gradient and
   text colors to the app's theme before using it.
3. Crop to hide what must not ship: a Debug-only toggle in a settings panel, the status
   column on an odd device, a blinking artifact at the top edge.
4. Name files in upload order (`1-play.png`, `2-swipe.png`, ...) and keep one folder per
   slot under `Store/screenshots/`.

Captions: one short line each, the benefit not the feature ("Nothing to lose. It only ever
says good job."). Six is plenty.

## In-app purchase review image

1024 x 1024, the panel section with the Buy row and its price visible. Use the compositor
with an empty caption and a crop of the panel. The price only loads with a store attached,
so capture it during a UI test that holds the panel open (`storekit.md`).

## Product page header and search results

Landscape banners shown at the top of the product page and in search. Sizes: universal
16:9 PNG 5244 x 2950 (accepted in both slots), header 21:9 3840 x 1646, search 3:2 from
1920 x 1280 to 3840 x 2560. Keep them text-free: the header is cropped to different widths
per device, so text could be cut. `scripts/compose-banner.swift` scatters the app's own
art around a centered logo and a phone capture, with nothing important near the edges.

## App preview video

Optional, up to three per slot. Specs: 15 to 30 s, H.264 High profile 4.0 at 10 to 12
Mbit/s, 30 fps max, stereo AAC 256 kbit/s at 44.1 or 48 kHz (a silent stereo track is
acceptable, but a licensed loop is nicer), resolution by slot not by device: every current
iPhone takes 886 x 1920, iPad 1200 x 1600. Poster frame defaults to 5 s; pick a better one
in App Store Connect.

`scripts/make-preview.sh` is the pipeline: record autoplay with `simctl recordVideo`,
patch capture artifacts (`preview-clean.swift`), compose the background with the caption
(`compose-screenshot`), mask the clip's corners (`preview-roundmask.swift`), then ffmpeg
scales the clip onto the background, trims to the interesting window and adds the
normalized, faded audio. Trim points come from probing frames (`px.swift`) for the moment
the first screen appears and the celebration ends.

## Hosting the required pages

`Store/site/index.html` (support: what the app is, contact, how to reach the hidden
panel, purchase and restore notes) and `privacy.html` (from `Store/privacy-policy.md`).
Any static host works; GitHub Pages is the fastest. Replace the e-mail placeholder before
publishing; the Support URL and Privacy Policy URL fields take those addresses.
