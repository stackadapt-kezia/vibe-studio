# Visualizer mode map

Reference for planning Vibe studio's visualizer modes. Derived from a 52-effect
inspiration list; the point of this document is that those 52 effects are not 52
features. They are roughly nine single-pass fragment-shader families plus four
effects that need real machinery.

Build by family, not by mode. One halftone shader yields four of the numbered
effects; one Sobel operator yields five.

## Status (9 Oct 2026, v0.9.27)

All nine families have a first mode on stage. The app was already WebGL when
this map was written, so "GL migration" never happened as a step; image and
video texture input landed on top of the existing pipeline. Two things turned
out differently from the plan:

- **Family 1 is a layer, not a pattern.** UV distortion is applied to the
  coordinate before any pattern samples it, so Fisheye, Scanlines, Band shift,
  Mirror and Grid work on the procedural patterns, the oscilloscope and every
  image mode alike. It lives in its own Distort section.
- **Family 3 was built and then replaced.** Voronoi tiles with grout read as
  stained glass, not mosaic. Mosaic is now family 4 (pixel blocks with ordered
  dither). The Voronoi version is in git history if a Tiles pattern is ever
  wanted.

Family 8 is likewise a layer (the Screen section), since a display treatment
belongs on top of whatever is showing.

Remaining from the numbered list, by family: 22 Diagonal Frame Fracture,
27 Luminance Flow, 19 Motion Study Grid, 16 Progressive Blur (1); 44 Survey
Data Overlay (2); all of 3; 40 Screen-Print Layers, 50 Photocopier Toner (4);
05 Eroded Halftone, 13 Variable Dot Matrix, 02 Binary Grid (5); 21 Ghost
Double Print, 29 Mirror Double Exposure (6); 31 Machine Vision Overlay (7);
39 Analog Scan Tear, 03 Digital Rain (8); 07 Ember Glyphs, 11 Cross-Stitch,
46 Woven Thread, 12 Date Stamp Burn (9); and everything under "Needs more than
a shader".

Not from the list but built along the way: a music library with a player
(tags and cover art read from MP3, M4A and FLAC), video playback controls, a
microphone input picker with a silent-input warning, per-mode control
visibility, folding and resizable panel sections, reactivity routes from any
band to any control, and the preset library with live thumbnails and a set
list on keys 1–8 (0.7.0, see `docs/preset-library.md`).

