// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "ArchersScoring",
  platforms: [
    .iOS(.v18),
    .macOS(.v15)
  ],
  products: [
    .library(
      name: "ArchersScoring",
      targets: ["ArchersScoring"]
    )
  ],
  targets: [
    .target(
      name: "ArchersScoring",
      path: "Archers/Scoring"
    ),
    .testTarget(
      name: "ArchersScoringTests",
      dependencies: ["ArchersScoring"],
      path: "ArchersScoringTests"
    )
  ]
)
