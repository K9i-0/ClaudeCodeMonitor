# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaudeCodeUsageMonitor is a macOS menubar application that monitors Claude Code API usage and costs. It wraps the [ccusage](https://github.com/ryoppippi/ccusage) CLI tool to provide real-time usage tracking with a native macOS interface.

## Build and Run Commands

```bash
# Run tests
swift test

# Build debug version
swift build

# Build release version
swift build -c release

# Create app bundle (required after CLI build)
mkdir -p ClaudeCodeUsageMonitor.app/Contents/MacOS
mkdir -p ClaudeCodeUsageMonitor.app/Contents/Resources
cp .build/arm64-apple-macosx/debug/ClaudeCodeUsageMonitor ClaudeCodeUsageMonitor.app/Contents/MacOS/
cp Info.plist ClaudeCodeUsageMonitor.app/Contents/
open ClaudeCodeUsageMonitor.app

# Build release with code signing (requires Developer ID)
./scripts/build-release.sh

# Run local server (REQUIRED for App Sandbox mode)
cd server
npm install
npm start  # Runs on http://127.0.0.1:3456

# Open in Xcode (recommended for development)
open Package.swift
# Then Build (⌘B) and Run (⌘R) in Xcode
```

## Architecture

### Data Flow
1. **ccusage Integration**: Fetches usage data via local server (required when App Sandbox is enabled)
2. **Session-Based Monitoring**: Claude Code uses 5-hour session blocks with token limits
3. **Real-Time Updates**: 5-minute auto-refresh with manual refresh option
4. **MainActor Isolation**: SwiftUI views and UsageMonitor are @MainActor isolated

### App Sandbox Support
- **App Sandbox is enabled** for App Store distribution
- When App Sandbox is enabled, the local server (http://127.0.0.1:3456) is **required**
- Direct command execution (npx) is not possible with App Sandbox
- Network entitlements allow localhost connections only

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

**ServerManager.swift**
- Manages local Express server lifecycle
- Auto-starts server when app launches
- Handles server health checks and restarts
- Logs server output for debugging

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

## Technical Decisions

### ccusage Execution Strategy
1. App Sandbox enabled: Server-only mode (required)
2. App Sandbox disabled: Try server first, then fall back to direct npx

### Module Name Mismatch
- Package name: `ClaudeCodeUsageMonitor`
- Source directory: `Sources/ClaudeUsageMonitor` (historical reasons)
- Import statement: `import ClaudeCodeUsageMonitor`
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
- Node.js 18+ (for ccusage CLI and local server)
- Xcode 15+ (for development)
- App runs as LSUIElement (menubar only, no Dock icon)