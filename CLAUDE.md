# CLAUDE.md

Conventions for working in this repo. Vibe studio is a live WebGL visualizer
for projecting at events; it was extracted from the Pattern studio Apps Script
project and shares its conventions.

## Shape of the project

One file, no build step, no dependencies, no test suite: `index.html` holds
the whole app with inline CSS and JS. Keep it that way. No bundler, no
framework, no npm, no CDN script tags; Google Fonts are the only remote
resource. Frontend code is modern ES (`const`/`let`, arrow functions,
`async`/`await`, template literals).

## Docs to read first

- `mode-map.md` — the visualizer mode map: the nine shader families, what is
  built, what is open, and the build order. Read before adding or changing a
  pattern, the Distort layer, or the Screen layer.
- `docs/preset-library.md` — preset data model, library grid, and set list.
  Read before touching presets, thumbnails, or the look-switching UI.
- `docs/face-detection.md` — face detection schema: detection not recognition,
  nothing stored, normalised boxes, derived scalars and events, smoothing with
  asymmetric arrive/lose thresholds, fixed-size shader uniforms, and face values
  as a modulation source beside the audio bands. Read before adding a camera
  source or any face-driven control.
- `docs/text-effects.md` — the text source and the edge-effect pass that
  follows it: a signed distance field built on the CPU, spiking and weight as
  a source-level pass rather than a Distort mode, and what the same pass gives
  for free. Read before touching the text source or adding letterform effects.
- `docs/tv-pile.md` — the TV pile previewer, per-screen mapping, and the
  deployment model for the Conversion installation: zones, broadcast of
  commands rather than pixels, splitters versus Unified, and what is
  deliberately out of scope. Read before touching the pile preview, the
  mappings, or anything about driving more than one screen.
- `docs/plan-view.md` — screen depth and the plan projection: why the main
  stage overlaps in depth rather than sitting on one plane, the deck depth
  budget, the build order, and the sightline rays that decide how wide the
  seating can be. Read before touching screen geometry or adding a projection.
- `presets/library.json` — the canonical preset library. The short
  `BUILTIN_PRESETS` list in `index.html` is only a fallback for copies opened
  from disk; edit the JSON, not the fallback.

## Versioning

`APP_VERSION` near the top of the script is the user-visible version, shown
in the header. Any user-visible change bumps it in the same edit, updates the
comment on that line, and adds a `CHANGELOG` entry at the top of the array
just below. The changelog is a product surface: the version button in the
header opens it. Write entries in plain language about what changed for the
operator, not commit-message prose.

## Verifying changes

There are no automated tests. Do not claim a visual change works without
rendering it: serve the folder (`python3 -m http.server 8000`) and check in a
browser, or drive headless Chrome. Mic input needs `http://localhost` or the
deployed https address; a `file://` copy cannot ask for permission.

## Depth pattern

- **Depth** (style 22) is a depth pass. A black-and-white depth image or video
  (white = near) is coloured through the palette by distance, with Focus and
  Lens blur as a depth of field, a light sweep from far to near, parallax, and
  the Bass → Push and Beat → Focus routes. Trails stay off in this style: a
  depth pass fed back into itself ghosts, and with beat flashes it piles up to
  white. The map is one texture on unit 7, kept in IndexedDB flagged `depth`,
  apart from the stage sources.
- Depth files a browser can't show are decoded in the page, no library:
  OpenEXR (scanline, uncompressed/RLE/ZIPS/ZIP; a Z or Depth channel is
  scaled to the scene's range and flipped so near is white, Mist is flipped),
  Radiance HDR, TIFF (strips, 8/16/32-bit, none/LZW/Deflate/PackBits),
  Targa, PFM/PGM/PPM and NumPy `.npy`. An OBJ has no pixels, so its depth is
  rendered by a small WebGL pass on a turntable (Speed sets the turn) into
  the same texture. Models usually ship with `.mtl` materials and textures
  beside them; the loader takes only the `.obj`, since a depth pass needs
  nothing but geometry.
- Headless Chromium can't decode H.264, so test depth video with WebM.

## Constraints

- Runs unattended for hours on a projector. Multi-hour stability beats any
  individual effect.
- Audio comes from a line feed via a USB audio interface, not a laptop mic.
- Songs, fonts and loaded pictures live in the operator's browser (IndexedDB),
  never in the repo; text sources persist in localStorage. The one bundled
  image is `presets/thumb.jpg`, the reference source for preset thumbnails;
  keep it small, since git keeps every version of a binary.
