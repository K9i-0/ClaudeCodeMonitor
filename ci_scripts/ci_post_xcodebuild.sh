#!/bin/sh

# Xcode Cloud Post-Build Script
# This script runs after Xcode Cloud completes the build

echo "Running Xcode Cloud post-build script..."

# Verify the build output
if [ -f "$CI_ARCHIVE_PATH/Products/Applications/ClaudeUsageMonitor.app/Contents/MacOS/ClaudeUsageMonitor" ]; then
    echo "✅ Build artifact verified"
    
    # Check binary architecture
    file "$CI_ARCHIVE_PATH/Products/Applications/ClaudeUsageMonitor.app/Contents/MacOS/ClaudeUsageMonitor"
else
    echo "❌ Build artifact not found"
    exit 1
fi

# Run any post-build verification
# For example, checking that entitlements are correct
codesign -d --entitlements - "$CI_ARCHIVE_PATH/Products/Applications/ClaudeUsageMonitor.app" 2>/dev/null

echo "Post-build script completed"