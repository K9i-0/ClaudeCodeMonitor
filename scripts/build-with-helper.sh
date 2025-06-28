#!/bin/bash

set -e

echo "Building ClaudeCodeMonitor with Login Helper Item..."

# Clean previous builds
rm -rf .build
rm -rf ClaudeCodeMonitor.app

# Build both executables
echo "Building executables..."
swift build -c release --product ClaudeCodeMonitor
swift build -c release --product ClaudeMonitorHelper

# Create app bundle structure
echo "Creating app bundle..."
mkdir -p ClaudeCodeMonitor.app/Contents/MacOS
mkdir -p ClaudeCodeMonitor.app/Contents/Resources
mkdir -p ClaudeCodeMonitor.app/Contents/Library/LoginItems

# Copy main executable
cp .build/arm64-apple-macosx/release/ClaudeCodeMonitor ClaudeCodeMonitor.app/Contents/MacOS/

# Copy helper executable
cp .build/arm64-apple-macosx/release/ClaudeMonitorHelper ClaudeCodeMonitor.app/Contents/Library/LoginItems/

# Copy Info.plist files
cp Info.plist ClaudeCodeMonitor.app/Contents/
cp ClaudeMonitorHelper-Info.plist ClaudeCodeMonitor.app/Contents/Library/LoginItems/Info.plist

# Copy resources
if [ -d Sources/ClaudeUsageMonitor/Resources ]; then
    cp -r Sources/ClaudeUsageMonitor/Resources ClaudeCodeMonitor.app/Contents/
fi

# Sign with ad-hoc certificate for local testing
echo "Signing with ad-hoc certificate..."
codesign --force --sign - ClaudeCodeMonitor.app/Contents/Library/LoginItems/ClaudeMonitorHelper
codesign --force --sign - --deep ClaudeCodeMonitor.app

echo "Build complete!"
echo "To run: open ClaudeCodeMonitor.app"