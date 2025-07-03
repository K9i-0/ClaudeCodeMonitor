#!/bin/bash

# Build script for local development
# This creates a development build with the current git state

echo "🔨 Building ClaudeCodeMonitor (Development Version)"

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

# Build the app
echo "Building Swift package..."
swift build -c release

# Find the executable
EXECUTABLE_PATH=$(find .build -name ClaudeCodeMonitor -type f -perm +111 | grep -v '.dSYM' | grep release | head -1)

if [ ! -f "$EXECUTABLE_PATH" ]; then
  echo "❌ Failed to find executable"
  exit 1
fi

echo "✅ Binary built at: $EXECUTABLE_PATH"

# Create app bundle
echo "Creating app bundle..."
rm -rf ClaudeCodeMonitor.app
mkdir -p "ClaudeCodeMonitor.app/Contents/MacOS"
mkdir -p "ClaudeCodeMonitor.app/Contents/Resources"

# Copy executable
cp "$EXECUTABLE_PATH" "ClaudeCodeMonitor.app/Contents/MacOS/"

# Copy and update Info.plist
cp Info.plist "ClaudeCodeMonitor.app/Contents/"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "ClaudeCodeMonitor.app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "ClaudeCodeMonitor.app/Contents/Info.plist"

# Copy resource bundles
echo "Looking for resource bundles..."
find .build -name "*.bundle" -type d | grep release | while read bundle; do
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