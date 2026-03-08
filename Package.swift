// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SmoothScroll",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", branch: "release/6.2"),
    ],
    targets: [
        .executableTarget(
            name: "SmoothScroll",
            path: "Sources/SmoothScroll",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("IOKit"),
                .linkedFramework("SwiftUI"),
            ]
        ),
        .testTarget(
            name: "SmoothScrollTests",
            dependencies: [
                "SmoothScroll",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/SmoothScrollTests"
        ),
    ]
)
