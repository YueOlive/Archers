import Foundation

struct ArcheryPoint: Sendable, Equatable {
  let x: Double
  let y: Double
}

struct ShoulderPair: Sendable, Equatable {
  let left: ArcheryPoint
  let right: ArcheryPoint
}

struct ArcheryPose: Sendable, Equatable {
  var shoulders: ShoulderPair?
  var leftWrist: ArcheryPoint?
  var leftElbow: ArcheryPoint?
  var rightWrist: ArcheryPoint?
  var rightElbow: ArcheryPoint?
  var neck: ArcheryPoint?
  var leftAnkle: ArcheryPoint?
  var rightAnkle: ArcheryPoint?
  var root: ArcheryPoint?
}

struct ArcheryScoreBreakdown: Sendable, Equatable {
  var leftArm: Double?
  var rightArm: Double?
  var body: Double?
  var legs: Double?
  var total: Double
  var horizontalLegDistance: Double?
  var leftArmDetails: LeftArmScoreDetails?
  var rightArmDetails: RightArmScoreDetails?
  var legsDetails: LegsScoreDetails?
}

struct LegsScoreDetails: Sendable, Equatable {
  var horizontalDistance: Double
  var horizontalScore: Double
  var isHorizontalAcceptable: Bool
  var verticalDistance: Double
  var verticalScore: Double
  var isVerticalAcceptable: Bool
}

struct LeftArmScoreDetails: Sendable, Equatable {
  var elbowAngle: Double
  var elbowAngleScore: Double
  var isElbowAngleAcceptable: Bool
  var shoulderWristHeightDiff: Double
  var shoulderWristHeightScore: Double
  var armGroundAngle: Double
  var isParallelToGround: Bool
}

struct RightArmScoreDetails: Sendable, Equatable {
  var elbowAngle: Double
  var elbowAngleScore: Double
  var isElbowAngleAcceptable: Bool
  var forearmHeightDiff: Double
  var forearmHeightScore: Double
  var isForearmHeightAcceptable: Bool
}

struct ArcheryScoreWeights: Sendable, Equatable {
  var leftArm: Double
  var rightArm: Double
  var body: Double
  var legs: Double

  static let `default` = ArcheryScoreWeights(
    leftArm: 0.4,
    rightArm: 0.4,
    body: 0.11,
    legs: 0.09
  )
}

enum ArcheryScorer {
  private static let leftArmElbowAcceptableRange = 168.0 ... 175.0
  private static let leftArmElbowFalloff = 10.0
  private static let rightArmElbowAcceptableRange = 15.0 ... 22.0
  private static let rightArmElbowFalloff = 10.0
  private static let rightArmForearmHeightAcceptableRange = 0.02 ... 0.04
  private static let rightArmForearmHeightFalloff = 0.03
  private static let legsHorizontalAcceptableRange = 0.16 ... 0.20
  private static let legsHorizontalFalloff = 0.05
  private static let legsVerticalAcceptableRange = 0.0 ... 0.01
  private static let legsVerticalFalloff = 0.09

  static func score(
    for pose: ArcheryPose,
    weights: ArcheryScoreWeights = .default
  ) -> ArcheryScoreBreakdown {
    let leftArmDetails = evaluateLeftArmDetails(in: pose)
    let leftArm = leftArmDetails.map { $0.elbowAngleScore * 0.8 + $0.shoulderWristHeightScore * 0.2 }
    let rightArmDetails = evaluateRightArmDetails(in: pose)
    let rightArm = rightArmDetails.map { $0.elbowAngleScore * 0.2 + $0.forearmHeightScore * 0.8 }
    let body = evaluateBody(in: pose)
    let legsDetails = evaluateLegsDetails(in: pose)
    let legs = legsDetails.map { $0.horizontalScore * 0.8 + $0.verticalScore * 0.2 }

    var total = 0.0
    var weight = 0.0

    if let leftArm {
      total += leftArm * max(0, weights.leftArm)
      weight += max(0, weights.leftArm)
    }

    if let rightArm {
      total += rightArm * max(0, weights.rightArm)
      weight += max(0, weights.rightArm)
    }

    if let body {
      total += body * max(0, weights.body)
      weight += max(0, weights.body)
    }

    if let legs {
      total += legs * max(0, weights.legs)
      weight += max(0, weights.legs)
    }

    return ArcheryScoreBreakdown(
      leftArm: leftArm,
      rightArm: rightArm,
      body: body,
      legs: legs,
      total: weight > 0 ? total / weight : 0,
      horizontalLegDistance: horizontalLegDistance(in: pose),
      leftArmDetails: leftArmDetails,
      rightArmDetails: rightArmDetails,
      legsDetails: legsDetails
    )
  }

