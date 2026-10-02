# Preset library

Feature spec. Save as `docs/preset-library.md` and reference it from `CLAUDE.md`.

## The problem

Individual modes are mechanisms — halftone, distortion, palette lookup. A
convincing look is several of them stacked in a fixed order with tuned
parameters. Finding a good stack takes a lot of toggling, many stacks look
similar in isolation, and nobody can tell what a mode does from its name until
they've applied it.

At a live event none of that exploration is possible. You need to click one
thing and have it be right.

## The two layers

- **Modes** are mechanisms. They live in the shader code. Technical names are
  correct here (`bayer4x4`, `sobel`, `chromaBleed`).
- **Presets** are named stacks of modes with saved parameters and audio
  bindings. Evocative names are correct here (`Newsprint`, `Dead Channel`,
  `Departure Board`).

Modes are for building. Presets are for choosing. They want different names and
different organisation.

---

## Data model

A preset is data, not code. Store the canonical library as JSON in the repo so
it's diffable, reviewable, and travels with the app.

```
presets/
  library.json
```

Each preset:

```json
{
  "id": "dead-channel",
  "name": "Dead Channel",
  "group": "damaged",
  "stack": [
    { "mode": "lowResRender", "params": { "height": 480 } },
    { "mode": "chromaBleed",  "params": { "amount": 0.7 } },
    { "mode": "syncJitter",   "params": { "amount": 0.3, "burstiness": 0.8 } },
    { "mode": "rollingBar",   "params": { "speed": 0.12, "softness": 0.4 } },
    { "mode": "bloom",        "params": { "threshold": 0.8, "anisotropy": 3.0 } }
  ],
  "audio": [
    { "target": "syncJitter.amount", "band": "transient", "depth": 0.6 },
    { "target": "bloom.threshold",   "band": "low",       "depth": 0.3 }
  ]
}
```

**Stack order matters and is explicit.** Renderers apply the array in sequence.
Don't infer order from mode type.

**Audio bindings are part of the preset**, not a separate global setting. The
same stack with bass-driven distortion and with transient-driven distortion are
two different looks, and both deserve to be saved.

### Where edits live

- `presets/library.json` — the canonical, committed library.
- `localStorage` — in-progress tweaks and unsaved user presets, so experimenting
  never dirties the repo.
- An **Export** action writes the current stack as JSON to the clipboard, so a
  good accident can be pasted into `library.json` and committed.

That promotion path is the point: play freely, commit deliberately.

---

## The library grid

A grid of tiles, each showing that preset rendered live.

### Thumbnails render live, round-robin

Each tile is a small framebuffer (around 160×90). Twenty of them is under
300,000 pixels total — less than one 720p frame. The cost isn't pixels, it's
switching shader programs, so:

- **Update two or three tiles per frame**, cycling through the grid. Everything
  is current within a second and the cost stays negligible.
- **One shared source texture** for all tiles. Decode the video or camera feed
  once, bind it to every tile. Never decode per tile.
- **Tiles scrolled out of view don't render at all.**

### Live input needs a reference clip fallback

In a dark room every live thumbnail is a dark rectangle and the grid tells you
nothing. Ship a short reference loop chosen to exercise the differences: motion,
high contrast, a face, fine detail, saturated colour.

Toggle: **Live / Reference**. Default to Reference when the library is opened for
browsing; the point of that clip is that it's a test fixture, not a pretty
picture.

### Group by character, not by family

The mode map is organised by mechanism because that's right for implementing.
The grid is organised by feel because that's right for choosing. Nobody at an
event thinks "something from the quantisation family."

Suggested groups — adjust once there are real presets to sort:

- **Print** — halftone, riso, screen-print, newsprint
- **Broadcast** — CRT, VHS, composite bleed, rolling bar
- **Terminal** — segment columns, dither, monochrome, ASCII
- **Damaged** — sync loss, datamosh, corruption, tearing
- **Optical** — bloom, warp, prism, mirror

### Naming

Tiles carry evocative names. Technical names stay in the shader code where
they're accurate. `bayer4x4` in the source, `Newsprint` on the tile.

---

## The set list

Browsing the library is preparation. Performing is not.

- A pinned row of tonight's picks — six to eight presets, chosen in advance.
- Mapped to number keys **1–8**. Pressing a number switches instantly.
- Clear active state on the current preset.
- Reachable **without leaving fullscreen**, alongside the sensitivity controls
  from the show-readiness work. A keypress opens and closes it.

Transitions: hard cut by default, since a cut on a beat is usually what you
want. A crossfade duration setting is worth having but is not the default.

---

## Curation discipline

This is a build constraint, not advice.

**If two presets are not distinguishable at thumbnail size, one of them should
not exist.** Fifteen genuinely distinct looks beat forty variations. The grid's
second job, after helping you choose, is exposing redundancy — build it, then
use it to prune.

