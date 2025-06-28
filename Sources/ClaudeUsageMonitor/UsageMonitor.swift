import Foundation
import Combine

@MainActor
class UsageMonitor: ObservableObject, UsageMonitoring {
    @Published var usageData = UsageData()
    @Published var isLoading = false
    @Published var error: ClaudeMonitorError?
    
    private var timer: Timer?
    private let updateInterval = Constants.Timing.refreshInterval
    private let userDefaults = UserDefaults.standard
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
        // ユーザーが手動選択したプランを優先的に読み込む
        if let userPlan = userDefaults.string(forKey: userPlanKey) {
            usageData.detectedPlanType = userPlan
            print("Loaded user selected plan: \(userPlan)")
        } else if let savedPlan = userDefaults.string(forKey: detectedPlanKey) {
            // 自動検出されたプランを読み込む（後方互換性）
            usageData.detectedPlanType = savedPlan
            print("Loaded auto-detected plan: \(savedPlan)")
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
            // Try local server first
            if let url = URL(string: "http://127.0.0.1:8456/usage") {
                var request = URLRequest(url: url)
                request.timeoutInterval = 5.0 // 5 second timeout
                
                print("Attempting to fetch from server: \(url)")
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    guard httpResponse.statusCode == 200 else {
                        throw ClaudeMonitorError.networkError("サーバーエラー: ステータスコード \(httpResponse.statusCode)")
                    }
                    
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
                    
                    // Get today's date in YYYY-MM-DD format
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let today = formatter.string(from: Date())
                    print("Looking for today's date: \(today)")
                    
                    // Find today's usage from the array
                    if let todayData = ccusageResponse.daily.first(where: { $0.date == today }) {
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
                    
                    isLoading = false
                    return
                }
            }
        } catch let decodingError as DecodingError {
            error = ClaudeMonitorError.parsingError(decodingError.localizedDescription)
            print("Decoding error: \(decodingError)")
        } catch {
            // Server not running or request failed
            print("Local server not available: \(error.localizedDescription)")
            print("Error type: \(type(of: error))")
            print("Full error: \(error)")
            self.error = ClaudeMonitorError.networkError(L10n.Error.serverNotRunning)
            isLoading = false
            return
        }
        
        isLoading = false
    }
    
    private func fetchMonthlyUsage() async {
        // Monthly data is now fetched together with daily data
        // This method is kept for compatibility but does nothing
    }
    
    private func fetchSessionData() async {
        // Print environment info for debugging
        print("[DEBUG] Running from Xcode: \(ProcessInfo.processInfo.environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil)")
        print("[DEBUG] PATH: \(ProcessInfo.processInfo.environment["PATH"] ?? "not set")")
        
        do {
            // Try local server first for session data
            if let url = URL(string: "http://127.0.0.1:8456/blocks/active") {
                print("[DEBUG] Attempting server connection to \(url)")
                
                var request = URLRequest(url: url)
                request.timeoutInterval = 2.0 // Quick timeout
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("[DEBUG] Server response: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
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
                            print("Active session: \(activeBlock.totalTokens) tokens, \(activeBlock.isActive ? "active" : "inactive")")
                            print("Historical max tokens: \(maxTokens)")
                            print("Session percentage: \(usageData.sessionUsagePercentage)%")
                            print("Detected plan: \(usageData.detectedPlan)")
                            
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
                        return
                    }
                }
            }
        } catch {
            print("[DEBUG] Server connection failed: \(error.localizedDescription)")
            self.error = ClaudeMonitorError.networkError(L10n.Error.serverNotRunning)
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
            print("Updated detected plan to: \(plan)")
        }
    }
    
    func setUserPlan(_ plan: String) {
        usageData.detectedPlanType = plan
        userDefaults.set(plan, forKey: userPlanKey)
        // 自動検出のキーを削除
        userDefaults.removeObject(forKey: detectedPlanKey)
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