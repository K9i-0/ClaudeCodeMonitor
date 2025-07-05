#!/bin/bash

set -e

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install it (brew install jq)."
    exit 1
fi

# Get paths
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_DIR=$(dirname "$SCRIPT_DIR")
PACKAGE_JSON_PATH="$PROJECT_DIR/package.json"
INFO_PLIST_PATH="$PROJECT_DIR/Info.plist"

# Extract version from package.json
CCUSAGE_VERSION=$(jq -r '.dependencies.ccusage' "$PACKAGE_JSON_PATH")

if [ -z "$CCUSAGE_VERSION" ]; then
    echo "Could not find ccusage version in package.json"
    exit 1
fi

# Update Info.plist
plutil -replace CcusageVersion -string "$CCUSAGE_VERSION" "$INFO_PLIST_PATH"

echo "Successfully updated Info.plist with ccusage version: $CCUSAGE_VERSION"
