// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeCodeMonitor",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClaudeCodeMonitor",
            targets: ["ClaudeCodeMonitor"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ClaudeCodeMonitor",
            path: "Sources/ClaudeUsageMonitor",
            resources: [
                .process("Resources/en.lproj"),
                .process("Resources/ja.lproj"),
                .process("Resources/Assets.xcassets"),
                .copy("AppIcon.icns")
            ]
        ),
        .testTarget(
            name: "ClaudeCodeMonitorTests",
            dependencies: ["ClaudeCodeMonitor"],
            path: "Tests/ClaudeUsageMonitorTests"
        )
    ]
)