import SwiftUI

struct ClaudeNotInstalledView: View {
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
                if let url = URL(string: "https://claude.ai/download") {
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