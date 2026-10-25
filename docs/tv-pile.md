# TV pile: mapping and deployment

Feature spec and design intent for the Conversion installation — a pile of
20-plus mismatched HDMI screens. The previewer shipped in 0.9.34 and 0.9.35;
groups with their own mapping in 0.9.37.

**Nothing below is a build right now.** Groups and per-group sources shipped in
0.9.37 to 0.9.39. Everything from "Deployment model" onward is conditional on a
decision that has not been made yet — see the next section. **Do not build the
networking.** It is likely to be unnecessary.

## The display technology is not settled, and it gates everything

The installation may not be separate HDMI screens at all. The team is now
discussing **custom screen panels**, built by the same AV crew as last year —
the crew that assembled an 80ft curved LED wall piece by piece and flew it.

If it is **modular LED tiles**, the architecture collapses:

- The processor treats the whole array as **one canvas**. One machine, one
  video output. No multiple machines, no output assignment, no splitters.
- **Node mode, the WebSocket broadcast and clock sync all become
  unnecessary.** Everything in "Deployment model" and most of "Zones" is moot.
- **Groups survive unchanged.** They become regions of one canvas, which is
  already how the previewer works: it renders one frame and `drawPileScreens()`
  slices it.
- Low pixel density suits this app. A large LED wall may total 1920x1080 or
  less, and the whole aesthetic is low-resolution anyway.
- Power, rigging, heat and the processor become the vendor's responsibility
  rather than ours.

If it is **displays in custom fabricated housings**, the sections below stand,
with two additions: enclosed displays need designed-in venting or they cook,
and custom fabrication lead times are months, which is the likelier schedule
risk than anything technical.

### Three questions that unblock the rest

Ask the AV crew before building anything downstream:

1. What LED product, and what is the tile size and pixel pitch?
2. What does the processor take as input, and what is the total canvas
   resolution?
3. Can tiles be arranged irregularly — stepped, offset, with gaps?

Tile size decides whether the layout tool should work in inches or in tile
units. Canvas resolution decides what the app renders at. Irregular
arrangement decides whether the pile concept survives at all, or whether it
becomes a conventional flat video wall — which is the thing this was
deliberately not meant to be.

### Known defect in the AV spec

`Copy spec for AV` hardcodes a playback line reading
`N Raspberry Pi 5 boards (2 HDMI outputs each)`. That is wrong on both paths:
Pis were ruled out on GPU grounds, and an LED build needs one machine with one
output. Remove it or drive it from a Playback choice (Separate displays / LED
panels) before the spec goes to AV.

### Build-anything-now list

Safe under either outcome:

- Fix the playback line above.
- Make the render resolution settable, so the app can output an arbitrary
  canvas size rather than the window's. Needed for whatever number the
  processor returns.

## What exists

In the app the view is called **Multi-screen** (renamed from TV pile in
0.9.60, since it designs stage screens as much as piles; this document keeps
the original name) and the room section is **Background**, which also takes
a ceiling height: a dashed line at that height with the clearance above the
screens, shaded space above it, and a line in the AV spec. Devices is
**Elements** (0.9.61) and can place a Person, a flat silhouette of settable
height and colour standing in front of the screens for scale; it stays out
of the spec and the measurements. Background also takes a stage height and
width (0.9.62): the build stands on a deck of that size, the room floor drops
below it, and the ceiling is measured from the room floor. The deck can be
selected and dragged sideways, with a centre mark that reports its offset
from the grid's centre, and the view zooms about the pointer and pans
(0.9.63), double-click on the background fitting everything again. Sizes
read in the operator's unit (0.9.64): inches, feet and inches, centimetres,
or pixels at a pixel pitch saved with the layout, and the AV spec follows,
so an LED build can be specified in pixels directly. With a stage set, the
backdrop is locked to the deck's width and position (0.9.66), the overhang
applying to the top only.

Output has a Multi-screen preview beside Full frame: screens laid out in inches,
dragged and resized (TV diagonals, or since 0.9.58 custom panels with their
own width and height, for the LED-tile path), with speaker cabinets, a mounting grid of uprights and
rails, a backdrop (wall, photo of the real wall scaled to feet, drape, palette
fabric, solid colour or artwork), event-dim or bright-lobby lighting, and
**Copy spec for AV**. The layout persists in this browser.

The renderer draws one frame into `fin` and `drawPileScreens()` slices it onto
each screen. Every screen belongs to one **group** (up to ten since 0.9.57), and each group
carries its own mapping:

