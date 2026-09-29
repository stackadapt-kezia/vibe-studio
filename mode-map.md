# Visualizer mode map

Reference for planning Vibe studio's visualizer modes. Derived from a 52-effect
inspiration list; the point of this document is that those 52 effects are not 52
features. They are roughly nine single-pass fragment-shader families plus four
effects that need real machinery.

Build by family, not by mode. One halftone shader yields four of the numbered
effects; one Sobel operator yields five.

---

## Families

### 1. UV distortion — move the coordinate before sampling
**Tier: build first.** Cheapest family on the list.

Covers: 25 Fisheye Lens, 26 Wavy Scanlines, 01 Horizontal Band Shift,
22 Diagonal Frame Fracture, 14 Mirror Side Panels, 10 Repeated Crop Grid,
27 Luminance Flow, 19 Motion Study Grid, 16 Progressive Blur.

One shader with a mode switch. Transform `uv`, then sample. Fisheye is a radial
push; wavy scanlines is a sine offset on `uv.x` driven by `uv.y`; band shift
quantises `uv.y` into rows and offsets each row.

This is the "warp / manipulate image" requirement.

### 2. Luminance → palette — map brightness through a gradient
**Tier: build first.** Strategically the most valuable block here.

Covers: 24 Thermal HUD, 44 Survey Data Overlay.

The app's existing colour-stop control is a lookup table. Take the image's
luminance, use it as the position along the palette gradient, output that colour.
That is heatmap mode. Every future false-colour treatment is the same shader with
a different palette, so every saved palette becomes a new look for free.

Depends on the palette colour-stop reordering bug being fixed first.

### 3. Cell and Voronoi — average colour per region
**Tier: build first.**

Covers: 47 Mosaic Tile Scatter, 42 Geometric Masks, 15 Polygon Fragmentation,
48 Puzzle Collage.

A jittered grid or Voronoi cell function assigns each pixel to a region; every
pixel in a region takes one sampled colour. Polygon fragmentation is the same
idea with sharper cell edges and per-cell offset — a good approximation without
generating real geometry.

This is "mosaic mode".

### 4. Quantisation and dither
**Tier: next.**

Covers: 04 Block Pixelation, 32 Quantized Pixel Art, 30 Monochrome Dither,
40 Screen-Print Layers, 50 Photocopier Toner.

Pixelation is `floor(uv * n) / n`. Colour quantisation rounds each channel to N
steps. Dither thresholds against a Bayer matrix. Screen-print posterises into flat
separations.

### 5. Halftone and dot screens
**Tier: next.**

Covers: 33 Magazine Halftone, 43 Risograph Dots, 05 Eroded Halftone,
13 Variable Dot Matrix, 02 Binary Grid.

One shader: rotate the coordinate space, build a dot grid, size each dot by the
luminance beneath it. The variants are parameter changes — dot shape, screen
angle, ink count, erosion.

Likely to travel back to Pattern studio (print-effects-for-motion direction).

### 6. Channel separation and ghosting
**Tier: next.**

Covers: 37 RGB Prism Slices, 35 CMYK Misregistration, 21 Ghost Double Print,
29 Mirror Double Exposure.

Sample the same texture three or four times at slightly different coordinates and
recombine. RGB at offset positions gives chromatic aberration; the same move in
CMYK reads as print rather than video. Driving offset distance from the bass band
is a two-line change once the family exists.

### 7. Edge and gradient detection
**Tier: next.**

Covers: 09 Neon Edge Trace, 23 Technical Pen Hatching, 08 Topographic Lines,
38 3D Relief Grid, 31 Machine Vision Overlay.

All from one Sobel operator — nine samples giving the brightness gradient at each
pixel. Colour the gradient for neon edges; use its direction to pick a hatch angle
for pen hatching; treat luminance as height and light it from the gradient for
relief. Contour lines are separate and trivial: `fract(luminance * n)` thresholded.

### 8. Analog and CRT artifacts
**Tier: later.**

Covers: 34 CRT Phosphor Mesh, 36 Retro LCD Screen, 45 VHS Tape Damage,
39 Analog Scan Tear, 20 Film Gate Flicker, 03 Digital Rain.

Subpixel masks, scanline darkening, per-row noise offsets, time-varying brightness
jitter. Individually easy; they only look right stacked and carefully tuned, which
is where the time goes. Most of them reuse the channel-separation work.

### 9. Glyph atlas substitution
**Tier: later.**

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
28 Particle Reconstruction.

These need memory of previous frames or a simulation. Datamosh and slit-scan need
a ring buffer of past frames in GPU memory plus a second render pass. Pixel sorting
needs repeated sorting passes, which is awkward on a GPU and expensive at
projection resolution. Particle reconstruction needs a particle system driven by
the image.

All achievable; none belong in the first build. Slit-scan is the one to reach for
first — most striking, most forgiving of an approximate implementation.

---

## Build order

0. **Bug fixes** (no GL needed): palette colour-stop reordering, then oscilloscope
   `devicePixelRatio`. Palette first — it blocks family 2.
1. **Show-readiness**: audio input device picker, `echoCancellation` /
   `noiseSuppression` / `autoGainControl` all false, fullscreen presentation mode,
   Screen Wake Lock re-acquired on `visibilitychange`, live sensitivity controls.
2. **GL migration + image texture input + one mode.** Heatmap (family 2) is the
   right first mode: it consumes the palette control, so it proves the migration
   and the palette fix together. This commit contains nothing else.
3. Family 1 (UV distortion).
4. Family 3 (cells / mosaic).
5. Families 4–7, then 8–9.

Sound In tab polish — media player controls, file metadata, album art — is
operator UI, hidden in presentation mode. Low priority against anything above.

## Constraints to keep in mind

- Runs unattended for hours on a projector at live events. Multi-hour stability
  beats any individual effect.
- Audio comes from a line feed via a USB audio interface, not a laptop mic.
- Bundled demo audio must be CC0 or royalty-free — no commercial tracks in the
  repo — and kept small, since git stores every version of a binary permanently.