  static func evaluateBody(in pose: ArcheryPose) -> Double? {
    guard let root = pose.root, let neck = pose.neck else {
      return nil
    }

    let body = abs(neck.x - root.x)
    return score(for: body, ideal: 0, tolerance: 5)
  }

  static func evaluateRightArm(in pose: ArcheryPose) -> Double? {
    evaluateRightArmDetails(in: pose).map { $0.elbowAngleScore * 0.2 + $0.forearmHeightScore * 0.8 }
  }

  static func evaluateRightArmDetails(in pose: ArcheryPose) -> RightArmScoreDetails? {
    guard
      let shoulder = pose.shoulders?.right,
      let elbow = pose.rightElbow,
      let wrist = pose.rightWrist,
      let elbowAngle = angle(a: shoulder, b: elbow, c: wrist)
    else {
      return nil
    }

    let elbowAngleScore = score(
      for: elbowAngle,
      acceptableRange: rightArmElbowAcceptableRange,
      toleranceOutsideRange: rightArmElbowFalloff
    )
    let forearmHeightDiff = abs(elbow.y - wrist.y)
    let forearmHeightScore = score(
      for: forearmHeightDiff,
      acceptableRange: rightArmForearmHeightAcceptableRange,
      toleranceOutsideRange: rightArmForearmHeightFalloff
    )

    return RightArmScoreDetails(
      elbowAngle: elbowAngle,
      elbowAngleScore: elbowAngleScore,
      isElbowAngleAcceptable: rightArmElbowAcceptableRange.contains(elbowAngle),
      forearmHeightDiff: forearmHeightDiff,
      forearmHeightScore: forearmHeightScore,
      isForearmHeightAcceptable: rightArmForearmHeightAcceptableRange.contains(forearmHeightDiff)
    )
  }

  static func evaluateLeftArm(in pose: ArcheryPose) -> Double? {
    evaluateLeftArmDetails(in: pose).map { $0.elbowAngleScore * 0.8 + $0.shoulderWristHeightScore * 0.2 }
  }

  static func evaluateLeftArmDetails(in pose: ArcheryPose) -> LeftArmScoreDetails? {
    guard
      let shoulder = pose.shoulders?.left,
      let elbow = pose.leftElbow,
      let wrist = pose.leftWrist,
      let elbowAngle = angle(a: shoulder, b: elbow, c: wrist)
    else {
      return nil
    }

    let elbowScore = score(
      for: elbowAngle,
      acceptableRange: leftArmElbowAcceptableRange,
      toleranceOutsideRange: leftArmElbowFalloff
    )
    let shoulderWristHeightDiff = abs(wrist.y - shoulder.y)
    let shoulderWristHeightScore = score(for: shoulderWristHeightDiff, ideal: 0, tolerance: 0.15)
    let armGroundAngle = armAngleFromHorizontal(a: shoulder, b: wrist)

    return LeftArmScoreDetails(
      elbowAngle: elbowAngle,
      elbowAngleScore: elbowScore,
      isElbowAngleAcceptable: leftArmElbowAcceptableRange.contains(elbowAngle),
      shoulderWristHeightDiff: shoulderWristHeightDiff,
      shoulderWristHeightScore: shoulderWristHeightScore,
      armGroundAngle: armGroundAngle,
      isParallelToGround: armGroundAngle <= 10
    )
  }

