# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaudeUsageMonitor is a macOS menubar application built with SwiftUI that monitors Claude API usage and costs in real-time. The app runs as a menu bar utility (LSUIElement) and displays usage data fetched from the `ccusage` CLI tool.

## Build Commands

```bash
# Build the executable
swift build

# Create app bundle after building
mkdir -p ClaudeUsageMonitor.app/Contents/MacOS
mkdir -p ClaudeUsageMonitor.app/Contents/Resources
cp .build/arm64-apple-macosx/debug/ClaudeUsageMonitor ClaudeUsageMonitor.app/Contents/MacOS/
cp Info.plist ClaudeUsageMonitor.app/Contents/

# Run the app
open ClaudeUsageMonitor.app

# Build for release
swift build -c release
```

## Architecture

### Core Components

1. **ClaudeUsageMonitorApp.swift**: Entry point using @main attribute, sets up AppDelegate
2. **AppDelegate.swift**: Manages NSStatusItem, popover lifecycle, and automatic updates (5-minute intervals)
3. **UsageMonitor.swift**: @MainActor ObservableObject that executes `ccusage` CLI and parses JSON responses
4. **ContentView.swift**: SwiftUI view with tabs for today/this month usage display
5. **Models.swift**: Codable structs matching ccusage JSON output structure

### Key Design Patterns

- **SwiftUI + AppKit Integration**: Uses NSHostingController to embed SwiftUI views in NSPopover
- **Observable Pattern**: UsageMonitor publishes changes to UI via @Published properties
- **Process Execution**: Spawns child process to run `npx ccusage@latest --json`
- **Event Monitoring**: Global event monitor to close popover on outside clicks

### Data Flow

1. AppDelegate creates UsageMonitor instance and sets up 5-minute timer
2. UsageMonitor executes ccusage CLI and parses JSON response
3. Parsed data updates @Published properties triggering UI refresh
4. Menu bar shows today's cost, popover shows detailed breakdown

## Development Guidelines

### Adding Features

- UI changes: Modify ContentView.swift
- Data model changes: Update Models.swift to match ccusage output
- Monitoring logic: Extend UsageMonitor.swift
- Menu bar behavior: Modify AppDelegate.swift

### Error Handling

- UsageMonitor catches Process execution errors and updates errorMessage
- Empty or malformed responses handled gracefully with default values
- UI shows appropriate messages for loading/error states

### Testing External Dependencies

The app requires `ccusage` CLI tool. Test with:
```bash
npx ccusage@latest --json
```

## Important Notes

- Bundle Identifier: `com.example.claudeusagemonitor`
- Minimum macOS version: 13.0
- Swift version: 5.9+
- App runs as menu bar only (no Dock icon)
- Automatic termination disabled via Info.plist