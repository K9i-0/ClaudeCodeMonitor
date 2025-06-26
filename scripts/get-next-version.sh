#!/bin/bash

# Get next version based on git tags
# Usage: ./get-next-version.sh [patch|minor|major]

VERSION_TYPE=${1:-patch}

# Get the latest tag (semantic version tags only)
LATEST_TAG=$(git tag -l "v*.*.*" | grep -E "^v[0-9]+\.[0-9]+\.[0-9]+$" | sort -V | tail -1)

if [ -z "$LATEST_TAG" ]; then
  # No tags found, start with v0.1.0
  echo "No semantic version tags found, starting with v0.1.0" >&2
  CURRENT_VERSION="0.0.0"
else
  # Extract version from tag (remove 'v' prefix)
  CURRENT_VERSION=${LATEST_TAG#v}
  echo "Latest tag: $LATEST_TAG (version: $CURRENT_VERSION)" >&2
fi

# Parse version components
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]:-0}"
MINOR="${VERSION_PARTS[1]:-0}"
PATCH="${VERSION_PARTS[2]:-0}"

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
    echo "Error: Invalid version type. Use 'patch', 'minor', or 'major'" >&2
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
NEW_TAG="v$NEW_VERSION"

# Check if the new tag already exists
if git rev-parse "$NEW_TAG" >/dev/null 2>&1; then
  echo "Error: Tag $NEW_TAG already exists!" >&2
  echo "Current tags:" >&2
  git tag -l "v*.*.*" | grep -E "^v[0-9]+\.[0-9]+\.[0-9]+$" | sort -V | tail -5 >&2
  exit 1
fi

# Output the new version (without 'v' prefix for version, with 'v' for tag)
echo "Next version: $NEW_VERSION" >&2
echo "Next tag: $NEW_TAG" >&2

# Output for scripts (clean output)
if [ -n "$GITHUB_OUTPUT" ]; then
  echo "version=$NEW_VERSION" >> $GITHUB_OUTPUT
  echo "tag=$NEW_TAG" >> $GITHUB_OUTPUT
else
  # For local testing, output just the version
  echo "$NEW_VERSION"
fi