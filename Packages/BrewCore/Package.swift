// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BrewCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BrewCore", targets: ["BrewCore"]),
    ],
    targets: [
        .target(
            name: "BrewCore",
            resources: [.copy("Resources/Content")]
        ),
        .testTarget(
            name: "BrewCoreTests",
            dependencies: ["BrewCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
