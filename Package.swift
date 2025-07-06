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
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.5.2")
    ],
    targets: [
        .executableTarget(
            name: "ClaudeCodeMonitor",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle", condition: .when(platforms: [.macOS]))
            ],
            path: "Sources/ClaudeUsageMonitor",
            resources: [
                .process("Resources/en.lproj"),
                .process("Resources/ja.lproj"),
                .process("Resources/Assets.xcassets"),
                .copy("AppIcon.icns")
            ],
            swiftSettings: [
                .define("TEST", .when(configuration: .test))
            ]
        ),
        .testTarget(
            name: "ClaudeCodeMonitorTests",
            dependencies: ["ClaudeCodeMonitor"],
            path: "Tests/ClaudeUsageMonitorTests",
            exclude: ["README.md"]
        )
    ]
)