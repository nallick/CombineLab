// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "CombineLab",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "CombineLab",
            targets: ["CombineLab"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CombineLab",
            dependencies: []),
        .testTarget(
            name: "CombineLabTests",
            dependencies: ["CombineLab"]),
    ]
)
