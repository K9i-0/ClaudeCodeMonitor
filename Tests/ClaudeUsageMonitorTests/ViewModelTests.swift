import XCTest
import SwiftUI
@testable import ClaudeUsageMonitor

@MainActor
final class ViewModelTests: XCTestCase {
    
    // MARK: - SessionViewModel Tests
    
    func testSessionViewModelInitialization() {
        // Create a mock monitor
        let mockMonitor = MockUsageMonitor()
        
        let testSession = SessionBlock(
            id: "test-123",
            startTime: Date().addingTimeInterval(-3600).ISO8601Format(),
            endTime: Date().addingTimeInterval(1800).ISO8601Format(),
            actualEndTime: nil,
            isActive: true,
            isGap: false,
            entries: 10,
            tokenCounts: TokenCounts(
                inputTokens: 2000,
                outputTokens: 1000,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 0
            ),
            totalTokens: 3000,
            costUSD: 1.50,
            models: ["claude-3.5-sonnet"],
            burnRate: BurnRate(tokensPerMinute: 50.0, costPerHour: 1.50),
            projection: Projection(
                totalTokens: 4000,
                totalCost: 2.00,
                remainingMinutes: 80
            )
        )
        
        mockMonitor.usageData.activeSession = testSession
        
        let viewModel = SessionViewModel(monitor: mockMonitor)
        
        XCTAssertEqual(viewModel.session?.id, "test-123")
        XCTAssertEqual(viewModel.remainingTokens, 4000) // 7000 - 3000 for Pro plan
    }
    
    func testSessionViewModelPercentages() {
        let mockMonitor = MockUsageMonitor()
        
        let testSession = SessionBlock(
            id: "test-123",
            startTime: Date().ISO8601Format(),
            endTime: Date().addingTimeInterval(3600).ISO8601Format(),
            actualEndTime: nil,
            isActive: true,
            isGap: false,
            entries: 10,
            tokenCounts: TokenCounts(
                inputTokens: 3500,
                outputTokens: 1750,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 0
            ),
            totalTokens: 5250,
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
            startTime: Date().addingTimeInterval(-1800).ISO8601Format(),
            endTime: Date().addingTimeInterval(1800).ISO8601Format(),
            actualEndTime: nil,
            isActive: true,
            isGap: false,
            entries: 10,
            tokenCounts: TokenCounts(
                inputTokens: 1500,
                outputTokens: 0,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 0
            ),
            totalTokens: 1500,
            costUSD: 1.00,
            models: ["claude-3.5-sonnet"],
            burnRate: BurnRate(tokensPerMinute: 50.0, costPerHour: 3.00),
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
        let mockMonitor = MockUsageMonitor()
        
        let todayUsage = DailyUsage(
            date: Date().ISO8601Format(),
            inputTokens: 1000,
            outputTokens: 500,
            cacheCreationTokens: 0,
            cacheReadTokens: 0,
            totalTokens: 1500,
            totalCost: 1.00,
            modelsUsed: ["claude-3.5-sonnet"],
            modelBreakdowns: []
        )
        
        let monthlyTotal = Totals(
            inputTokens: 40000,
            outputTokens: 10000,
            cacheCreationTokens: 0,
            cacheReadTokens: 0,
            totalCost: 45.00,
            totalTokens: 50000
        )
        
        mockMonitor.usageData.todayUsage = todayUsage
        mockMonitor.usageData.monthlyTotal = monthlyTotal
        
        let viewModel = HistoryViewModel(monitor: mockMonitor)
        
        XCTAssertEqual(viewModel.todayUsage?.totalTokens, 1500)
        XCTAssertEqual(viewModel.monthlyUsage?.totalCost, 45.00)
    }
    
    func testHistoryViewModelFormatting() {
        let mockMonitor = MockUsageMonitor()
        
        let todayUsage = DailyUsage(
            date: Date().ISO8601Format(),
            inputTokens: 1000,
            outputTokens: 500,
            cacheCreationTokens: 0,
            cacheReadTokens: 0,
            totalTokens: 1500,
            totalCost: 3.45,
            modelsUsed: ["claude-3.5-sonnet"],
            modelBreakdowns: []
        )
        
        mockMonitor.usageData.todayUsage = todayUsage
        
        let viewModel = HistoryViewModel(monitor: mockMonitor)
        
        XCTAssertEqual(viewModel.formattedTodayCost, "$3.45")
        XCTAssertEqual(viewModel.formattedTodayTokens, "1.5K")
    }
}