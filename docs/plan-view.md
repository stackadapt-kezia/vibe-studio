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
