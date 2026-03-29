# Archers Project Understanding

## High-level summary

Archers is a SwiftUI-based iOS app for archery posture guidance using:

- `ARKit` (`ARFaceTrackingConfiguration`) for face-based distance estimation.
- `Vision` (`VNDetectHumanBodyPoseRequest`) for body joint detection.
- A custom scoring pipeline in `ARManager` for arm, body, and leg posture.

The repo also contains a watchOS companion target (`Archery Watch App`), currently still template-level and not connected to iOS posture/session logic.

## Repository structure

- `Archers/`
  - `ArchersApp.swift`: iOS app entry point.
  - `ARManager.swift`: AR session lifecycle, camera preview creation, Vision pose extraction, and scoring.
  - `Views/`: onboarding + correction UI.
  - `Resources/`: app assets + custom font.
  - `Info.plist`: custom font registration.
- `Archery Watch App/`
  - `ArcheryApp.swift`: watchOS app entry.
  - `Views/ContentView.swift`: placeholder “Hello, world!” UI.
- `Archers.xcodeproj/`: project and target configuration.
- `AGENTS.md`: implementation constraints for future changes.

## AGENTS.md implementation constraints

The project-level coding constraints are:

1. Use latest Swift / SwiftUI / Combine / ARKit APIs.
2. Prefer `async`/`await` for async operations.
3. Use Observation framework instead of `@StateObject`.
4. Do not use Apple-obsoleted APIs.

Current code already uses Observation (`@Observable` in `ARManager`) and avoids `@StateObject`.

## iOS app flow and stage model

`Archers/Views/ContentView.swift` defines a stage-driven flow via:

- `welcome`
- `guidePrivacy`
- `intentedUse`
- `takeABreak`
- `cameraAccess`
- `watchAccess`
- `correction`

The app currently launches directly into `.correction`:

```swift
@State var appStage = AppStage.correction
```

Onboarding views still exist and transition forward one step at a time with `withAnimation`.

## Core architecture

### 1) Session and lifecycle

`ARManager` is an `@Observable` class and `ARSessionDelegate`.

- Owns a single `ARSession`.
- Uses internal client reference counting:
  - `attachSessionClient()`
  - `detachSessionClient()`
- Starts/stops AR session only when needed.

`GuideCameraView` and `CorrectionView` both attach/detach session usage on appear/disappear.

### 2) Frame processing pipeline

On each `session(_:didUpdate:)` callback:

1. `detectHumanBody(...)`:
   - Reads `ARFaceAnchor` tracking state.
   - Updates `estimatedDistance` from `faceAnchor.transform.columns.3.z`.
2. `createCameraPreview(...)`:
   - Converts current AR frame `CVPixelBuffer` to oriented `UIImage`.
3. `performVisionRequest(...)`:
   - Runs `VNDetectHumanBodyPoseRequest` on a background queue.
   - Extracts joints (shoulders, elbows, wrists, neck, ankles, root).
   - Computes score.

### 3) Orientation and mirroring

`ARManager` explicitly maps interface orientation + camera position + mirror setting into:

- Vision EXIF orientation (`mappedCGImageOrientation`).
- Preview image orientation (`mappedUIImageOrientation`).

This keeps Vision coordinates and rendered preview aligned for overlay drawing.

### 4) Joint mapping strategy

Joint extraction uses confidence threshold `>= 0.3` and normalized points converted into top-left-origin UI space (`y: 1 - y`).

For front-camera/mirror alignment, several joints intentionally cross-map left/right (e.g. left arm uses Vision right wrist/elbow).

## Scoring model

Subscores:

- Left arm: elbow angle + wrist/shoulder height.
- Right arm: elbow angle + forearm vertical relationship.
- Body: neck/root horizontal alignment.
- Legs: ankle horizontal spread + vertical balance.

Weights in `calcScore()`:

- Left arm: `0.4`
- Right arm: `0.4`
- Body: `0.11`
- Legs: `0.09`

Base scoring is from `scoreFor(value:ideal:tolerance:)` producing `0...100`.

Current `calcScore()` behavior (fixed):

- Computes `frameTotal` and `frameWeight` as local per-frame accumulators.
- Sets `totalScore = frameTotal / frameWeight` when at least one component exists.
- Resets `totalScore = 0` when no score components are available.

## UI implementation summary

### Onboarding screens

`WelcomeView`, `GuidePrivacyView`, `GuideIntentedUseView`, `GuideBreakView`, `GuideCameraView`, `GuideWatchView` share a consistent visual style:

- Fullscreen `BackgroundBg` image.
- White typography with custom `Newsreader` font.
- Rounded “Next”/start actions.

### Guide camera preview

`GuideCameraView` can show live camera preview with shoulder markers and a distance label when preview data is available.

### Correction screen

`CorrectionView`:

- Uses live `previewImage` background.
- Shows red status when no body detected, green status when body detected.
- Shows distance feedback (`away`, `towrd`, `perfect`).
- Draws multiple debug circles for corners and tracked joints.
- Uses `mapPoint(screenSize:imageSize:pt:)` to place normalized pose points under `.scaledToFill`.

## Target and build configuration snapshot

From `project.pbxproj`:

- iOS target (`Archers`)
  - `PRODUCT_BUNDLE_IDENTIFIER = archers.Archers`
  - `IPHONEOS_DEPLOYMENT_TARGET = 18.0` (with project-level generic values also showing `18.4`)
  - `TARGETED_DEVICE_FAMILY = "1,2"`
  - camera/microphone usage strings configured in build settings.
- watchOS target (`Archery Watch App`)
  - `PRODUCT_BUNDLE_IDENTIFIER = archers.Archers.watchkitapp`
  - `WATCHOS_DEPLOYMENT_TARGET = 8.7`
  - `TARGETED_DEVICE_FAMILY = 4`

`Archers/Info.plist` currently registers:

- `UIAppFonts -> Newsreader.ttf`

## Current technical risks / debt

1. Mixed concurrency model:
   - Vision runs with `DispatchQueue.async` + many `Task { @MainActor }` updates instead of structured `async/await`.
2. Thread-safety ambiguity:
   - Shared mutable state is updated from multiple contexts; actor isolation is not explicit.
3. Typo/quality issues in naming and copy:
   - `intentedUse`, `elvaluateRightArm`, `towrd`, `archary`, etc.
4. Production UI still contains heavy debug overlays in correction view.
5. No automated tests:
   - no unit/UI tests for score math, mapping, or stage flow.
6. watchOS app is not integrated yet:
   - no data sync, no `WatchConnectivity`, no shared session commands.

## What is ready for next feature work

Good foundation already exists for near-term expansion:

- Stage-based onboarding shell is easy to evolve.
- AR/Vision pipeline already produces actionable joints and distance.
- Score components are centralized in one manager and can be refactored into testable modules.

Most impactful stabilization before larger features:

1. Refactor frame-processing into structured concurrency and clearer main-thread mutation boundaries.
2. Separate core scoring math into a testable, pure Swift module.
3. Add unit tests for `calcScore()` (including partial-joint and no-joint frames).
4. Decide whether debug overlays should be gated by a debug flag.
