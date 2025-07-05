import SwiftUI

struct EnvironmentSetupView: View {
    @StateObject private var languageSettings = LanguageSettings.shared
    @State private var isChecking = false
    @State private var showRestartMessage = false
    @State private var environmentCheck = EnvironmentCheckResult()
    
    private var setupURL: String {
        let langCode = languageSettings.currentLanguage == .japanese ? "ja" : "en"
        return "https://docs.anthropic.com/\(langCode)/docs/claude-code/setup"
    }
    
    private var nodeInstallURL: String {
        "https://nodejs.org/"
    }
    
    private var bunInstallURL: String {
        "https://bun.sh/"
    }
    
    private func checkEnvironment() {
        isChecking = true
        
        Task {
            let result = await CommandExecutor.shared.checkEnvironment()
            
            await MainActor.run {
                environmentCheck = result
                
                // If all requirements are met, show restart message
                if result.isClaudeCodeInstalled && result.canExecuteCommands {
                    showRestartMessage = true
                }
                
                isChecking = false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if showRestartMessage {
                // Show success message
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)
                
                Text(L10n.Environment.allRequirementsMet)
                    .font(.headline)
                
                Text(L10n.Environment.pleaseRestart)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text(L10n.Action.quit)
                        .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                
                #if DEBUG
                Text(L10n.Environment.debugRestartNote)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                #endif
            } else {
                // Show environment check
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)
                
                Text(L10n.Environment.setupRequired)
                    .font(.headline)
                
                // Requirements list
                VStack(alignment: .leading, spacing: 12) {
                    RequirementRow(
                        title: "Claude Code",
                        isInstalled: environmentCheck.isClaudeCodeInstalled,
                        installURL: setupURL,
                        installButtonTitle: L10n.Action.installClaudeCode
                    )
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Environment.nodeOrBunRequired)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        RequirementRow(
                            title: "Bun (bunx)",
                            isInstalled: environmentCheck.isBunInstalled,
                            installURL: bunInstallURL,
                            installButtonTitle: L10n.Action.installBun,
                            isOptional: true
                        )
                        
                        RequirementRow(
                            title: "Node.js (npx)",
                            isInstalled: environmentCheck.isNpxInstalled,
                            installURL: nodeInstallURL,
                            installButtonTitle: L10n.Action.installNode,
                            isOptional: true
                        )
                    }
                }
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .padding(.horizontal, 40)
                
                VStack(spacing: 8) {
                    Text(L10n.Environment.afterInstallation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            checkEnvironment()
                        }) {
                            HStack {
                                if isChecking {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .frame(width: 16, height: 16)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text(L10n.Action.checkAgain)
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
        .frame(width: 480, height: 360)
        .padding()
        .onAppear {
            checkEnvironment()
        }
    }
}

struct RequirementRow: View {
    let title: String
    let isInstalled: Bool
    let installURL: String
    let installButtonTitle: String
    var isOptional: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: isInstalled ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isInstalled ? .green : .secondary)
                .frame(width: 20)
            
            Text(title)
                .font(.system(.body, design: .monospaced))
                .frame(width: 120, alignment: .leading)
            
            if isInstalled {
                Text(L10n.Environment.installed)
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Button(action: {
                    if let url = URL(string: installURL) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text(installButtonTitle)
                        .font(.caption)
                }
                .buttonStyle(.link)
                
                if isOptional {
                    Text(L10n.Environment.optional)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    EnvironmentSetupView()
}