The mode map can hold every technique that exists. The preset library holds the
ones worth reaching for.

---

## Out of scope

Explicitly not building: cloud sync, preset sharing, user accounts, tagging,
search, or categories beyond the handful of groups above. This is a grid of
roughly fifteen things that one person picks from. Anything that would help with
five hundred presets is wasted here.

---

## Open questions

- Reference clip: source, length, and whether it ships in the repo (watch the
  file size — git keeps every version of a binary forever) or loads from the
  hosted copy.
- Whether thumbnails should render at the preset's own low internal resolution
  or at tile resolution. Rendering at the real internal resolution is more
  honest about what you'll get.
- How the set list is edited — drag from the grid, or a separate mode.

---

## Implementation notes (0.7.0)

What was built against this spec, and where it departs.

**Schema.** This app's render is one fixed pipeline (pattern, then the Distort
layer, then palette lookup, trails, grain, then the Screen layer), so a preset
is one look object rather than an ordered stack:

```json
{
  "id": "dead-channel", "name": "Dead Channel", "group": "broadcast",
  "look": { "style": 5, "scale": 1, "warp": 0.2, "dist": 2, "distort": 0.35,
            "screen": 3, "screenAmt": 0.9, "trails": 0.3, "grain": 0.3 },
  "palette": "sa-dark",
  "routes": [ { "src": "beat", "dst": "distort", "amt": 0.8 } ]
}
```

- `look` keys are the state keys: `style` (pattern index), `scale`, `speed`,
  `warp`, `blobs`, `trails`, `fbZoom`, `fbSpin`, `grain`, `bands`, `dist`,
  `distort`, `screen`, `screenAmt`, plus `microText` and `microFont` for
  Microtext. Any key left out takes the app default, so a preset resets what
  it does not mention.
- `palette` is either a named palette key (`sa-light`, `sa-dark`,
  `cv27-miami`) or `{ "colors": [...], "weights": [...] }`.
- `routes` are the reactivity routes (`src`: bass, mid, high, beat; `dst`:
  size, motion, colour, grain, flash, distort, warp, trails, push, spin).
  Audio bindings are part of the preset, as the spec asks.

**Where edits live.** `presets/library.json` is canonical and loaded by
fetch. A copy opened from disk cannot fetch, so `index.html` carries a
three-preset built-in list as a safety net; the JSON is the library. User
looks saved with "Save look" go to `localStorage` under a "Mine" group, and
"Export" copies the current look as JSON for pasting into the library.

**Thumbnails.** Not live (0.7.3). Every preset is rendered once through its
look at a fixed moment, with trails off and no audio, from one shared source
image; a queue spreads the renders over a few frames and the grid re-renders
when the source changes. The source is whatever is loaded in Video in (the
current frame, for a video), else `presets/thumb.jpg` if the repo ships one,
else the plasma field (0.8.0). The name sits lower left inside the tile on a
black-to-clear fade and shows on hover or when the preset is active. Tiles
are 2:1, the grid runs 2 to 4 columns with the panel width, and each family
folds from its heading. Patterns that ignore the source (Blobs, Plasma,
Waves, Fractal, the oscilloscope) show themselves. Text presets render with
the current copy, not their own.

**Reference clip.** Optional: drop `presets/thumb.jpg` into the repo and it
becomes the default thumbnail source. Keep it small; git keeps every version.

**The lower third (0.9.2).** The whole library lives in a panel just off the
bottom of the stage, toggled with S or the Output button and hidden in
fullscreen: a toolbar (Fade, default Hold, Gain, Auto, Update preset, Revert,
Save look, Export), the library as horizontal strips by group, and the
timeline of eight slots on keys 1–8. Drag a tile onto a slot to add it
(inserting, the rest shift right; a full timeline replaces the slot), drag a
slot to another to reorder, drag it off to remove. Each slot has its own hold
time; Auto plays through them with a progress bar on the active slot, using
the crossfade if Fade is set.

**Update preset.** Apply a preset, tweak the controls, press Update preset:
the current look is stored as that preset's defaults in this browser (an
override merged over the shipped look), its tile re-renders, and Export copies
the merged look for `presets/library.json`. Revert drops the override. A look
in Mine is rewritten in place.

**Open questions, answered for now.** Reference clip: not needed. Thumbnail
resolution: tile resolution. Set list editing: from the tiles.

**Editing the library (0.9.17).** The library is arrangeable in the browser:
drag a tile onto another to place it before that tile (in that tile's group,
moving it between groups if needed), onto a group heading to put it last
there, remove any look with its ×, and press + in a group to save the current
controls as a new look in that group. Shipped looks that are removed are only
hidden (Restore in the toolbar brings them all back); the shipped JSON is never
changed by the UI. Edits live in `localStorage`: hidden ids, a per-group order,
and a `group` on a preset's override. Export still produces the merged look to
commit.
