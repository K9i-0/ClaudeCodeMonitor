#!/bin/bash

# Post-build script for Xcode
# This helps ensure the helper is properly copied when building from Xcode

echo "Running Xcode post-build script..."

# Get the built products directory
BUILT_PRODUCTS_DIR="${BUILT_PRODUCTS_DIR:-${BUILD_DIR}/${CONFIGURATION}}"

if [ -z "$BUILT_PRODUCTS_DIR" ]; then
    echo "Warning: BUILT_PRODUCTS_DIR not set"
    exit 0
fi

APP_PATH="$BUILT_PRODUCTS_DIR/ClaudeCodeMonitor.app"
HELPER_PATH="$BUILT_PRODUCTS_DIR/ClaudeMonitorHelper"

if [ -f "$HELPER_PATH" ] && [ -d "$APP_PATH" ]; then
    echo "Copying helper to app bundle..."
    mkdir -p "$APP_PATH/Contents/Library/LaunchServices"
    cp "$HELPER_PATH" "$APP_PATH/Contents/Library/LaunchServices/"
    echo "Helper copied successfully"
else
    echo "Warning: Helper or app not found"
fi