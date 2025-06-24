import XCTest
@testable import ClaudeCodeUsageMonitor

final class ModelsTests: XCTestCase {
    
    // MARK: - UsageData Tests
    
    func testUsageDataBillableTokens() {
        var usageData = UsageData()
        
        // Test with no data
        XCTAssertEqual(usageData.todayBillableTokens, 0)
        XCTAssertEqual(usageData.monthlyBillableTokens, 0)
        
        // Test with today's usage
        usageData.todayUsage = DailyUsage(
            date: "2025-01-23",
            inputTokens: 800,
            outputTokens: 200,
            cacheCreationTokens: 100,
            cacheReadTokens: 50,
            totalTokens: 1150,
            totalCost: 1.50,
            modelsUsed: ["claude-3-5-sonnet"],
            modelBreakdowns: []
        )
        
        // Billable tokens should only include input + output
        XCTAssertEqual(usageData.todayBillableTokens, 1000)
        
        // Test with monthly data
        usageData.monthlyTotal = Totals(
            inputTokens: 40000,
            outputTokens: 10000,
            cacheCreationTokens: 5000,
            cacheReadTokens: 2000,
            totalCost: 45.00,
            totalTokens: 57000
        )
        
        XCTAssertEqual(usageData.monthlyBillableTokens, 50000)
    }
    
    func testUsageDataCostFormatting() {
        var usageData = UsageData()
        
        // Test with no data
        XCTAssertEqual(usageData.formattedDailyCost, "$0.00")
        XCTAssertEqual(usageData.formattedMonthlyCost, "$0.00")
        
        // Test with data
        usageData.todayUsage = createDailyUsage(cost: 12.34)
        usageData.monthlyTotal = createTotals(cost: 56.78)
        
        XCTAssertEqual(usageData.formattedDailyCost, "$12.34")
        XCTAssertEqual(usageData.formattedMonthlyCost, "$56.78")
    }
    
    func testUsageDataCostPercentages() {
        var usageData = UsageData()
        
        // Test daily percentage
        usageData.todayUsage = createDailyUsage(cost: 6.0) // 50% of $12 limit
        XCTAssertEqual(usageData.dailyCostPercentage, 50.0, accuracy: 0.01)
        
        // Test monthly percentage
        usageData.monthlyTotal = createTotals(cost: 30.0) // 50% of $60 limit
        XCTAssertEqual(usageData.monthlyCostPercentage, 50.0, accuracy: 0.01)
        
        // Test over 100%
        usageData.todayUsage = createDailyUsage(cost: 24.0) // 200% of limit
        XCTAssertEqual(usageData.dailyCostPercentage, 200.0, accuracy: 0.01)
    }
    
    func testUsageDataFormattedPercentages() {
        var usageData = UsageData()
        
        usageData.todayUsage = createDailyUsage(cost: 3.6) // 30% of $12
        usageData.monthlyTotal = createTotals(cost: 45.0) // 75% of $60
        
        XCTAssertEqual(usageData.formattedDailyPercentage, "30.0%")
        XCTAssertEqual(usageData.formattedMonthlyPercentage, "75.0%")
    }
    
    // MARK: - DailyUsage Tests
    
    func testDailyUsageDecoding() throws {
        let json = """
        {
            "date": "2025-01-23",
            "inputTokens": 800,
            "outputTokens": 200,
            "cacheCreationTokens": 100,
            "cacheReadTokens": 50,
            "totalTokens": 1150,
            "totalCost": 1.50,
            "modelsUsed": ["claude-3-5-sonnet-20241022"],
            "modelBreakdowns": [
                {
                    "modelName": "claude-3-5-sonnet-20241022",
                    "inputTokens": 800,
                    "outputTokens": 200,
                    "cacheCreationTokens": 100,
                    "cacheReadTokens": 50,
                    "cost": 1.50
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let dailyUsage = try JSONDecoder().decode(DailyUsage.self, from: data)
        
        XCTAssertEqual(dailyUsage.date, "2025-01-23")
        XCTAssertEqual(dailyUsage.inputTokens, 800)
        XCTAssertEqual(dailyUsage.outputTokens, 200)
        XCTAssertEqual(dailyUsage.totalTokens, 1150)
        XCTAssertEqual(dailyUsage.totalCost, 1.50)
        XCTAssertEqual(dailyUsage.modelsUsed.count, 1)
        XCTAssertEqual(dailyUsage.modelBreakdowns.count, 1)
    }
    
    // MARK: - CcusageResponse Tests
    
    func testCcusageResponseDecoding() throws {
        let json = """
        {
            "daily": [
                {
                    "date": "2025-01-23",
                    "inputTokens": 800,
                    "outputTokens": 200,
                    "cacheCreationTokens": 0,
                    "cacheReadTokens": 0,
                    "totalTokens": 1000,
                    "totalCost": 1.50,
                    "modelsUsed": ["claude-3-5-sonnet-20241022"],
                    "modelBreakdowns": []
                }
            ],
            "totals": {
                "inputTokens": 40000,
                "outputTokens": 10000,
                "cacheCreationTokens": 0,
                "cacheReadTokens": 0,
                "totalCost": 45.00,
                "totalTokens": 50000
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(CcusageResponse.self, from: data)
        
        XCTAssertEqual(response.daily.count, 1)
        XCTAssertEqual(response.totals.totalTokens, 50000)
        XCTAssertEqual(response.totals.totalCost, 45.00)
    }
    
    // MARK: - Helper Methods
    
    private func createDailyUsage(cost: Double) -> DailyUsage {
        return DailyUsage(
            date: Date().ISO8601Format(),
            inputTokens: 800,
            outputTokens: 200,
            cacheCreationTokens: 0,
            cacheReadTokens: 0,
            totalTokens: 1000,
            totalCost: cost,
            modelsUsed: ["claude-3-5-sonnet-20241022"],
            modelBreakdowns: []
        )
    }
    
    private func createTotals(cost: Double) -> Totals {
        return Totals(
            inputTokens: 40000,
            outputTokens: 10000,
            cacheCreationTokens: 0,
            cacheReadTokens: 0,
            totalCost: cost,
            totalTokens: 50000
        )
    }
}