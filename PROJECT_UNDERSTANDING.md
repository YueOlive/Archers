# Archers Project Understanding

## High-level summary

Archers is a SwiftUI-based iOS app for archery posture guidance using:

- `ARKit` (`ARFaceTrackingConfiguration`) for face-based distance estimation.
- `Vision` (`VNDetectHumanBodyPoseRequest`) for body joint detection.
- A pure Swift scoring module (`Archers/Scoring/ArcheryScorer.swift`) for arm, body, and leg posture evaluation, with `ARManager` acting as the adapter from Vision/UI state into scoring input.

The repo also contains a watchOS companion target (`Archery Watch App`), currently still template-level and not connected to iOS posture/session logic.

## Repository structure

- `Archers/`
  - `ArchersApp.swift`: iOS app entry point.
  - `ARManager.swift`: AR session lifecycle, camera preview creation, Vision pose extraction, and adapter into the pure scoring module.
  - `Scoring/`
    - `ArcheryScorer.swift`: pure Swift scoring domain, geometry helpers, subscore evaluators, and weighted total aggregation.
  - `Views/`: onboarding + correction UI.
  - `Resources/`: app assets + custom font.
  - `Info.plist`: custom font registration.
- `Archery Watch App/`
  - `ArcheryApp.swift`: watchOS app entry.
  - `Views/ContentView.swift`: placeholder “Hello, world!” UI.
- `Archers.xcodeproj/`: project and target configuration.
- `Package.swift`: SwiftPM manifest for isolated scoring tests.
- `ArchersScoringTests/`: package tests for scoring behavior.
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
   - Uses an internal `VisionCoordinator` actor to manage frame sequencing and task cancellation (`latest-frame-wins`).
   - Runs `VNDetectHumanBodyPoseRequest` and extracts all joints into a local `PosePoints` payload.
   - Applies pose points + score on `MainActor` in a single update path.
   - Uses monotonically increasing `frameID` to ignore stale out-of-order results.

Current frame-processing state in `ARManager`:

- `visionCoordinator.currentVisionTask`: currently active Vision task.
- `visionCoordinator.nextFrameID`: issued frame sequence number.
- `visionCoordinator.latestAppliedFrameID`: newest frame applied to observable state.

### 3) Orientation and mirroring

`ARManager` explicitly maps interface orientation + camera position + mirror setting into:

- Vision EXIF orientation (`mappedCGImageOrientation`).
- Preview image orientation (`mappedUIImageOrientation`).

This keeps Vision coordinates and rendered preview aligned for overlay drawing.

### 4) Joint mapping strategy

Joint extraction uses confidence threshold `>= 0.3` and normalized points converted into top-left-origin UI space (`y: 1 - y`).

For front-camera/mirror alignment, several joints intentionally cross-map left/right (e.g. left arm uses Vision right wrist/elbow).

## Scoring model

Scoring logic now lives in the pure Swift `ArcheryScorer` module.

- Input model:
  - `ArcheryPoint`
  - `ShoulderPair`
  - `ArcheryPose`
- Output model:
  - `ArcheryScoreBreakdown`
- `ARManager` converts tracked `CGPoint` state into `ArcheryPose`, calls `ArcheryScorer.score(for:)`, then maps the result back into observable UI properties.

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

Base scoring is from `ArcheryScorer.score(for:ideal:tolerance:)` producing `0...100`.

Current scoring behavior:

- Computes per-frame weighted totals from whichever components are present.
- Sets `totalScore = frameTotal / frameWeight` when at least one component exists.
- Resets `totalScore = 0` when no score components are available.
- Returns `nil` for missing component data instead of forcing a zero score.
- Corrected legs behavior:
  - `evaluateLegs(in:)` now returns `nil` when either ankle is missing.
  - Missing leg data no longer consumes the `0.09` legs weight in the total.

Geometry and helper math are now also pure Swift:

- `distance(_:_:)`
- `angle(a:b:c:)`
- `score(for:ideal:tolerance:)`
- `scoreForDistance(_:_:idealDistance:tolerance:)`

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

1. Typo/quality issues in naming and copy:
   - `intentedUse`, `towrd`, `archary`, etc.
2. Production UI still contains heavy debug overlays in correction view.
3. Test coverage is still partial:
   - scoring math now has package tests, but there are still no tests for Vision-to-pose mapping, stage flow, or stale-frame suppression.
4. watchOS app is not integrated yet:
   - no data sync, no `WatchConnectivity`, no shared session commands.
5. Naming drift remains in app-side score state:
   - `horizontalLegDistanceIdeal` is now storing measured horizontal ankle distance, not an ideal/reference value.

## What is ready for next feature work

Good foundation already exists for near-term expansion:

- Stage-based onboarding shell is easy to evolve.
- AR/Vision pipeline already produces actionable joints and distance.
- Score math is now isolated into a pure Swift module and verified independently from ARKit/Vision.

Most impactful stabilization before larger features:

1. Expand scoring tests beyond aggregate totals to cover individual component edge cases.
2. Decide whether debug overlays should be gated by a debug flag.
3. Add tests for frame ordering and stale-frame suppression in the Vision pipeline.
4. Rename app-side state like `horizontalLegDistanceIdeal` to match current semantics.