| Mapping | What it does |
|---|---|
| Unified | One picture spread across the whole pile |
| Mirror | The full frame on every screen |
| Scatter | Each screen takes its own drifting crop |
| Chaos | Each screen plays a different saved preset, up to 8 distinct |

**Mapping presets** (0.9.54) sit under Groups: a named snapshot of the groups
(name, mapping, source, set list) and of which screen is in which group, saved
from a pad row and recalled by pressing a pad; the pad matching the wall is
lit. Screens are matched back by position and size, since item ids are
reissued on every load, and a held source by kind and name. The presets are
part of the layout, so they persist with it and travel in Copy layout code.
This is the "pads: preset recall, per group" line of the control surface,
done first as on-screen pads.

Unified spreads one picture across the outline of the Unified screens, so a
central cluster can be Unified while the outer screens run Chaos. A Chaos group
deals from its own set list, or from the whole library when the set list is
empty; the eight-look budget is shared between Chaos groups by screen count.
Screens are assigned with a group's **Assign** tool (click screens on the
stage), the Group picker on a selected screen, or **G** to cycle. Groups save
with the layout (`v: 2`); a `v: 1` layout loads as one group carrying its old
global mapping. **Copy spec for AV** lists the groups. The app always opens on
Full frame; the pile is a planning view you switch to.

## Groups carry source and mapping (built in 0.9.37)

The goal is to run **Unified and Chaos at the same time** — a unified picture
across a central cluster, with outlier screens doing their own thing. That
reads better than either alone: a focal point, plus life at the edges.

Mapping moves from a global switch to a property of a **group**, with every
screen belonging to one group. Three to five groups, and a group is:

    group = { screens, source, mapping, set list }

**Design that whole shape now**, even if the source selector ships after the
mapping selector. Building `{ screens, mapping, set list }` first means
reworking the same code when source follows, and source has to follow — see
the next section.

Mapping is testable with no hardware. Assign a central cluster to Unified and
the rest to Chaos in the previewer and look at it. If the mix reads well on
the preview it will read well on the wall. **Build this before anything
networked.**

What shipped: the group shape is `{ id, name, mapping, source, presets }` on
`P.groups`, with each screen holding its group id in `g`. `source` is written
and read but fixed to `"stage"`, whichever held source is on the stage, so the
next section lands without reworking the model. Chaos render state lives on the
group at runtime (`g.ch`) and is never saved.

## Source is a group property (built in 0.9.38 and 0.9.39)

Sources are **held**, not swapped (0.9.38): Media, Text, Camera and Tab each
add a row under Source and one row is on the stage; switching never tears the
others down, so `setImageSource()` became `addSource()` (create and hold) plus
`activateSource()` (put on the stage). Each group then picks what it shows
(0.9.39): the stage source, or any held source, from the Source menu on its
row. A held source gets its own texture (`srcTexFor`), and a group on Unified,
Mirror or Scatter with its own source renders the current look from it into a
per-group pair (`g.gr`, shaped like its screens for Unified); Chaos groups bind
the source around their slot renders. Those renders show the scene, Distort and
Texture layers, as Chaos does; Screen effects stay with groups on the stage
source. Held sources are per session, so a loaded layout starts every group on
the stage source. A Chaos group's picker also offers **Set list**, which deals
the looks on timeline keys 1–8.

Today the stage source is a singleton. `setImageSource()` does not add a
source, it replaces one, and it tears down whatever was there: switching to
Text pauses a playing video, stops a shared tab and shuts down face detection.
There is one `imgTex` on the GPU.

So per-screen mapping on its own gives different *presets* per screen while
every screen still draws from the same source. Camera on one cluster and type
on another is impossible until source moves into the group.

The cost is in the state model and the UI, not the GPU. A text canvas is
static and costs nothing to hold once uploaded, and two or three 2048px
textures is trivial memory. The real ceiling is CPU: two or three concurrent
*live* sources (camera, video, tab) is the practical limit, while static text
beside one live source is free.

`setImageSource()` splits into the two jobs it currently conflates: create and
hold a source, and assign a source to a group.

**This gets easier in the distributed model, not harder.** A node only needs
its own source — the camera node holds the camera, the text nodes hold a
canvas, and no machine carries all of them. The previewer, juggling every
source on one machine, is the hard case. Accept some load there rather than
designing around it.

It also matches the room: a camera sits at one physical spot and only makes
sense for the screens near it, so camera is inherently zone-scoped.

### Rename (done in 0.9.38)

"Video in" stopped being accurate the moment Text landed under it. The section
is now **Picture Source**, paired with "Audio Source".

## Why mixing is possible at all

