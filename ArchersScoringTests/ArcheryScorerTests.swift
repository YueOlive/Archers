import Testing
@testable import ArchersScoring

struct ArcheryScorerTests {
  @Test func fullPoseProducesWeightedTotal() {
    let pose = ArcheryPose(
      shoulders: ShoulderPair(
        left: ArcheryPoint(x: 0, y: 0),
        right: ArcheryPoint(x: 5, y: 11.339_745_962)
      ),
      leftWrist: ArcheryPoint(x: 2, y: 0),
      leftElbow: ArcheryPoint(x: 1, y: 0),
      rightWrist: ArcheryPoint(x: 0, y: 0),
      rightElbow: ArcheryPoint(x: 0, y: 20),
      neck: ArcheryPoint(x: 1, y: 0),
      leftAnkle: ArcheryPoint(x: 0, y: 0),
      rightAnkle: ArcheryPoint(x: 0.16, y: 0),
      root: ArcheryPoint(x: 1, y: 10)
    )

    let score = ArcheryScorer.score(for: pose)

    #expect(abs((score.leftArm ?? 0) - 100) < 0.000_001)
    #expect(abs((score.rightArm ?? 0) - 100) < 0.000_001)
    #expect(abs((score.body ?? 0) - 100) < 0.000_001)
    #expect(abs((score.legs ?? 0) - 100) < 0.000_001)
    #expect(abs(score.total - 100) < 0.000_001)
    #expect(abs((score.horizontalLegDistance ?? 0) - 0.16) < 0.000_001)
    #expect(abs((score.leftArmDetails?.elbowAngle ?? 0) - 180) < 0.000_001)
    #expect(score.leftArmDetails?.isParallelToGround == true)
  }

  @Test func missingLegJointExcludesLegWeight() {
    let pose = ArcheryPose(
      shoulders: ShoulderPair(
        left: ArcheryPoint(x: 0, y: 0),
        right: ArcheryPoint(x: 5, y: 11.339_745_962)
      ),
      leftWrist: ArcheryPoint(x: 2, y: 0),
      leftElbow: ArcheryPoint(x: 1, y: 0),
      rightWrist: ArcheryPoint(x: 0, y: 0),
      rightElbow: ArcheryPoint(x: 0, y: 20),
      neck: ArcheryPoint(x: 1, y: 0),
      leftAnkle: ArcheryPoint(x: 0, y: 0),
      rightAnkle: nil,
      root: ArcheryPoint(x: 1, y: 10)
    )

    let score = ArcheryScorer.score(for: pose)

    #expect(score.legs == nil)
    #expect(score.horizontalLegDistance == nil)
    #expect(abs(score.total - 100) < 0.000_001)
  }

  @Test func noScoreComponentsProducesZeroTotal() {
    let pose = ArcheryPose()

    let score = ArcheryScorer.score(for: pose)

    #expect(score.leftArm == nil)
    #expect(score.rightArm == nil)
    #expect(score.body == nil)
    #expect(score.legs == nil)
    #expect(score.total == 0)
    #expect(score.leftArmDetails == nil)
  }

  @Test func partialPoseUsesOnlyAvailableWeights() {
    let pose = ArcheryPose(
      shoulders: ShoulderPair(
        left: ArcheryPoint(x: 0, y: 0),
        right: ArcheryPoint(x: 0, y: 0)
      ),
      leftWrist: ArcheryPoint(x: 2, y: 0),
      leftElbow: ArcheryPoint(x: 1, y: 0),
      rightWrist: nil,
      rightElbow: nil,
      neck: ArcheryPoint(x: 0.2, y: 0),
      leftAnkle: nil,
      rightAnkle: nil,
      root: ArcheryPoint(x: 0, y: 0)
    )

    let score = ArcheryScorer.score(for: pose)

    #expect(abs((score.leftArm ?? 0) - 100) < 0.000_001)
    #expect(score.rightArm == nil)
    #expect(score.body == 96)
    #expect(score.legs == nil)
    #expect(abs(score.total - 99.137_254_901_960_79) < 0.000_001)
  }

  @Test func customWeightsBiasTotalTowardBodyAndLegs() {
    let pose = ArcheryPose(
      shoulders: ShoulderPair(
        left: ArcheryPoint(x: 0, y: 0),
        right: ArcheryPoint(x: 0, y: 0)
      ),
      leftWrist: ArcheryPoint(x: 1.8, y: 0),
      leftElbow: ArcheryPoint(x: 1, y: 0),
      rightWrist: ArcheryPoint(x: 0, y: 0),
      rightElbow: ArcheryPoint(x: 0, y: 20),
      neck: ArcheryPoint(x: 0, y: 0),
      leftAnkle: ArcheryPoint(x: 0, y: 0),
      rightAnkle: ArcheryPoint(x: 0.16, y: 0),
      root: ArcheryPoint(x: 0, y: 0)
    )

    let defaultScore = ArcheryScorer.score(for: pose)
    let bodyLegBiased = ArcheryScorer.score(
      for: pose,
      weights: ArcheryScoreWeights(
        leftArm: 0.1,
        rightArm: 0.1,
        body: 0.4,
        legs: 0.4
      )
    )

    #expect(defaultScore.total < bodyLegBiased.total)
  }
}
