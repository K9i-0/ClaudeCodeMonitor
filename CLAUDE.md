# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaudeUsageMonitor is a macOS menubar application that monitors Claude Code API usage and costs. It wraps the [ccusage](https://github.com/ryoppippi/ccusage) CLI tool to provide real-time usage tracking with a native macOS interface.

## Build and Run Commands

```bash
# Option 1: Using Xcode (Recommended)
open Package.swift
# Then Build (⌘B) and Run (⌘R) in Xcode

# Option 2: Swift CLI
swift build
swift build -c release  # For release build

# Create app bundle (required after CLI build)
mkdir -p ClaudeUsageMonitor.app/Contents/MacOS
mkdir -p ClaudeUsageMonitor.app/Contents/Resources
cp .build/arm64-apple-macosx/debug/ClaudeUsageMonitor ClaudeUsageMonitor.app/Contents/MacOS/
cp Info.plist ClaudeUsageMonitor.app/Contents/
open ClaudeUsageMonitor.app

# Run local server (recommended to avoid npx path issues)
cd server
npm install
npm start  # Runs on http://127.0.0.1:3456
```

## Architecture

### Data Flow
1. **ccusage Integration**: Fetches usage data via local server (preferred) or direct npx execution
2. **Session-Based Monitoring**: Claude Code uses 5-hour session blocks with token limits
3. **Real-Time Updates**: 5-minute auto-refresh with manual refresh option
4. **MainActor Isolation**: SwiftUI views and UsageMonitor are @MainActor isolated

### Key Components

**AppDelegate.swift**
- Manages NSStatusItem (menubar icon) and NSPopover
- Updates menubar display: emoji + percentage (e.g., "✨ 24%")
- Handles popover show/hide with outside click detection

**UsageMonitor.swift**
- Central data management with @Published properties
- Multi-strategy ccusage execution (server → npx paths → shell)
- Handles Pro/Max5/Max20 plan detection and persistence

**ContentView.swift**
- Two-tab interface: "現在" (current session) / "履歴" (history)
- CurrentSessionView: Large remaining tokens display, progress bar, burn rate
- Compact 380x300 popover that fits without scrolling

**SessionModels.swift**
- Token limits: Pro (7K), Max5 (35K), Max20 (140K) per 5-hour session
- Auto-detects plan from historical usage or manual selection
- Calculates burn rate, remaining time, and usage percentage

### UI Design Decisions

**Menubar Display**
- Shows only emoji + percentage for clarity
- Emoji states: ✨ (0-20%), 💎 (20-50%), 🚀 (50-70%), ⚡ (70-90%), 🔥 (90%+)
- No dollar sign icon, no cost in menubar (ambiguous without context)

**Session Cost Display**
- Current session cost shown prominently in popover
- Historical costs marked as "参考値" (reference) since billing is session-based
- Plan selection via settings (gear icon)

## Technical Decisions

### ccusage Execution Strategy
1. Try local Express server first (avoids PATH issues)
2. Search common npx locations (mise, homebrew, volta, nvm)
3. Use `which npx` command
4. Fall back to shell with extended PATH

### Xcode Execution Issues
Xcode has limited PATH environment. Debug with:
- Check console for `[DEBUG]` messages
- Ensure server is running: `cd server && npm start`
- Add new npx paths to `npxSearchPaths` array in UsageMonitor.swift

### Plan Detection
- Stores selected plan in UserDefaults
- Manual selection overrides auto-detection
- Detects Max5/Max20 from historical token usage

## Environment Requirements

- macOS 13.0+
- Swift 5.9+
- Node.js (for ccusage CLI)
- App runs as LSUIElement (menubar only, no Dock icon)