  static func evaluateLegs(in pose: ArcheryPose) -> Double? {
    evaluateLegsDetails(in: pose).map { $0.horizontalScore * 0.8 + $0.verticalScore * 0.2 }
  }

  static func evaluateLegsDetails(in pose: ArcheryPose) -> LegsScoreDetails? {
    guard let leftAnkle = pose.leftAnkle, let rightAnkle = pose.rightAnkle else {
      return nil
    }

    let horizontalDistance = abs(leftAnkle.x - rightAnkle.x)
    let horizontalScore = score(
      for: horizontalDistance,
      acceptableRange: legsHorizontalAcceptableRange,
      toleranceOutsideRange: legsHorizontalFalloff
    )

    let verticalDistance = abs(leftAnkle.y - rightAnkle.y)
    let verticalScore = score(
      for: verticalDistance,
      acceptableRange: legsVerticalAcceptableRange,
      toleranceOutsideRange: legsVerticalFalloff
    )

    return LegsScoreDetails(
      horizontalDistance: horizontalDistance,
      horizontalScore: horizontalScore,
      isHorizontalAcceptable: legsHorizontalAcceptableRange.contains(horizontalDistance),
      verticalDistance: verticalDistance,
      verticalScore: verticalScore,
      isVerticalAcceptable: legsVerticalAcceptableRange.contains(verticalDistance)
    )
  }

  static func horizontalLegDistance(in pose: ArcheryPose) -> Double? {
    guard let leftAnkle = pose.leftAnkle, let rightAnkle = pose.rightAnkle else {
      return nil
    }

    return abs(leftAnkle.x - rightAnkle.x)
  }

  static func distance(_ a: ArcheryPoint, _ b: ArcheryPoint) -> Double {
    let sum = (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)
    return sqrt(sum)
  }

  static func score(for value: Double, ideal: Double, tolerance: Double) -> Double {
    let diff = abs(value - ideal)

    guard tolerance > 0 else {
      return diff == 0 ? 100 : 0
    }

    if diff >= tolerance {
      return 0
    }

    let ratio = 1 - diff / tolerance
    return ratio * 100
  }

  static func score(
    for value: Double,
    acceptableRange: ClosedRange<Double>,
    toleranceOutsideRange: Double
  ) -> Double {
    if acceptableRange.contains(value) {
      return 100
    }

    guard toleranceOutsideRange > 0 else {
      return 0
    }

    let distanceToRange = min(
      abs(value - acceptableRange.lowerBound),
      abs(value - acceptableRange.upperBound)
    )

    if distanceToRange >= toleranceOutsideRange {
      return 0
    }

    let ratio = 1 - distanceToRange / toleranceOutsideRange
    return ratio * 100
  }

  static func scoreForDistance(
    _ a: ArcheryPoint,
    _ b: ArcheryPoint,
    idealDistance: Double,
    tolerance: Double
  ) -> Double {
    let measuredDistance = distance(a, b)
    return score(for: measuredDistance, ideal: idealDistance, tolerance: tolerance)
  }

  static func angle(a: ArcheryPoint, b: ArcheryPoint, c: ArcheryPoint) -> Double? {
    let v1 = ArcheryPoint(x: a.x - b.x, y: a.y - b.y)
    let v2 = ArcheryPoint(x: c.x - b.x, y: c.y - b.y)

    let len1 = sqrt(v1.x * v1.x + v1.y * v1.y)
    let len2 = sqrt(v2.x * v2.x + v2.y * v2.y)

    guard len1 > 0.0001, len2 > 0.0001 else { return nil }

    let dot = v1.x * v2.x + v1.y * v2.y
    let cosValue = max(-1, min(1, dot / (len1 * len2)))
    let radians = acos(cosValue)
    return radians * 180 / .pi
  }

  static func armAngleFromHorizontal(a: ArcheryPoint, b: ArcheryPoint) -> Double {
    let dx = abs(b.x - a.x)
    let dy = abs(b.y - a.y)
    guard dx > 0.0001 || dy > 0.0001 else { return 90 }
    return atan2(dy, dx) * 180 / .pi
  }
}
