import XCTest
import SwiftUI
@testable import ClaudeCodeMonitor

final class UtilitiesTests: XCTestCase {
    // MARK: - Date Extension Tests

    func testFormatTimeFromISOString() {
        let isoString = "2025-01-23T14:30:00Z"
        let formatted = Date.formatTime(from: isoString)

        // Note: The exact output depends on the system timezone
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertNotEqual(formatted, isoString)
    }

    func testFormatTimeWithInvalidString() {
        let invalidString = "not-a-date"
        let formatted = Date.formatTime(from: invalidString)

        // Should return the original string when parsing fails
        XCTAssertEqual(formatted, invalidString)
    }

    func testGetElapsedTime() {
        // Skip locale-dependent tests in CI environment
        guard ProcessInfo.processInfo.environment["CI"] == nil else {
            print("Skipping locale-dependent test in CI environment")
            return
        }

        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3_600).ISO8601Format()
        let elapsed = Date.getElapsedTime(from: oneHourAgo)

        // In test environment, localization returns the key
        // Check that we get the expected localization key
        XCTAssertEqual(elapsed, "time.hoursMinutes")
    }

    func testGetElapsedTimeMinutesOnly() {
        // Skip locale-dependent tests in CI environment
        guard ProcessInfo.processInfo.environment["CI"] == nil else {
            print("Skipping locale-dependent test in CI environment")
            return
        }

        let now = Date()
        let thirtyMinutesAgo = now.addingTimeInterval(-1_800).ISO8601Format()
        let elapsed = Date.getElapsedTime(from: thirtyMinutesAgo)

        // In test environment, localization returns the key
        // Check that we get the expected localization key
        XCTAssertEqual(elapsed, "time.minutes")
        XCTAssertFalse(
            elapsed.contains("時間") ||
            elapsed.contains("hour")
        )
    }

    // MARK: - Color Extension Tests

    func testUsageColorGradient() {
        // Test color transitions
        XCTAssertEqual(Color.usageColor(for: 0), .blue)
        XCTAssertEqual(Color.usageColor(for: 25), .blue)
        XCTAssertEqual(Color.usageColor(for: 50), .blue)
        XCTAssertEqual(Color.usageColor(for: 75), .orange)
        XCTAssertEqual(Color.usageColor(for: 90), .red)
        XCTAssertEqual(Color.usageColor(for: 100), .red)
    }

    func testProgressGradient() {
        let gradient = Color.progressGradient(for: 50)
        XCTAssertNotNil(gradient)
    }

    // MARK: - SF Symbol Tests

    func testGetSFSymbol() {
        XCTAssertEqual(SFSymbols.getSFSymbol(for: 0), "circle.fill")
        XCTAssertEqual(SFSymbols.getSFSymbol(for: 25), "circle.fill")
        XCTAssertEqual(SFSymbols.getSFSymbol(for: 50), "flame.fill")
        XCTAssertEqual(SFSymbols.getSFSymbol(for: 75), "bolt.fill")
        XCTAssertEqual(SFSymbols.getSFSymbol(for: 90), "exclamationmark.triangle.fill")
        XCTAssertEqual(SFSymbols.getSFSymbol(for: 100), "exclamationmark.triangle.fill")
    }

    // MARK: - Number Formatter Tests

    func testTokenFormatter() {
        let formatter = NumberFormatters.tokenFormatter

        XCTAssertEqual(formatter.string(for: 1_000), "1,000")
        XCTAssertEqual(formatter.string(for: 1_000_000), "1,000,000")
        XCTAssertEqual(formatter.string(for: 0), "0")
    }

    func testCurrencyFormatter() {
        let formatter = NumberFormatters.currencyFormatter

        // Note: Currency formatting depends on locale
        XCTAssertNotNil(formatter.string(for: 10.50))
        XCTAssertNotNil(formatter.string(for: 0))
        XCTAssertTrue(formatter.string(for: 10.50)?.contains("10") ?? false)
    }

    func testPercentFormatter() {
        let formatter = NumberFormatters.percentFormatter

        XCTAssertEqual(formatter.string(for: 0.5), "50%")
        XCTAssertEqual(formatter.string(for: 0.756), "75.6%")
        XCTAssertEqual(formatter.string(for: 1.0), "100%")
    }

    func testCompactNumberFormatter() {
        // Use the static method instead of formatter
        XCTAssertEqual(NumberFormatters.formatTokens(1_000), "1.0K")
        XCTAssertEqual(NumberFormatters.formatTokens(1_500), "1.5K")
        XCTAssertEqual(NumberFormatters.formatTokens(1_000_000), "1.0M")
    }

    // MARK: - Error Type Tests

    func testClaudeMonitorErrorDescriptions() {
        // Skip locale-dependent tests in CI environment
        guard ProcessInfo.processInfo.environment["CI"] == nil else {
            print("Skipping locale-dependent test in CI environment")
            return
        }

        let networkError = ClaudeMonitorError.networkError("Connection failed")
        XCTAssertEqual(networkError.errorDescription, "ネットワークエラー: Connection failed")

        let parsingError = ClaudeMonitorError.parsingError("Invalid JSON")
        XCTAssertEqual(parsingError.errorDescription, "データ解析エラー: Invalid JSON")

        let commandError = ClaudeMonitorError.commandExecutionError("Command not found")
        XCTAssertEqual(commandError.errorDescription, "コマンド実行エラー: Command not found")

        let fileError = ClaudeMonitorError.fileNotFound("/path/to/file")
        XCTAssertEqual(fileError.errorDescription, "ファイルが見つかりません: /path/to/file")

        let unknownError = ClaudeMonitorError.unknownError("Something went wrong")
        XCTAssertEqual(unknownError.errorDescription, "不明なエラー: Something went wrong")
    }

    func testClaudeMonitorErrorRecoverySuggestions() {
        // Skip locale-dependent tests in CI environment
        guard ProcessInfo.processInfo.environment["CI"] == nil else {
            print("Skipping locale-dependent test in CI environment")
            return
        }

        let networkError = ClaudeMonitorError.networkError("Connection failed")
        XCTAssertEqual(networkError.recoverySuggestion, "インターネット接続を確認してください")

        let parsingError = ClaudeMonitorError.parsingError("Invalid JSON")
        XCTAssertEqual(parsingError.recoverySuggestion, "ccusageが最新バージョンであることを確認してください")

        let commandError = ClaudeMonitorError.commandExecutionError("Command not found")
        XCTAssertEqual(commandError.recoverySuggestion, "Node.jsまたはBunが正しくインストールされているか確認してください")
    }

    // MARK: - Constants Tests

    func testConstants() {
        XCTAssertEqual(Constants.Timing.refreshInterval, 300) // 5 minutes
        XCTAssertEqual(Constants.Timing.animationDuration, 0.3)
        XCTAssertEqual(Constants.Timing.longAnimationDuration, 0.5)
    }
}
