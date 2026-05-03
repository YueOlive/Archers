//
//  ARManager.swift
//  Archers
//
//  Created by Xiaoyue Wu on 8/2/25.
//

import ARKit
import Vision
import Foundation
import Observation

@Observable
class ARManager: NSObject, ARSessionDelegate{
  private actor VisionCoordinator {
    private var currentVisionTask: Task<Void, Never>?
    private var nextFrameID: UInt64 = 0
    private var latestAppliedFrameID: UInt64 = 0
    
    func reserveFrameIDAndCancelCurrentTask() -> UInt64 {
      currentVisionTask?.cancel()
      nextFrameID += 1
      return nextFrameID
    }
    
    func setCurrentVisionTask(_ task: Task<Void, Never>, for frameID: UInt64) {
      guard frameID == nextFrameID else {
        task.cancel()
        return
      }
      currentVisionTask = task
    }
    
    func shouldApply(frameID: UInt64) -> Bool {
      guard frameID > latestAppliedFrameID else { return false }
      latestAppliedFrameID = frameID
      return true
    }
    
    func markHandled(frameID: UInt64) {
      if frameID > latestAppliedFrameID {
        latestAppliedFrameID = frameID
      }
    }
    
    func cancelCurrentTask() {
      currentVisionTask?.cancel()
      currentVisionTask = nil
    }
  }
  
  let session = ARSession()
  @ObservationIgnored private var isSessionRunning = false
  @ObservationIgnored private var sessionClientCount = 0

  var previewImage: UIImage? = nil
  var shoulderPoints: (left: CGPoint, right: CGPoint)?
  
  var leftWristPoint: CGPoint? = nil
  var leftElbowPoint: CGPoint? = nil
  var rightWristPoint: CGPoint? = nil
  var rightElbowPoint: CGPoint? = nil
  var neckPoint: CGPoint? = nil
  var leftAnklePoint: CGPoint? = nil
  var rightAnklePoint: CGPoint? = nil
  var rootPoint: CGPoint? = nil
  
  var legScore: CGFloat = 0
  var laScore: CGFloat = 0
  var raScore: CGFloat = 0
  var bScore: CGFloat = 0
  
  var totalScore: CGFloat = 0
  var leftArmAngle: CGFloat? = nil
  var leftArmAngleScore: CGFloat? = nil
  var leftArmAngleAcceptable: Bool? = nil
  var leftArmHeightDiff: CGFloat? = nil
  var leftArmHeightScore: CGFloat? = nil
  var leftArmGroundAngle: CGFloat? = nil
  var leftArmIsParallelToGround: Bool? = nil
  var rightArmAngle: CGFloat? = nil
  var rightArmAngleScore: CGFloat? = nil
  var rightArmAngleAcceptable: Bool? = nil
  var rightArmForearmHeightDiff: CGFloat? = nil
  var rightArmForearmHeightScore: CGFloat? = nil
  var rightArmForearmHeightAcceptable: Bool? = nil
  var legsHorizontalDistance: CGFloat? = nil
  var legsHorizontalScore: CGFloat? = nil
  var legsHorizontalAcceptable: Bool? = nil
  var legsVerticalDistance: CGFloat? = nil
  var legsVerticalScore: CGFloat? = nil
  var legsVerticalAcceptable: Bool? = nil

  var armsWeight: Double = ArcheryScoreWeights.default.leftArm + ArcheryScoreWeights.default.rightArm {
    didSet {
      calcScore()
    }
  }

  var bodyWeight: Double = ArcheryScoreWeights.default.body {
    didSet {
      calcScore()
    }
  }

  var legsWeight: Double = ArcheryScoreWeights.default.legs {
    didSet {
      calcScore()
    }
  }
  
  var horizontalLegDistance: CGFloat? = nil
  
  var estimatedDistance: CGFloat? = nil
  var mirrorFrontPreview: Bool = false
  @ObservationIgnored private let visionCoordinator = VisionCoordinator()
  
  var onBodyPositionUpdate: (CGFloat) -> Void = { _ in }

  override init() {
    super.init()
    session.delegate = self
  }
  
  deinit {
    let coordinator = visionCoordinator
    Task {
      await coordinator.cancelCurrentTask()
    }
    stopSession()
  }

  func startSession() {
    guard !isSessionRunning else { return }
    guard ARFaceTrackingConfiguration.isSupported else {
      print("ARFaceTrackingConfiguration is not supported on this device.")
      return
    }

    let configuration = ARFaceTrackingConfiguration()
    configuration.isLightEstimationEnabled = true
    session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    isSessionRunning = true
  }
  
