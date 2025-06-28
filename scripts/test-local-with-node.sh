#!/bin/bash

set -e

echo "🧪 Local testing script for ClaudeCodeMonitor with Node.js"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
NODE_VERSION="v20.18.2"
NODE_VERSION_SHORT="20.18.2"
APP_NAME="ClaudeCodeMonitor.app"

# Step 1: Check if Node.js binaries exist
echo "📦 Checking for Node.js binaries..."
if [ ! -f "Resources/node/node" ]; then
    echo -e "${YELLOW}Node.js binary not found. Downloading...${NC}"
    
    # Create directory
    mkdir -p Resources/node
    cd Resources/node
    
    # Download for both architectures
    echo "  Downloading Node.js ${NODE_VERSION} for arm64..."
    curl -L "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-darwin-arm64.tar.gz" -o node-arm64.tar.gz
    tar -xzf node-arm64.tar.gz
    mv node-${NODE_VERSION}-darwin-arm64/bin/node node-arm64
    
    echo "  Downloading Node.js ${NODE_VERSION} for x64..."
    curl -L "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-darwin-x64.tar.gz" -o node-x64.tar.gz
    tar -xzf node-x64.tar.gz
    mv node-${NODE_VERSION}-darwin-x64/bin/node node-x64
    
    # Create universal binary
    echo "  Creating universal binary..."
    lipo -create -output node node-arm64 node-x64
    chmod +x node
    
    # Cleanup
    rm -rf node-*.tar.gz node-${NODE_VERSION}-darwin-* node-arm64 node-x64
    
    cd ../..
    echo -e "${GREEN}✅ Node.js binary created${NC}"
else
    echo -e "${GREEN}✅ Node.js binary already exists${NC}"
fi

# Step 2: Build the app
echo ""
echo "🔨 Building app bundle (skipping signing)..."
./scripts/create-app-bundle.sh 0.0.0-dev --skip-signing

# Step 3: Sign Node.js with entitlements
echo ""
echo "🔏 Checking Node.js binary signature..."
if [ -f "${APP_NAME}/Contents/Resources/node/node" ]; then
    # Check if Node.js has valid Developer ID signature
    if codesign -dvv "${APP_NAME}/Contents/Resources/node/node" 2>&1 | grep -q "Developer ID Application: Node.js Foundation"; then
        echo -e "${GREEN}✅ Node.js has valid Developer ID signature, keeping it${NC}"
    else
        echo "⚠️  Node.js doesn't have Developer ID signature, signing with ad-hoc..."
        # Remove existing signature first
        codesign --remove-signature "${APP_NAME}/Contents/Resources/node/node" 2>/dev/null || true
        # Sign with ad-hoc signature
        codesign --force --sign - --entitlements node.entitlements "${APP_NAME}/Contents/Resources/node/node"
        echo -e "${GREEN}✅ Node.js binary signed with ad-hoc${NC}"
    fi
else
    echo -e "${RED}❌ Node.js binary not found in app bundle${NC}"
    exit 1
fi

# Step 4: Sign the app
echo ""
echo "🔏 Signing app with entitlements (ad-hoc)..."
# Remove existing signature first
codesign --remove-signature "${APP_NAME}" 2>/dev/null || true
# Sign with ad-hoc signature (without --deep to preserve inner signatures)
codesign --force --sign - --entitlements ClaudeCodeMonitor.entitlements "${APP_NAME}"
echo -e "${GREEN}✅ App signed${NC}"

# Step 5: Verify signatures
echo ""
echo "🔍 Verifying signatures..."
codesign --verify --verbose "${APP_NAME}/Contents/Resources/node/node"
codesign --verify --verbose "${APP_NAME}"

# Step 6: Check entitlements
echo ""
echo "📋 Node.js entitlements:"
codesign -d --entitlements - "${APP_NAME}/Contents/Resources/node/node" 2>&1 | grep -A 20 "<?xml"

echo ""
echo "📋 App entitlements:"
codesign -d --entitlements - "${APP_NAME}" 2>&1 | grep -A 20 "<?xml"

# Step 7: Launch the app
echo ""
echo -e "${GREEN}🚀 Ready to test!${NC}"
echo ""
echo "Launch the app with:"
echo "  open ${APP_NAME}"
echo ""
echo "Monitor logs with:"
echo "  log stream --predicate 'processImagePath CONTAINS \"ClaudeCodeMonitor\"'"
echo ""
echo "Check server logs:"
echo "  tail -f ~/Library/Logs/ClaudeCodeMonitor/server.log"