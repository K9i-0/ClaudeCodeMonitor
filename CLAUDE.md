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

# Open in Xcode (recommended for development)
open Package.swift
# Then Build (⌘B) and Run (⌘R) in Xcode

# Clean up processes if needed
killall ClaudeCodeMonitor 2>/dev/null || true
```

## Architecture

### Data Flow
1. **ccusage Integration**: Directly executes ccusage via CommandExecutor (bunx preferred, npx fallback)
2. **Session-Based Monitoring**: Claude Code uses 5-hour session blocks with token limits
3. **Real-Time Updates**: 5-minute auto-refresh with manual refresh option
4. **MainActor Isolation**: SwiftUI views and UsageMonitor are @MainActor isolated

### Command Execution Strategy
- **CommandExecutor.swift**: Manages ccusage command execution
- Preference order: bunx > npx
- Automatic fallback if preferred command is not available
- Environment setup validation before app launch

### Environment Requirements
- Claude Code installed (~/.claude/projects directory)
- Either Bun (bunx) or Node.js (npx) installed
- EnvironmentSetupView guides users through missing requirements

### Key Components

**AppDelegate.swift**
- Manages NSStatusItem (menubar icon) and NSPopover
- Updates menubar display: SF Symbol + percentage (e.g., "bolt.fill 24%")
- Handles popover show/hide with outside click detection
- Checks environment requirements on launch

**UsageMonitor.swift**
- Central data management with @Published properties
- Direct command execution via CommandExecutor
- Handles Pro/Max5/Max20 plan detection and persistence
- Implements UsageMonitoring protocol for dependency injection
- Key methods: `fetchUsageData()`, `startMonitoring()`, `stopMonitoring()`

**CommandExecutor.swift**
- Executes ccusage commands with bunx/npx
- Handles command detection and fallback logic
- Provides environment checking functionality
- Thread-safe singleton pattern

**EnvironmentSetupView.swift**
- Replaces ClaudeNotInstalledView
- Comprehensive environment checking
- Guides users to install missing dependencies
- Shows Claude Code, Bun, and Node.js status

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

### Direct Command Execution
- No local server required
- Simpler architecture and maintenance
- Better reliability
- Faster startup time

### Module Name Mismatch
- Package name: `ClaudeCodeMonitor`
- Source directory: `Sources/ClaudeUsageMonitor` (historical reasons)
- Import statement: `import ClaudeCodeMonitor`
- This is handled via path specifications in Package.swift

### Error Handling
- ClaudeMonitorError enum for typed errors
- CommandExecutor.CommandError for command-specific errors
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
- Bun or Node.js 18+ (for ccusage CLI)
- Xcode 15+ (for development)
- App runs as LSUIElement (menubar only, no Dock icon)