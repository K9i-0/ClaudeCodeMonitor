import SwiftUI

// 共有用の静的なHistoryビュー
struct HistorySnapshotView: View {
    let monthDescription: String
    let dailyData: [DailyUsage]
    let monthlyTotals: Totals?
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // 月選択ヘッダー（共有時は操作不可）
            HStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .opacity(0.5)
                
                Text(monthDescription)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(minWidth: 140)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .opacity(0.5)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                if isLoading {
                    // Skeleton loading state
                    MonthlySummarySkeletonCard()
                    
                    ForEach(0..<3) { _ in
                        DailyUsageSkeletonCard()
                    }
                } else {
                    // 月間サマリー
                    if !dailyData.isEmpty, let totals = monthlyTotals {
                        MonthlySummaryCard(
                            totals: totals,
                            dailyData: dailyData
                        )
                    }
                    
                    // 日次データ（最大5件まで表示）
                    if dailyData.isEmpty {
                        EmptyStateView(
                            message: L10n.History.noData
                        )
                        .padding(.vertical, 30)
                    } else {
                        ForEach(dailyData.sorted(by: { $0.date > $1.date }).prefix(5), id: \.date) { daily in
                            DailyUsageCard(
                                daily: daily,
                                isToday: isToday(daily.date)
                            )
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func isToday(_ dateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return dateString == formatter.string(from: Date())
    }
}