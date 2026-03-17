// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "GoProStitcherKit",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "GoProStitcherKit",
            targets: ["GoProStitcherKit"]
        ),
    ],
    targets: [
        .target(
            name: "GoProStitcherKit"
        ),
        .testTarget(
            name: "GoProStitcherKitTests",
            dependencies: ["GoProStitcherKit"],
            resources: [
                .copy("Resources")
            ]
        ),
    ]
)
