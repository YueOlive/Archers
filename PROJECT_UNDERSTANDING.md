# Archers Project Understanding

## High-level summary

Archers is an iOS SwiftUI app focused on **archery posture correction** using a live camera feed.
It combines:

- `ARKit` (face tracking) to estimate user distance from camera.
- `Vision` (`VNDetectHumanBodyPoseRequest`) to detect body joints.
- A custom scoring model in `ARManager` for left arm, right arm, body alignment, and leg stance.

The repository also includes a companion watchOS target (`Archery Watch App`), but it is currently a template app and not yet integrated with the iOS posture system.

## Repository structure

- `Archers/` - iOS app source.
  - `ArchersApp.swift` - app entry point.
  - `ARManager.swift` - camera/session/pose detection and scoring logic.
  - `Views/` - onboarding pages + correction screen.
  - `Resources/` - assets and custom font (`Newsreader.ttf`).
- `Archery Watch App/` - watchOS app (basic placeholder UI).
- `Archers.xcodeproj/` - project config with two targets:
  - `Archers` (iOS)
  - `Archery Watch App` (watchOS)

There are no unit/UI tests and no README currently.

## Project agent constraints (`AGENTS.md`)

The repository defines implementation constraints that should guide all new feature work:

- Always use latest `Swift`, `SwiftUI`, `Combine`, and `ARKit` APIs.
- Prefer `async`/`await` for asynchronous operations.
- Use the Observation framework instead of `@StateObject`.
- Do not use any API marked obsolete by Apple.

## App flow (iOS)

`Archers/Views/ContentView.swift` contains a simple stage machine:

1. `welcome`
2. `guidePrivacy`
3. `intentedUse`
4. `takeABreak`
5. `cameraAccess`
6. `watchAccess`
7. `correction`

Each onboarding view receives `@Binding var appStage` and moves to the next stage with animated transition.

Current default launch stage is set to `.correction` (likely for development), so onboarding is skipped unless changed.

## Core technical architecture

### 1) `ARManager` responsibilities

`Archers/ARManager.swift` is the core engine and currently combines multiple concerns:

- Owns `ARSession` and starts `ARFaceTrackingConfiguration`.
- Receives frame updates via `ARSessionDelegate`.
- Builds oriented camera preview image for SwiftUI rendering.
- Runs Vision pose detection on each frame.
- Extracts joint points (shoulders, elbows, wrists, neck, ankles, root).
- Computes posture sub-scores and total score.

### 2) Camera and orientation handling

The manager maps interface orientation + camera position + mirror mode into:

- EXIF orientation for Vision (`mappedCGImageOrientation`).
- UIImage orientation for preview (`mappedUIImageOrientation`).

This is important so pose points and displayed frame stay aligned.

### 3) Pose extraction model

`VNRecognizedPoint`s are converted into normalized `CGPoint`s (0...1 space).
Several joint mappings are intentionally swapped left/right to account for mirrored/front-camera perspective.

### 4) Scoring model

Subscores:

- Left arm (`evaluateLeftArm`) - elbow angle + wrist/shoulder height relation.
- Right arm (`elvaluateRightArm`) - elbow angle + forearm height relation.
- Body (`evaluateBody`) - neck/root horizontal alignment.
- Legs (`evaluateLegs`) - ankle horizontal spread and vertical level.

Weights:

- Left arm: `0.4`
- Right arm: `0.4`
- Body: `0.11`
- Legs: `0.09`

Scores are normalized to 0-100 using `scoreFor(value:ideal:tolerance:)`.

## UI state and rendering

### Onboarding views

`WelcomeView`, `GuidePrivacyView`, `GuideIntentedUseView`, `GuideBreakView`, `GuideCameraView`, and `GuideWatchView` share similar structure:

- Full-screen background image.
- Symbol/icon + title + explanatory text.
- Rounded CTA button to advance app stage.

### Correction screen

`Archers/Views/CorrectionView.swift`:

- Instantiates `ARManager` and reads observable state directly.
- Uses `previewImage` as background.
- Displays status messaging:
  - Red prompt when no body is detected.
  - Green prompt and distance panel when body is detected.
- Draws many debug markers (colored circles) for joints and screen corners.
- Includes helper functions for distance wording and point mapping under `scaledToFill`.

This screen appears to be actively used for iterative debugging of pose alignment.

## Watch app status

The watch target (`Archery Watch App`) currently has default template content (`Hello, world!`).
No data sharing, connectivity, or command interface exists yet between iPhone and Apple Watch targets.

## Build/config observations

- iOS deployment target: `18.0` (project-level has `18.4` in generic settings).
- Portrait-only orientation for iPhone target.
- Custom font configured in `Archers/Info.plist` (`Newsreader.ttf`).
- `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` are set in build settings.

I could not run `xcodebuild` in this environment because full Xcode is not selected (`xcode-select` points to Command Line Tools only).

## Current quality and technical debt notes

1. **Score accumulation bug risk**: `totalScore` is incremented inside `calcScore()` without reset each frame; values can drift over time.
2. **`ARManager` lifecycle in views**: `CorrectionView` and `GuideCameraView` use plain stored properties (`let/var arManager = ARManager()`), which can recreate manager instances on view reload.
3. **Concurrency style mismatch**: Vision work currently uses `DispatchQueue.global` plus `Task { @MainActor ... }`; this works, but does not yet follow the repo's `async`/`await` preference and is easy to race.
4. **Unused/unfinished members**: `onBodyPositionUpdate` and `visionQueue` are present but not used.
5. **Naming/typos**: `intentedUse`, `elvaluateRightArm`, and some user-facing copy typos (`towrd`, `archary`, grammar issues).
6. **No test coverage**: no automated validation for scoring math, mapping logic, or stage transitions.
7. **Debug overlays in production path**: marker circles are always rendered on correction screen.

## What is ready for feature work

The project already has a clear foundation to extend:

- Stage-based onboarding flow is simple to modify.
- AR/Vision pipeline is in place and exposes many intermediate points.
- Scoring logic is centralized in one file and can be tuned.

Likely first refactor candidates before larger features:

- Stabilize `ARManager` ownership with an Observation-native lifecycle pattern (without `@StateObject`).
- Split `ARManager` into session, pose extraction, and scoring components.
- Add a small testable scoring module independent of camera input.

---

Prepared from direct review of all Swift source files, Info.plist, and Xcode project configuration in this repository.
