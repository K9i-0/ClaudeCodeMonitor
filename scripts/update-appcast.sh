#!/bin/bash
set -euo pipefail

# Script to update appcast files in gh-pages branch
# Usage: ./scripts/update-appcast.sh <version> <is_dev_build>

VERSION="${1:-}"
IS_DEV_BUILD="${2:-false}"
SPARKLE_PRIVATE_KEY="${SPARKLE_PRIVATE_KEY:-}"

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> [is_dev_build]"
    exit 1
fi

echo "Updating appcast for version $VERSION (dev: $IS_DEV_BUILD)"

# Save current branch
CURRENT_BRANCH=$(git branch --show-current)

# Download Sparkle tools if needed
if [ ! -f "sparkle/bin/generate_appcast" ] && [ -n "$SPARKLE_PRIVATE_KEY" ]; then
    echo "Downloading Sparkle tools..."
    mkdir -p sparkle
    cd sparkle
    curl -Lo sparkle.tar.xz https://github.com/sparkle-project/Sparkle/releases/download/2.7.1/Sparkle-2.7.1.tar.xz
    tar xzf sparkle.tar.xz
    cd ..
fi

# Create temp directory for appcast generation
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy DMG to temp directory
DMG_NAME="ClaudeCodeMonitor-${VERSION}.dmg"
if [ -f "$DMG_NAME" ]; then
    cp "$DMG_NAME" "$TEMP_DIR/"
else
    echo "Warning: $DMG_NAME not found in current directory"
fi

# Checkout gh-pages branch
echo "Switching to gh-pages branch..."
git fetch origin gh-pages
git checkout gh-pages

# Determine which appcast to update
if [ "$IS_DEV_BUILD" == "true" ]; then
    APPCAST_FILE="appcast-dev.xml"
else
    APPCAST_FILE="appcast.xml"
fi

# Copy existing appcast to temp directory
if [ -f "$APPCAST_FILE" ]; then
    cp "$APPCAST_FILE" "$TEMP_DIR/"
fi

# Generate new appcast
if [ -n "$SPARKLE_PRIVATE_KEY" ] && [ -f "sparkle/bin/generate_appcast" ]; then
    echo "Generating appcast with Sparkle..."
    
    # Create private key file
    PRIVATE_KEY_FILE=$(mktemp)
    (umask 077 && echo -n "$SPARKLE_PRIVATE_KEY" > "$PRIVATE_KEY_FILE")
    
    # Generate appcast
    DOWNLOAD_URL_PREFIX="https://github.com/K9i-0/ClaudeCodeMonitor/releases/download/v${VERSION}/"
    ./sparkle/bin/generate_appcast \
        --ed-key-file "$PRIVATE_KEY_FILE" \
        --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
        -o "$APPCAST_FILE" \
        "$TEMP_DIR/"
    
    rm -f "$PRIVATE_KEY_FILE"
else
    echo "No Sparkle private key available, manual appcast update required"
fi

# Commit and push changes
if git diff --quiet "$APPCAST_FILE"; then
    echo "No changes to $APPCAST_FILE"
else
    git add "$APPCAST_FILE"
    git commit -m "Update $APPCAST_FILE for version $VERSION"
    git push origin gh-pages
    echo "Successfully updated $APPCAST_FILE"
fi

# Return to original branch
git checkout "$CURRENT_BRANCH"

# Clean up Sparkle tools
rm -rf sparkle

echo "✅ Appcast update complete"