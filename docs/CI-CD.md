# CI/CD Pipeline Documentation

## Overview

Claude Usage Monitor uses GitHub Actions for continuous integration and deployment. This document describes the various workflows and how to use them.

## Workflows

### 1. CI Workflow (`.github/workflows/ci.yml`)

**Trigger**: Push to `main` branch or Pull Requests targeting `main`

**Purpose**: Ensure code quality and test coverage

**Jobs**:
- **Test**: Runs on multiple Xcode versions (15.0, 15.2)
  - Builds the project
  - Runs all tests with code coverage
  - Uploads coverage reports to Codecov
- **Lint**: Runs SwiftLint to check code style
- **Format Check**: Ensures code follows swift-format rules

### 2. Release Workflow (`.github/workflows/release.yml`)

**Trigger**: Push of tags matching `v*` (e.g., `v1.0.0`, `v2.1.0-beta`)

**Purpose**: Build, sign, notarize, and release the application

**Features**:
- Builds universal binary (Intel + Apple Silicon)
- Code signing (when certificates are available)
- Notarization for macOS Gatekeeper
- Automatic changelog generation
- Creates GitHub Release with DMG attachment
- Supports prerelease versions (beta/alpha)

### 3. Dependabot

**Configuration**: `.github/dependabot.yml`

**Purpose**: Keep dependencies up to date

**Monitors**:
- GitHub Actions
- Swift Package Manager dependencies

**Schedule**: Weekly on Mondays at 9:00 AM JST

## Setting up Secrets

For full functionality, configure these secrets in your GitHub repository:

### For Code Signing and Notarization:
- `MACOS_CERTIFICATE`: Base64 encoded .p12 certificate
- `MACOS_CERTIFICATE_PWD`: Password for the certificate
- `MACOS_CERTIFICATE_NAME`: Certificate name for codesign (e.g., "Developer ID Application: Your Name")
- `APPLE_ID`: Apple ID for notarization
- `APPLE_ID_PASSWORD`: App-specific password for notarization
- `APPLE_TEAM_ID`: Your Apple Developer Team ID

### For Code Coverage:
- `CODECOV_TOKEN`: Token from codecov.io

## Local Development

### Running Tests Locally
```bash
swift test
```

### Running SwiftLint Locally
```bash
swiftlint
```

### Running swift-format Locally
```bash
# Check formatting
swift-format lint --recursive Sources Tests

# Auto-fix formatting
swift-format format --recursive Sources Tests -i
```

## Release Process

1. Ensure all tests pass on `main` branch
2. Update version in appropriate files
3. Create and push a tag:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```
4. GitHub Actions will automatically:
   - Build the universal binary
   - Sign and notarize (if configured)
   - Create DMG
   - Generate changelog
   - Create GitHub Release

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes
3. Ensure tests pass locally
4. Run linters locally
5. Create PR using the template
6. Wait for CI checks to pass
7. Request review from code owners

## Troubleshooting

### CI Tests Failing
- Check if running in CI environment affects your code
- Use `ProcessInfo.processInfo.environment["CI"]` to detect CI environment
- Some UI/system features may not work in CI

### Code Signing Issues
- Ensure all secrets are properly configured
- Certificate must be valid Developer ID Application certificate
- Check certificate expiration date

### Notarization Issues
- Use app-specific password, not regular Apple ID password
- Ensure app is properly signed before notarization
- Check Apple's notarization service status