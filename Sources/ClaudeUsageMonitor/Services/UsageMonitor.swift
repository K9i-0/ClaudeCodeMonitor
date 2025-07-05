import Foundation
import Combine

@MainActor
class UsageMonitor: ObservableObject, UsageMonitoring {
    @Published var usageData = UsageData()
    @Published var isLoading = false
    @Published var error: ClaudeMonitorError?

    private var timer: Timer?
    private let updateInterval = Constants.Timing.refreshInterval
    private let userDefaults = UserDefaultsManager.shared
    private let detectedPlanKey = "ClaudeUsageMonitor.detectedPlan"
    private let userPlanKey = "ClaudeUsageMonitor.userSelectedPlan"
    private lazy var notificationManager: NotificationManager? = {
        // バンドル環境でのみ通知マネージャーを初期化
        guard Bundle.main.bundleIdentifier != nil else {
            print("[DEBUG] Running outside of app bundle - notifications disabled")
            return nil
        }
        return NotificationManager.shared
    }()
    private var lastSessionId: String?

    // エラーメッセージ（後方互換性のため）
    var errorMessage: String? {
        error?.errorDescription
    }

    init() {
        // デバッグ情報を出力
        #if DEBUG
        print("[DEBUG] userPlanKey: \(userPlanKey) = \(String(describing: userDefaults.string(forKey: userPlanKey)))")
        print("[DEBUG] detectedPlanKey: \(detectedPlanKey) = \(String(describing: userDefaults.string(forKey: detectedPlanKey)))")
        #endif
        
        // ユーザーが手動選択したプランを優先的に読み込む
        if let userPlan = userDefaults.string(forKey: userPlanKey) {
            usageData.detectedPlanType = userPlan
            print("Loaded user selected plan: \(userPlan)")
        } else if let savedPlan = userDefaults.string(forKey: detectedPlanKey) {
            // 自動検出されたプランを読み込む（後方互換性）
            usageData.detectedPlanType = savedPlan
            print("Loaded auto-detected plan: \(savedPlan)")
        } else {
            print("No saved plan found, will auto-detect")
        }
        startMonitoring()
    }

