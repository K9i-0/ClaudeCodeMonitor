import XCTest
import SwiftUI
@testable import ClaudeCodeMonitor

@MainActor
final class ViewModelTests: XCTestCase {
    // MARK: - SessionViewModel Tests

    func testSessionViewModelInitialization() {
        // Create a mock monitor
        let mockMonitor = MockUsageMonitor()

        let testSession = SessionBlock(
            id: "test-123",
            startTime: Date().addingTimeInterval(-3_600).ISO8601Format(),
            endTime: Date().addingTimeInterval(1_800).ISO8601Format(),
            actualEndTime: nil,
            isActive: true,
            isGap: false,
            entries: 10,
            tokenCounts: TokenCounts(
                inputTokens: 2_000,
                outputTokens: 1_000,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 0
            ),
            totalTokens: 3_000,
            costUSD: 1.50,
            models: ["claude-3.5-sonnet"],
            burnRate: BurnRate(tokensPerMinute: 50.0, costPerHour: 1.50),
            projection: Projection(
                totalTokens: 4_000,
                totalCost: 2.00,
                remainingMinutes: 80
            )
        )

        mockMonitor.usageData.activeSession = testSession

        let viewModel = SessionViewModel(monitor: mockMonitor)

        XCTAssertEqual(viewModel.session?.id, "test-123")
        XCTAssertEqual(viewModel.remainingTokens, 4_000) // 7000 - 3000 for Pro plan
    }

    func testSessionViewModelPercentages() {
        let mockMonitor = MockUsageMonitor()

        let testSession = SessionBlock(
            id: "test-123",
            startTime: Date().ISO8601Format(),
            endTime: Date().addingTimeInterval(3_600).ISO8601Format(),
            actualEndTime: nil,
            isActive: true,
            isGap: false,
            entries: 10,
            tokenCounts: TokenCounts(
                inputTokens: 3_500,
                outputTokens: 1_750,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 0
            ),
            totalTokens: 5_250,
            costUSD: 2.50,
            models: ["claude-3.5-sonnet"],
            burnRate: nil,
            projection: nil
        )

        mockMonitor.usageData.activeSession = testSession

        let viewModel = SessionViewModel(monitor: mockMonitor)

        // 5250 / 7000 = 75%
        XCTAssertEqual(viewModel.percentage, 75.0, accuracy: 0.1)
    }

    func testSessionViewModelBurnRate() {
        let mockMonitor = MockUsageMonitor()

        let testSession = SessionBlock(
            id: "test-123",
            startTime: Date().addingTimeInterval(-1_800).ISO8601Format(),
            endTime: Date().addingTimeInterval(1_800).ISO8601Format(),
            actualEndTime: nil,
            isActive: true,
            isGap: false,
            entries: 10,
            tokenCounts: TokenCounts(
                inputTokens: 1_500,
                outputTokens: 0,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 0
            ),
            totalTokens: 1_500,
            costUSD: 1.00,
            models: ["claude-3.5-sonnet"],
            burnRate: BurnRate(tokensPerMinute: 50_000.0, costPerHour: 3.00),
            projection: nil
        )

        mockMonitor.usageData.activeSession = testSession
        mockMonitor.usageData.detectedPlanType = "Pro"

        let viewModel = SessionViewModel(monitor: mockMonitor)

        // Burn rate from the session data
        XCTAssertEqual(viewModel.burnRate, 50.0, accuracy: 1.0)
    }

    // MARK: - HistoryViewModel Tests

    func testHistoryViewModelInitialization() {
        let viewModel = HistoryViewModel()

        // 初期状態のテスト
        XCTAssertEqual(viewModel.dailyData.count, 0)
        XCTAssertNil(viewModel.monthlyTotals)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.selectedMonth)
    }

    func testHistoryViewModelMonthNavigation() {
        let viewModel = HistoryViewModel()

        // 前月への移動
        viewModel.previousMonth()
        let previousMonth = viewModel.selectedMonth

        // 翌月への移動
        viewModel.nextMonth()
        let nextMonth = viewModel.selectedMonth

        // 月が正しく変更されているか確認
        let calendar = Calendar.current
        let monthsBetween = calendar.dateComponents([.month], from: previousMonth, to: nextMonth).month
        XCTAssertEqual(monthsBetween, 1)
    }

    func testHistoryViewModelComputedProperties() {
        let viewModel = HistoryViewModel()

        // 月の説明文字列が正しいフォーマットか確認
        XCTAssertFalse(viewModel.monthDescription.isEmpty)
        XCTAssertTrue(viewModel.monthDescription.contains("年"))
        XCTAssertTrue(viewModel.monthDescription.contains("月"))

        // 初期状態での計算プロパティ
        XCTAssertEqual(viewModel.monthlyTotalCost, 0)
        XCTAssertEqual(viewModel.monthlyTotalTokens, 0)
        XCTAssertEqual(viewModel.dailyAverage, 0)
        XCTAssertNil(viewModel.peakDay)
    }
}
