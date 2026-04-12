# Gesture Scoring Design Plan

## Goal

Let the user understand whether the current posture scoring is reasonable, and make it easy to adjust the scoring settings for each posture component without guessing.

This plan is design-only. No implementation is included here.

## Current State

The app already computes these live scores in `ARManager` via `ArcheryScorer`:

- `leftArm`
- `rightArm`
- `body`
- `legs`
- `total`

The scorer currently uses hard-coded ideals, tolerances, and weights:

- Left arm:
  - elbow angle ideal `180`, tolerance `5`
  - wrist/shoulder height ideal `0`, tolerance `0.15`
  - internal mix `80% / 20%`
- Right arm:
  - elbow angle ideal `30`, tolerance `5`
  - forearm height ideal `20`, tolerance `3`
  - internal mix `20% / 80%`
- Body:
  - neck/root horizontal alignment ideal `0`, tolerance `5`
- Legs:
  - ankle horizontal spread ideal `0.16`, tolerance `0.06`
  - ankle vertical alignment ideal `0`, tolerance `0.1`
  - internal mix `80% / 20%`
- Overall weight:
  - left arm `0.4`
  - right arm `0.4`
  - body `0.11`
  - legs `0.09`

The current UI only exposes a debug-like horizontal leg distance value from `ARManager.horizontalLegDistance`, which is not enough to judge whether tuning is correct.

Recent implementation update:

- Renamed app-side state from `horizontalLegDistanceIdeal` to `horizontalLegDistance` to match measured semantics.
- The value is now optional (`CGFloat?`) and preserves missing-joint state.
- The current UI shows `--` when ankle data is unavailable, instead of forcing `0.00`.

## Recommendation

Do not stop at simply showing the part scores on screen.

Showing only `leftArm = 72` or `legs = 54` helps the user notice a problem, but it does not help them understand whether:

- the posture is actually wrong
- the ideal target is wrong
- the tolerance is too strict
- the overall weighting is biased

The better design is a two-layer scoring UI:

1. A lightweight live summary visible during posture checking.
2. A focused tuning panel where each posture component can expose its target values, tolerances, and effect on total score.

## Proposed UX

### 1. Live Score Summary on the correction screen

Add a compact scoring panel on top of the existing camera view.

Suggested content:

- Total score as the primary number
- Four small score chips/cards:
  - Left Arm
  - Right Arm
  - Body
  - Legs
- Color state for each:
  - green: healthy
  - yellow: borderline
  - red: poor
  - gray: unavailable due to missing joints

Why this helps:

- The user can immediately see which body area is dragging the total down.
- It keeps the live experience simple and readable.
- It avoids forcing them into settings just to understand feedback.

### 2. Tap any part to inspect details

Each score chip should open a detail sheet or bottom panel for that body part.

Example for `Left Arm`:

- Current score
- Current measured elbow angle
- Current measured wrist-to-shoulder height difference
- Current ideal values
- Current tolerances
- A short explanation:
  - "This score prefers a straighter bow arm."
  - "A small vertical wrist offset is allowed."

This is more useful than a raw score because it explains why the score changed.

### 3. Tuning mode for scoring settings

Inside the detail panel, expose editable controls for the corresponding scoring configuration.

Controls should be simple and direct:

- `Ideal` value
- `Tolerance`
- Optional submetric weight
- Reset to default

Examples:

- Left Arm
  - Elbow angle ideal
  - Elbow angle tolerance
  - Wrist height ideal
  - Wrist height tolerance
  - Elbow vs wrist-height contribution
- Legs
  - Horizontal ankle distance ideal
  - Horizontal distance tolerance
  - Vertical ankle difference ideal
  - Vertical difference tolerance
  - Horizontal vs vertical contribution
- Overall
  - Left arm weight
  - Right arm weight
  - Body weight
  - Legs weight

## UI Structure

### In-session layout

Recommended layout for `CorrectionView`:

- Top:
  - distance feedback
  - compact live score summary
- Middle:
  - camera preview with pose markers
- Bottom:
  - body-detected state
  - optional "Tune Scoring" action

This keeps the live feedback visible without blocking the camera.

### Score chip design

Each chip should include:

- body part label
- score number
- small status dot or color fill
- optional trend icon if score is improving or dropping

Example:

`Left Arm 82`

`Legs 54`

If data is missing:

`Legs --`

with a muted style and a hint like "ankles not detected".

### Detail panel design

The detail panel should contain three groups:

1. Live measurement
2. Scoring rule
3. Tuning controls

Example for `Legs`:

- Live measurement
  - current horizontal ankle distance
  - current vertical ankle offset
- Scoring rule
  - ideal horizontal distance
  - horizontal tolerance
  - ideal vertical offset
  - vertical tolerance
- Tuning controls
  - sliders or steppers
  - reset button

## Why This Design Is Better Than Raw Scores Alone

Showing all scores on screen is a good first step, but it still hides the main question: "Is the configuration reasonable?"

To answer that, the UI needs to expose:

- the measured value
- the expected ideal
- the allowed tolerance
- how much that metric affects the part score
- how much the part score affects the total

Without those, the user can see bad output but cannot calibrate the system.

## Configuration Model Proposal

The scorer should eventually move from hard-coded constants to a configurable model.

Suggested concept:

- `GestureScoringConfiguration`
- nested configs per body part
- default preset matching the current values

Example shape:

- overall weights
- left arm config
- right arm config
- body config
- legs config

Each body-part config should contain:

- metric ideals
- metric tolerances
- metric blend weights

This keeps tuning separate from the pure scoring math and makes the UI much easier to bind to.

## Suggested Phased Rollout

### Phase 1

Expose live scores in the correction screen:

- total score
- left arm
- right arm
- body
- legs
- unavailable state for missing joints

This is low-risk and immediately useful.

### Phase 2

Add per-part detail panels showing live measurements and scoring explanations.

This is the point where the user can actually judge whether the current settings make sense.

### Phase 3

Add editable tuning controls backed by a dedicated scoring configuration model.

This is where posture-based scoring becomes adjustable instead of hard-coded.

### Phase 4

Persist user tuning:

- local defaults
- reset to app defaults
- optional presets such as:
  - beginner
  - strict form
  - custom

## Specific Product Suggestions

If only one improvement is added first, make it this:

Add a compact live score summary plus tap-to-open part details.

That gives the user:

- immediate feedback
- per-part visibility
- a path to understanding the rules

If a second improvement is added, make it this:

Expose the underlying live measurements beside each score.

Examples:

- left elbow angle
- right elbow angle
- body horizontal offset
- ankle spread
- ankle height difference

This makes it much easier to tell whether the issue is posture or scoring calibration.

## Risks To Avoid

- Do not put all tuning controls directly on the main camera screen.
  - That will make the experience noisy and hard to use during live posture checking.
- Do not show only totals.
  - Total score is too coarse for calibration.
- Do not expose unlabeled numeric controls.
  - Users need plain-language labels tied to body posture.
- Do not bind tuning directly to debug/internal names like `laScore`, `bScore`, or `horizontalLegDistance`.
  - The UI should use clear, stable labels such as `Left Arm`, `Body`, and `Leg Stance`.

## Final Recommendation

Yes, displaying the score for each part on screen is worth doing, but it should be the first layer, not the whole solution.

The best design is:

- live total + per-part score chips on the correction screen
- tap into a part to see live measurements and scoring logic
- adjust ideals, tolerances, and weights in a dedicated tuning panel

That gives the user a fast live view, and also a practical way to decide whether the current posture scoring configuration is reasonable.