    func startMonitoring() {
        fetchUsageData()

        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            Task { @MainActor in
                self.fetchUsageData()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func fetchUsageData() {
        print("Fetching usage data at \(Date())")
        Task {
            await fetchSessionData()
            await fetchDailyUsage()
            await fetchMonthlyUsage()
        }
    }

    private func fetchDailyUsage() async {
        isLoading = true
        error = nil

        do {
            // Calculate the first day of current month
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            let monthStart = dateFormatter.string(from: startOfMonth)
            let today = dateFormatter.string(from: now)
            
            print("Fetching usage data for current month: \(monthStart) to \(today)")
            
            // Fetch usage data for current month only
            let result = try await CommandExecutor.shared.executeCcusageCommand(
                subcommand: nil,
                additionalArgs: ["--since", monthStart, "--until", today]
            )
            let data = Data(result.utf8)
            let ccusageResponse = try JSONDecoder().decode(CcusageResponse.self, from: data)

            // Debug print
            print("API Response - Daily count: \(ccusageResponse.daily.count)")
            if let first = ccusageResponse.daily.first {
                print("First daily entry: date=\(first.date), cost=$\(first.totalCost)")
            }
            if let last = ccusageResponse.daily.last {
                print("Last daily entry: date=\(last.date), cost=$\(last.totalCost)")
            }
            print("Monthly total: $\(ccusageResponse.totals.totalCost)")

            // Get today's date in YYYY-MM-DD format for matching
            let dashFormatter = DateFormatter()
            dashFormatter.dateFormat = "yyyy-MM-dd"
            let todayWithDashes = dashFormatter.string(from: now)
            print("Looking for today's date: \(todayWithDashes)")

            // Find today's usage from the array
            if let todayData = ccusageResponse.daily.first(where: { $0.date == todayWithDashes }) {
                print("Found today's data: cost=$\(todayData.totalCost)")
                usageData.todayUsage = todayData
            } else {
                print("No data found for today")
                usageData.todayUsage = nil
            }

            // Store monthly total
            usageData.monthlyTotal = ccusageResponse.totals
            usageData.lastUpdated = Date()

            // Debug final state
            print("Final state - Today's cost: $\(usageData.todayUsage?.totalCost ?? 0)")
            print("Final state - Monthly cost: $\(usageData.monthlyTotal?.totalCost ?? 0)")

        } catch let decodingError as DecodingError {
            self.error = ClaudeMonitorError.parsingError(decodingError.localizedDescription)
            print("Decoding error: \(decodingError)")
        } catch {
            self.error = ClaudeMonitorError.unknownError(error.localizedDescription)
            print("Unexpected error: \(error)")
        }

        isLoading = false
    }

    private func fetchMonthlyUsage() async {
        // Monthly data is now fetched together with daily data
        // This method is kept for compatibility but does nothing
    }

    private func fetchSessionData() async {
        // Print environment info for debugging
        let runningFromXcode = ProcessInfo.processInfo.environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil
        print("[DEBUG] Running from Xcode: \(runningFromXcode)")
        print("[DEBUG] PATH: \(ProcessInfo.processInfo.environment["PATH"] ?? "not set")")

        do {
            let result = try await CommandExecutor.shared.executeCcusageCommand(subcommand: "blocks")
            let data = Data(result.utf8)
            let blocksResponse = try JSONDecoder().decode(BlocksResponse.self, from: data)

            // Get the active block
            print("Blocks response: \(blocksResponse.blocks.count) blocks")

            // 過去のセッションから最大トークン使用量を検出
            var maxTokens = 0
            for block in blocksResponse.blocks {
                if !block.isGap && block.totalTokens > maxTokens {
                    maxTokens = block.totalTokens
                }
            }
            usageData.historicalMaxTokens = maxTokens

            // プランタイプを自動判定して保存
            if maxTokens > UsageData.max5SessionTokenLimit {
                updateDetectedPlan("Max20")
            } else if maxTokens > UsageData.proSessionTokenLimit {
                updateDetectedPlan("Max5")
            } else {
                // 保存されたプランタイプがない場合のみProに設定
                if usageData.detectedPlanType == nil {
                    updateDetectedPlan("Pro")
                }
            }

            if let activeBlock = blocksResponse.blocks.first(where: { $0.isActive }) {
                usageData.activeSession = activeBlock
                print("Active session: \(activeBlock.totalTokens) tokens")

                // セッションが変わったかチェック
                checkSessionChange(activeBlock)

                // 通知チェック
                let burnRateValue = Double(usageData.sessionBurnRate) ?? 0
                notificationManager?.checkAndSendNotification(
                    for: usageData.sessionUsagePercentage,
                    burnRate: burnRateValue,
                    remainingTime: usageData.sessionRemainingTime
                )
            } else {
                print("No active session found")
                usageData.activeSession = nil
            }
        } catch {
            print("[DEBUG] Session data fetch failed: \(error.localizedDescription)")
            self.error = ClaudeMonitorError.commandExecutionError(error.localizedDescription)
        }
    }

    func formatTokens(_ tokens: Int) -> String {
        return NumberFormatters.formatTokens(tokens)
    }

    func formatCost(_ cost: Double) -> String {
        return NumberFormatters.formatCost(cost)
    }

    private func updateDetectedPlan(_ plan: String) {
        // ユーザーが手動でプランを選択している場合は自動更新しない
        if userDefaults.string(forKey: userPlanKey) != nil {
            return
        }

        if usageData.detectedPlanType != plan {
            usageData.detectedPlanType = plan
            userDefaults.set(plan, forKey: detectedPlanKey)
            userDefaults.synchronize()
            print("Updated detected plan to: \(plan)")
        }
    }

    func setUserPlan(_ plan: String) {
        usageData.detectedPlanType = plan
        userDefaults.set(plan, forKey: userPlanKey)
        // 自動検出のキーを削除
        userDefaults.removeObject(forKey: detectedPlanKey)
        userDefaults.synchronize()
        print("User selected plan: \(plan)")

        // UIを即座に更新するために、変更を通知
        objectWillChange.send()
    }

    func getUserPlan() -> String {
        return usageData.detectedPlanType ?? "Pro"
    }

    private func checkSessionChange(_ newSession: SessionBlock) {
        let sessionId = "\(newSession.startTime)-\(newSession.endTime)"

        if lastSessionId != nil && lastSessionId != sessionId {
            // セッションが変わった（リセットされた）
            notificationManager?.sendSessionResetNotification()
        }

        lastSessionId = sessionId
    }
}