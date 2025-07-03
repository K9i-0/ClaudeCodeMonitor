import SwiftUI

struct ClaudeNotInstalledView: View {
    @StateObject private var languageSettings = LanguageSettings.shared
    
    private var setupURL: String {
        let langCode = languageSettings.currentLanguage == .japanese ? "ja" : "en"
        return "https://docs.anthropic.com/\(langCode)/docs/claude-code/setup"
    }
    
    var body: some View {
        VStack(spacing: 20) {
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
        }
        .frame(width: 380, height: 300)
        .padding()
    }
}