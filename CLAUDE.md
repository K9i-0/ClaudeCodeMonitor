# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaudeCodeMonitor is a macOS menubar application that monitors Claude Code API usage and costs. It wraps the [ccusage](https://github.com/ryoppippi/ccusage) CLI tool to provide real-time usage tracking with a native macOS interface.

## Build and Run Commands

```bash
# Run tests
swift test

# Build debug version
swift build

# Build release version
swift build -c release

# Create app bundle (required after CLI build)
mkdir -p ClaudeCodeMonitor.app/Contents/MacOS
mkdir -p ClaudeCodeMonitor.app/Contents/Resources
cp .build/arm64-apple-macosx/debug/ClaudeCodeMonitor ClaudeCodeMonitor.app/Contents/MacOS/
cp Info.plist ClaudeCodeMonitor.app/Contents/
open ClaudeCodeMonitor.app

# Build release with code signing (requires Developer ID)
./scripts/build-release.sh

# Run local server (REQUIRED for App Sandbox mode)
cd server
npm install
npm start  # Runs on http://127.0.0.1:3456

# Open in Xcode (recommended for development)
open Package.swift
# Then Build (⌘B) and Run (⌘R) in Xcode

# Local testing with Node.js bundled (App Sandbox mode)
./scripts/test-local-with-node.sh
# This script:
# 1. Downloads Node.js binaries (if not already present)
# 2. Creates universal binary
# 3. Builds the app with --skip-signing flag
# 4. Signs Node.js with entitlements
# 5. Signs the app with ad-hoc certificate
# Then run: open ClaudeCodeMonitor.app

# Clean up processes if needed
killall ClaudeCodeMonitor 2>/dev/null || true
ps aux | grep -E "node.*server" | grep -v grep | awk '{print $2}' | xargs kill 2>/dev/null || true

# Debug with different port (to avoid conflict with release version)
cd server && PORT=3457 npm start  # Start server on port 3457
CLAUDE_MONITOR_PORT=3457 swift run  # Run app using port 3457
```

## Debugging with Port Configuration

To avoid port conflicts between the DMG-distributed app and debug builds:

### Using Environment Variables

Both the server and application support custom port configuration via environment variables:

- Server: `PORT` environment variable (defaults to 3456)
- Application: `CLAUDE_MONITOR_PORT` environment variable (defaults to 3456)

### Debug Setup in Xcode

1. Open the project in Xcode: `open Package.swift`
2. Edit the scheme (Product → Scheme → Edit Scheme...)
3. In the "Run" section, go to "Arguments" tab
4. Add environment variable: `CLAUDE_MONITOR_PORT` = `3457`

### Command Line Debug

```bash
# Terminal 1: Start server on custom port
cd server
PORT=3457 npm start

# Terminal 2: Run app with custom port
CLAUDE_MONITOR_PORT=3457 swift run
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

### Data Access (App Sandbox)
- Uses NSOpenPanel for user to grant access to ~/.claude directory
- Security-scoped bookmarks persist access across app launches
- No temporary-exception entitlements (App Store compliant)
- ClaudeDataAccessManager handles folder selection and bookmark management

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

### ccusage Execution Strategy
1. App Sandbox enabled: Server-only mode (required)
2. App Sandbox disabled: Try server first, then fall back to direct npx

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
- Node.js 18+ (for ccusage CLI and local server)
- Xcode 15+ (for development)
- App runs as LSUIElement (menubar only, no Dock icon)