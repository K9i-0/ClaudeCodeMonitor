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

# Copy resource bundle
if [ -d .build/arm64-apple-macosx/release/ClaudeCodeMonitor_ClaudeCodeMonitor.bundle ]; then
    cp -r .build/arm64-apple-macosx/release/ClaudeCodeMonitor_ClaudeCodeMonitor.bundle ClaudeCodeMonitor.app/Contents/Resources/
fi

# Sign with ad-hoc certificate for local testing
echo "Signing with ad-hoc certificate..."
# Helper ItemはSandboxなしで署名（Login Helper ItemはSandbox外で動作する必要がある）
codesign --force --sign - ClaudeCodeMonitor.app/Contents/Library/LoginItems/ClaudeMonitorHelper
# メインアプリにエンタイトルメントを追加して署名
codesign --force --sign - --entitlements ClaudeCodeMonitor.entitlements --deep ClaudeCodeMonitor.app

echo "Build complete!"
echo "To run: open ClaudeCodeMonitor.app"