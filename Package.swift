// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SmoothScroll",
    platforms: [
        .macOS(.v13)
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
    ]
)
