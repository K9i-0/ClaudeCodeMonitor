# Xcode Cloud Setup for TestFlight Distribution

This document describes how to set up Xcode Cloud for automatic TestFlight distribution.

## Prerequisites

1. Apple Developer Program membership
2. App Store Connect access
3. Valid signing certificates and provisioning profiles

## Initial Setup

### 1. Create App ID

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to Certificates, Identifiers & Profiles
3. Create new App ID with bundle identifier: `com.k9i.claude-usage-monitor`
4. Enable required capabilities:
   - App Sandbox
   - Hardened Runtime

### 2. Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create new macOS app
3. Set bundle ID to `com.k9i.claude-usage-monitor`
4. Configure app information

### 3. Configure Xcode Cloud

1. Open project in Xcode
2. Navigate to Product → Xcode Cloud
3. Set up new workflow with these settings:

#### Workflow: TestFlight Release

**Environment:**
- **Name**: TestFlight Release
- **Environment**: macOS

**Start Conditions:**
- **Source**: Tag
- **Condition**: Tags starting with `v`
- **Branch**: main

**Actions:**
1. **Archive - macOS**
   - **Scheme**: ClaudeUsageMonitor
   - **Platform**: macOS
   - **Distribution**: TestFlight (Internal Testing)

**Post-Actions:**
- **TestFlight Internal Testing**: Automatic
- **Notify**: Team members when build is available

### 4. Custom Build Scripts

Xcode Cloud will automatically detect and run scripts in the `ci_scripts` directory:

- `ci_post_clone.sh`: Runs after repository clone
  - Sets build number from CI_BUILD_NUMBER
  - Sets version from git tag
  
- `ci_post_xcodebuild.sh`: Runs after build completion
  - Verifies build artifacts
  - Checks binary architecture

### 5. Environment Variables

Configure these in Xcode Cloud settings if needed:

- `MARKETING_VERSION`: Override CFBundleShortVersionString
- `CURRENT_PROJECT_VERSION`: Override CFBundleVersion

## Workflow

### Automatic TestFlight Distribution

1. Create and push a version tag:
   ```bash
   git tag -a v1.0.0 -m "Version 1.0.0"
   git push origin v1.0.0
   ```

2. Xcode Cloud automatically:
   - Builds the app
   - Archives with proper signing
   - Uploads to TestFlight
   - Notifies internal testers

### Manual Builds

You can also trigger builds manually from Xcode or App Store Connect.

## Testing Groups

Configure testing groups in App Store Connect:

1. **Internal Testing**
   - Automatic distribution
   - Up to 100 testers
   - No review required

2. **External Testing** (optional)
   - Manual submission
   - Up to 10,000 testers
   - Requires TestFlight review

## Troubleshooting

### Build Failures

1. Check Xcode Cloud logs in App Store Connect
2. Verify signing certificates are valid
3. Ensure provisioning profiles include all capabilities

### Distribution Issues

1. Verify app metadata in App Store Connect
2. Check export compliance settings
3. Ensure TestFlight agreements are signed

## Best Practices

1. **Version Management**
   - Use semantic versioning (e.g., 1.0.0)
   - Tag format: `v1.0.0`
   - Build numbers auto-increment via CI_BUILD_NUMBER

2. **Testing**
   - Test each build internally before external distribution
   - Include release notes for testers
   - Monitor crash reports and feedback

3. **Security**
   - Never commit signing certificates to repository
   - Use Xcode Cloud's managed signing when possible
   - Enable App Sandbox and Hardened Runtime

## Integration with GitHub Actions

While Xcode Cloud handles TestFlight distribution, GitHub Actions continues to handle:
- Pull request checks
- Code quality (SwiftLint, tests)
- GitHub Releases with DMG files
- Homebrew distribution

This provides a comprehensive CI/CD pipeline:
- **GitHub Actions**: Open source distribution
- **Xcode Cloud**: App Store/TestFlight distribution