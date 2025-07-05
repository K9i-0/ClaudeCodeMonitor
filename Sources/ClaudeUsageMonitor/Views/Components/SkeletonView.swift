import SwiftUI

// Skeleton loading animation view
struct SkeletonView: View {
    @State private var isAnimating = false
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 10) {
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(NSColor.controlBackgroundColor).opacity(0.3),
                        Color(NSColor.controlBackgroundColor).opacity(0.6),
                        Color(NSColor.controlBackgroundColor).opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.3)
                        .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 0.3)
                        .animation(
                            Animation.linear(duration: 1.5)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                isAnimating = true
            }
    }
}

// Skeleton card for daily usage
struct DailyUsageSkeletonCard: View {
    var body: some View {
        HStack(spacing: 0) {
            // 日付部分
            HStack(spacing: 8) {
                SkeletonView(cornerRadius: 4)
                    .frame(width: 32, height: 24)
                
                Divider()
                    .frame(height: 20)
                    .opacity(0.3)
                
                SkeletonView(cornerRadius: 4)
                    .frame(width: 20, height: 16)
            }
            .padding(.leading, 12)
            
            // コスト情報
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SkeletonView(cornerRadius: 4)
                        .frame(width: 80, height: 20)
                    
                    Spacer()
                }
                
                HStack {
                    SkeletonView(cornerRadius: 4)
                        .frame(width: 120, height: 16)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
        )
    }
}

// Skeleton for monthly summary
struct MonthlySummarySkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonView(cornerRadius: 4)
                .frame(width: 100, height: 16)
            
            VStack(spacing: 10) {
                // 合計
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                            .frame(width: 20, height: 20)
                        SkeletonView(cornerRadius: 4)
                            .frame(width: 40, height: 16)
                    }
                    
                    Spacer()
                    
                    SkeletonView(cornerRadius: 4)
                        .frame(width: 80, height: 20)
                }
                
                Divider()
                    .opacity(0.5)
                
                // 日次平均
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                            .frame(width: 20, height: 20)
                        SkeletonView(cornerRadius: 4)
                            .frame(width: 60, height: 16)
                    }
                    
                    Spacer()
                    
                    SkeletonView(cornerRadius: 4)
                        .frame(width: 60, height: 16)
                }
                
                // ピーク
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                            .frame(width: 20, height: 20)
                        SkeletonView(cornerRadius: 4)
                            .frame(width: 50, height: 16)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        SkeletonView(cornerRadius: 4)
                            .frame(width: 40, height: 14)
                        SkeletonView(cornerRadius: 4)
                            .frame(width: 60, height: 16)
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