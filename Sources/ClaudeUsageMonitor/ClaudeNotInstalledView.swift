import SwiftUI

struct ClaudeNotInstalledView: View {
    @StateObject private var languageSettings = LanguageSettings.shared
    @State private var isChecking = false
    @State private var showRestartMessage = false
    
    private var setupURL: String {
        let langCode = languageSettings.currentLanguage == .japanese ? "ja" : "en"
        return "https://docs.anthropic.com/\(langCode)/docs/claude-code/setup"
    }
    
    private func checkForClaudeCode() {
        isChecking = true
        
        // Add a small delay to show the checking state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
            let claudePath = homeDirectory.appendingPathComponent(".claude")
            let projectsPath = claudePath.appendingPathComponent("projects")
            
            if FileManager.default.fileExists(atPath: projectsPath.path) {
                // Claude Code is now installed
                showRestartMessage = true
            }
            isChecking = false
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if showRestartMessage {
                // Show success message
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)
                
                Text("Claude Code Detected!")
                    .font(.headline)
                
                Text("Please restart the app to continue")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit App")
                        .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                
                #if DEBUG
                Text("Note: In Xcode debug mode, you'll need to manually restart")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                #endif
            } else {
                // Show install prompt
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)
                
                Text("Claude Code Required")
                    .font(.headline)
                
                Text("This app requires Claude Code to be installed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    if let url = URL(string: setupURL) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("Install Claude Code")
                        .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                
                Divider()
                    .padding(.horizontal, 40)
                
                VStack(spacing: 8) {
                    Text("After installation:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            checkForClaudeCode()
                        }) {
                            HStack {
                                if isChecking {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .frame(width: 16, height: 16)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text("Check Again")
                            }
                            .frame(minWidth: 100)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isChecking)
                        
                        Button(action: {
                            NSApplication.shared.terminate(nil)
                        }) {
                            Text(L10n.Action.quit)
                                .frame(minWidth: 60)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .frame(width: 380, height: 300)
        .padding()
    }
}