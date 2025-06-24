#!/bin/bash

# Build script for Claude Code Monitor release
# Creates a signed and notarized DMG for distribution

set -e

# Configuration
APP_NAME="Claude Code Monitor"
BUNDLE_ID="com.k9i.claude-code-monitor"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_PATH="$APP_NAME.app"
DMG_NAME="ClaudeCodeMonitor-$VERSION.dmg"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building $APP_NAME v$VERSION for release...${NC}"

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$APP_PATH"
rm -f "$DMG_NAME"

# Build in release mode
echo -e "${YELLOW}Building with Swift...${NC}"
swift build -c release

# Create app bundle structure
echo -e "${YELLOW}Creating app bundle...${NC}"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/ClaudeCodeMonitor" "$APP_PATH/Contents/MacOS/"

# Copy Info.plist
cp Info.plist "$APP_PATH/Contents/"

# Copy entitlements (for reference, not embedded)
cp ClaudeCodeMonitor.entitlements "$APP_PATH/Contents/"

# Sign the app if not skipped
if [ -z "$SKIP_SIGNING" ]; then
    echo -e "${YELLOW}Signing app...${NC}"
    
    # Use ad-hoc signing for now (replace with Developer ID for distribution)
    codesign --force --deep --strict \
        --options runtime \
        --entitlements ClaudeCodeMonitor.entitlements \
        --sign - \
        "$APP_PATH"
    
    # Verify the signature
    echo -e "${YELLOW}Verifying signature...${NC}"
    codesign --verify --deep --strict --verbose=2 "$APP_PATH"
else
    echo -e "${YELLOW}Skipping code signing (SKIP_SIGNING is set)${NC}"
fi

# Create DMG
echo -e "${YELLOW}Creating DMG...${NC}"
mkdir -p dmg-content
cp -R "$APP_PATH" dmg-content/

# Create a simple DMG (for more advanced DMG with background image, use create-dmg tool)
hdiutil create -volname "$APP_NAME" \
    -srcfolder dmg-content \
    -ov -format UDZO \
    "$DMG_NAME"

# Clean up temporary files
rm -rf dmg-content

# Calculate checksums
echo -e "${YELLOW}Calculating checksums...${NC}"
shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"

echo -e "${GREEN}Build complete!${NC}"
echo -e "${GREEN}Created: $DMG_NAME${NC}"
echo -e "${GREEN}SHA256: $(cat $DMG_NAME.sha256)${NC}"

# Instructions for notarization (requires Developer ID)
echo -e "${YELLOW}"
echo "To notarize this app for distribution:"
echo "1. Sign with a Developer ID Application certificate"
echo "2. Submit for notarization: xcrun notarytool submit $DMG_NAME --wait"
echo "3. Staple the notarization: xcrun stapler staple $DMG_NAME"
echo -e "${NC}"