  func stopSession() {
    guard isSessionRunning else { return }
    session.pause()
    isSessionRunning = false
  }
  
  func attachSessionClient() {
    sessionClientCount += 1
    if sessionClientCount == 1 {
      startSession()
    }
  }
  
  func detachSessionClient() {
    sessionClientCount = max(0, sessionClientCount - 1)
    if sessionClientCount == 0 {
      stopSession()
    }
  }

  func session(_ session: ARSession, didUpdate anchors: [ARAnchor]){
    //detect human body
    detectHumanBody(session: session, anchors: anchors)
    
    //create camra preview
    createCameraPreview(session: session)
    
    //detect joints
    performVisionRequest(session: session)
  }
  
  func pixelBufferToUIImage(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let context = CIContext(options: nil)
    
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
      return nil
    }
    
    return UIImage(cgImage: cgImage)
  }
  
  func currentInterfaceOrientation() -> UIInterfaceOrientation {
      return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
          .interfaceOrientation ?? .portrait
  }
  
  /// 从 AR 配置判断当前使用的摄像头位置
  func cameraPosition(from configuration: ARConfiguration?) -> AVCaptureDevice.Position {
      switch configuration {
      case is ARFaceTrackingConfiguration:
          return .front
      default:
          return .back
      }
  }
  
  /// 依据界面方向 + 摄像头 + 是否镜像，得到 EXIF 方向（供 Vision）
  func mappedCGImageOrientation(_ interfaceOrientation: UIInterfaceOrientation,
                                _ cameraPosition: AVCaptureDevice.Position,
                                mirrorFront: Bool) -> CGImagePropertyOrientation {
      switch interfaceOrientation {
      case .portrait:
          if cameraPosition == .front { return mirrorFront ? .leftMirrored : .right }
          return .right
      case .portraitUpsideDown:
          if cameraPosition == .front { return mirrorFront ? .rightMirrored : .left }
          return .left
      case .landscapeLeft:
          if cameraPosition == .front { return mirrorFront ? .downMirrored : .down }
          return .up
      case .landscapeRight:
          if cameraPosition == .front { return mirrorFront ? .upMirrored : .up }
          return .down
      default:
          if cameraPosition == .front { return mirrorFront ? .leftMirrored : .right }
          return .right
      }
  }
  
  /// 依据界面方向 + 摄像头 + 是否镜像，得到 UIImage.Orientation（供预览）
  func mappedUIImageOrientation(_ interfaceOrientation: UIInterfaceOrientation,
                                _ cameraPosition: AVCaptureDevice.Position,
                                mirrorFront: Bool) -> UIImage.Orientation {
      switch interfaceOrientation {
      case .portrait:
          if cameraPosition == .front { return mirrorFront ? .leftMirrored : .right }
          return .right
      case .portraitUpsideDown:
          if cameraPosition == .front { return mirrorFront ? .rightMirrored : .left }
          return .left
      case .landscapeLeft:
          if cameraPosition == .front { return mirrorFront ? .downMirrored : .down }
          return .up
      case .landscapeRight:
          if cameraPosition == .front { return mirrorFront ? .upMirrored : .up }
          return .down
      default:
          if cameraPosition == .front { return mirrorFront ? .leftMirrored : .right }
          return .right
      }
  }
  
  func makeUIImage(from pixelBuffer: CVPixelBuffer,
                   interfaceOrientation: UIInterfaceOrientation,
                   cameraPosition: AVCaptureDevice.Position,
                   mirrorFront: Bool) -> UIImage? {
      let ci = CIImage(cvPixelBuffer: pixelBuffer)
      let ctx = CIContext()
      guard let cg = ctx.createCGImage(ci, from: ci.extent) else { return nil }
  
      let uiOri = mappedUIImageOrientation(interfaceOrientation, cameraPosition, mirrorFront: mirrorFront)
      return UIImage(cgImage: cg, scale: 1, orientation: uiOri)
  }
}

extension ARManager {
  private struct PosePoints {
    var shoulderPoints: (left: CGPoint, right: CGPoint)?
    var leftWristPoint: CGPoint?
    var leftElbowPoint: CGPoint?
    var rightWristPoint: CGPoint?
    var rightElbowPoint: CGPoint?
    var neckPoint: CGPoint?
    var leftAnklePoint: CGPoint?
    var rightAnklePoint: CGPoint?
    var rootPoint: CGPoint?
  }
  
