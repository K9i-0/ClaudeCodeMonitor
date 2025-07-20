# ClaudeCodeMonitor Release Strategy

## Overview

This document outlines the release strategy for ClaudeCodeMonitor, including versioning, branching, and distribution channels.

## Branch Strategy

### 1. Main Branch (`main`)
- **Purpose**: Stable, production-ready code
- **Protection**: Protected branch with required PR reviews
- **CI/CD**: Automatically creates stable releases on push
- **Version**: Uses version from Info.plist as-is (e.g., `1.2.3`)

### 2. Development Branch (`develop`)
- **Purpose**: Integration branch for features
- **Merges**: Feature branches merge here first
- **Testing**: Development builds distributed for testing
- **CI/CD**: Automatically creates dev releases on push
- **Version**: Adds `-dev` suffix (e.g., `1.2.3-dev`)

### 3. Feature Branches (`feature/*`)
- **Purpose**: Individual feature development
- **Naming**: `feature/feature-name` (e.g., `feature/add-sparkle-auto-update`)
- **Lifecycle**: Created from `develop`, merged back to `develop`
- **Requirement**: Must update version in Info.plist before merging

### 4. Hotfix Branches (`hotfix/*`)
- **Purpose**: Emergency fixes for production
- **Naming**: `hotfix/fix-description`
- **Process**: Created from `main`, merged to both `main` and `develop`
- **Requirement**: Must increment version and update CHANGELOG

## Version Management

### Version Update Rules
1. **feature → develop**: Version must be incremented in Info.plist
2. **develop → main**: Version remains the same (only removes `-dev` suffix)
3. **hotfix → main**: Version must be incremented

### Version Format
- **Info.plist**: Always contains the base version (e.g., `1.2.3`)
- **Development builds**: Append `-dev` during build (e.g., `1.2.3-dev`)
- **Stable builds**: Use version as-is (e.g., `1.2.3`)

### Development Versions
- **Purpose**: Testing and preview builds
- **Format**: `1.2.3-dev`
- **Distribution**: GitHub pre-releases

## Release Process

### 1. Feature Development Flow
```
feature/xxx → develop → automatic dev release
```

1. Create feature branch from `develop`
2. Implement feature
3. **Update version in Info.plist** (required)
4. Create PR to `develop`
5. After merge, `1.2.3-dev` is automatically released

### 2. Stable Release Flow
```
develop → main → automatic stable release
```

1. Create PR from `develop` to `main`
2. Update CHANGELOG.md (required)
3. Version stays the same in Info.plist
4. After merge, `1.2.3` is automatically released

### 3. Hotfix Flow
```
main → hotfix/xxx → main + develop
```

1. Create hotfix branch from `main`
2. Fix critical issue
3. **Update version** (increment PATCH)
4. **Update CHANGELOG.md**
5. Merge to `main` first (automatic release)
6. Merge to `develop` to sync

## CI/CD Configuration

### GitHub Actions Workflows

#### 1. Development Release (`release-dev.yml`)
- **Trigger**: Push to `develop` branch
- **Action**: Build and release with `-dev` suffix
- **Output**: `ClaudeCodeMonitor-1.2.3-dev.dmg`

#### 2. Stable Release (`release-stable.yml`)
- **Trigger**: Push to `main` branch
- **Action**: Build and release stable version
- **Output**: `ClaudeCodeMonitor-1.2.3.dmg`
- **Note**: Skips if version tag already exists

#### 3. PR Validation (`pr-validation.yml`)
- **Trigger**: PR to `develop` or `main`
- **Checks**:
  - Version update for feature → develop
  - CHANGELOG update for develop → main
  - Conventional commit format (warning only)

#### 4. Version Helper (`version-helper.yml`)
- **Trigger**: PR opened to `develop` or `main`
- **Action**: Posts helpful comment with:
  - Current version info
  - Commit analysis
  - Update instructions

#### 5. Build & Test (`build.yml`)
- **Trigger**: Push/PR to `main` or `develop`
- **Action**: Run swift build and tests

## Sparkle Update Configuration

### Update Channels

#### 1. Stable Channel (Production)
- **Feed URL**: `https://your-domain.com/appcast.xml`
- **Versions**: Only stable releases (e.g., `1.2.3`)
- **Users**: Default for all users

#### 2. Development Channel (Testing)
- **Feed URL**: `https://your-domain.com/appcast-dev.xml`
- **Versions**: Dev releases + stable releases
- **Users**: Opt-in for development builds
- **Setting**: Toggle in app preferences

### Channel Selection
```swift
// User can choose update channel in settings
enum UpdateChannel {
    case stable   // appcast.xml
    case dev      // appcast-dev.xml
}
```

## Distribution Strategy

### 1. GitHub Releases
- **Stable**: Tagged releases on `main`
- **Beta**: Pre-release flag enabled
- **Assets**: DMG, release notes, checksums

### 2. Homebrew Cask
- **Updates**: Only stable releases
- **Process**: Automated PR via GitHub Actions
- **Timing**: After successful release

### 3. Direct Download
- **Website**: Link to latest GitHub release
- **Auto-update**: Via Sparkle

## Testing Sparkle in Development

### Environment Variable Method
```bash
# Enable Sparkle in debug build
TEST_SPARKLE=1 swift run

# Or in Xcode
# Edit Scheme → Run → Arguments → Environment Variables
# Add: TEST_SPARKLE = 1
```

This allows testing Sparkle functionality without creating release builds.

## Recommended Workflow

### For New Features
1. Create feature branch from `develop`
2. Implement and test locally
3. **Update version** using `./scripts/update-version.sh x.y.z`
4. Create PR to `develop`
5. After merge, dev version is automatically released
6. Test with dev build
7. When ready for stable, PR `develop` → `main`

### For Urgent Fixes
1. Create hotfix from `main`
2. Fix and test
3. **Update version** (increment patch)
4. **Update CHANGELOG.md**
5. PR to `main` (automatic release on merge)
6. Merge to `develop` to sync

### Version Update Helper Script
```bash
# Update version easily
./scripts/update-version.sh 1.2.3

# This will:
# - Update Info.plist
# - Add placeholder to CHANGELOG.md
# - Show git status
# - Suggest commit command
```

## Security Considerations

### Code Signing
- **Development**: Ad-hoc signing for testing
- **Beta**: Developer ID for distribution
- **Production**: Developer ID + Notarization

### Sparkle Security
- **EdDSA Key**: Required for secure updates
- **HTTPS**: Always use HTTPS for appcast
- **Verification**: Sparkle verifies signatures automatically