cask "ccmonitor" do
  version "1.0.0"
  sha256 "PLACEHOLDER_SHA256"  # This will be updated after release

  url "https://github.com/K9i-0/ClaudeCodeMonitor/releases/download/v#{version}/ClaudeCodeMonitor-#{version}.dmg"
  name "Claude Code Monitor"
  desc "Real-time monitoring for Claude Code API usage"
  homepage "https://github.com/K9i-0/ClaudeCodeMonitor"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates false
  depends_on macos: ">= :ventura"

  app "Claude Code Monitor.app"

  uninstall quit: "com.k9i.claude-code-monitor"

  zap trash: [
    "~/Library/Preferences/com.k9i.claude-code-monitor.plist",
    "~/Library/Application Support/Claude Code Monitor",
  ]
end