#!/bin/bash

# Bump version script for Claude Code Monitor
# Usage: ./bump-version.sh [patch|minor|major]

VERSION_TYPE=${1:-patch}

# Get current version from Info.plist
CURRENT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist)

if [ -z "$CURRENT_VERSION" ]; then
  echo "Error: Could not read current version from Info.plist"
  exit 1
fi

echo "Current version: $CURRENT_VERSION"

# Parse version components
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Increment version based on type
case "$VERSION_TYPE" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Error: Invalid version type. Use 'patch', 'minor', or 'major'"
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "New version: $NEW_VERSION"

# Update Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_VERSION" Info.plist

# Update Package.swift version comment (optional)
if [ -f "Package.swift" ]; then
  # Add or update version comment at the top of the file
  if grep -q "// Version:" Package.swift; then
    sed -i '' "s|// Version:.*|// Version: $NEW_VERSION|" Package.swift
  else
    sed -i '' "1i\\
// Version: $NEW_VERSION\\
" Package.swift
  fi
fi

echo "✅ Version updated to $NEW_VERSION"
echo "NEW_VERSION=$NEW_VERSION" >> $GITHUB_OUTPUT