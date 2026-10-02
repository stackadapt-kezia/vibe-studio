# Face detection schema

Feature spec. Save as `docs/face-detection.md` and reference it from `CLAUDE.md`.

## Scope

**Detection, not recognition.** The system reports that a face is present and
where it is. It never identifies who someone is, never builds a face template,
and never stores anything.

- Detection results exist in memory for the current frame and are discarded.
- Track IDs are ephemeral integers, reset every session, meaningless outside it.
- No frames, crops, embeddings or descriptors are written anywhere.

This is not a privacy nicety, it's the design. Face *recognition* creates
biometric data with real legal obligations attached. Face *detection* with no
identity and no storage does not, and it's all the visuals need.

## What produces it

MediaPipe Face Detector, running client-side via the browser. Lightweight,
real-time, returns a bounding box plus six keypoints per face.

Do not reach for Face Landmarker (468-point mesh) for this. That's for
close-range filter work on one person; it's heavier and the extra detail is
invisible from across a room.

Needs a real GPU. The mirror zone wants a proper mini PC; the abstract zones
can stay cheap.

---

## Per-frame output

All coordinates **normalised 0–1** against the source frame, never pixels. The
wall has screens of different sizes and the same data has to work on all of
them.

```json
{
  "t": 1733160000000,
  "source": { "w": 1280, "h": 720 },

  "faces": [
    {
      "id": 3,
      "state": "tracked",
      "age": 47,
      "confidence": 0.93,
      "box": { "x": 0.41, "y": 0.22, "w": 0.14, "h": 0.19 },
      "keypoints": {
        "leftEye":  { "x": 0.45, "y": 0.28 },
        "rightEye": { "x": 0.51, "y": 0.28 },
        "nose":     { "x": 0.48, "y": 0.32 },
        "mouth":    { "x": 0.48, "y": 0.37 },
        "leftEar":  { "x": 0.42, "y": 0.30 },
        "rightEar": { "x": 0.54, "y": 0.30 }
      },
      "roll": -0.08
    }
  ],

  "derived": {
    "count": 1,
    "presence": 1.0,
    "occupancy": 0.027,
    "largest": 0.19,
    "nearest": { "x": 0.48, "y": 0.31 },
    "spread": 0.0
  },

  "events": [ { "type": "arrive", "id": 3 } ]
}
```

### Face fields

| Field | Meaning |
|---|---|
| `id` | Ephemeral track id, stable while the face stays detected. Reused after a session restart. |
| `state` | `new`, `tracked`, or `lost` — `lost` means not detected this frame but still inside the grace period. |
| `age` | Frames this track has survived. Use it to ignore flickers: don't react to anything under ~5. |
| `box` | Normalised bounding box. |
| `roll` | Head tilt in radians, derived from the eye line. |

### Derived fields

This layer is the important one. **Shaders want scalars, not arrays.** Raw
detections drive logic; derived values drive visuals.

| Field | Meaning | Good for |
|---|---|---|
| `count` | Faces currently tracked | Switching behaviour at thresholds |
| `presence` | Smoothed 0–1, is anyone there | Fading effects in and out |
| `occupancy` | Sum of face areas ÷ frame area | How crowded it is |
| `largest` | Height of the biggest face | Proxy for proximity — someone close |
| `nearest` | Centre of the largest face | Point effects at a person |
| `spread` | How distributed the faces are | One person close vs a group across the frame |

`spread` is worth having: it's the difference between "someone is standing right
here" and "five people walking past," which should probably look different.

### Events

Emitted once on transition, not every frame.

```json
{ "type": "arrive",  "id": 3 }
{ "type": "depart",  "id": 3 }
{ "type": "crowd",   "count": 5 }
{ "type": "empty" }
```

`empty` after a sustained absence is the useful one — that's your cue to drop
back to an ambient state when nobody's around.

---

## Smoothing and hysteresis

Detection flickers. A face drops for two frames and returns. Drive visuals
straight off raw detection and everything strobes.

