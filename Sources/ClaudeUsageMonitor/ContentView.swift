import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: UsageMonitor
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    @State private var showingSettings = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background with visual effect
            VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with material background
                ZStack {
                    VisualEffectBlur(material: .headerView, blendingMode: .withinWindow)
                        .frame(height: 44)
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.blue)
                            Text("Claude Usage Monitor")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button(action: {
                                showingSettings = true
                            }) {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("設定")
                            .keyboardShortcut(",", modifiers: .command)
                            .accessibilityLabel("設定を開く")
                            .accessibilityHint("アプリケーションの設定画面を開きます")
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isRefreshing = true
                                }
                                monitor.fetchUsageData()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    withAnimation {
                                        isRefreshing = false
                                    }
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 13))
                                    .foregroundStyle(isRefreshing ? .blue : .secondary)
                                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                    .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("使用状況を更新")
                            .keyboardShortcut("r", modifiers: .command)
                            .accessibilityLabel("更新")
                            .accessibilityHint("使用状況データを最新に更新します")
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Divider().opacity(0.5)
            
                // Tab selector with modern style
                Picker("", selection: $selectedTab) {
                    Label("現在", systemImage: "chart.line.uptrend.xyaxis")
                        .tag(0)
                    Label("履歴", systemImage: "clock.arrow.circlepath")
                        .tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Content with transition
                Group {
                    if selectedTab == 0 {
                        // Current session
                        if let session = monitor.usageData.activeSession {
                            CurrentSessionView(session: session, monitor: monitor)
                                .padding()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        } else {
                            EmptyStateView(message: "セッションがアクティブではありません")
                                .padding()
                        }
                    } else {
                        // History
                        ScrollView {
                            HistoryView(monitor: monitor)
                                .padding()
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
                
                Divider().opacity(0.5)
                
                // Footer with material background
                ZStack {
                    VisualEffectBlur(material: .menu, blendingMode: .withinWindow)
                        .frame(height: 36)
                    
                    HStack {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(monitor.isLoading ? Color.orange : Color.green)
                                .frame(width: 6, height: 6)
                            Text("更新: \(monitor.usageData.lastUpdated.formattedTime())")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            NSApplication.shared.terminate(nil)
                        }) {
                            Text("終了")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(LinkButtonStyle())
                        .keyboardShortcut("q", modifiers: .command)
                        .accessibilityLabel("アプリケーションを終了")
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(width: 380, height: 460)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(monitor)
        }
    }
}

struct CurrentSessionView: View {
    let session: SessionBlock
    let monitor: UsageMonitor
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // 残りトークン数を大きく表示（カード風デザイン）
            VStack(spacing: 8) {
                Text("残りトークン")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(monitor.formatTokens(monitor.usageData.sessionTokenLimit - session.totalTokens))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(progressGradient)
                        .accessibilityLabel("残り\(monitor.formatTokens(monitor.usageData.sessionTokenLimit - session.totalTokens))トークン")
                    Text("トークン")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                
                // プログレスバー（改善版）
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(Color(NSColor.separatorColor).opacity(0.3))
                            .frame(height: 10)
                        
                        // Progress
                        Capsule()
                            .fill(progressGradient)
                            .frame(width: min(geometry.size.width, geometry.size.width * (monitor.usageData.sessionTokenPercentage / 100)), height: 10)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: monitor.usageData.sessionTokenPercentage)
                        
                        // Glow effect for high usage
                        if monitor.usageData.sessionTokenPercentage > 80 {
                            Capsule()
                                .fill(Color.red.opacity(0.3))
                                .frame(width: min(geometry.size.width, geometry.size.width * (monitor.usageData.sessionTokenPercentage / 100)), height: 10)
                                .blur(radius: 8)
                        }
                    }
                }
                .frame(height: 10)
                .accessibilityElement()
                .accessibilityLabel("使用状況")
                .accessibilityValue("\(Int(monitor.usageData.sessionTokenPercentage))パーセント使用済み")
                .accessibilityAddTraits(.updatesFrequently)
                
                HStack {
                    Text(monitor.usageData.formattedSessionPercentage + " 使用済み")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if monitor.usageData.sessionTokenPercentage > 90 {
                        Label("使用率が高い", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
            
            // メトリクスカード
            HStack(spacing: 12) {
                // リセットまでの時間
                VStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                    Text("リセットまで")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(monitor.usageData.sessionRemainingTime)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.1))
                )
                
                // 消費速度
                VStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.orange)
                    Text("燃焼率")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("\(monitor.usageData.sessionBurnRate)/分")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.orange)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.1))
                )
            }
            
            // セッションコスト（改善版）
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("セッションコスト")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("$")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.green)
                        Text(String(format: "%.2f", session.costUSD))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                }
                
                Spacer()
                
                // プラン情報
                VStack(alignment: .trailing, spacing: 4) {
                    Text(monitor.usageData.planDescription)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.15))
                        )
                    Text("リセット: \(formatTime(session.endTime))")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }
    
    private var progressGradient: LinearGradient {
        return Color.usageGradient(for: monitor.usageData.sessionTokenPercentage)
    }
    
    private func formatTime(_ timeString: String) -> String {
        return Date.formatTime(from: timeString)
    }
    
    private func getElapsedTime(from startTimeString: String) -> String {
        return Date.getElapsedTime(from: startTimeString)
    }
}

