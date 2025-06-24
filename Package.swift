// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeCodeUsageMonitor",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClaudeCodeUsageMonitor",
            targets: ["ClaudeCodeUsageMonitor"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ClaudeCodeUsageMonitor",
            path: "Sources/ClaudeUsageMonitor",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ClaudeCodeUsageMonitorTests",
            dependencies: ["ClaudeCodeUsageMonitor"],
            path: "Tests/ClaudeUsageMonitorTests"
        )
    ]
)