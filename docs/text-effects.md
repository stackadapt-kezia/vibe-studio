# Text effects

Feature spec. The text source shipped in 0.9.36; the edge effects below are
the next build. Read alongside `mode-map.md` — this is a source-level pass,
not a tenth shader family.

## What exists

`renderTextSource()` draws the operator's copy white-on-black to a 2048×1152
canvas and hands it to `setImageSource()` as kind `"text"`. From there it is
an ordinary image texture, so all sixteen patterns and every Distort, Screen
and Texture mode already work on the letterforms with no shader changes.

`useFont()` registers any .ttf, .otf or .woff2 through the `FontFace` API for
the session only. Nothing is written to the repo and no font is redistributed.

Controls: copy, size as a fraction of the frame width, and tracking.

## The goal

Puckered and spiked letterform edges driven by audio — spikes radiating
perpendicular to the outline, the way Illustrator's Pucker & Bloat behaves on
live text.

This is **not** a lens bulge. Fisheye already does that and it is the wrong
effect: it warps the whole frame while the outline keeps its shape. That
distinction is the reason this document exists.

## Approach: a signed distance field

### 1. Build the field on the CPU

After rasterising the copy, derive a field where every pixel stores its
distance to the nearest letterform edge — negative inside the glyph, positive
outside. A two-pass Euclidean distance transform (Felzenszwalb) is about
forty lines and runs in a few milliseconds at 2048px.

It runs once per copy or font change, never per frame.

No dependencies. `CLAUDE.md` rules out npm and CDN script tags, so the
transform is written in the file. Do not reach for `msdf-bmfont` or similar.

### 2. Upload it as its own texture

The field goes in a separate texture, not as extra channels on the text
canvas. The patterns consume the text source as an ordinary picture, and
changing that texture's format breaks all sixteen of them.

### 3. Render the effect as a source pass

A pixel is ink when its distance falls below a threshold. Modulate that
threshold by direction: take the gradient of the field, which gives the edge
normal — which way this piece of outline faces — and feed its angle into a
high-frequency periodic function. Edges facing some directions push outward,
others pull in, and the result is spikes perpendicular to the outline.

Render that into an offscreen target (`makeTarget` and `resize` already
exist) and use the target as the image texture for the rest of the pipeline.

## Why this is a source pass and not a Distort mode

The Distort layer displaces `uv` before sampling. Spiking does something
different: it re-decides where the edge of the shape is. In the Distort switch
every pattern downstream would see an already-warped picture rather than a
differently-shaped one, and the two could not be stacked.

As a source pass it composes correctly. The letterforms take their new shape
first, then the chosen pattern, Distort, Screen and Texture apply on top,
exactly as they do for an image or a camera feed.

## What the same pass gives for free

| Effect | How |
|---|---|
| Weight | Move the threshold uniformly. Any font gains variable-weight behaviour, with no variable-font axes and no re-rasterising. |
| Outline | Threshold at two distances and keep the band between them. |
| Glow | Fade across distance instead of thresholding hard. |
| Font as a frame | Use the sign of the field as a mask: video inside the letterforms, background outside. |

**Build Weight first.** It proves the field is correct — if the letters
thicken and thin smoothly, the transform works — and it is a strong effect on
its own driven from the audio envelope.

## Controls

Under the text source: **Edge** (Off / Spike / Bloat / Weight), **Amount**,
and **Frequency** for the spike count.

Amount and Weight join the existing reactivity targets beside the audio bands
and face sources, through the same routes mechanism, so bass can make a word
bristle or swell.

## A note on legibility

Legible type and heavily distorted type are different jobs, and one setting
cannot serve both. Default the effects low enough that copy stays readable and
let the operator push into abstraction deliberately. On the TV pile this
resolves per zone rather than per setting: some screens carry words, others
carry texture.

## Out of scope

- Glyph outline extraction and bezier tessellation (opentype.js plus a
  triangulator). Weeks of edge cases, and at viewing distance it is
  indistinguishable from the field approach. The field also gives a continuous
  spike-frequency dial, which anchor-driven spikes do not.
- Multi-line copy, text layout, and per-glyph animation. One line of display
  copy is the brief.
- Shipping any font in the repo. Fonts are loaded by the operator at runtime.
