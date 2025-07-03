# CI/CD Pipeline Documentation

## Overview

ClaudeCodeMonitor uses GitHub Actions for continuous integration and deployment. This document helps contributors understand the CI/CD pipeline.

## Workflows

### 1. CI Workflow (`.github/workflows/ci.yml`)

**Trigger**: Push to `main` branch or Pull Requests targeting `main`

**Purpose**: Ensure code quality and test coverage

**Jobs**:
- **Build**: Verifies the project builds in both debug and release modes
- **Test**: Runs on multiple Xcode versions (15.0, 15.2)
  - Executes all unit tests
  - Generates code coverage reports
- **SwiftLint**: Checks code style and conventions
- **Security**: Basic security scanning for hardcoded secrets
- **Format Check**: Swift-format validation (warnings only)

### 2. Release Workflow (`.github/workflows/release.yml`)

**Trigger**: Push of tags matching `v*` (e.g., `v1.0.0`, `v2.1.0-beta`)

**Purpose**: Automatically build and release the application

**Features**:
- Builds universal binary (Intel + Apple Silicon)
- Creates DMG installer
- Generates changelog from commit messages
- Creates GitHub Release
- Optional code signing and notarization

### 3. Dependabot

Automatically creates PRs for dependency updates weekly.

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

## Contributing

When submitting a PR:
1. Ensure all CI checks pass
2. Follow SwiftLint rules
3. Add tests for new features
4. Update documentation as needed

The CI pipeline will automatically validate your changes.