A shader is deterministic: the same preset, parameters, audio values and time
produce the same image on any machine. Unified therefore does not need one
shared canvas. Each renderer needs the pile geometry and knowledge of its own
rectangle, and it draws its own crop of a picture no machine ever holds whole.

That is what makes a distributed wall viable, and it is why per-screen mapping
is natural rather than awkward: each screen is told individually what to do.

## Deployment model (only if separate displays)

**Superseded if the build is LED tiles** — in that case there is one machine
and one output, and none of this applies. Kept for the separate-display path.

**Broadcast commands, not pixels.** No capture cards, no HDMI matrix, no NDI.

- The previewer becomes the **master**. Nodes run the same `index.html` as
  `?node=N`, listening instead of controlling, rendering fullscreen.
- The master broadcasts a clock timestamp, the four audio values (bass, mid,
  high, beat) and any assignment changes. Roughly 50 bytes at 30Hz.
- **Only the master needs audio input.** One USB interface for the whole wall.
- A small WebSocket server on the master, on its own router and switch.
  Never venue wifi, and not Cloudflare — this is local-network state.
- Clock sync by NTP-style offset estimation over the same socket. A quiet LAN
  gives sub-frame accuracy.

Each screen needs a stable id and an output assignment; positions already
exist in the layout.

## Zones (only if separate displays)

On an LED build the word still has a creative use — a cluster of the canvas
that shares a look — but it stops being a hardware boundary. The rest of this
section is about hardware.

A **zone** is the set of screens one machine drives, chosen so those screens
also belong together creatively. Three nested units, smallest first:

1. **Duplicate group** — screens fed from one output through a splitter. They
   show an identical image and can never differ.
2. **A machine's screens** — one box, its 2-3 outputs, each optionally feeding
   a duplicate group.
3. **Zone** — the above, drawn so the technical and creative groupings
   coincide. A creative group spanning two machines invents a sync problem
   that did not need to exist.

**Any screen in the Unified group needs its own output.** A splitter duplicates,
so two screens on one cannot show different slices of a picture. Splitters are
fine for Mirror and Chaos screens.

Height is the natural creative boundary: screens at eye level can carry legible
content (the text source, a session title, a name), screens up high carry
texture, where nobody is reading. That resolves the legibility tension in
`docs/text-effects.md` physically rather than through a slider.

### Worked sizing

24 screens, 10 of them in the Unified cluster:

- 10 dedicated outputs for the Unified screens
- 14 outer screens on Mirror or Chaos, sharing splitters — about 5 outputs
- 15 outputs, so **5 machines at 3 outputs each**

Sanity check: Chaos already caps at 8 distinct looks. Twelve to fifteen output
channels comfortably exceeds what the content model asks for.

## Control surface

The NM2 MIDI controller addresses the **master only**, never a node.

- Pads — preset recall, per group
- Encoders — live parameters (sensitivity, distort amount, text edge amount)
- Tilt — one continuous parameter performed by hand
- Banks — which group is being addressed

The point is eyes-free operation in a dark venue, not feature count.

## Hardware

**If LED tiles: one machine, driving one output into the processor.** A single
capable laptop is enough; the vendor supplies everything downstream of the
cable. Ignore the rest of this section.

For the separate-display path: Intel N100-class mini PCs for zones, not
Raspberry Pis. Mesh is ray-marched and
a Pi will struggle; twenty Pis is twenty SD cards and twenty failure points on
show day. A Pi is the right test rig for a single node, and a good hobby build,
but it is a separate project from this deployment.

## Out of scope

- **Per-screen timelines.** Nobody authors or runs twenty sequences under
  pressure. Three to five groups with per-screen offset and jitter gets ninety
  percent of the effect for a tenth of the build. Chaos already has the right
  instinct: randomise per screen rather than author per screen.
- Video distribution of any kind.
- Genlock or frame-perfect sync. Gaps between mismatched screens hide a frame
  of drift, and perfect lock would read as a video wall, which is the opposite
  of the intent.
- Anything that depends on venue wifi.

## Open questions

- **Panels or separate displays** — the question that gates the rest. See
  "The display technology is not settled" above.
- Screen count and sizes — unknown until the December site visit.
- Camera placement, and who owns housings and fabrication.
- Whether **Copy spec for AV** should also emit zone and output assignments.
  It probably should: "machine 2, output 1, splits to these two screens" is
  what the AV team needs and what they will otherwise ask for by email the
  night before.
- Whether Unified or Chaos is the hero look. Both now run at once, so this is
  a question of emphasis rather than a fork.
