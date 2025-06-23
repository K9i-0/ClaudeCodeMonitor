#!/bin/sh

# Xcode Cloud Post-Clone Script
# This script runs after Xcode Cloud clones your repository

echo "Running Xcode Cloud post-clone script..."

# Set up environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Install any required dependencies
# brew install swiftlint # If needed

# Copy any required files or configurations
# For example, if you have environment-specific configurations

# Set build number based on Xcode Cloud's CI_BUILD_NUMBER
if [ -n "$CI_BUILD_NUMBER" ]; then
    echo "Setting build number to $CI_BUILD_NUMBER"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CI_BUILD_NUMBER" "$CI_WORKSPACE/Info.plist"
fi

# Set version number if provided
if [ -n "$CI_TAG" ]; then
    # Extract version from tag (assumes tags like v1.0.0)
    VERSION=$(echo $CI_TAG | sed 's/^v//')
    echo "Setting version to $VERSION"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CI_WORKSPACE/Info.plist"
fi

echo "Post-clone script completed"