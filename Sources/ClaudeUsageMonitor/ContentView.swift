import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: UsageMonitor
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Claude Usage Monitor")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    isRefreshing = true
                    monitor.fetchUsageData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isRefreshing = false
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Refresh usage data")
            }
            .padding()
            
            Divider()
            
            // Tab selector
            Picker("", selection: $selectedTab) {
                Text("Session").tag(0)
                Text("Today").tag(1)
                Text("Month").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if selectedTab == 0 {
                        // Session usage
                        if let session = monitor.usageData.activeSession {
                            SessionDetailView(session: session, monitor: monitor)
                        } else {
                            EmptyStateView(message: "No active session")
                        }
                    } else if selectedTab == 1 {
                        // Daily usage
                        if let daily = monitor.usageData.todayUsage {
                            UsageDetailView(
                                title: "Today's Usage",
                                totalCost: daily.totalCost,
                                totalTokens: daily.totalTokens,
                                modelBreakdowns: daily.modelBreakdowns,
                                monitor: monitor,
                                usagePercentage: monitor.usageData.dailyCostPercentage,
                                formattedPercentage: monitor.usageData.formattedDailyPercentage
                            )
                        } else {
                            EmptyStateView(message: "No usage data for today")
                        }
                    } else {
                        // Monthly usage
                        if let monthly = monitor.usageData.monthlyTotal {
                            UsageDetailView(
                                title: "Monthly Usage",
                                totalCost: monthly.totalCost,
                                totalTokens: monthly.totalTokens,
                                modelBreakdowns: [],
                                monitor: monitor,
                                usagePercentage: monitor.usageData.monthlyCostPercentage,
                                formattedPercentage: monitor.usageData.formattedMonthlyPercentage
                            )
                        } else {
                            EmptyStateView(message: "No monthly usage data available")
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("Last updated: \(monitor.usageData.lastUpdated.formattedTime())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(LinkButtonStyle())
            }
            .padding()
        }
        .frame(width: 300, height: 380)
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
                Text("Session Details")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("Started: \(formatTime(session.startTime))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Text("Ends: \(formatTime(session.endTime))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatTime(_ timeString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: timeString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "HH:mm"
            return displayFormatter.string(from: date)
        }
        return timeString
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
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}