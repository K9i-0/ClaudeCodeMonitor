import Foundation
import Combine

@MainActor
class UsageMonitor: ObservableObject {
    @Published var usageData = UsageData()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var timer: Timer?
    private let updateInterval: TimeInterval = 300 // 5 minutes
    
    init() {
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
        errorMessage = nil
        
        do {
            // Try local server first
            if let url = URL(string: "http://127.0.0.1:3456/usage") {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let ccusageResponse = try JSONDecoder().decode(CcusageResponse.self, from: data)
                    
                    // Debug print
                    print("API Response - Daily count: \(ccusageResponse.daily.count)")
                    if let first = ccusageResponse.daily.first {
                        print("First daily entry: date=\(first.date), cost=$\(first.totalCost)")
                    }
                    print("Monthly total: $\(ccusageResponse.totals.totalCost)")
                    
                    // Get today's date in YYYY-MM-DD format
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let today = formatter.string(from: Date())
                    
                    // Find today's usage from the array
                    if let todayData = ccusageResponse.daily.first(where: { $0.date == today }) {
                        usageData.todayUsage = todayData
                    } else {
                        usageData.todayUsage = nil
                    }
                    
                    // Store monthly total
                    usageData.monthlyTotal = ccusageResponse.totals
                    usageData.lastUpdated = Date()
                    isLoading = false
                    return
                }
            }
        } catch {
            // Server not running or request failed, fall back to npx
            print("Local server not available, falling back to npx command")
        }
        
        // Fallback to npx command with better path handling
        print("[DEBUG] Daily data: falling back to npx command")
        do {
            let process = Process()
            
            // Try to use the same npx detection as in fetchSessionData
            let npxSearchPaths = [
                "/Users/\(NSUserName())/.local/share/mise/shims/npx",
                "/opt/homebrew/bin/npx",
                "/usr/local/bin/npx"
            ]
            
            var foundNpx = false
            for path in npxSearchPaths {
                let expandedPath = (path as NSString).expandingTildeInPath
                if FileManager.default.fileExists(atPath: expandedPath) {
                    process.executableURL = URL(fileURLWithPath: expandedPath)
                    process.arguments = ["ccusage@latest", "--json"]
                    foundNpx = true
                    print("[DEBUG] Using npx at: \(expandedPath)")
                    break
                }
            }
            
            if !foundNpx {
                // Use shell with extended PATH
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-l", "-c", 
                    "export PATH=\"$HOME/.local/share/mise/shims:/opt/homebrew/bin:/usr/local/bin:$PATH\" && npx ccusage@latest --json"]
                print("[DEBUG] Using shell with extended PATH for daily data")
            }
            
            let pipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = pipe
            process.standardError = errorPipe
            
            try process.run()
            process.waitUntilExit()
            
            // Check for errors
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            if !errorData.isEmpty {
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("ccusage error: \(errorString)")
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if !data.isEmpty {
                let response = try JSONDecoder().decode(CcusageResponse.self, from: data)
                // Get today's date in YYYY-MM-DD format
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let today = formatter.string(from: Date())
                
                // Find today's usage from the array
                if let todayData = response.daily.first(where: { $0.date == today }) {
                    usageData.todayUsage = todayData
                } else {
                    // If no data for today, create empty data
                    usageData.todayUsage = nil
                }
                
                // Store monthly total
                usageData.monthlyTotal = response.totals
                usageData.lastUpdated = Date()
            }
        } catch {
            errorMessage = "Failed to fetch usage data: \(error.localizedDescription)"
            print("Error details: \(error)")
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
            if let url = URL(string: "http://127.0.0.1:3456/blocks/active") {
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
                        if let activeBlock = blocksResponse.blocks.first(where: { $0.isActive }) {
                            usageData.activeSession = activeBlock
                            print("Active session: \(activeBlock.totalTokens) tokens, \(activeBlock.isActive ? "active" : "inactive")")
                            print("Session percentage: \(usageData.sessionTokenPercentage)%")
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
        }
        
        // Fallback: Try multiple methods to run ccusage
        print("[DEBUG] Falling back to direct ccusage execution")
        
        // Method 1: Try to find npx in common locations
        let npxSearchPaths = [
            "/Users/\(NSUserName())/.local/share/mise/shims/npx",
            "/opt/homebrew/bin/npx",
            "/usr/local/bin/npx",
            "/Users/\(NSUserName())/.nvm/default/bin/npx",
            "/Users/\(NSUserName())/.volta/bin/npx"
        ]
        
        var npxPath: String? = nil
        for path in npxSearchPaths {
            let expandedPath = (path as NSString).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expandedPath) {
                npxPath = expandedPath
                print("[DEBUG] Found npx at: \(expandedPath)")
                break
            }
        }
        
        // Method 2: Use which command to find npx
        if npxPath == nil {
            let whichProcess = Process()
            whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
            whichProcess.arguments = ["npx"]
            let whichPipe = Pipe()
            whichProcess.standardOutput = whichPipe
            whichProcess.standardError = Pipe()
            
            do {
                try whichProcess.run()
                whichProcess.waitUntilExit()
                
                let data = whichPipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !output.isEmpty {
                    npxPath = output
                    print("[DEBUG] Found npx via which: \(output)")
                }
            } catch {
                print("[DEBUG] which command failed: \(error)")
            }
        }
        
        // Method 3: Try with full shell initialization
        do {
            let process = Process()
            
            if let npxPath = npxPath {
                // Use found npx directly
                process.executableURL = URL(fileURLWithPath: npxPath)
                process.arguments = ["ccusage", "blocks", "--active", "--json"]
                print("[DEBUG] Using direct npx: \(npxPath)")
            } else {
                // Last resort: use shell with full environment
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-l", "-c", 
                    "export PATH=\"$HOME/.local/share/mise/shims:$HOME/.volta/bin:/opt/homebrew/bin:/usr/local/bin:$PATH\" && npx ccusage blocks --active --json"]
                print("[DEBUG] Using shell with extended PATH")
            }
            
            let pipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = pipe
            process.standardError = errorPipe
            
            try process.run()
            process.waitUntilExit()
            
            // Check for errors
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            if !errorData.isEmpty {
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("[DEBUG] ccusage stderr: \(errorString)")
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if !data.isEmpty {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[DEBUG] ccusage output length: \(jsonString.count) characters")
                }
                
                let blocksResponse = try JSONDecoder().decode(BlocksResponse.self, from: data)
                if let activeBlock = blocksResponse.blocks.first(where: { $0.isActive }) {
                    usageData.activeSession = activeBlock
                    print("[DEBUG] Session data loaded via fallback")
                }
            } else {
                print("[DEBUG] No data from ccusage command")
            }
        } catch {
            print("[DEBUG] All fallback methods failed: \(error)")
            print("[DEBUG] Error details: \(error.localizedDescription)")
        }
    }
    
    func formatTokens(_ tokens: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: tokens)) ?? "0"
    }
    
    func formatCost(_ cost: Double) -> String {
        return String(format: "$%.2f", cost)
    }
}

extension Date {
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: self)
    }
}