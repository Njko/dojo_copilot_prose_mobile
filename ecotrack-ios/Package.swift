// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EcoTrack",
    platforms: [.iOS(.v17), .macOS(.v14)],
    targets: [
        .target(
            name: "EcoTrack",
            path: "Sources/EcoTrack",
            exclude: [
                "Presentation"
            ]
        ),
        .testTarget(
            name: "EcoTrackTests",
            dependencies: ["EcoTrack"],
            path: "Tests/EcoTrackTests"
        )
    ]
)
