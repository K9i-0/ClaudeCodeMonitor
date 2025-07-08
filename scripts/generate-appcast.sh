#!/bin/bash
set -euo pipefail

# This script demonstrates how to properly generate separate appcast files
# for stable and dev channels

SPARKLE_VERSION="2.7.1"
GITHUB_REPO="${GITHUB_REPOSITORY:-K9i-0/ClaudeCodeMonitor}"
PRIVATE_KEY_FILE="${1:-}"

if [ -z "$PRIVATE_KEY_FILE" ]; then
    echo "Usage: $0 <private-key-file>"
    exit 1
fi

# Download Sparkle tools if not present
if [ ! -f "sparkle/bin/generate_appcast" ]; then
    echo "Downloading Sparkle tools..."
    mkdir -p sparkle
    cd sparkle
    curl -Lo sparkle.tar.xz "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz"
    tar xzf sparkle.tar.xz
    cd ..
fi

# Fetch all releases from GitHub
echo "Fetching releases from GitHub..."
gh release list --limit 100 --json tagName,isDraft,isPrerelease,createdAt | jq -r '.[] | select(.isDraft == false) | .tagName' > all-tags.txt

# Create directories for each channel
mkdir -p appcast-stable appcast-dev

# Download DMGs for stable releases (no -dev suffix)
echo "Processing stable releases..."
while IFS= read -r tag; do
    VERSION="${tag#v}"
    if [[ ! "$VERSION" =~ -dev$ ]]; then
        DMG_NAME="ClaudeCodeMonitor-${VERSION}.dmg"
        DMG_URL="https://github.com/${GITHUB_REPO}/releases/download/${tag}/${DMG_NAME}"
        
        if [ ! -f "appcast-stable/${DMG_NAME}" ]; then
            echo "  Downloading ${DMG_NAME}..."
            curl -L -o "appcast-stable/${DMG_NAME}" "$DMG_URL" || echo "  Failed to download ${DMG_NAME}"
        fi
        
        # Also include in dev channel
        if [ ! -f "appcast-dev/${DMG_NAME}" ]; then
            cp "appcast-stable/${DMG_NAME}" "appcast-dev/${DMG_NAME}" 2>/dev/null || true
        fi
    fi
done < all-tags.txt

# Download DMGs for dev releases (-dev suffix)
echo "Processing dev releases..."
while IFS= read -r tag; do
    VERSION="${tag#v}"
    if [[ "$VERSION" =~ -dev$ ]]; then
        DMG_NAME="ClaudeCodeMonitor-${VERSION}.dmg"
        DMG_URL="https://github.com/${GITHUB_REPO}/releases/download/${tag}/${DMG_NAME}"
        
        if [ ! -f "appcast-dev/${DMG_NAME}" ]; then
            echo "  Downloading ${DMG_NAME}..."
            curl -L -o "appcast-dev/${DMG_NAME}" "$DMG_URL" || echo "  Failed to download ${DMG_NAME}"
        fi
    fi
done < all-tags.txt

# Generate appcast.xml for stable channel
echo "Generating appcast.xml for stable channel..."
DOWNLOAD_URL_PREFIX="https://github.com/${GITHUB_REPO}/releases/download/"
./sparkle/bin/generate_appcast \
    --ed-key-file "$PRIVATE_KEY_FILE" \
    --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
    -o appcast.xml \
    appcast-stable/

# Generate appcast-dev.xml for dev channel
echo "Generating appcast-dev.xml for dev channel..."
./sparkle/bin/generate_appcast \
    --ed-key-file "$PRIVATE_KEY_FILE" \
    --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
    -o appcast-dev.xml \
    appcast-dev/

# Clean up
rm -rf sparkle appcast-stable appcast-dev all-tags.txt

echo "✅ Successfully generated appcast.xml and appcast-dev.xml"