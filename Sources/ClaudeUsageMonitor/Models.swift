import Foundation

struct CcusageResponse: Codable {
    let daily: [DailyUsage]
    let totals: Totals
}

struct DailyUsage: Codable {
    let date: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let totalTokens: Int
    let totalCost: Double
    let modelsUsed: [String]
    let modelBreakdowns: [ModelBreakdown]
}

struct ModelBreakdown: Codable {
    let modelName: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let cost: Double
}

struct Totals: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let totalCost: Double
    let totalTokens: Int
}

struct UsageData {
    var todayUsage: DailyUsage?
    var monthlyTotal: Totals?
    var lastUpdated: Date = Date()
    
    // Claude Code typical cost limits based on documentation
    // $12/day for 90% of users, $60/month average
    static let dailyCostLimit: Double = 12.0
    static let monthlyCostLimit: Double = 60.0
    
    // Approximate token-to-cost conversion based on Claude 3.5 Sonnet pricing
    // Input: $3 per million tokens, Output: $15 per million tokens
    // Assuming 80/20 split for input/output tokens
    static let averageCostPerMillionTokens: Double = 6.0  // Weighted average
    
    var formattedDailyCost: String {
        guard let today = todayUsage else { return "$0.00" }
        return String(format: "$%.2f", today.totalCost)
    }
    
    var formattedMonthlyCost: String {
        guard let monthly = monthlyTotal else { return "$0.00" }
        return String(format: "$%.2f", monthly.totalCost)
    }
    
    // Cost-based usage percentages
    var dailyCostPercentage: Double {
        guard let today = todayUsage else { return 0 }
        return min(100, (today.totalCost / Self.dailyCostLimit) * 100)
    }
    
    var monthlyCostPercentage: Double {
        guard let monthly = monthlyTotal else { return 0 }
        return min(100, (monthly.totalCost / Self.monthlyCostLimit) * 100)
    }
    
    var formattedDailyPercentage: String {
        return String(format: "%.1f%%", dailyCostPercentage)
    }
    
    var formattedMonthlyPercentage: String {
        return String(format: "%.1f%%", monthlyCostPercentage)
    }
    
    // Token-based estimates (converted from typical daily cost limit)
    var estimatedDailyTokenLimit: Int {
        // $12 daily limit / $6 per million tokens = 2 million tokens
        return 2_000_000
    }
    
    var dailyTokenPercentage: Double {
        guard let today = todayUsage else { return 0 }
        return min(100, (Double(today.totalTokens) / Double(estimatedDailyTokenLimit)) * 100)
    }
    
    var formattedDailyTokenPercentage: String {
        return String(format: "%.1f%%", dailyTokenPercentage)
    }
}