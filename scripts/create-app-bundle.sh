#!/bin/bash

# Create macOS app bundle from Swift executable
# Usage: ./scripts/create-app-bundle.sh <version>

set -euo pipefail

VERSION="${1:-0.0.0-dev}"

echo "🔨 Creating macOS app bundle for version $VERSION"

# Build universal binary
echo "Building universal binary..."

# Build for arm64
echo "  Building for arm64..."
swift build -c release --arch arm64

# Build for x86_64
echo "  Building for x86_64..."
swift build -c release --arch x86_64

# Find the executables
ARM64_PATH=$(find .build -path "*arm64*/release/ClaudeCodeMonitor" -type f | head -1)
X86_64_PATH=$(find .build -path "*x86_64*/release/ClaudeCodeMonitor" -type f | head -1)

if [ -z "$ARM64_PATH" ] || [ -z "$X86_64_PATH" ]; then
    echo "❌ Failed to find one or both architectures"
    echo "  ARM64: $ARM64_PATH"
    echo "  X86_64: $X86_64_PATH"
    exit 1
fi

echo "  Found ARM64 binary: $ARM64_PATH"
echo "  Found X86_64 binary: $X86_64_PATH"

# Create universal binary
UNIVERSAL_DIR=".build/universal/release"
UNIVERSAL_PATH="$UNIVERSAL_DIR/ClaudeCodeMonitor"
mkdir -p "$UNIVERSAL_DIR"

echo "  Creating universal binary..."
lipo -create -output "$UNIVERSAL_PATH" "$ARM64_PATH" "$X86_64_PATH"

if [ ! -f "$UNIVERSAL_PATH" ]; then
    echo "❌ Failed to create universal binary"
    exit 1
fi

echo "✅ Universal binary created"
file "$UNIVERSAL_PATH"
lipo -info "$UNIVERSAL_PATH"

# Create app bundle structure
echo ""
echo "Creating app bundle..."
APP_PATH="ClaudeCodeMonitor.app"

# Clean existing app bundle
if [ -d "$APP_PATH" ]; then
    echo "  Removing existing app bundle..."
    rm -rf "$APP_PATH"
fi

# Create directory structure
mkdir -p "$APP_PATH/Contents/"{MacOS,Resources}

# Copy executable
echo "  Copying executable..."
cp "$UNIVERSAL_PATH" "$APP_PATH/Contents/MacOS/ClaudeCodeMonitor"

# Copy Info.plist and update version
echo "  Copying Info.plist..."
cp Info.plist "$APP_PATH/Contents/Info.plist"

echo "  Updating version to $VERSION..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP_PATH/Contents/Info.plist"

# Copy resource bundles from arm64 build (they are identical across architectures)
echo "  Looking for resource bundles..."
find .build -path "*arm64*/release/*.bundle" -type d | while read bundle; do
    echo "    Found bundle: $(basename "$bundle")"
    cp -R "$bundle" "$APP_PATH/Contents/Resources/"
done

# Verify app structure
echo ""
echo "Verifying app bundle structure..."
echo "  App bundle root:"
ls -la "$APP_PATH/"
echo ""
echo "  Contents directory:"
ls -la "$APP_PATH/Contents/"
echo ""
echo "  MacOS directory:"
ls -la "$APP_PATH/Contents/MacOS/"
echo ""
echo "  Resources directory:"
ls -la "$APP_PATH/Contents/Resources/" || echo "  No Resources directory"
echo ""
echo "  Executable info:"
file "$APP_PATH/Contents/MacOS/ClaudeCodeMonitor"

echo ""
echo "✅ App bundle created successfully: $APP_PATH"
echo "   Version: $VERSION"