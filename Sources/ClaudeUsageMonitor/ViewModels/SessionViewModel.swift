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

        // 通知機能は初回リリースでは無効化
        /*
        // 通知チェック（テスト環境では無効）
        if Bundle.main.bundleIdentifier != nil && !ProcessInfo.processInfo.environment.keys.contains("XCTestConfigurationFilePath") {
            NotificationManager.shared.checkAndSendNotification(
                for: percentage,
                burnRate: burnRate,
                remainingTime: remainingTime,
                sessionId: data.id
            )
        }
        */
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
    @Published var selectedMonth = Date()
    @Published var dailyData: [DailyUsage] = []
    @Published var monthlyTotals: Totals?
    @Published var isLoading = false
    
    private let commandExecutor = CommandExecutor.shared
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }
    
    init() {
        Task {
            await fetchMonthlyData()
        }
    }
    
    func previousMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        Task {
            await fetchMonthlyData()
        }
    }
    
    func nextMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
        Task {
            await fetchMonthlyData()
        }
    }
    
    func fetchMonthlyData() async {
        isLoading = true
        
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        
        // endOfMonthは次月の最初の日なので、1日引いて当月の最終日を取得
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: endOfMonth) ?? endOfMonth
        
        let monthStart = dateFormatter.string(from: startOfMonth)
        let monthEnd = dateFormatter.string(from: lastDayOfMonth)
        
        do {
            let result = try await commandExecutor.executeCcusageCommand(
                subcommand: nil,
                additionalArgs: ["--since", monthStart, "--until", monthEnd]
            )
            
            let data = Data(result.utf8)
            let response = try JSONDecoder().decode(CcusageResponse.self, from: data)
            
            withAnimation {
                dailyData = response.daily
                monthlyTotals = response.totals
            }
        } catch {
            print("Failed to fetch monthly data: \(error)")
            dailyData = []
            monthlyTotals = nil
        }
        
        isLoading = false
    }
    
    // For sharing
    var monthDescription: String {
        monthFormatter.string(from: selectedMonth)
    }
    
    var monthlyTotalCost: Double {
        monthlyTotals?.totalCost ?? 0
    }
    
    var monthlyTotalTokens: Int {
        monthlyTotals?.totalTokens ?? 0
    }
    
    var dailyAverage: Double {
        guard !dailyData.isEmpty else { return 0 }
        return monthlyTotalCost / Double(dailyData.count)
    }
    
    var peakDay: DailyUsage? {
        dailyData.max(by: { $0.totalCost < $1.totalCost })
    }
}
