#!/bin/bash

set -euo pipefail

# This script signs a release file with Sparkle's EdDSA signature

# Check if the required arguments are provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <file-to-sign>"
    exit 1
fi

FILE_TO_SIGN="$1"

# Check if the file exists
if [ ! -f "$FILE_TO_SIGN" ]; then
    echo "Error: File not found: $FILE_TO_SIGN"
    exit 1
fi

# Check if the required environment variable is set
if [ -z "${SPARKLE_PRIVATE_KEY:-}" ]; then
    echo "Error: SPARKLE_PRIVATE_KEY environment variable is not set"
    exit 1
fi

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
echo "Generating signature for $FILE_TO_SIGN..."
SIGNATURE=$("$SIGN_UPDATE" -f "$SPARKLE_PRIVATE_KEY" "$FILE_TO_SIGN" | tail -1)

if [ -z "$SIGNATURE" ]; then
    echo "Error: Failed to generate signature"
    exit 1
fi

echo "Signature: $SIGNATURE"

# Export for use in other scripts
export SPARKLE_SIGNATURE="$SIGNATURE"