Since 0.5.4 the layers have grown: Distort gained Bleed and Glass (Frosted,
Flute and five glass-block faces, with Seam controls); Screen gained Echo (a
16-frame ring of past captures) and Slit-scan (0.9.26, the first "needs more
than a shader" mode, reading the same ring); a Texture layer holds Scratches
and Print dots; crossfades have five transition types; and the camera feeds
face detection as a reactivity source (`docs/face-detection.md`).

---

## Families

### 1. UV distortion — move the coordinate before sampling
**Tier: build first.** Cheapest family on the list. **Built** as the Distort
layer (0.3.1): Fisheye, Scanlines, Band shift, Mirror, Grid, with an Amount
slider and a Beat → Distort reactivity control.

Covers: 25 Fisheye Lens, 26 Wavy Scanlines, 01 Horizontal Band Shift,
22 Diagonal Frame Fracture, 14 Mirror Side Panels, 10 Repeated Crop Grid,
27 Luminance Flow, 19 Motion Study Grid, 16 Progressive Blur.

One shader with a mode switch. Transform `uv`, then sample. Fisheye is a radial
push; wavy scanlines is a sine offset on `uv.x` driven by `uv.y`; band shift
quantises `uv.y` into rows and offsets each row.

This is the "warp / manipulate image" requirement.

### 2. Luminance → palette — map brightness through a gradient
**Tier: build first.** Strategically the most valuable block here. **Built**
as Heatmap (0.3.0): Scale is contrast, Warp cycles the palette, Bands
posterises.

Covers: 24 Thermal HUD, 44 Survey Data Overlay.

The app's existing colour-stop control is a lookup table. Take the image's
luminance, use it as the position along the palette gradient, output that colour.
That is heatmap mode. Every future false-colour treatment is the same shader with
a different palette, so every saved palette becomes a new look for free.

The palette colour-stop reordering bug this depended on is fixed (0.2.1).

### 3. Cell and Voronoi — average colour per region
**Tier: build first.** **Built then removed** (0.3.2 → 0.3.3), see Status.

Covers: 47 Mosaic Tile Scatter, 42 Geometric Masks, 15 Polygon Fragmentation,
48 Puzzle Collage.

A jittered grid or Voronoi cell function assigns each pixel to a region; every
pixel in a region takes one sampled colour. Polygon fragmentation is the same
idea with sharper cell edges and per-cell offset — a good approximation without
generating real geometry.

If this comes back it should be a separate Tiles pattern, not Mosaic.

### 4. Quantisation and dither
**Tier: next.** **Built** as Mosaic (0.3.3): square blocks, posterised to a few
levels (Bands), with a Bayer ordered dither at block resolution (Warp).

Covers: 04 Block Pixelation, 32 Quantized Pixel Art, 30 Monochrome Dither,
40 Screen-Print Layers, 50 Photocopier Toner.

Pixelation is `floor(uv * n) / n`. Colour quantisation rounds each channel to N
steps. Dither thresholds against a Bayer matrix. Screen-print posterises into flat
separations.

### 5. Halftone and dot screens
**Tier: next.** **Built** as Halftone (0.4.0): rotated dot screen, dot area by
darkness, dot colour up the palette, on paper of the first colour.

Covers: 33 Magazine Halftone, 43 Risograph Dots, 05 Eroded Halftone,
13 Variable Dot Matrix, 02 Binary Grid.

One shader: rotate the coordinate space, build a dot grid, size each dot by the
luminance beneath it. The variants are parameter changes — dot shape, screen
angle, ink count, erosion.

Likely to travel back to Pattern studio (print-effects-for-motion direction).

### 6. Channel separation and ghosting
**Tier: next.** **Built** as Prism (0.4.1). Note for anyone extending it:
averaging palette-mapped copies goes muddy. The blend that works keeps the base
at full saturation and only prints the offset copies where they disagree with
it, so fringing lands on edges.

Covers: 37 RGB Prism Slices, 35 CMYK Misregistration, 21 Ghost Double Print,
29 Mirror Double Exposure.

Sample the same texture three or four times at slightly different coordinates and
recombine. RGB at offset positions gives chromatic aberration; the same move in
CMYK reads as print rather than video. Driving offset distance from the bass band
is a two-line change once the family exists (done: bass pushes the offset).

### 7. Edge and gradient detection
**Tier: next.** **Built** (0.4.2) as four patterns from one Sobel helper:
Edges, Relief, Contour, Hatch. Hatch follows the gradient direction only where
the gradient is strong; in flat areas it holds one angle, otherwise it
dissolves into noise.

Covers: 09 Neon Edge Trace, 23 Technical Pen Hatching, 08 Topographic Lines,
38 3D Relief Grid, 31 Machine Vision Overlay.

All from one Sobel operator — nine samples giving the brightness gradient at each
pixel. Colour the gradient for neon edges; use its direction to pick a hatch angle
for pen hatching; treat luminance as height and light it from the gradient for
relief. Contour lines are separate and trivial: `fract(luminance * n)` thresholded.

### 8. Analog and CRT artifacts
**Tier: later.** **Built** as the Screen layer (0.4.3): CRT, LCD, VHS with an
Amount slider. VHS's row tears run before sampling (with the distortions); its
noise, dropout lines and rolling bar run after.

Covers: 34 CRT Phosphor Mesh, 36 Retro LCD Screen, 45 VHS Tape Damage,
39 Analog Scan Tear, 20 Film Gate Flicker, 03 Digital Rain.

Subpixel masks, scanline darkening, per-row noise offsets, time-varying brightness
jitter. Individually easy; they only look right stacked and carefully tuned, which
is where the time goes. Most of them reuse the channel-separation work.

### 9. Glyph atlas substitution
**Tier: later.** **Built** (0.4.4) as ASCII and Microtext. The atlas is drawn
on a 2D canvas at startup and rebuilt when the Microtext copy or font changes
(0.5.1), so no image assets ship with the app.

Covers: 06 ASCII Symbols, 07 Ember Glyphs, 51 Microtext Portrait,
11 Cross-Stitch Pixels, 46 Woven Thread Pixels, 12 Date Stamp Burn.

Divide the frame into cells, read average luminance per cell, draw the glyph whose
density matches, from a texture atlas. One shader for all of them; the work is
producing the atlases. Date stamp burn is the odd one out and is trivial — a text
overlay with a screen blend. Microtext with StackAdapt copy has real brand
potential.

---

## Needs more than a shader

18 Datamosh Smear, 49 Slit-Scan Time Slices, 52 Pixel Sorting Streaks,
28 Particle Reconstruction. **Slit-scan built** (0.9.26) as a Screen mode on
Echo's ring: sixteen quarter-size captures, so the older slices are softer
than the live edge. Spacing sets how many frames apart they are. The rest are
open.

These need memory of previous frames or a simulation. Datamosh and slit-scan need
a ring buffer of past frames in GPU memory plus a second render pass. Pixel sorting
needs repeated sorting passes, which is awkward on a GPU and expensive at
projection resolution. Particle reconstruction needs a particle system driven by
the image.

All achievable; none belong in the first build. Slit-scan is the one to reach for
first — most striking, most forgiving of an approximate implementation.

---

## Build order

0. **Bug fixes** — done (0.2.1, 0.2.2). The palette stops also had an
   init-order bug that piled them at the bottom of the pill. The oscilloscope's
   stair-stepping was 8-bit sample precision, not `devicePixelRatio`, which was
   already handled.
1. **Show-readiness** — done. Mic constraints all false on laptops (already were),
   fullscreen (already was), live sensitivity controls (Gain and Smoothing
   under Reactivity), audio input device picker (0.5.4), Screen Wake Lock,
   re-taken whenever the page shows (0.9.26). A soak harness (0.9.27) found
   and fixed a render-target leak on resize and a feedback loop that broke
   the first draw of every crossfade; after the fixes a one-hour run (video,
   camera, a preset change with a fade every 15 s, resizes, Slit-scan, Echo
   and Frosted) held flat on JS heap, textures and framebuffers, with no GL
   or page errors. It ran on software rendering, so it says nothing about
   frame rate on real hardware.
2. **Image texture input + Heatmap** — done (0.3.0). Video input too, with
   playback controls (0.4.5).
3. Family 1 — done, as a layer.
4. Family 3 — built and replaced by family 4 (see Status).
5. Families 4–7, then 8–9 — done, first mode each.

Next, in rough order of value: face positions into the shader (the "not
yet" list in `docs/face-detection.md`); datamosh, which can reuse the ring;
or a second pass over families 1, 5 and 9 for the remaining numbered effects.

Sound In polish — media player controls, file metadata, album art — turned out
to be wanted early and is done (0.5.0). It is operator UI, hidden in
presentation mode.

## Constraints to keep in mind

- Runs unattended for hours on a projector at live events. Multi-hour stability
  beats any individual effect.
- Audio comes from a line feed via a USB audio interface, not a laptop mic.
  The input picker exists for exactly this; the app warns when an input has
  been silent for three seconds.
- Bundled demo audio must be CC0 or royalty-free — no commercial tracks in the
  repo — and kept small, since git stores every version of a binary permanently.
  (Nothing is bundled today: the music library stores the operator's own files
  in the browser, not in the repo.)
- Palette ramps blend in linear light (0.9.26). Other mixes in the shaders
  (crossfades, Prism's offset copies, trails) still blend stored sRGB values.
