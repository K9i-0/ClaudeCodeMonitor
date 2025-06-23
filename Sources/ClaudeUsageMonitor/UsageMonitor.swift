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
        
        // Fallback to npx command
        do {
            let process = Process()
            // Use shell to ensure proper PATH resolution
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-l", "-c", "npx ccusage@latest --json"]
            
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