  func detectHumanBody(session: ARSession, anchors: [ARAnchor]) {
    let faces = anchors.compactMap { $0 as? ARFaceAnchor }
    
    if let faceAnchor = faces.first(where: { $0.isTracked }) {
      let position = faceAnchor.transform.columns.3
      Task { @MainActor in
        self.estimatedDistance = CGFloat(abs(position.z))
        print("Distance: \(self.estimatedDistance ?? -1)")
      }
    }
    else {
      Task { @MainActor in
        self.shoulderPoints = nil
        self.estimatedDistance = nil
      }
      
      print("NOBODY detect.")
    }
  }
  
  func createCameraPreview(session: ARSession) {
    guard let frame = session.currentFrame else { return }
    
    // --- Compute interface orientation and active camera position ---
    let io = currentInterfaceOrientation() // Portrait or Landscape
    let camPos = cameraPosition(from: session.configuration) // Front or back
    let pixelBuffer = frame.capturedImage
    
    // --- Preview image with correct orientation/mirroring ---
    if let uiImage = makeUIImage(
      from: pixelBuffer,
      interfaceOrientation: io,
      cameraPosition: camPos,
      mirrorFront: mirrorFrontPreview) {
      Task { @MainActor in
        self.previewImage = uiImage
      }
    }
  }
  
  typealias JointRecords = [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint]
  
  func performVisionRequest(session: ARSession) {
    guard let frame = session.currentFrame else { return }
    
    let io = currentInterfaceOrientation() // Portrait or Landscape
    let camPos = cameraPosition(from: session.configuration) // Front or back
    let pixelBuffer = frame.capturedImage
    
    // --- Vision with matching EXIF orientation (must mirror consistently) ---
    let exif = mappedCGImageOrientation(io, camPos, mirrorFront: mirrorFrontPreview)
    
    Task(priority: .userInitiated) { [weak self] in
      guard let self else { return }
      let frameID = await self.visionCoordinator.reserveFrameIDAndCancelCurrentTask()
      
      let visionTask = Task(priority: .userInitiated) { [weak self] in
        guard let self else { return }
        do {
          let request = VNDetectHumanBodyPoseRequest()
          let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer, orientation: exif, options: [:]
          )
          try handler.perform([request])
          try Task.checkCancellation()
          
          guard let result = request.results?.first else {
            await self.markPoseFrameHandled(frameID)
            return
          }
          
          let recognizedPoints = try result.recognizedPoints(.all)
          let posePoints = self.extractPosePoints(from: recognizedPoints)
          try Task.checkCancellation()
          
          await self.applyPosePoints(posePoints, frameID: frameID)
        } catch is CancellationError {
          // ignore stale canceled task
        } catch {
          print("Vision Error: \(error.localizedDescription).")
        }
      }
      
      await self.visionCoordinator.setCurrentVisionTask(visionTask, for: frameID)
    }
  }
  
  private func point(
    from points: JointRecords,
    joint: VNHumanBodyPoseObservation.JointName
  ) -> CGPoint? {
    guard let p = points[joint], p.confidence >= 0.3 else { return nil }
    return CGPoint(x: p.x, y: 1 - p.y)
  }
  
  private func extractPosePoints(from points: JointRecords) -> PosePoints {
    let leftShoulder = point(from: points, joint: .rightShoulder)
    let rightShoulder = point(from: points, joint: .leftShoulder)
    
    return PosePoints(
      shoulderPoints: {
        guard let leftShoulder, let rightShoulder else { return nil }
        return (left: leftShoulder, right: rightShoulder)
      }(),
      leftWristPoint: point(from: points, joint: .rightWrist),
      leftElbowPoint: point(from: points, joint: .rightElbow),
      rightWristPoint: point(from: points, joint: .leftWrist),
      rightElbowPoint: point(from: points, joint: .leftElbow),
      neckPoint: point(from: points, joint: .neck),
      leftAnklePoint: point(from: points, joint: .rightAnkle),
      rightAnklePoint: point(from: points, joint: .leftAnkle),
      rootPoint: point(from: points, joint: .root)
    )
  }
  
  private func markPoseFrameHandled(_ frameID: UInt64) async {
    await visionCoordinator.markHandled(frameID: frameID)
  }
  
  @MainActor
  private func applyPosePoints(_ posePoints: PosePoints, frameID: UInt64) async {
    guard await visionCoordinator.shouldApply(frameID: frameID) else { return }
    
    shoulderPoints = posePoints.shoulderPoints
    leftWristPoint = posePoints.leftWristPoint
    leftElbowPoint = posePoints.leftElbowPoint
    rightWristPoint = posePoints.rightWristPoint
    rightElbowPoint = posePoints.rightElbowPoint
    neckPoint = posePoints.neckPoint
    leftAnklePoint = posePoints.leftAnklePoint
    rightAnklePoint = posePoints.rightAnklePoint
    rootPoint = posePoints.rootPoint
    
    calcScore()
    
    if let distance = estimatedDistance {
      onBodyPositionUpdate(distance)
    }
  }
}

