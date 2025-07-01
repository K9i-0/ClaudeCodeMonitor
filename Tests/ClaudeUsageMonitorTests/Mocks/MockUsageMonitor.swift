import Foundation
@testable import ClaudeCodeMonitor

@MainActor
class MockUsageMonitor: UsageMonitoring {
    var usageData = UsageData()
    var isLoading = false
    var error: ClaudeMonitorError?

    var startMonitoringCalled = false
    var stopMonitoringCalled = false
    var fetchUsageDataCalled = false
    var fetchUsageDataCallCount = 0

    func startMonitoring() {
        startMonitoringCalled = true
    }

    func stopMonitoring() {
        stopMonitoringCalled = true
    }

    func fetchUsageData() {
        fetchUsageDataCalled = true
        fetchUsageDataCallCount += 1
    }

    func formatTokens(_ tokens: Int) -> String {
        return NumberFormatters.tokenFormatter.string(for: tokens) ?? "0"
    }

    func formatCost(_ cost: Double) -> String {
        return NumberFormatters.currencyFormatter.string(for: cost) ?? "$0.00"
    }

    func setUserPlan(_ plan: String) {
        usageData.detectedPlanType = plan
    }

    func getUserPlan() -> String {
        return usageData.detectedPlanType ?? "Pro"
    }

    // Test helpers
    func setTestData(
        todayTokens: Int = 1_000,
        todayCost: Double = 1.50,
        monthlyTokens: Int = 50_000,
        monthlyCost: Double = 45.00,
        activeSessionTokens: Int = 3_000,
        planType: String = "Pro"
    ) {
        usageData.todayUsage = DailyUsage(
            date: Date().ISO8601Format(),
            inputTokens: todayTokens * 4 / 5,
            outputTokens: todayTokens / 5,
            cacheCreationTokens: 0,
            cacheReadTokens: 0,
            totalTokens: todayTokens,
            totalCost: todayCost,
            modelsUsed: ["claude-3-5-sonnet-20241022"],
            modelBreakdowns: []
        )

        usageData.monthlyTotal = Totals(
            inputTokens: monthlyTokens * 4 / 5,
            outputTokens: monthlyTokens / 5,
            cacheCreationTokens: 0,
            cacheReadTokens: 0,
            totalCost: monthlyCost,
            totalTokens: monthlyTokens
        )

        if activeSessionTokens > 0 {
            let now = Date()
            let startTime = now.addingTimeInterval(-3_600) // 1 hour ago
            let endTime = now.addingTimeInterval(14_400) // 4 hours from start

            usageData.activeSession = SessionBlock(
                id: "test-session",
                startTime: startTime.ISO8601Format(),
                endTime: endTime.ISO8601Format(),
                actualEndTime: nil,
                isActive: true,
                isGap: false,
                entries: 10,
                tokenCounts: TokenCounts(
                    inputTokens: activeSessionTokens * 4 / 5,
                    outputTokens: activeSessionTokens / 5,
                    cacheCreationInputTokens: 0,
                    cacheReadInputTokens: 0
                ),
                totalTokens: activeSessionTokens,
                costUSD: Double(activeSessionTokens) * 0.000006,
                models: ["claude-3-5-sonnet-20241022"],
                burnRate: BurnRate(
                    tokensPerMinute: 50.0,
                    costPerHour: 0.18
                ),
                projection: Projection(
                    totalTokens: 7_000,
                    totalCost: 0.042,
                    remainingMinutes: 80
                )
            )
        }

        usageData.detectedPlanType = planType
    }
}
