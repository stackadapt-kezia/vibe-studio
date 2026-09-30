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
