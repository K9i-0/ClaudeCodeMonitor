#!/bin/bash

# DEPRECATED: This script is kept for backward compatibility
# Use get-next-version.sh instead for tag-based versioning

echo "WARNING: bump-version.sh is deprecated. Use get-next-version.sh instead." >&2
echo "This script will be removed in a future version." >&2

# For backward compatibility, just call get-next-version.sh
VERSION_TYPE=${1:-patch}
exec "$(dirname "$0")/get-next-version.sh" "$VERSION_TYPE"