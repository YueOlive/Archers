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
  
  var horizontalLegDistanceIdeal: CGFloat = 0
  
  var estimatedDistance: CGFloat? = nil
  var mirrorFrontPreview: Bool = false
  @ObservationIgnored  private let visionQueue = DispatchQueue(label: "vision.pose.queue")
  
  var onBodyPositionUpdate: (CGFloat) -> Void = { _ in }

  override init() {
    super.init()
    session.delegate = self
  }
  
  deinit {
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
      self.previewImage = uiImage
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
    let request = VNDetectHumanBodyPoseRequest()
    let handler = VNImageRequestHandler(
      cvPixelBuffer: pixelBuffer, orientation: exif, options: [:]
    )
    
    visionQueue.async {
      do{
        try handler.perform([request])
        guard let result = request.results?.first else { return }
        
        let recognizedPoints = try result.recognizedPoints(.all)
        
        self.extractShoulderPositions(from: recognizedPoints)
        self.extractLeftArmPositions(from: recognizedPoints)
        self.extractRightArmPositions(from: recognizedPoints)
        self.extractNeckPositions(from: recognizedPoints)
        self.extractLeftLegPositions(from: recognizedPoints)
        self.extractRightLegPositions(from: recognizedPoints)
        self.extractRootPositions(from: recognizedPoints)
        self.calcScore()
      }catch{
        print("Vision Error: \(error.localizedDescription).")
      }
    }
  }
  
  func extractShoulderPositions(from points: JointRecords) {
    guard let l = points[.leftShoulder],
          let r = points[.rightShoulder],
          l.confidence >= 0.3,
          r.confidence >= 0.3 else { return }
    
    Task { @MainActor in
      let leftPoint = CGPoint(x: r.x, y: 1 - r.y)
      let rightPoint = CGPoint(x: l.x, y: 1 - l.y)
      
      self.shoulderPoints = (leftPoint, rightPoint)
    }
  }
  
  func extractLeftArmPositions(from points: JointRecords) {
    guard let leftWrist = points[.rightWrist],
          let leftElbow = points[.rightElbow],
          leftWrist.confidence >= 0.3,
          leftElbow.confidence >= 0.3 else { return }
    
    Task { @MainActor in
      let leftWrist = CGPoint(x: leftWrist.x, y: 1 - leftWrist.y)
      let leftElbow = CGPoint(x: leftElbow.x, y: 1 - leftElbow.y)
      
      self.leftWristPoint = leftWrist
      self.leftElbowPoint = leftElbow
    }
  }
  
  func extractRightArmPositions(from points: JointRecords) {
    guard let rightWrist = points[.leftWrist],
          let rightElbow = points[.leftElbow],
          rightWrist.confidence >= 0.3,
          rightElbow.confidence >= 0.3 else { return }
    
    Task { @MainActor in
      let rightWrist = CGPoint(x: rightWrist.x, y: 1 - rightWrist.y)
      let rightElbow = CGPoint(x: rightElbow.x, y: 1 - rightElbow.y)
      
      self.rightWristPoint = rightWrist
      self.rightElbowPoint = rightElbow
    }
  }
  
  func extractNeckPositions(from points: JointRecords) {
    guard let neck = points[.neck],
          neck.confidence >= 0.3 else { return }
    
    Task { @MainActor in
      let neck = CGPoint(x: neck.x, y: 1 - neck.y)
      
      self.neckPoint = neck
    }
  }
  
  func extractLeftLegPositions(from points: JointRecords) {
    guard let leftAnkle = points[.rightAnkle],
          leftAnkle.confidence >= 0.3 else { return }
    
    Task { @MainActor in
      let leftAnkle = CGPoint(x: leftAnkle.x, y: 1 - leftAnkle.y)
      
      self.leftAnklePoint = leftAnkle
    }
  }
  
  func extractRightLegPositions(from points: JointRecords) {
    guard let rightAnkle = points[.leftAnkle],
          rightAnkle.confidence >= 0.3 else { return }
    
    Task { @MainActor in
      let rightAnkle = CGPoint(x: rightAnkle.x, y: 1 - rightAnkle.y)
      
      self.rightAnklePoint = rightAnkle
    }
  }
  
  func extractRootPositions(from points: JointRecords) {
    guard let root = points[.root],
          root.confidence >= 0.3 else { return }
    
    Task { @MainActor in
      let root = CGPoint(x: root.x, y: 1 - root.y)
      
      self.rootPoint = root
    }
  }
}

