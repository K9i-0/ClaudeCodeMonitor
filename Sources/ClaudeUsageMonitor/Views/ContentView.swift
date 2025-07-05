import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: UsageMonitor
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    @State private var showCopiedFeedback = false
    @StateObject private var historyViewModel = HistoryViewModel()

    @Environment(\.colorScheme)
    var colorScheme

    var body: some View {
        mainContent
    }

    var mainContent: some View {
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
                        Text("ClaudeCodeMonitor")
                            .font(.system(size: 14, weight: .semibold))

                        Spacer()

                        HStack(spacing: 12) {
                            // Share button - only show on Current or History tabs
                            if selectedTab == 0 || selectedTab == 1 {
                                Button(action: {
                                    shareScreenshot()
                                }) {
                                    Image(systemName: showCopiedFeedback ? "checkmark" : "square.and.arrow.up")
                                        .font(.system(size: 13))
                                        .foregroundStyle(showCopiedFeedback ? .green : .secondary)
                                        .animation(.easeInOut(duration: 0.2), value: showCopiedFeedback)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("クリップボードにコピー")
                                .keyboardShortcut("s", modifiers: .command)
                                .accessibilityLabel("クリップボードにコピー")
                            }

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
                                    .animation(
                                        isRefreshing
                                            ? .linear(duration: 1).repeatForever(autoreverses: false)
                                            : .default,
                                        value: isRefreshing
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help(L10n.Action.refresh)
                            .keyboardShortcut("r", modifiers: .command)
                            .accessibilityLabel(L10n.Action.refresh)
                            .accessibilityHint(L10n.Action.refresh)
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                    .padding(.horizontal)
                }

                Divider().opacity(0.5)

                // Tab selector with modern style
                Picker("", selection: $selectedTab) {
                    Label(L10n.Tab.current, systemImage: "chart.line.uptrend.xyaxis")
                        .tag(0)
                    Label(L10n.Tab.history, systemImage: "clock.arrow.circlepath")
                        .tag(1)
                    Label(L10n.Action.settings, systemImage: "gearshape")
                        .tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Content with transition - all tabs are scrollable
                Group {
                    switch selectedTab {
                    case 0:
                        // Current session
                        ScrollView {
                            if let session = monitor.usageData.activeSession {
                                CurrentSessionView(session: session, monitor: monitor)
                                    .padding()
                            } else {
                                EmptyStateView(message: L10n.Session.noActiveSession)
                                    .padding()
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    case 1:
                        // History
                        ScrollView {
                            HistoryView(viewModel: historyViewModel)
                                .padding()
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    case 2:
                        // Settings
                        ScrollView {
                            SettingsTabView()
                                .environmentObject(monitor)
                                .padding()
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    default:
                        EmptyView()
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
                            Text(L10n.Status.lastUpdated(time: monitor.usageData.lastUpdated.formattedTime()))
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            NSApplication.shared.terminate(nil)
                        }) {
                            Text(L10n.Action.quit)
                                .font(.system(size: 11))
                        }
                        .buttonStyle(LinkButtonStyle())
                        .keyboardShortcut("q", modifiers: .command)
                        .accessibilityLabel(L10n.Action.quitApp)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(width: 380, height: 480)
    }

    // swiftlint:disable:next function_body_length
    private func shareScreenshot() {
        Task { @MainActor in
            // Create the content view to capture based on selected tab
            let contentToCapture: AnyView

            switch selectedTab {
            case 0:
                // Current session tab content
                if let session = monitor.usageData.activeSession {
                    contentToCapture = AnyView(
                        CurrentSessionView(session: session, monitor: monitor)
                            .padding()
                            .frame(width: 380)
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            .environment(\.colorScheme, colorScheme)
                    )
                } else {
                    contentToCapture = AnyView(
                        EmptyStateView(message: L10n.Session.noActiveSession)
                            .padding()
                            .frame(width: 380, height: 400)
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            .environment(\.colorScheme, colorScheme)
                    )
                }
            case 1:
                // History tab content - use actual HistoryView
                print("[Share] History data count: \(historyViewModel.dailyData.count)")
                print("[Share] Monthly totals: \(String(describing: historyViewModel.monthlyTotals))")
                print("[Share] Is loading: \(historyViewModel.isLoading)")

                // もしデータがまだ読み込まれていない場合は、読み込みを待つ
                if historyViewModel.dailyData.isEmpty && !historyViewModel.isLoading {
                    await historyViewModel.fetchMonthlyData()

                    // データ取得後の状態を再度ログに出力
                    print("[Share] After fetch - data count: \(historyViewModel.dailyData.count)")
                    print("[Share] After fetch - monthly totals: \(String(describing: historyViewModel.monthlyTotals))")
                }

                // 少し待機してUIの更新を確実にする
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒

                // HistoryViewの中身を直接構築（ScrollViewを除外）
                contentToCapture = AnyView(
                    VStack(spacing: 12) {
                        // 月選択ヘッダーと月間サマリーを横並び
                        HStack(spacing: 12) {
                            // 月選択部分
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .opacity(0.5)

                                Text(historyViewModel.monthDescription)
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(minWidth: 100)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .opacity(0.5)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )

                            // 月間サマリー（インライン）
                            if !historyViewModel.dailyData.isEmpty, let totals = historyViewModel.monthlyTotals {
                                HStack(spacing: 4) {
                                    // 合計
                                    HStack(spacing: 12) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "chart.bar.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.blue)
                                                .frame(width: 20, height: 20)
                                            
                                            Text(L10n.History.total)
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(String(format: "$%.0f", totals.totalCost))
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.primary)
                                            Text("\(NumberFormatters.formatTokens(totals.totalTokens))")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(NSColor.controlBackgroundColor))
                                            .opacity(0.8)
                                    )
                                    
                                    // 日次平均
                                    HStack(spacing: 12) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "calendar.day.timeline.left")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.green)
                                                .frame(width: 20, height: 20)
                                            
                                            Text(L10n.History.dailyAverage)
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(String(format: "$%.0f", totals.totalCost / Double(historyViewModel.dailyData.count)))
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.primary)
                                            Text(L10n.History.perDay)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(NSColor.controlBackgroundColor))
                                            .opacity(0.8)
                                    )
                                }
                                .padding(.horizontal, 2)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 4)

                        // コンテンツ部分
                        VStack(spacing: 8) {
                            if historyViewModel.dailyData.isEmpty {
                                EmptyStateView(
                                    message: L10n.History.noData
                                )
                                .padding(.vertical, 60)
                            } else {
                                ForEach(historyViewModel.dailyData.sorted(by: { $0.date > $1.date }), id: \.date) { daily in
                                    CompactDailyUsageCard(
                                        daily: daily,
                                        isToday: isToday(daily.date)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding()
                    .frame(width: 380)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .environment(\.colorScheme, colorScheme)
                )
            default:
                return
            }

            // Generate text content based on selected tab
            let textContent: String
            switch selectedTab {
            case 0:
                if let session = monitor.usageData.activeSession {
                    let tokens = monitor.formatTokens(session.totalTokens)
                    let cost = String(format: "%.2f", session.costUSD)
                    let remainingTime = monitor.usageData.sessionRemainingTimeForShare
                    textContent = """
                    \(String(format: L10n.Share.CurrentSession.consuming, tokens, cost))
                    \(String(format: L10n.Share.CurrentSession.resetIn, remainingTime))

                    \(L10n.Share.hashtags)
                    """
                } else {
                    textContent = "\(L10n.Share.CurrentSession.noSession)\n\n\(L10n.Share.hashtags)"
                }
            case 1:
                let monthTokens = NumberFormatters.formatTokens(historyViewModel.monthlyTotalTokens)
                let monthCost = String(format: "%.2f", historyViewModel.monthlyTotalCost)
                let dailyAvg = String(format: "%.2f", historyViewModel.dailyAverage)

                var peakInfo = ""
                if let peak = historyViewModel.peakDay {
                    let peakDate = formatShareDate(peak.date)
                    let peakCost = String(format: "%.2f", peak.totalCost)
                    peakInfo = "\nピーク: \(peakDate) - $\(peakCost)"
                }

                textContent = """
                \(historyViewModel.monthDescription)の使用状況
                月間合計: \(monthTokens) tokens ($\(monthCost))
                日次平均: $\(dailyAvg)\(peakInfo)

                \(L10n.Share.hashtags)
                """
            default:
                textContent = ""
            }

            let success = await ScreenshotManager.shared.captureViewContent(contentToCapture, withText: textContent)
            if success {
                // Show visual feedback
                showCopiedFeedback = true

                // Reset after delay
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                showCopiedFeedback = false
            }
        }
    }

    private func formatShareDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "M/d"

        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }

    private func isToday(_ dateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return dateString == formatter.string(from: Date())
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
                        .foregroundColor(
                            monitor.usageData.sessionUsagePercentage > 90 ? .red :
                            (monitor.usageData.sessionUsagePercentage > 70 ? .orange : .green)
                        )
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                monitor.usageData.sessionUsagePercentage > 90 ? Color.red :
                                (monitor.usageData.sessionUsagePercentage > 70 ? Color.orange : Color.green)
                            )
                            .frame(
                                width: min(
                                    geometry.size.width,
                                    geometry.size.width * (monitor.usageData.sessionUsagePercentage / 100)
                                ),
                                height: 8
                            )
                            .animation(.easeInOut(duration: 0.3), value: monitor.usageData.sessionUsagePercentage)
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
                Text(L10n.Session.sessionDetails)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                HStack {
                    Text(L10n.Session.plan)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(monitor.usageData.planDescription)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                }

                HStack {
                    Text(L10n.Session.startTime)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(formatTimeWithDate(session.startTime))
                        .font(.system(size: 11))
                }

                HStack {
                    Text(L10n.Session.endTime)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(formatTimeWithDate(session.endTime))
                        .font(.system(size: 11))
                }

                HStack {
                    Text(L10n.Session.elapsedTime)
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
                            .fill(
                                usagePercentage > 80 ? Color.red :
                                (usagePercentage > 60 ? Color.orange : Color.green)
                            )
                            .frame(
                                width: min(geometry.size.width, geometry.size.width * (usagePercentage / 100)),
                                height: 8
                            )
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

                ForEach(modelBreakdowns.sorted(by: { $0.actualCost > $1.actualCost }), id: \.modelName) { breakdown in
                    HStack {
                        Text(formatModelName(breakdown.modelName))
                            .font(.system(size: 12))
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(monitor.formatCost(breakdown.actualCost))
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
