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

# Check if we're in CI environment with setup-sparkle
if [ -n "${SPARKLE_BIN:-}" ] && [ -f "$SPARKLE_BIN/sign_update" ]; then
    echo "Using Sparkle tools from setup-sparkle action: $SPARKLE_BIN"
    SIGN_UPDATE="$SPARKLE_BIN/sign_update"
else
    # Create temporary directory for Sparkle tools
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    # Download Sparkle tools if not available
    SPARKLE_VERSION="2.6.2"
    SPARKLE_TOOLS_URL="https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz"

    echo "Downloading Sparkle tools..."
    if ! curl -L -o "$TEMP_DIR/sparkle.tar.xz" "$SPARKLE_TOOLS_URL"; then
        echo "Error: Failed to download Sparkle tools from $SPARKLE_TOOLS_URL"
        exit 1
    fi

    echo "Extracting Sparkle tools..."
    if ! tar -xf "$TEMP_DIR/sparkle.tar.xz" -C "$TEMP_DIR"; then
        echo "Error: Failed to extract Sparkle tools"
        exit 1
    fi

    # Path to sign_update tool
    SIGN_UPDATE="$TEMP_DIR/bin/sign_update"

    if [ ! -f "$SIGN_UPDATE" ]; then
        echo "Error: sign_update tool not found at $SIGN_UPDATE"
        echo "Checking alternative locations..."
        
        # Check alternative paths
        for path in "$TEMP_DIR/Sparkle.framework/Versions/Current/Resources/sign_update" "$TEMP_DIR/sign_update"; do
            if [ -f "$path" ]; then
                echo "Found sign_update at: $path"
                SIGN_UPDATE="$path"
                break
            fi
        done
        
        if [ ! -f "$SIGN_UPDATE" ]; then
            echo "Error: Could not find sign_update tool in any expected location"
            echo "Contents of temp directory:"
            find "$TEMP_DIR" -name "sign_update" -type f 2>/dev/null || true
            exit 1
        fi
    fi
fi

# Generate EdDSA signature
echo "Generating signature for $DMG_PATH..."
# Write private key to temporary file with secure permissions
PRIVATE_KEY_FILE="$TEMP_DIR/private_key.txt"
(umask 077 && echo "$SPARKLE_PRIVATE_KEY" > "$PRIVATE_KEY_FILE")
SIGNATURE=$("$SIGN_UPDATE" -f "$PRIVATE_KEY_FILE" -p "$DMG_PATH")

# Immediately remove the private key file after use
rm -f "$PRIVATE_KEY_FILE"

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