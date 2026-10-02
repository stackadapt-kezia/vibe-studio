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

## Constraints

- Runs unattended for hours on a projector. Multi-hour stability beats any
  individual effect.
- Audio comes from a line feed via a USB audio interface, not a laptop mic.
- Songs live in the operator's browser (IndexedDB), never in the repo. The one
  bundled image is `presets/thumb.jpg`, the reference source for preset
  thumbnails; keep it small, since git keeps every version of a binary.
