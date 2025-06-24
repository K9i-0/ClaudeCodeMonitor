#!/bin/bash

# Build script for ClaudeUsageMonitor with App Sandbox and Hardened Runtime
# This script builds the app with proper code signing for App Store distribution

set -e

# Configuration
APP_NAME="ClaudeCodeMonitor"
BUNDLE_ID="com.k9i.claude-code-monitor"  # Replace with your bundle ID
BUILD_DIR=".build/release"
APP_DIR="$APP_NAME.app"
DEVELOPER_ID="Developer ID Application: Your Name (XXXXXXXXXX)"  # Replace with your Developer ID

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building $APP_NAME for release...${NC}"

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$APP_DIR"

# Build in release mode
echo -e "${YELLOW}Building with Swift...${NC}"
swift build -c release

# Create app bundle structure
echo -e "${YELLOW}Creating app bundle...${NC}"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/"

# Copy Info.plist
cp Info.plist "$APP_DIR/Contents/"

# Copy entitlements
cp ClaudeCodeMonitor.entitlements "$APP_DIR/Contents/"

# Sign the app with hardened runtime and entitlements
echo -e "${YELLOW}Signing app with hardened runtime...${NC}"
if [ -z "$SKIP_SIGNING" ]; then
    codesign --force --deep --strict \
        --options runtime \
        --entitlements ClaudeCodeMonitor.entitlements \
        --sign "$DEVELOPER_ID" \
        "$APP_DIR"
    
    # Verify the signature
    echo -e "${YELLOW}Verifying signature...${NC}"
    codesign --verify --deep --strict --verbose=2 "$APP_DIR"
    
    # Check entitlements
    echo -e "${YELLOW}Checking entitlements...${NC}"
    codesign -d --entitlements - "$APP_DIR"
else
    echo -e "${YELLOW}Skipping code signing (SKIP_SIGNING is set)${NC}"
fi

echo -e "${GREEN}Build complete!${NC}"
echo -e "${GREEN}App bundle created at: $APP_DIR${NC}"

# Test App Sandbox
echo -e "${YELLOW}Testing App Sandbox...${NC}"
if [ -z "$SKIP_SIGNING" ]; then
    # Check if app is sandboxed
    if codesign -d --entitlements - "$APP_DIR" 2>/dev/null | grep -q "com.apple.security.app-sandbox.*true"; then
        echo -e "${GREEN}✓ App Sandbox is enabled${NC}"
    else
        echo -e "${RED}✗ App Sandbox is NOT enabled${NC}"
        exit 1
    fi
    
    # Check if hardened runtime is enabled
    if codesign --display --verbose "$APP_DIR" 2>&1 | grep -q "flags=.*runtime"; then
        echo -e "${GREEN}✓ Hardened Runtime is enabled${NC}"
    else
        echo -e "${RED}✗ Hardened Runtime is NOT enabled${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}All checks passed!${NC}"