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


struct Totals: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let totalCost: Double
    let totalTokens: Int
}

// Alias for backward compatibility
typealias TotalUsage = Totals

struct UsageData {
    var todayUsage: DailyUsage?
    var monthlyTotal: Totals?
    var activeSession: SessionBlock?
    var historicalMaxTokens: Int = 0  // 過去のセッションでの最大トークン使用量
    var detectedPlanType: String? = nil  // ユーザーのプラン（Pro/Max5/Max20）を保存
    var lastUpdated: Date = Date()
    
    // Helper computed properties for billable tokens (input + output only)
    var todayBillableTokens: Int {
        guard let today = todayUsage else { return 0 }
        return today.inputTokens + today.outputTokens
    }
    
    var monthlyBillableTokens: Int {
        guard let monthly = monthlyTotal else { return 0 }
        return monthly.inputTokens + monthly.outputTokens
    }
    
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
        let percentage = (today.totalCost / Self.dailyCostLimit) * 100
        print("Daily usage: $\(today.totalCost) / $\(Self.dailyCostLimit) = \(percentage)%")
        return percentage  // Don't cap at 100% to show actual usage
    }
    
    var monthlyCostPercentage: Double {
        guard let monthly = monthlyTotal else { return 0 }
        let percentage = (monthly.totalCost / Self.monthlyCostLimit) * 100
        return percentage  // Don't cap at 100% to show actual usage
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