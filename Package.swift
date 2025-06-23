// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeUsageMonitor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClaudeUsageMonitor",
            targets: ["ClaudeUsageMonitor"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ClaudeUsageMonitor"
        )
    ]
)