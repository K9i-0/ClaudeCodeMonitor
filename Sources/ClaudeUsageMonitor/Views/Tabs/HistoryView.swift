import SwiftUI

struct HistoryView: View {
    @StateObject var viewModel: HistoryViewModel
    @Environment(\.colorScheme) var colorScheme

    // formatPeakDate関数を定義
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
    
    var body: some View {
        VStack(spacing: 12) {
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
                        .scaleEffect(0.6)
                }
            }
            .padding(.horizontal, 4)
            
            // 月間サマリー（常時表示）
            if !viewModel.isLoading && !viewModel.dailyData.isEmpty, let totals = viewModel.monthlyTotals {
                HStack(spacing: 0) {
                    // 合計
                    VStack(spacing: 6) {
                        Text(L10n.History.total)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        Text(String(format: "$%.2f", totals.totalCost))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        
                        Text("\(NumberFormatters.formatTokens(totals.totalTokens))")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 50)
                        .padding(.horizontal, 8)
                    
                    // 日次平均
                    VStack(spacing: 6) {
                        Text(L10n.History.dailyAverage)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        Text(String(format: "$%.2f", totals.totalCost / Double(viewModel.dailyData.count)))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        
                        Text(L10n.History.perDay)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 50)
                        .padding(.horizontal, 8)
                    
                    // ピーク
                    VStack(spacing: 6) {
                        Text(L10n.History.peak)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        if let peak = viewModel.dailyData.max(by: { $0.totalCost < $1.totalCost }) {
                            Text(String(format: "$%.2f", peak.totalCost))
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                            
                            Text(self.formatPeakDate(peak.date))
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .padding(.horizontal, 4)
            }

            ScrollView {
                VStack(spacing: 8) {
                    if viewModel.isLoading {
                        // Skeleton loading state
                        ForEach(0..<5) { _ in
                            DailyUsageSkeletonCard()
                        }
                    } else {
                        // 日次データ
                        if viewModel.dailyData.isEmpty {
                            EmptyStateView(
                                message: L10n.History.noData
                            )
                            .padding(.vertical, 60)
                            .transition(.opacity)
                        } else {
                            ForEach(viewModel.dailyData.sorted(by: { $0.date > $1.date }), id: \.date) { daily in
                                CompactDailyUsageCard(
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
        if components.year! < 2_025 || (components.year == 2_025 && components.month! < 2) {
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.History.monthSummary)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                // 合計
                HStack {
                    Label(L10n.History.total, systemImage: "dollarsign.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "$%.2f", totals.totalCost))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Text("\(NumberFormatters.formatTokens(totals.totalTokens)) tokens")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()
                    .opacity(0.5)

                // 日次平均
                HStack {
                    Label(L10n.History.dailyAverage, systemImage: "chart.bar.fill")
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
                        Label(L10n.History.peak, systemImage: "flame.fill")
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
}

// コンパクトな日次使用量カード
struct CompactDailyUsageCard: View {
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
        formatter.locale = Locale(identifier: LanguageSettings.shared.effectiveLanguageCode() == "ja" ? "ja_JP" : "en_US")
        return formatter.string(from: date)
    }

    private var totalTokens: Int {
        daily.inputTokens + daily.outputTokens
    }

    var body: some View {
        HStack(spacing: 0) {
            // 日付部分（コンパクト化）
            HStack(spacing: 4) {
                Text(dayString)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(width: 24, alignment: .trailing)

                Text(weekdayString)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
            }
            .padding(.leading, 8)

            // コスト情報（コンパクト化）
            HStack {
                Text(String(format: "$%.2f", daily.totalCost))
                    .font(.system(size: 14, weight: .semibold))

                Text("\(NumberFormatters.formatTokens(totalTokens)) • \(formatModels(daily.modelsUsed))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Spacer()

                if isToday {
                    Text(L10n.History.today)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .opacity(isToday ? 1.0 : 0.6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
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

// 日次使用量カード（元のバージョン）
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
        formatter.locale = Locale(identifier: LanguageSettings.shared.effectiveLanguageCode() == "ja" ? "ja_JP" : "en_US")
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
                        Text(L10n.History.today)
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
