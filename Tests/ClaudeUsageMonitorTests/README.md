# ClaudeUsageMonitor Tests

This directory contains the test suite for ClaudeUsageMonitor.

## Test Structure

### Unit Tests
- **ModelsTests.swift**: Tests for data models and JSON decoding
- **SessionModelsTests.swift**: Tests for session-related models and calculations
- **UtilitiesTests.swift**: Tests for utility functions and formatters
- **LanguageSettingsTests.swift**: Tests for language/localization settings
- **NotificationManagerTests.swift**: Tests for notification settings (limited due to bundle requirements)

### Integration Tests
- **UsageMonitorTests.swift**: Tests for the main UsageMonitor class
- **ViewModelTests.swift**: Tests for view models

### Mocks
- **MockUsageMonitor.swift**: Mock implementation of UsageMonitoring protocol
- **MockNetworkService.swift**: Mock for network operations

## Running Tests

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter ModelsTests

# Run multiple test suites
swift test --filter "ModelsTests|SessionModelsTests"
```

## Test Coverage

Current test coverage includes:
- ✅ Data model encoding/decoding
- ✅ Session calculations and limits
- ✅ Number formatting and utilities
- ✅ Language settings persistence
- ✅ Basic notification settings
- ✅ Plan management
- ⚠️ Limited network operation testing (requires mocking)
- ⚠️ Limited UI testing (requires XCTest UI framework)

## Known Issues

- NotificationManager tests are limited due to bundle environment requirements
- Network operations in UsageMonitor can cause issues in test environment
- Some tests require running the local server