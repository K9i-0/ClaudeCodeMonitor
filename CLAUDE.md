# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaudeCodeMonitor is a macOS menubar application that monitors Claude Code API usage and costs. It wraps the [ccusage](https://github.com/ryoppippi/ccusage) CLI tool to provide real-time usage tracking with a native macOS interface.

## Build and Run Commands

```bash
# Run tests
swift test

# Development build and run
./scripts/build-local.sh  # Builds debug version with helper
./scripts/run-local.sh    # Starts helper and main app

# Build release version
./scripts/build-release.sh  # Requires Developer ID for distribution

# Open in Xcode (recommended for development)
open Package.swift
# Then Build (⌘B) and Run (⌘R) in Xcode

# Manual build steps (if needed)
swift build -c debug --product ClaudeCodeMonitor
swift build -c debug --product ClaudeMonitorHelper

# Clean up processes if needed
killall ClaudeCodeMonitor ClaudeMonitorHelper 2>/dev/null || true
```

## Architecture

### Data Flow
1. **ccusage Integration**: Fetches usage data via ClaudeMonitorHelper service
2. **Session-Based Monitoring**: Claude Code uses 5-hour session blocks with token limits
3. **Real-Time Updates**: 5-minute auto-refresh with manual refresh option
4. **MainActor Isolation**: SwiftUI views and UsageMonitor are @MainActor isolated

### ClaudeMonitorHelper Architecture
- **Separate executable** that runs as a non-sandboxed service
- **Communicates via HTTP** on port 8456 (http://127.0.0.1:8456)
- **Executes ccusage** commands directly without sandbox restrictions
- **Registered as Login Item** for production, manually started in development
- **App Group sharing** for environment variables and paths

### Key Components

**AppDelegate.swift**
- Manages NSStatusItem (menubar icon) and NSPopover
- Updates menubar display: SF Symbol + percentage (e.g., "bolt.fill 24%")
- Handles popover show/hide with outside click detection
- Sets up notification delegate with bundle safety checks

**UsageMonitor.swift**
- Central data management with @Published properties
- Server-first strategy when App Sandbox is enabled
- Handles Pro/Max5/Max20 plan detection and persistence
- Implements UsageMonitoring protocol for dependency injection
- Key methods: `fetchUsageData()`, `startMonitoring()`, `stopMonitoring()`

**ContentView.swift**
- Three-tab interface: Current Session / History / Settings
- CurrentSessionView: Large remaining tokens display, progress bar, burn rate
- Compact 480x300 popover with scrollable content
- Visual effects blur background for modern appearance

**SessionModels.swift**
- Token limits: Pro (7K), Max5 (35K), Max20 (140K) per 5-hour session
- Auto-detects plan from historical usage or manual selection
- Calculates burn rate, remaining time, and usage percentage
- Extends UsageData with session-specific properties

**NotificationManager.swift**
- Sends notification when usage reaches 90%
- One notification per session (tracked by session ID)
- Handles Xcode debug build limitations with bundle checks
- Implements UNUserNotificationCenterDelegate

**ClaudeMonitorHelper (main.swift)**
- Separate non-sandboxed executable for ccusage execution
- Built with SwiftNIO for HTTP server on port 8456
- Reads environment variables from App Group
- Executes ccusage via bash -l -c for proper shell environment
- Handles /blocks/active, /usage, and /health endpoints

### Testing Strategy
- Unit tests with mocks for UsageMonitor and network services
- CI environment detection to skip locale-dependent tests
- Test files follow naming pattern: `*Tests.swift`
- Mock implementations in `Tests/ClaudeUsageMonitorTests/Mocks/`

### Localization
- Supports English and Japanese
- Uses Localization.swift with generated L10n enum
- Resource bundles in `Sources/ClaudeUsageMonitor/Resources/`
- LanguageSettings.swift manages language preferences

## Code Signing and Distribution

### Current Status
- Using ad-hoc signing (`--sign -`) for development releases
- This causes Gatekeeper warnings on first launch
- Users need to manually approve in System Settings

### Future: Developer ID Signing
When Apple Developer Program is available:
1. Update `DEVELOPER_ID` in `scripts/build-release.sh`
2. Add notarization step to release workflow
3. Benefits: No Gatekeeper warnings, smoother user experience

### Distribution Channels Priority
1. **Homebrew Cask** - Primary distribution method
2. **GitHub Releases** - Direct DMG downloads
3. **App Store** - Not recommended due to Sandbox limitations

## Technical Decisions

### Helper Service Strategy
1. Main app (ClaudeCodeMonitor) runs with App Sandbox enabled
2. Helper service (ClaudeMonitorHelper) runs without sandbox
3. Communication via HTTP localhost (allowed by sandbox)
4. In development: Helper started automatically via AppDelegate
5. In production: Helper registered as Login Item via SMAppService

### Module Name Mismatch
- Package name: `ClaudeCodeMonitor`
- Source directory: `Sources/ClaudeUsageMonitor` (historical reasons)
- Import statement: `import ClaudeCodeMonitor`
- This is handled via path specifications in Package.swift

### Error Handling
- ClaudeMonitorError enum for typed errors
- Localized error descriptions and recovery suggestions
- Network errors, parsing errors, command execution errors

### UI/UX Principles
- Menubar icon changes based on usage level
- Color gradient: blue (0-50%) → orange (50-75%) → red (75%+)
- Minimal popover size (480x300) for quick glancing
- All content scrollable to handle varying data

## Environment Requirements

- macOS 13.0+
- Swift 5.9+
- Node.js 18+ (for ccusage CLI)
- Xcode 15+ (for development)
- App runs as LSUIElement (menubar only, no Dock icon)