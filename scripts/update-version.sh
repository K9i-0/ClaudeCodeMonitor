#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check if version argument is provided
if [ $# -eq 0 ]; then
    print_error "No version specified"
    echo "Usage: $0 <version>"
    echo "Example: $0 1.2.3"
    exit 1
fi

NEW_VERSION=$1

# Validate version format (x.y.z)
if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    print_error "Invalid version format: $NEW_VERSION"
    echo "Version must be in format x.y.z (e.g., 1.2.3)"
    exit 1
fi

# Get current version from Info.plist
CURRENT_VERSION=$(grep -A1 "CFBundleShortVersionString" Info.plist | tail -1 | sed -E 's/.*<string>(.*)<\/string>.*/\1/')

if [ -z "$CURRENT_VERSION" ]; then
    print_error "Failed to get current version from Info.plist"
    exit 1
fi

print_info "Current version: $CURRENT_VERSION"
print_info "New version: $NEW_VERSION"

# Update Info.plist
print_info "Updating Info.plist..."

# Create a temporary file
TEMP_FILE=$(mktemp)

# Update CFBundleShortVersionString
awk -v new_version="$NEW_VERSION" '
    /<key>CFBundleShortVersionString<\/key>/ {
        print
        getline
        sub(/<string>.*<\/string>/, "<string>" new_version "</string>")
    }
    { print }
' Info.plist > "$TEMP_FILE"

# Move temp file back
mv "$TEMP_FILE" Info.plist

# Verify the update
UPDATED_VERSION=$(grep -A1 "CFBundleShortVersionString" Info.plist | tail -1 | sed -E 's/.*<string>(.*)<\/string>.*/\1/')

if [ "$UPDATED_VERSION" != "$NEW_VERSION" ]; then
    print_error "Failed to update version in Info.plist"
    exit 1
fi

print_success "Updated Info.plist to version $NEW_VERSION"

# Update CHANGELOG.md if it exists
if [ -f "CHANGELOG.md" ]; then
    print_info "Checking CHANGELOG.md..."
    
    # Check if version already exists in changelog
    if grep -q "## \[$NEW_VERSION\]" CHANGELOG.md; then
        print_info "Version $NEW_VERSION already exists in CHANGELOG.md"
    else
        print_info "Adding new version section to CHANGELOG.md..."
        
        # Get today's date
        TODAY=$(date +%Y-%m-%d)
        
        # Create temporary file
        TEMP_CHANGELOG=$(mktemp)
        
        # Find the position after the header and before the first version entry
        awk -v version="$NEW_VERSION" -v date="$TODAY" '
            /^# Changelog/ { print; printed_new = 0; next }
            /^## \[/ && !printed_new {
                print ""
                print "## [" version "] - " date
                print ""
                print "### Added"
                print "- "
                print ""
                print "### Changed"
                print "- "
                print ""
                print "### Fixed"
                print "- "
                print ""
                printed_new = 1
            }
            { print }
        ' CHANGELOG.md > "$TEMP_CHANGELOG"
        
        mv "$TEMP_CHANGELOG" CHANGELOG.md
        print_success "Added version $NEW_VERSION to CHANGELOG.md"
        print_info "Please update the changelog entries before committing"
    fi
else
    print_info "No CHANGELOG.md found, skipping changelog update"
fi

# Show git status
echo ""
print_info "Git status:"
git status --short Info.plist CHANGELOG.md

# Suggest next steps
echo ""
print_success "Version updated successfully!"
echo ""
echo "Next steps:"
echo "1. Review the changes"
echo "2. Update CHANGELOG.md with actual changes (if needed)"
echo "3. Commit the changes:"
echo "   git add Info.plist CHANGELOG.md"
echo "   git commit -m \"chore: bump version to $NEW_VERSION\""
echo "4. Push to update your PR"