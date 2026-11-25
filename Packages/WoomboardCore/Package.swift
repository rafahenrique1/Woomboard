// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WoomboardCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "WoomboardCore",
            targets: ["WoomboardCore"]
        )
    ],
    targets: [
        .target(
            name: "WoomboardCore"
        ),
        .testTarget(
            name: "WoomboardCoreTests",
            dependencies: ["WoomboardCore"]
        )
    ]
)