```json
{
  "detectEveryNFrames": 2,
  "arriveAfterFrames": 3,
  "loseAfterFrames": 12,
  "smoothing": {
    "presence": 0.12,
    "position": 0.30,
    "size": 0.20
  }
}
```

Two rules that matter:

**The arrive and lose thresholds are deliberately asymmetric.** Three frames to
appear, twelve to disappear. A face that blinks out for a few frames stays
tracked, so effects don't flash off and on. Symmetric thresholds are the single
most common cause of a jittery installation.

**Detect less often than you render.** Running detection every second frame
while rendering at 60fps is plenty — interpolate derived values between
detections. Detection is the expensive part; rendering is not.

---

## Shader uniforms

Fixed-size, because shaders need them that way.

```
uFaceCount    int
uPresence     float      // 0..1, smoothed
uOccupancy    float      // 0..1
uLargestFace  float      // 0..1, box height
uNearestFace  vec2       // normalised centre
uFaceBoxes    vec4[8]    // x, y, w, h — unused slots zeroed
```

Cap at eight boxes. More than eight faces driving individually distinct
behaviour is visual noise, and the crowd-level values (`occupancy`, `spread`)
describe that situation better anyway.

## Binding into presets

Face values become another modulation source alongside the audio bands, using
the same shape as the audio bindings in `preset-library.md`:

```json
"face": [
  { "target": "bloom.threshold",   "source": "presence",   "depth": 0.5 },
  { "target": "mosaic.cellSize",   "source": "largest",    "depth": 0.7, "invert": true },
  { "target": "warp.centre",       "source": "nearest" }
]
```

`invert` on `largest` is the useful pattern: cells get smaller as someone gets
closer, so the image resolves as you approach it. That's a reason to walk up to
the wall, which is the whole point.

---

## Out of scope

- Identity, matching, or any persistence across sessions.
- Age, gender, emotion or any other inference about the person. Unreliable,
  unnecessary here, and a liability.
- Face mesh or landmark detail beyond the six keypoints.
- Recording or saving any frame, crop or derived descriptor.

---

## Implementation notes (0.9.18)

Built against this spec with the browser's **FaceDetector API** rather than
MediaPipe, because MediaPipe is a CDN script that fetches its model from
Google at runtime and the repo ships no external code. FaceDetector is built
into Chrome, returns the same box plus eye, nose and mouth keypoints, and
needs no download. It is Chrome-only and on desktop sits behind
`chrome://flags/#enable-experimental-web-platform-features`, which is flipped
once on the show machine. The detector is isolated in `startFaces` /
`detectFaces`; a vendored MediaPipe can replace it without touching the
derived values or the routes.

- **Source.** Camera is a Video in source beside Media and Tab; the feed is
  also the picture behind the effects. Detection runs only on the camera.
- **Tracking.** Boxes are matched to tracks by overlap each detection; a
  track arrives after 3 hits and is lost after 12 misses (asymmetric, as the
  spec asks). Detection runs every second frame. Nothing is kept beyond the
  current tracks, and track ids reset when the camera stops.
- **Derived values.** `presence`, `count`, `occupancy`, `largest`, `nearest`
  and `spread`, smoothed, plus up to eight boxes, exactly the spec's fields.
- **Binding.** Face values are reactivity sources beside the audio bands:
  Face: presence, Face: near (largest box height, scaled), Face: crowd
  (occupancy, scaled) and Face: spread. They route to any target the bands
  can, so "cells get smaller as someone gets closer" is Face: near →
  Size with a negative-feeling amount achieved by routing to a target that
  shrinks, or by pairing with a preset whose base is coarse.
- **Readout.** The camera's stage card shows the live count, presence, near
  and spread, or why detection is off.
- **Not yet.** `nearest` is computed but no target consumes a point; the
  shader uniforms block (`uFaceBoxes` and friends) is not bound; events are
  not emitted as such, though `presence` falling to 0 is the `empty` cue.
