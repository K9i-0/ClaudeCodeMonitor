#!/bin/bash

set -euo pipefail

# This script generates the appcast.xml file for Sparkle updates

# Check if the required environment variables are set
if [ -z "${SPARKLE_PRIVATE_KEY:-}" ]; then
    echo "Error: SPARKLE_PRIVATE_KEY environment variable is not set"
    exit 1
fi

if [ -z "${VERSION:-}" ]; then
    echo "Error: VERSION environment variable is not set"
    exit 1
fi

if [ -z "${DMG_PATH:-}" ]; then
    echo "Error: DMG_PATH environment variable is not set"
    exit 1
fi

# GitHub repository information
REPO_URL="https://github.com/K9i-0/ClaudeCodeMonitor"
DOWNLOAD_URL_PREFIX="${REPO_URL}/releases/download/v${VERSION}/"

# Create directories
mkdir -p sparkle appcast
cd sparkle

# Download and extract Sparkle
echo "Downloading Sparkle tools..."
SPARKLE_VERSION="2.6.2"
curl -Lo sparkle.tar.xz "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz"

echo "Extracting Sparkle tools..."
tar xzf sparkle.tar.xz
cd ..

# Copy DMG to appcast directory
echo "Copying DMG to appcast directory..."
cp "$DMG_PATH" appcast/

# Create temporary file for private key
PRIVATE_KEY_FILE=$(mktemp)
trap "rm -f $PRIVATE_KEY_FILE" EXIT
(umask 077 && echo "$SPARKLE_PRIVATE_KEY" > "$PRIVATE_KEY_FILE")

# Generate appcast
echo "Generating appcast.xml..."
./sparkle/bin/generate_appcast \
    --ed-key-file "$PRIVATE_KEY_FILE" \
    --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
    -o appcast.xml \
    appcast/

# Clean up
rm -rf sparkle appcast

if [ -f "appcast.xml" ]; then
    echo "Successfully generated appcast.xml for version ${VERSION}"
else
    echo "Error: Failed to generate appcast.xml"
    exit 1
fi