#!/bin/bash

# Build script for local development
# This creates a development build with the current git state

echo "🔨 Building Claude Code Monitor (Development Version)"

# Get version information
if git describe --exact-match --tags HEAD 2>/dev/null; then
  # Building from a tag
  VERSION=$(git describe --exact-match --tags HEAD | sed 's/^v//')
  echo "Building from tag: v$VERSION"
else
  # Development build
  COMMIT=$(git rev-parse --short HEAD)
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  VERSION="0.0.0-dev+$BRANCH.$COMMIT"
  echo "Development build: $VERSION"
fi

# Build the app and helper
echo "Building Swift packages..."
swift build -c debug --product ClaudeCodeMonitor
swift build -c debug --product ClaudeMonitorHelper

# Find the executables
EXECUTABLE_PATH=$(find .build -name ClaudeCodeMonitor -type f -perm +111 | grep -v '.dSYM' | grep debug | head -1)
HELPER_PATH=$(find .build -name ClaudeMonitorHelper -type f -perm +111 | grep -v '.dSYM' | grep debug | head -1)

if [ ! -f "$EXECUTABLE_PATH" ]; then
  echo "❌ Failed to find main executable"
  exit 1
fi

if [ ! -f "$HELPER_PATH" ]; then
  echo "❌ Failed to find helper executable"
  exit 1
fi

echo "✅ Main binary built at: $EXECUTABLE_PATH"
echo "✅ Helper binary built at: $HELPER_PATH"

# Create app bundle
echo "Creating app bundle..."
rm -rf ClaudeCodeMonitor.app
mkdir -p "ClaudeCodeMonitor.app/Contents/MacOS"
mkdir -p "ClaudeCodeMonitor.app/Contents/Resources"
mkdir -p "ClaudeCodeMonitor.app/Contents/Library/LaunchServices"

# Copy executables
cp "$EXECUTABLE_PATH" "ClaudeCodeMonitor.app/Contents/MacOS/"
cp "$HELPER_PATH" "ClaudeCodeMonitor.app/Contents/Library/LaunchServices/"

# Copy and update Info.plist files
cp Info.plist "ClaudeCodeMonitor.app/Contents/"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "ClaudeCodeMonitor.app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "ClaudeCodeMonitor.app/Contents/Info.plist"

# Copy helper Info.plist
cp ClaudeMonitorHelper-Info.plist "ClaudeCodeMonitor.app/Contents/Library/LaunchServices/Info.plist"

# Copy resource bundles
echo "Looking for resource bundles..."
find .build -name "*.bundle" -type d | grep debug | while read bundle; do
  echo "Found bundle: $bundle"
  cp -R "$bundle" "ClaudeCodeMonitor.app/Contents/Resources/"
done

# Ad-hoc sign for local use
echo "Signing app bundle..."
codesign --force --deep --sign - "ClaudeCodeMonitor.app"

echo "✅ Build complete!"
echo ""
echo "To run the app:"
echo "  open ClaudeCodeMonitor.app"
echo ""
echo "Version: $VERSION"
echo ""
echo "Note: In development mode, the helper will start automatically."
echo "If you encounter issues, you can manually start the helper:"
echo "  ./ClaudeCodeMonitor.app/Contents/Library/LaunchServices/ClaudeMonitorHelper &"