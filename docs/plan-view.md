# Screen depth and the plan view

Feature spec. Multi-screen draws one projection today, an elevation. This adds
a depth value per screen and a second projection, a plan.

## Why

The main stage is not three coplanar screens with gaps between them. It is one
centre screen downstage, with two wing screens a few feet **behind** it,
overlapping it visually. The walk-through is the gap in depth beside the centre
screen, concealed by that overlap, so speakers appear from behind the screen
rather than stepping through a visible slot.

The elevation draws screens in a row with gaps on one plane, which is the wrong
picture, and it cannot answer the question the arrangement raises.

## Depth budget, for reference

Front to back on the deck:

| | ft |
|---|---|
| Downstage performance area in front of the centre screen | 10–15 |
| Centre screen structure | 2–3 |
| Walk-through gap | 6–8 |
| Wing screen structure | 2–3 |
| **Total deck depth** | **~28–30** |

Keep the gap generous. Four feet is the physical minimum and reads as a fire
exit; six to eight lets a presenter walk through at pace without clipping a
shoulder on an LED frame.

## Build order

Each step is useful on its own; stop anywhere and the drawing is better than it
was.

1. **`depth` per screen**, in the layout's current unit, default 0. Positive is
   upstage, away from the audience.
2. **The elevation draws back to front.** Sort by depth descending so overlaps
   are correct. Dim or desaturate deeper screens slightly so the depth reads at
   a glance rather than looking like a drawing error.
3. **Stage depth**, beside stage height and width under Background, and into
   `Copy spec for AV`.
4. **A Plan toggle inside Multi-screen** — Elevation / Plan. Same scene, second
   projection.
5. **The spec emits depth per screen and the stage depth.**

Steps 1 to 3 alone make the elevation honest and are about an hour.

## The plan view

Same data, drawn at (x, depth) with each screen's width, instead of (x, y) with
its height.

It draws: the stage deck outline, each screen as a line segment at its depth,
the walk-through gaps, the first seating row, and the AV island.

**Label downstage and upstage.** Ground plans are drawn both ways in practice
and a vendor reading it upside down is a real failure. Labels remove the
question.

The 45° viewing cone belongs in this projection rather than the elevation.

## Sightline rays — the reason this exists

This is the feature. Everything above is scaffolding for it.

Draw a ray from the outermost seat, past the downstage edge of the centre
screen, and see where it lands: on the wing screen, or straight into the gap.
Repeat from a few seat positions along the front row.

That gives the exact seating width at which the overlap stops working — the
number that decides how wide the fan can be. There is no other way to get it.
Sightlines are a plan problem; that is what plans are for.

## What shipped (0.9.71)

All five build-order steps, in one pass:

- **`depth` per screen**, in inches internally, in the selection box as Depth
  and dragged in the plan. Zero is the screens' front line (the mounting grid's
  plane); positive is upstage. Saved with the layout.
- **The elevation draws back to front** (`pdrawOrder`: depth descending, then
  layout order) for the bezels, the GL slices and the overlay, and hit-testing
  picks the front-most. Deeper screens are dimmed and flattened by a `u_dim`
  uniform, about 15% at eight feet.
- **Stage depth and Apron** under Background. The apron is the performance
  area between the deck's front edge and the screens' front line (12′ to
  start), which is what places depth 0 on the deck. Both go into the spec.
- **A Plan card** with the Elevation / Plan switch (remembered in this
  browser), the first row's distance and width, and the AV island's distance
  behind the row (none to start, since sixty feet of house squashes the deck).
  `pfit` has a plan branch: PX is shared and PY maps depth, with `pfloor` the
  canvas y of depth 0, so zoom, pan and `pworld` work unchanged. Dragging a
  screen in the plan moves it sideways and in depth.
- **The spec** lists depth per screen, the stage depth and apron, the seating
  and the sightline result.

The plan draws the deck with its lit front edge and the backdrop line, each
screen as a 24″ structure with its glass face on the downstage side in the
group colour, the walk-through from each screen's back to the face of the
nearest screen behind that it overlaps (red under 4′, amber under 6′), the
first row with seats, the AV island, a 45° cone off the widest front screen,
and Upstage / Downstage labels.

**Editing in the plan (0.9.72).** The deck selects with a click and has
handles: the back edge sets the stage depth, the front edge sets the apron
with the back edge staying put, the sides set the width, and dragging the
deck moves it sideways. Screens drag sideways and in depth. The AV island
drags anywhere in the house (`avD` behind the first row, `avX` off the stage
centre). The seating block drags in depth only; it is locked to the stage
centre and follows the deck.

**The seating maker (0.9.72).** `pseating()` turns the Plan card's settings
into seats, tables and row lines in plan units, centred on the stage: Theatre
(straight rows in sections between aisles), Chevron (outer sections turned
about 15° so the aisle end sits nearest the stage), Curved (rows on arcs about
the screens' front line, aisles as angular gaps), Classroom (rows with an
18″ table on the stage side), Banquet (72″ rounds of ten in a staggered grid)
and Cabaret (60″ rounds of six with the stage-facing half open). Rows, row
spacing, seat width, aisles and aisle width are settable; the seat count shows
beside Rows, on the plan and in the spec. Row spacing doubles as table spacing
for rounds, with a floor of the table plus three feet.

**Selection, the island, the room (0.9.73).** Shift-click builds a selection
of several items in either view (`psel.more`); dragging any of them moves the
lot by the same step, the box offers Remove and Duplicate for all, and a Group
picker and Depth when they are all screens. The AV island has edge handles
for its width and depth (`avW`, `avL`). The Plan card takes the room: width,
depth, the gap from the deck's back edge to the back wall, and a sideways
offset (`P.room`). The plan draws the walls with the dimensions (and the
ceiling height when set) and cuts the Elements doors into the back wall with
their swing arcs, so the stage can be checked against the real room. Straight
row layouts take a **Taper**, inches each row grows from the one in front, so
the house fans towards the back; and an **Attendee count** toggle puts the
live seat count top-right of the plan, against an Expected figure when one is
given, red when short.

**Sightline rays** run from seven seats along the front row past each end of
a front screen that has a screen behind it. A ray lands on a screen behind
(green), passes outside the wing's outer end to the backdrop (grey, harmless),
or passes inside the wing's inner end into the walk-through (red). Seats are
then tried from the centre outwards in 6″ steps, and the first that sees in
gives the number at the top of the plan and in the spec: "Overlap holds to a
seating width of 30′ 0″, of 40′ 0″". Hand check for the default test: a 16′
centre screen, wings 8′ behind overlapping by 2′, first row 15′ off a 12′
apron. The ray from a seat s past the centre's left end reaches the wings'
depth shifted by (e − s) × 96 / 324, which exceeds the 24″ overlap once the
seat is more than 81″ outside the screen's end, so a half-width of 177″, a
30′ row. The plan says 30′.

## Out of scope

- **Perspective, of any kind.** No camera, no tilt, no vanishing point, no 3D.
  Orthographic projections are nearly free because they are flat 2D drawing on
  data that already exists; a perspective renderer is a camera, mesh loading, a
  model parser, a depth buffer and materials, and it is weeks. If a camera
  angle or a tilt control starts to appear, that is the line.
- **Importing venue 3D models.** The hotel's Social Tables model already exists
  and works; screenshot it and use it as the scaled photo backdrop instead.
- **A section view.** Worth having eventually for ceiling clearance and screen
  trim heights, but not before the plan.

## Terminology

Plan, elevation and section are the three orthographic views vendors build
from, and they are measurable — you can scale off them. A 3D render is a
persuasion tool. Webb and Nexus 6 will want the drawings.
