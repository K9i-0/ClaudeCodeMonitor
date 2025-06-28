import SwiftUI

struct DataAccessView: View {
    @EnvironmentObject var dataAccessManager: ClaudeDataAccessManager
    @EnvironmentObject var monitor: UsageMonitor
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 50))
                .foregroundStyle(.blue)
            
            Text("Claude Data Access Required")
                .font(.headline)
            
            Text("To monitor your Claude usage, this app needs access to your Claude data folder.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                Task {
                    isRequesting = true
                    let success = await dataAccessManager.requestAccess()
                    isRequesting = false
                    
                    if success {
                        print("[DataAccessView] Access granted, updating server...")
                        
                        // Update server with new path
                        ServerManager.shared.claudePath = dataAccessManager.claudePath
                        
                        // Stop server first if running
                        if ServerManager.shared.isServerRunning {
                            print("[DataAccessView] Stopping existing server...")
                            ServerManager.shared.stopServer()
                        }
                        
                        // Start server with new path
                        print("[DataAccessView] Starting server with new path...")
                        ServerManager.shared.checkAndStartServer()
                        
                        // Wait a bit for server to start before fetching data
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        
                        print("[DataAccessView] Fetching usage data...")
                        monitor.fetchUsageData()
                    }
                }
            }) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "folder.fill")
                    }
                    Text("Select Claude Data Folder")
                }
                .frame(minWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRequesting)
            
            Text("Typically located at ~/.claude")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}