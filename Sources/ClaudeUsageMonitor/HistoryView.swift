import SwiftUI
import Charts

struct HistoryView: View {
    let monitor: UsageMonitor
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            Text(L10n.History.usageSummary)
                .font(.system(size: 16, weight: .semibold))
            
            // 現在のセッション情報（カード風デザイン）
            if let session = monitor.usageData.activeSession {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.blue)
                            Text(L10n.History.currentSession)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Spacer()
                        Text(String(format: "$%.2f", session.costUSD))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    
                    HStack {
                        Label(L10n.History.tokensFormat(tokens: monitor.formatTokens(session.totalTokens)), systemImage: "number.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(monitor.usageData.formattedSessionPercentage)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(progressBackgroundColor)
                            )
                            .foregroundStyle(progressForegroundColor)
                    }
                    
                    // ミニプログレスバー
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(NSColor.separatorColor).opacity(0.2))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(progressGradient)
                                .frame(
                                    width: min(geometry.size.width, geometry.size.width * (monitor.usageData.sessionUsagePercentage / 100)),
                                    height: 4
                                )
                        }
                    }
                    .frame(height: 4)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }
            
            // 今日と今月の統計（横並び）
            HStack(spacing: 12) {
                // 今日の使用量
                if let daily = monitor.usageData.todayUsage {
                    StatCard(
                        icon: "calendar",
                        title: L10n.Usage.today,
                        cost: monitor.formatCost(daily.totalCost),
                        tokens: monitor.formatTokens(daily.inputTokens + daily.outputTokens),
                        accentColor: .green
                    )
                }
                
                // 今月の使用量
                if let monthly = monitor.usageData.monthlyTotal {
                    StatCard(
                        icon: "calendar.badge.clock",
                        title: L10n.Usage.thisMonth,
                        cost: monitor.formatCost(monthly.totalCost),
                        tokens: monitor.formatTokens(monthly.inputTokens + monthly.outputTokens),
                        accentColor: .purple
                    )
                }
            }
            
            Text(L10n.History.referenceNote)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }
    
    // 計算プロパティ
    @MainActor
    private var progressGradient: LinearGradient {
        return Color.usageGradient(for: monitor.usageData.sessionUsagePercentage)
    }
    
    @MainActor
    private var progressBackgroundColor: Color {
        return Color.usageColor(for: monitor.usageData.sessionUsagePercentage).opacity(0.15)
    }
    
    @MainActor
    private var progressForegroundColor: Color {
        return Color.usageColor(for: monitor.usageData.sessionUsagePercentage)
    }
    
    // チャートデータ生成（仮実装）
    private func generateTodayChartData(session: SessionBlock?) -> [ChartData] {
        // 実際のデータ構造に合わせて実装が必要
        guard let session = session else { return [] }
        
        // 仮のデータ生成
        let formatter = ISO8601DateFormatter()
        guard let startDate = formatter.date(from: session.startTime) else { return [] }
        
        var data: [ChartData] = []
        let now = Date()
        let elapsed = now.timeIntervalSince(startDate)
        let intervals = min(Int(elapsed / 300), 12) // 5分間隔、最大12ポイント
        
        for i in 0...intervals {
            let time = startDate.addingTimeInterval(Double(i) * 300)
            let tokens = Int(Double(session.totalTokens) * Double(i) / Double(intervals))
            data.append(ChartData(time: time, value: Double(tokens)))
        }
        
        return data
    }
}

// チャートデータ構造
struct ChartData: Identifiable {
    let id = UUID()
    let time: Date
    let value: Double
}

// 統計カードコンポーネント
struct StatCard: View {
    let icon: String
    let title: String
    let cost: String
    let tokens: String
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(accentColor)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            
            Text(cost)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(L10n.History.tokensFormat(tokens: tokens))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// チャートビューコンポーネント
struct UsageChartView: View {
    let title: String
    let data: [ChartData]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            
            if !data.isEmpty {
                Chart(data) { item in
                    LineMark(
                        x: .value(L10n.History.time, item.time),
                        y: .value(L10n.History.tokens, item.value)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value(L10n.History.time, item.time),
                        y: .value(L10n.History.tokens, item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartXAxis {
                    AxisMarks(preset: .aligned) { _ in
                        AxisValueLabel(format: .dateTime.hour().minute())
                            .font(.system(size: 9))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let intValue = value.as(Double.self) {
                                Text(formatAxisValue(intValue))
                                    .font(.system(size: 9))
                            }
                        }
                    }
                }
                .frame(height: 120)
                .padding(.horizontal, 4)
            } else {
                Text(L10n.History.noData)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(height: 120)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
    }
    
    private func formatAxisValue(_ value: Double) -> String {
        return NumberFormatters.formatAxisValue(value)
    }
}