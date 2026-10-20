# TV pile: mapping and deployment

Feature spec and design intent for the Conversion installation — a pile of
20-plus mismatched HDMI screens. The previewer shipped in 0.9.34 and 0.9.35.

**Only the first two sections are builds.** Everything from "Deployment model"
onward is recorded intent for when the screen count is known, after the
December site visit. Do not build the networking yet.

## What exists

Output has a TV pile preview beside Full frame: screens laid out in inches,
dragged and resized, with speaker cabinets, a mounting grid of uprights and
rails, a backdrop (wall, photo of the real wall scaled to feet, drape, palette
fabric, solid colour or artwork), event-dim or bright-lobby lighting, and
**Copy spec for AV**. The layout persists in this browser.

The renderer draws one frame into `fin` and `drawPileScreens()` slices it onto
each screen. Four mappings, as a **global** switch:

| Mapping | What it does |
|---|---|
| Unified | One picture spread across the whole pile |
| Mirror | The full frame on every screen |
| Scatter | Each screen takes its own drifting crop |
| Chaos | Each screen plays a different saved preset, up to 8 distinct |

## Next build: groups carry source and mapping

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

## Source is a group property too

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

### Rename

"Video in" stopped being accurate the moment Text landed under it. The section
becomes **Source**, paired with "Sound in". Fold the rename into this redesign
rather than doing it separately, since the section changes shape anyway once
sources are assigned to groups instead of set globally.

## Why mixing is possible at all

A shader is deterministic: the same preset, parameters, audio values and time
produce the same image on any machine. Unified therefore does not need one
shared canvas. Each renderer needs the pile geometry and knowledge of its own
rectangle, and it draws its own crop of a picture no machine ever holds whole.

That is what makes a distributed wall viable, and it is why per-screen mapping
is natural rather than awkward: each screen is told individually what to do.

## Deployment model (intent, not yet built)

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

## Zones

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

Intel N100-class mini PCs for zones, not Raspberry Pis. Mesh is ray-marched and
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

- Screen count and sizes — unknown until the December site visit.
- Camera placement, and who owns housings and fabrication.
- Whether **Copy spec for AV** should also emit zone and output assignments.
  It probably should: "machine 2, output 1, splits to these two screens" is
  what the AV team needs and what they will otherwise ask for by email the
  night before.
- Whether Unified or Chaos is the hero look. Both now run at once, so this is
  a question of emphasis rather than a fork.
