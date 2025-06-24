import XCTest
@testable import ClaudeCodeMonitor

final class SessionModelsTests: XCTestCase {
    
    func testSessionTokenLimits() {
        XCTAssertEqual(UsageData.proSessionTokenLimit, 7_000)
        XCTAssertEqual(UsageData.max5SessionTokenLimit, 35_000)
        XCTAssertEqual(UsageData.max20SessionTokenLimit, 140_000)
    }
    
    func testSessionTokenLimitForProPlan() {
        var usageData = UsageData()
        usageData.detectedPlanType = "Pro"
        XCTAssertEqual(usageData.sessionTokenLimit, 7_000)
    }
    
    func testSessionTokenLimitForMax5Plan() {
        var usageData = UsageData()
        usageData.detectedPlanType = "Max5"
        XCTAssertEqual(usageData.sessionTokenLimit, 35_000)
    }
    
    func testSessionTokenLimitForMax20Plan() {
        var usageData = UsageData()
        usageData.detectedPlanType = "Max20"
        XCTAssertEqual(usageData.sessionTokenLimit, 140_000)
    }
    
    func testSessionTokenLimitAutoDetection() {
        var usageData = UsageData()
        
        // Test Pro detection (default)
        usageData.historicalMaxTokens = 4_000
        XCTAssertEqual(usageData.sessionTokenLimit, 7_000)
        
        // Test Max5 detection
        usageData.historicalMaxTokens = 10_000
        XCTAssertEqual(usageData.sessionTokenLimit, 35_000)
        
        // Test Max20 detection - need more than 35,000 tokens
        usageData.historicalMaxTokens = 40_000
        XCTAssertEqual(usageData.sessionTokenLimit, 140_000)
    }
    
    func testSessionUsagePercentage() {
        var usageData = UsageData()
        usageData.detectedPlanType = "Pro"
        
        // No active session
        XCTAssertEqual(usageData.sessionUsagePercentage, 0)
        
        // Active session with 3000 tokens used
        usageData.activeSession = createMockSession(totalTokens: 3000)
        XCTAssertEqual(usageData.sessionUsagePercentage, 42.86, accuracy: 0.01)
    }
    
    func testRemainingSessionTokens() {
        var usageData = UsageData()
        usageData.detectedPlanType = "Max5"
        
        // No active session - should return full limit
        XCTAssertEqual(usageData.remainingSessionTokens, 35_000)
        
        // Active session with 10000 tokens used
        usageData.activeSession = createMockSession(totalTokens: 10_000)
        XCTAssertEqual(usageData.remainingSessionTokens, 25_000)
    }
    
    func testTokenCountsBillableTokens() {
        let tokenCounts = TokenCounts(
            inputTokens: 1000,
            outputTokens: 500,
            cacheCreationInputTokens: 200,
            cacheReadInputTokens: 100
        )
        
        // Billable tokens should only include input and output
        XCTAssertEqual(tokenCounts.billableTokens, 1500)
    }
    
    func testSessionBlockConversion() {
        let session = createMockSession(totalTokens: 5000)
        
        // Test conversion protocol
        XCTAssertEqual(session.toSessionBlock().id, session.id)
        XCTAssertEqual(session.toSessionBlock().totalTokens, session.totalTokens)
    }
    
    // MARK: - Helper Methods
    
    private func createMockSession(totalTokens: Int) -> SessionBlock {
        let now = Date()
        return SessionBlock(
            id: "test-session",
            startTime: now.addingTimeInterval(-3600).ISO8601Format(),
            endTime: now.addingTimeInterval(14400).ISO8601Format(),
            actualEndTime: nil,
            isActive: true,
            isGap: false,
            entries: 10,
            tokenCounts: TokenCounts(
                inputTokens: totalTokens * 4 / 5,
                outputTokens: totalTokens / 5,
                cacheCreationInputTokens: 0,
                cacheReadInputTokens: 0
            ),
            totalTokens: totalTokens,
            costUSD: Double(totalTokens) * 0.000006,
            models: ["claude-3-5-sonnet-20241022"],
            burnRate: BurnRate(
                tokensPerMinute: 50.0,
                costPerHour: 0.18
            ),
            projection: Projection(
                totalTokens: 7000,
                totalCost: 0.042,
                remainingMinutes: 80
            )
        )
    }
}