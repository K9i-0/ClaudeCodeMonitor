import SwiftUI

struct HistoryView: View {
    @StateObject var viewModel: HistoryViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // 月選択ヘッダー
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.previousMonth()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(isFirstAvailableMonth)
                
                Text(viewModel.monthDescription)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(minWidth: 140)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.nextMonth()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(isCurrentMonth)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal, 4)
            
            ScrollView {
                VStack(spacing: 12) {
                    if viewModel.isLoading {
                        // Skeleton loading state
                        MonthlySummarySkeletonCard()
                        
                        ForEach(0..<5) { _ in
                            DailyUsageSkeletonCard()
                        }
                    } else {
                        // 月間サマリー
                        if !viewModel.dailyData.isEmpty, let totals = viewModel.monthlyTotals {
                            MonthlySummaryCard(
                                totals: totals,
                                dailyData: viewModel.dailyData
                            )
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity
                                ))
                        }
                        
                        // 日次データ
                        if viewModel.dailyData.isEmpty {
                            EmptyStateView(
                                message: L10n.History.noData
                            )
                            .padding(.vertical, 60)
                            .transition(.opacity)
                        } else {
                            ForEach(viewModel.dailyData.sorted(by: { $0.date > $1.date }), id: \.date) { daily in
                                DailyUsageCard(
                                    daily: daily,
                                    isToday: isToday(daily.date)
                                )
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                                    removal: .opacity
                                ))
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var isCurrentMonth: Bool {
        Calendar.current.isDate(viewModel.selectedMonth, equalTo: Date(), toGranularity: .month)
    }
    
    private var isFirstAvailableMonth: Bool {
        // Claude Codeは2025年2月24日リリース
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: viewModel.selectedMonth)
        
        // 2025年2月より前には戻れないようにする（Claude Codeリリース前）
        if components.year! < 2025 || (components.year == 2025 && components.month! < 2) {
            return true
        }
        
        return false
    }
    
    private func isToday(_ dateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return dateString == formatter.string(from: Date())
    }
}

// 月間サマリーカード
struct MonthlySummaryCard: View {
    let totals: Totals
    let dailyData: [DailyUsage]
    
    private var dailyAverage: Double {
        guard !dailyData.isEmpty else { return 0 }
        return totals.totalCost / Double(dailyData.count)
    }
    
    private var peakDay: DailyUsage? {
        dailyData.max(by: { $0.totalCost < $1.totalCost })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("月間サマリー")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 10) {
                // 合計
                HStack {
                    Label("合計", systemImage: "yensign.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(String(format: "$%.2f", totals.totalCost))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                
                Divider()
                    .opacity(0.5)
                
                // 日次平均
                HStack {
                    Label("日次平均", systemImage: "chart.bar.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.blue)
                    
                    Spacer()
                    
                    Text(String(format: "$%.2f", dailyAverage))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                // ピーク日
                if let peak = peakDay {
                    HStack {
                        Label("ピーク", systemImage: "flame.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.orange)
                        
                        Spacer()
                        
                        Text(formatPeakDate(peak.date))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        
                        Text(String(format: "$%.2f", peak.totalCost))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }
    
    private func formatPeakDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "M/d"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}

// 日次使用量カード
struct DailyUsageCard: View {
    let daily: DailyUsage
    let isToday: Bool
    
    private var date: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: daily.date)
    }
    
    private var dayString: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    private var weekdayString: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private var totalTokens: Int {
        daily.inputTokens + daily.outputTokens
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 日付部分
            HStack(spacing: 8) {
                Text(dayString)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .frame(width: 32, alignment: .trailing)
                
                Divider()
                    .frame(height: 20)
                    .opacity(0.3)
                
                Text(weekdayString)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
            }
            .padding(.leading, 12)
            
            // コスト情報
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(String(format: "$%.2f", daily.totalCost))
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    if isToday {
                        Text("今日")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.blue)
                            )
                            .foregroundStyle(.white)
                    }
                }
                
                HStack {
                    Text("\(NumberFormatters.formatTokens(totalTokens)) tokens")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    if !daily.modelsUsed.isEmpty {
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        
                        Text(formatModels(daily.modelsUsed))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .opacity(isToday ? 1.0 : 0.6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private func formatModels(_ models: [String]) -> String {
        let shortNames = models.map { model in
            if model.contains("opus") {
                return "Opus"
            } else if model.contains("sonnet") {
                return "Sonnet"
            } else if model.contains("haiku") {
                return "Haiku"
            }
            return "Other"
        }
        return shortNames.joined(separator: ", ")
    }
}