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
    
    var formattedDailyCost: String {
        guard let today = todayUsage else { return "$0.00" }
        return String(format: "$%.2f", today.totalCost)
    }
    
    var formattedMonthlyCost: String {
        guard let monthly = monthlyTotal else { return "$0.00" }
        return String(format: "$%.2f", monthly.totalCost)
    }
}