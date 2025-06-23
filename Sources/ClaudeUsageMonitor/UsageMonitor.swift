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
        Task {
            await fetchDailyUsage()
            await fetchMonthlyUsage()
        }
    }
    
    private func fetchDailyUsage() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Find npx command in common locations
            let npxPaths = [
                "/Users/\(NSUserName())/.local/share/mise/shims/npx",
                "/opt/homebrew/bin/npx",
                "/usr/local/bin/npx",
                "/Users/\(NSUserName())/.nvm/versions/node/*/bin/npx",
                "/Users/\(NSUserName())/.npm-global/bin/npx"
            ]
            
            var npxPath: String?
            for path in npxPaths {
                // Expand wildcards if needed
                let expandedPath = (path as NSString).expandingTildeInPath
                if FileManager.default.fileExists(atPath: expandedPath) {
                    npxPath = expandedPath
                    break
                }
                
                // Check for wildcard patterns
                if path.contains("*") {
                    let directory = (path as NSString).deletingLastPathComponent
                    let expandedDir = (directory as NSString).expandingTildeInPath
                    if let contents = try? FileManager.default.contentsOfDirectory(atPath: expandedDir) {
                        for item in contents {
                            let fullPath = (expandedDir as NSString).appendingPathComponent(item + "/bin/npx")
                            if FileManager.default.fileExists(atPath: fullPath) {
                                npxPath = fullPath
                                break
                            }
                        }
                    }
                }
            }
            
            // If not found in common locations, try using shell
            let process = Process()
            if let foundNpxPath = npxPath {
                print("Using npx at: \(foundNpxPath)")
                process.executableURL = URL(fileURLWithPath: foundNpxPath)
                process.arguments = ["ccusage@latest", "--json"]
            } else {
                print("npx not found in common locations, using shell fallback")
                // Fallback to shell with proper PATH setup
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-l", "-c", "export PATH=\"$HOME/.local/share/mise/shims:$PATH\" && npx ccusage@latest --json"]
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