struct SessionDetailView: View {
    let session: SessionBlock
    let monitor: UsageMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Token usage with progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label("Token Limit", systemImage: "chart.bar.fill")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text(monitor.usageData.formattedSessionPercentage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(monitor.usageData.sessionTokenPercentage > 90 ? .red : (monitor.usageData.sessionTokenPercentage > 70 ? .orange : .green))
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(monitor.usageData.sessionTokenPercentage > 90 ? Color.red : (monitor.usageData.sessionTokenPercentage > 70 ? Color.orange : Color.green))
                            .frame(width: min(geometry.size.width, geometry.size.width * (monitor.usageData.sessionTokenPercentage / 100)), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: monitor.usageData.sessionTokenPercentage)
                    }
                }
                .frame(height: 8)
                
                if monitor.usageData.isOverLimit {
                    Text("⚠️ Token limit exceeded!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
            }
            
            Divider()
            
            // Session info
            HStack {
                Label("Tokens Used", systemImage: "number.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text("\(monitor.formatTokens(session.totalTokens)) / \(monitor.formatTokens(monitor.usageData.sessionTokenLimit))")
                    .font(.system(size: 14))
            }
            
            HStack {
                Label("Burn Rate", systemImage: "flame.fill")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text("\(monitor.usageData.sessionBurnRate) tokens/min")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
            }
            
            HStack {
                Label("Cost/Hour", systemImage: "dollarsign.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text(monitor.usageData.sessionCostPerHour)
                    .font(.system(size: 14))
                    .foregroundColor(.accentColor)
            }
            
            HStack {
                Label("Time Left", systemImage: "clock.fill")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text(monitor.usageData.sessionRemainingTime)
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }
            
            Divider()
            
            // Session details
            VStack(alignment: .leading, spacing: 4) {
                Text("Session Details (5時間セッション)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("プラン:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(monitor.usageData.planDescription)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("開始:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(formatTimeWithDate(session.startTime))
                        .font(.system(size: 11))
                }
                
                HStack {
                    Text("終了:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(formatTimeWithDate(session.endTime))
                        .font(.system(size: 11))
                }
                
                HStack {
                    Text("経過時間:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(getElapsedTime(from: session.startTime))
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    private func formatTime(_ timeString: String) -> String {
        return Date.formatTime(from: timeString)
    }
    
    private func formatTimeWithDate(_ timeString: String) -> String {
        return Date.formatTime(from: timeString, format: "MM/dd HH:mm")
    }
    
    private func getElapsedTime(from startTimeString: String) -> String {
        return Date.getElapsedTime(from: startTimeString)
    }
}

struct UsageDetailView: View {
    let title: String
    let totalCost: Double
    let totalTokens: Int
    let modelBreakdowns: [ModelBreakdown]
    let monitor: UsageMonitor
    let usagePercentage: Double
    let formattedPercentage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Usage percentage with progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label("Usage Limit", systemImage: "chart.bar.fill")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text(formattedPercentage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(usagePercentage > 80 ? .red : (usagePercentage > 60 ? .orange : .green))
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(usagePercentage > 80 ? Color.red : (usagePercentage > 60 ? Color.orange : Color.green))
                            .frame(width: min(geometry.size.width, geometry.size.width * (usagePercentage / 100)), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: usagePercentage)
                    }
                }
                .frame(height: 8)
            }
            
            Divider()
            
            // Total cost
            HStack {
                Label("Total Cost", systemImage: "dollarsign.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text(monitor.formatCost(totalCost))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            
            // Total tokens
            HStack {
                Label("Total Tokens", systemImage: "number.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text(monitor.formatTokens(totalTokens))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            if !modelBreakdowns.isEmpty {
                Divider()
                
                // Model breakdown
                Text("Model Breakdown")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                ForEach(modelBreakdowns.sorted(by: { $0.cost > $1.cost }), id: \.modelName) { breakdown in
                    HStack {
                        Text(formatModelName(breakdown.modelName))
                            .font(.system(size: 12))
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(monitor.formatCost(breakdown.cost))
                                .font(.system(size: 12, weight: .medium))
                            Text("\(monitor.formatTokens(breakdown.inputTokens + breakdown.outputTokens)) tokens")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private func formatModelName(_ name: String) -> String {
        // Format model names for better readability
        return name
            .replacingOccurrences(of: "claude-", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

struct EmptyStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            
            VStack(spacing: 4) {
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                
                Text("Claude Codeで作業を開始すると\nここに使用状況が表示されます")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}