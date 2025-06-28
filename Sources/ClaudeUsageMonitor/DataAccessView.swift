import SwiftUI

struct DataAccessView: View {
    @EnvironmentObject var dataAccessManager: ClaudeDataAccessManager
    @EnvironmentObject var monitor: UsageMonitor
    @State private var isRequesting = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 50))
                .foregroundStyle(.blue)
            
            Text("Permission Required")
                .font(.headline)
            
            Text("Grant access to monitor your Claude usage")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                print("[DataAccessView] Button clicked")
                isRequesting = true
                
                Task { @MainActor in
                    let success = await dataAccessManager.requestAccess()
                    print("[DataAccessView] Request completed with success: \(success)")
                    
                    if success {
                        print("[DataAccessView] Access granted, fetching usage data...")
                        
                        // Helper item is already running, just fetch data
                        // Wait a bit for any filesystem operations to complete
                        let waitTime = UInt64(Constants.Timing.dataAccessWaitTime * 1_000_000_000)
                        try? await Task.sleep(nanoseconds: waitTime)
                        
                        print("[DataAccessView] Fetching usage data...")
                        monitor.fetchUsageData()
                    } else {
                        // Access request was cancelled or failed
                        errorMessage = "Access to Claude data folder was not granted."
                        showingError = true
                    }
                    
                    isRequesting = false
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
                    Text("Grant Access to Claude Data")
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
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
}