extension ARManager {
  func calcScore() {
    var weight: CGFloat = 0
    
    // evaluate LM
    if let leftArmScore = evaluateLeftArm(){
      laScore = leftArmScore
      totalScore += (leftArmScore * 0.4)
      weight += 0.4
    }
    // evaluate RM
    if let rightArmScore = elvaluateRightArm(){
      raScore = rightArmScore
      totalScore += (rightArmScore * 0.4)
      weight += 0.4
    }
    // evaluate B
    if let bodyScore = evaluateBody(){
      bScore = bodyScore
      totalScore += (bodyScore * 0.11)
      weight += 0.11
    }
    
    // evaluate leg
    if let legScore = evaluateLegs() {
      self.legScore = legScore
      self.totalScore += (legScore * 0.09)
      weight += 0.09
    }
    
    if weight > 0 {
      totalScore /= weight
    }
  }
  
  
  
  func evaluateBody() -> CGFloat?{
    guard let rp = rootPoint,
          let np = neckPoint else {
      return nil
    }
    
    let body = abs (np.x - rp.x)
    let bodyScore = scoreFor(value: body, ideal: 0, tolerance: 5)
    
    return bodyScore
  }
  
  func elvaluateRightArm() -> CGFloat?{
    guard let rs = shoulderPoints?.right,
          let re = rightElbowPoint,
          let rw = rightWristPoint else {
      return nil
    }
    
    guard let elbowAngle = angle(a: rs, b: re, c: rw) else{
      return nil
    }
    let elbowAngleScore = scoreFor(value: elbowAngle, ideal: 30, tolerance: 5)
    
    let forearmHeightDiff = abs(re.y - rw.y)
    let forearmHeightScore = scoreFor(value: forearmHeightDiff, ideal: 20, tolerance: 3)
    
    return elbowAngleScore * 0.2 + forearmHeightScore * 0.8
  }
  
  func evaluateLeftArm() -> CGFloat?{
    guard let ls = shoulderPoints?.left,
          let le = leftElbowPoint,
          let lw = leftWristPoint else {
      return nil
    }
    
    guard let elbowAngle = angle(a: ls, b: le, c: lw) else{
      return nil
    }
    
    let elbowScore = scoreFor(value: elbowAngle, ideal: 180.0, tolerance: 5)
    
    let heightDiff = abs(lw.y - ls.y)
    let heightScore = scoreFor (value: heightDiff, ideal: 0, tolerance: 0.15)
    
    return elbowScore * 0.8 + heightScore * 0.2

  }
  
  func evaluateLegs() -> CGFloat?{
    guard let lp = leftAnklePoint,
          let rp = rightAnklePoint else {
      return 0.0
    }
    // h. distance
    let horizontalDistance = abs(lp.x - rp.x)
    horizontalLegDistanceIdeal = horizontalDistance
    
    let horizontalScore = scoreFor(
      value: horizontalDistance,
      ideal: 0.16,
      tolerance: 0.06)
    
    // v. distance
    let verticalDistance = abs(lp.y - rp.y)
    let verticalScore = scoreFor(
      value: verticalDistance,
      ideal: 0,
      tolerance: 0.1)
    
    //calc score
    return horizontalScore * 0.8 + verticalScore * 0.2
  }
}

extension ARManager{
  func distance(_ a:CGPoint,_ b:CGPoint) -> CGFloat{
    let sum = (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)
    
    return sqrt(sum)
  }
  
  func scoreFor(value: CGFloat, ideal: CGFloat, tolerance: CGFloat) -> CGFloat{
    let diff = abs(value - ideal)
    
    if diff >= tolerance {return 0}
    
    let ratio = 1 - diff/tolerance
    return ratio * 100.0
  }
  
  func scoreForDistance(
    _ a:CGPoint,_ b:CGPoint,
    idealDistance: CGFloat,
    tolerance: CGFloat
  ) -> CGFloat {
    let d = distance(a, b)
    return scoreFor(value: d, ideal: idealDistance, tolerance: tolerance)
  }
  
  /// 计算以 b 为顶点的夹角 ∠ABC，单位：度
  /// A - B - C
  private func angle(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat? {
    let v1 = CGPoint(x: a.x - b.x, y: a.y - b.y)
    let v2 = CGPoint(x: c.x - b.x, y: c.y - b.y)
    
    let len1 = sqrt(v1.x * v1.x + v1.y * v1.y)
    let len2 = sqrt(v2.x * v2.x + v2.y * v2.y)
    
    guard len1 > 0.0001, len2 > 0.0001 else { return nil }
    
    let dot = v1.x * v2.x + v1.y * v2.y
    let cosValue = max(-1, min(1, dot / (len1 * len2)))
    let rad = acos(cosValue)
    let deg = rad * 180 / .pi
    return deg
  }
}
