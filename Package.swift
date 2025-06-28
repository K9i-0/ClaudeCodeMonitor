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
        ),
        .executable(
            name: "ClaudeMonitorHelper",
            targets: ["ClaudeMonitorHelper"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
    ],
    targets: [
        .executableTarget(
            name: "ClaudeCodeMonitor",
            path: "Sources/ClaudeUsageMonitor",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "ClaudeMonitorHelper",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ],
            path: "Sources/ClaudeMonitorHelper"
        ),
        .testTarget(
            name: "ClaudeCodeMonitorTests",
            dependencies: ["ClaudeCodeMonitor"],
            path: "Tests/ClaudeUsageMonitorTests"
        )
    ]
)