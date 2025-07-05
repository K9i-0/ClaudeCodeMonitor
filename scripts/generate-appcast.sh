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
DOWNLOAD_URL="${REPO_URL}/releases/download/v${VERSION}/ClaudeCodeMonitor-${VERSION}.dmg"

# Get file size and date
FILE_SIZE=$(stat -f%z "$DMG_PATH")
RELEASE_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S %z")

# Create temporary directory for Sparkle tools
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Download Sparkle tools if not available
SPARKLE_VERSION="2.5.2"
SPARKLE_TOOLS_URL="https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz"

echo "Downloading Sparkle tools..."
curl -L -o "$TEMP_DIR/sparkle.tar.xz" "$SPARKLE_TOOLS_URL"
tar -xf "$TEMP_DIR/sparkle.tar.xz" -C "$TEMP_DIR"

# Path to sign_update tool
SIGN_UPDATE="$TEMP_DIR/Sparkle.framework/Versions/Current/Resources/sign_update"

if [ ! -f "$SIGN_UPDATE" ]; then
    echo "Error: sign_update tool not found at $SIGN_UPDATE"
    exit 1
fi

# Generate EdDSA signature
echo "Generating signature for $DMG_PATH..."
SIGNATURE=$("$SIGN_UPDATE" -f "$SPARKLE_PRIVATE_KEY" "$DMG_PATH" | tail -1)

if [ -z "$SIGNATURE" ]; then
    echo "Error: Failed to generate signature"
    exit 1
fi

# Generate appcast.xml
cat > appcast.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>Claude Code Monitor Changelog</title>
        <link>${REPO_URL}/releases/latest/download/appcast.xml</link>
        <description>Most recent changes with links to updates.</description>
        <language>en</language>
        <item>
            <title>Version ${VERSION}</title>
            <pubDate>${RELEASE_DATE}</pubDate>
            <enclosure url="${DOWNLOAD_URL}"
                       sparkle:version="${VERSION}"
                       sparkle:shortVersionString="${VERSION}"
                       length="${FILE_SIZE}"
                       type="application/octet-stream"
                       sparkle:edSignature="${SIGNATURE}" />
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
        </item>
    </channel>
</rss>
EOF

echo "Successfully generated appcast.xml for version ${VERSION}"
echo "Signature: ${SIGNATURE}"