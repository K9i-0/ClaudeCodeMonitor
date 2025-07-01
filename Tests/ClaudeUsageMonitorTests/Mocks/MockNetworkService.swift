import Foundation
@testable import ClaudeCodeMonitor

class MockNetworkService: NetworkService {
    var shouldThrowError = false
    var errorToThrow: ClaudeMonitorError?
    var mockCcusageResponse: CcusageResponse?
    var mockBlocksResponse: BlocksResponse?

    func fetchUsageData(from url: URL) async throws -> CcusageResponse {
        if shouldThrowError {
            throw errorToThrow ?? ClaudeMonitorError.networkError("Mock network error")
        }

        return mockCcusageResponse ?? CcusageResponse(
            daily: [
                DailyUsage(
                    date: Date().ISO8601Format(),
                    inputTokens: 800,
                    outputTokens: 200,
                    cacheCreationTokens: 0,
                    cacheReadTokens: 0,
                    totalTokens: 1_000,
                    totalCost: 1.50,
                    modelsUsed: ["claude-3-5-sonnet-20241022"],
                    modelBreakdowns: []
                )
            ],
            totals: Totals(
                inputTokens: 40_000,
                outputTokens: 10_000,
                cacheCreationTokens: 0,
                cacheReadTokens: 0,
                totalCost: 45.00,
                totalTokens: 50_000
            )
        )
    }

    func fetchSessionData(from url: URL) async throws -> BlocksResponse {
        if shouldThrowError {
            throw errorToThrow ?? ClaudeMonitorError.networkError("Mock network error")
        }

        return mockBlocksResponse ?? BlocksResponse(
            blocks: [
                SessionBlock(
                    id: "test-session-1",
                    startTime: Date().addingTimeInterval(-3_600).ISO8601Format(),
                    endTime: Date().addingTimeInterval(14_400).ISO8601Format(),
                    actualEndTime: nil,
                    isActive: true,
                    isGap: false,
                    entries: 10,
                    tokenCounts: TokenCounts(
                        inputTokens: 2_400,
                        outputTokens: 600,
                        cacheCreationInputTokens: 0,
                        cacheReadInputTokens: 0
                    ),
                    totalTokens: 3_000,
                    costUSD: 0.018,
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
            ]
        )
    }
}
