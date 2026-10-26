# Scripts

Swift sources compile with Command Line Tools: `swiftc -O name.swift -o name`. Copy the
ones you use into the project's `Tools/` and adapt colors, bundle ids and paths.

| Script | Purpose |
|---|---|
| `compose-screenshot.swift` | `compose <out> <w> <h> <capture> "<caption>" [x y w h]`: a store screenshot on a gradient with a caption, opaque PNG; prints the capture's rectangle. Edit the two gradient colors, the disc colors and the text color to the app's theme. |
| `compose-banner.swift` | `banner <out> <w> <h> <capture> <image dir> [seed]`: text-free product-page header/search banner from the app's own art. Edit the image names and the logo name. |
| `preview-clean.swift` | Patches a fixed region of every frame of a recording from clean screenshots (the foldable simulator's camera disc). Edit `region`, the probe pixel and the phase rule. |
| `preview-roundmask.swift` | White rounded rectangle on black for ffmpeg `alphamerge`. |
| `make-preview.sh` | The whole preview pipeline: record, clean, compose, encode. Needs `UDID`, `BUNDLE_ID`, `APP_PATH`, `MUSIC` in the environment and ffmpeg. Trim points (`-ss`, `-t`) must be found per app by probing frames. |
| `sheet.swift` | `sheet <dir> <n>`: contact sheet of `gj_1.png ... gj_n.png` into `sheet.png`. Rename the prefix as needed. |
| `probe.swift` | `probe <png> x y w h`: counts near-black pixels in a rectangle and reports the darkest value. |
| `px.swift` | `px <png> x y [x y ...]`: prints RGB at points, for finding trim moments and states. |
