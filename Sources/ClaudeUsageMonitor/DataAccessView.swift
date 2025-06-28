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
                        // Update server with new path
                        ServerManager.shared.claudePath = dataAccessManager.claudePath
                        
                        // Restart server if it's running
                        if ServerManager.shared.isServerRunning {
                            ServerManager.shared.stopServer()
                            ServerManager.shared.checkAndStartServer()
                        } else {
                            ServerManager.shared.checkAndStartServer()
                        }
                        
                        // Fetch data
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