extension ARManager {
  func calcScore() {
    let score = ArcheryScorer.score(
      for: makeArcheryPose(),
      weights: makeScoreWeights()
    )

    laScore = CGFloat(score.leftArm ?? 0)
    raScore = CGFloat(score.rightArm ?? 0)
    bScore = CGFloat(score.body ?? 0)
    legScore = CGFloat(score.legs ?? 0)
    totalScore = CGFloat(score.total)
    horizontalLegDistance = score.horizontalLegDistance.map { CGFloat($0) }
    leftArmAngle = score.leftArmDetails.map { CGFloat($0.elbowAngle) }
    leftArmAngleScore = score.leftArmDetails.map { CGFloat($0.elbowAngleScore) }
    leftArmAngleAcceptable = score.leftArmDetails?.isElbowAngleAcceptable
    leftArmHeightDiff = score.leftArmDetails.map { CGFloat($0.shoulderWristHeightDiff) }
    leftArmHeightScore = score.leftArmDetails.map { CGFloat($0.shoulderWristHeightScore) }
    leftArmGroundAngle = score.leftArmDetails.map { CGFloat($0.armGroundAngle) }
    leftArmIsParallelToGround = score.leftArmDetails?.isParallelToGround
    rightArmAngle = score.rightArmDetails.map { CGFloat($0.elbowAngle) }
    rightArmAngleScore = score.rightArmDetails.map { CGFloat($0.elbowAngleScore) }
    rightArmAngleAcceptable = score.rightArmDetails?.isElbowAngleAcceptable
    rightArmForearmHeightDiff = score.rightArmDetails.map { CGFloat($0.forearmHeightDiff) }
    rightArmForearmHeightScore = score.rightArmDetails.map { CGFloat($0.forearmHeightScore) }
    rightArmForearmHeightAcceptable = score.rightArmDetails?.isForearmHeightAcceptable
    legsHorizontalDistance = score.legsDetails.map { CGFloat($0.horizontalDistance) }
    legsHorizontalScore = score.legsDetails.map { CGFloat($0.horizontalScore) }
    legsHorizontalAcceptable = score.legsDetails?.isHorizontalAcceptable
    legsVerticalDistance = score.legsDetails.map { CGFloat($0.verticalDistance) }
    legsVerticalScore = score.legsDetails.map { CGFloat($0.verticalScore) }
    legsVerticalAcceptable = score.legsDetails?.isVerticalAcceptable
  }

  private func makeArcheryPose() -> ArcheryPose {
    ArcheryPose(
      shoulders: shoulderPoints.flatMap { points in
        guard
          let left = makeArcheryPoint(from: points.left),
          let right = makeArcheryPoint(from: points.right)
        else {
          return nil
        }

        return ShoulderPair(left: left, right: right)
      },
      leftWrist: makeArcheryPoint(from: leftWristPoint),
      leftElbow: makeArcheryPoint(from: leftElbowPoint),
      rightWrist: makeArcheryPoint(from: rightWristPoint),
      rightElbow: makeArcheryPoint(from: rightElbowPoint),
      neck: makeArcheryPoint(from: neckPoint),
      leftAnkle: makeArcheryPoint(from: leftAnklePoint),
      rightAnkle: makeArcheryPoint(from: rightAnklePoint),
      root: makeArcheryPoint(from: rootPoint)
    )
  }

  private func makeArcheryPoint(from point: CGPoint?) -> ArcheryPoint? {
    guard let point else { return nil }
    return ArcheryPoint(x: Double(point.x), y: Double(point.y))
  }

  private func makeScoreWeights() -> ArcheryScoreWeights {
    ArcheryScoreWeights(
      leftArm: armsWeight / 2,
      rightArm: armsWeight / 2,
      body: bodyWeight,
      legs: legsWeight
    )
  }

  func resetScoreWeights() {
    armsWeight = ArcheryScoreWeights.default.leftArm + ArcheryScoreWeights.default.rightArm
    bodyWeight = ArcheryScoreWeights.default.body
    legsWeight = ArcheryScoreWeights.default.legs
  }
}
