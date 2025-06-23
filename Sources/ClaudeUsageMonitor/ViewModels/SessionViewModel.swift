import Foundation
import SwiftUI

@MainActor
class SessionViewModel: ObservableObject {
    @Published var session: SessionBlock?
    @Published var remainingTokens: Int = 0
    @Published var percentage: Double = 0
    @Published var burnRate: Double = 0
    @Published var remainingTime: String = ""
    @Published var cost: Double = 0
    @Published var planDescription: String = ""
    @Published var resetTime: String = ""
    
    private let monitor: UsageMonitoring
    
    init(monitor: UsageMonitoring) {
        self.monitor = monitor
        updateFromMonitor()
    }
    
    func updateFromMonitor() {
        guard let data = monitor.usageData.activeSession else {
            session = nil
            return
        }
        
        session = data
        remainingTokens = monitor.usageData.sessionTokenLimit - data.totalTokens
        percentage = monitor.usageData.sessionUsagePercentage
        burnRate = Double(monitor.usageData.sessionBurnRate) ?? 0
        remainingTime = monitor.usageData.sessionRemainingTime
        cost = data.costUSD
        planDescription = monitor.usageData.planDescription
        resetTime = Date.formatTime(from: data.endTime)
        
        // 通知チェック
        NotificationManager.shared.checkAndSendNotification(
            for: percentage,
            burnRate: burnRate,
            remainingTime: remainingTime,
            sessionId: data.id
        )
    }
    
    var formattedRemainingTokens: String {
        NumberFormatters.formatTokens(remainingTokens)
    }
    
    var formattedCost: String {
        NumberFormatters.formatCost(cost)
    }
    
    var formattedBurnRate: String {
        "\(Int(burnRate))"
    }
    
    var progressColor: Color {
        Color.usageColor(for: percentage)
    }
    
    var progressGradient: LinearGradient {
        Color.usageGradient(for: percentage)
    }
    
    var shouldShowWarning: Bool {
        percentage > 90
    }
    
    var statusIcon: String {
        switch percentage {
        case 90...:
            return "exclamationmark.triangle.fill"
        case 70..<90:
            return "bolt.fill"
        case 50..<70:
            return "flame.fill"
        default:
            return "circle.fill"
        }
    }
}

// MARK: - History ViewModel
@MainActor
class HistoryViewModel: ObservableObject {
    @Published var todayUsage: DailyUsage?
    @Published var monthlyUsage: TotalUsage?
    @Published var chartData: [ChartData] = []
    
    private let monitor: UsageMonitoring
    
    init(monitor: UsageMonitoring) {
        self.monitor = monitor
        updateFromMonitor()
    }
    
    func updateFromMonitor() {
        todayUsage = monitor.usageData.todayUsage
        monthlyUsage = monitor.usageData.monthlyTotal
        updateChartData()
    }
    
    private func updateChartData() {
        guard let session = monitor.usageData.activeSession else {
            chartData = []
            return
        }
        
        let formatter = ISO8601DateFormatter()
        guard let startDate = formatter.date(from: session.startTime) else {
            chartData = []
            return
        }
        
        var data: [ChartData] = []
        let now = Date()
        let elapsed = now.timeIntervalSince(startDate)
        let intervals = min(Int(elapsed / 300), 12) // 5分間隔、最大12ポイント
        
        for i in 0...intervals {
            let time = startDate.addingTimeInterval(Double(i) * 300)
            let tokens = Int(Double(session.totalTokens) * Double(i) / Double(intervals))
            data.append(ChartData(time: time, value: Double(tokens)))
        }
        
        chartData = data
    }
    
    var formattedTodayCost: String? {
        guard let cost = todayUsage?.totalCost else { return nil }
        return NumberFormatters.formatCost(cost)
    }
    
    var formattedTodayTokens: String? {
        guard let tokens = todayUsage?.totalTokens else { return nil }
        return NumberFormatters.formatTokens(tokens)
    }
    
    var formattedMonthlyCost: String? {
        guard let cost = monthlyUsage?.totalCost else { return nil }
        return NumberFormatters.formatCost(cost)
    }
    
    var formattedMonthlyTokens: String? {
        guard let tokens = monthlyUsage?.totalTokens else { return nil }
        return NumberFormatters.formatTokens(tokens)
    }
}