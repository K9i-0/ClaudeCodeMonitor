# Status Badges Configuration

Add these badges to your README.md to show build status and code quality metrics.

## GitHub Actions Badges

```markdown
![CI](https://github.com/K9i-0/ClaudeUsageMonitor/workflows/CI/badge.svg)
![Release](https://github.com/K9i-0/ClaudeUsageMonitor/workflows/Release/badge.svg)
```

## Code Coverage Badge

After setting up Codecov:
```markdown
[![codecov](https://codecov.io/gh/K9i-0/ClaudeUsageMonitor/branch/main/graph/badge.svg)](https://codecov.io/gh/K9i-0/ClaudeUsageMonitor)
```

## Swift Version Badge

```markdown
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
```

## Platform Badge

```markdown
![Platform](https://img.shields.io/badge/platform-macOS%2013.0+-blue.svg)
```

## License Badge

```markdown
![License](https://img.shields.io/github/license/K9i-0/ClaudeUsageMonitor)
```

## Release Version Badge

```markdown
![GitHub release (latest by date)](https://img.shields.io/github/v/release/K9i-0/ClaudeUsageMonitor)
```

## Complete Example

```markdown
# Claude Usage Monitor

![CI](https://github.com/K9i-0/ClaudeUsageMonitor/workflows/CI/badge.svg)
[![codecov](https://codecov.io/gh/K9i-0/ClaudeUsageMonitor/branch/main/graph/badge.svg)](https://codecov.io/gh/K9i-0/ClaudeUsageMonitor)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2013.0+-blue.svg)
![License](https://img.shields.io/github/license/K9i-0/ClaudeUsageMonitor)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/K9i-0/ClaudeUsageMonitor)
```

## Required Status Checks Summary

When configuring branch protection, require these checks:
1. `build` - Build Verification
2. `Test on macOS (15.0)` - Test suite on Xcode 15.0
3. `Test on macOS (15.2)` - Test suite on Xcode 15.2
4. `SwiftLint` - Code style check
5. `security` - Security scan

Optional (non-blocking):
- `Swift Format Check` - Code formatting (warnings only)