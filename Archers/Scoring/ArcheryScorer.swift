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
  static func score(
    for pose: ArcheryPose,
    weights: ArcheryScoreWeights = .default
  ) -> ArcheryScoreBreakdown {
    let leftArm = evaluateLeftArm(in: pose)
    let rightArm = evaluateRightArm(in: pose)
    let body = evaluateBody(in: pose)
    let legs = evaluateLegs(in: pose)

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
      horizontalLegDistance: horizontalLegDistance(in: pose)
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
    guard
      let shoulder = pose.shoulders?.right,
      let elbow = pose.rightElbow,
      let wrist = pose.rightWrist,
      let elbowAngle = angle(a: shoulder, b: elbow, c: wrist)
    else {
      return nil
    }

    let elbowAngleScore = score(for: elbowAngle, ideal: 30, tolerance: 5)
    let forearmHeightDiff = abs(elbow.y - wrist.y)
    let forearmHeightScore = score(for: forearmHeightDiff, ideal: 20, tolerance: 3)

    return elbowAngleScore * 0.2 + forearmHeightScore * 0.8
  }

  static func evaluateLeftArm(in pose: ArcheryPose) -> Double? {
    guard
      let shoulder = pose.shoulders?.left,
      let elbow = pose.leftElbow,
      let wrist = pose.leftWrist,
      let elbowAngle = angle(a: shoulder, b: elbow, c: wrist)
    else {
      return nil
    }

    let elbowScore = score(for: elbowAngle, ideal: 180, tolerance: 5)
    let heightDiff = abs(wrist.y - shoulder.y)
    let heightScore = score(for: heightDiff, ideal: 0, tolerance: 0.15)

    return elbowScore * 0.8 + heightScore * 0.2
  }

  static func evaluateLegs(in pose: ArcheryPose) -> Double? {
    guard let leftAnkle = pose.leftAnkle, let rightAnkle = pose.rightAnkle else {
      return nil
    }

    let horizontalDistance = abs(leftAnkle.x - rightAnkle.x)
    let horizontalScore = score(for: horizontalDistance, ideal: 0.16, tolerance: 0.06)

    let verticalDistance = abs(leftAnkle.y - rightAnkle.y)
    let verticalScore = score(for: verticalDistance, ideal: 0, tolerance: 0.1)

    return horizontalScore * 0.8 + verticalScore * 0.2
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
}
