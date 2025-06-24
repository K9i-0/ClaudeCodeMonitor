cask "ccmonitor" do
  version "0.1.5"
  sha256 "f6004ac4931a90506c032e25afbd75ee43334fcf82add57cd429f7ca4d3b6e72"

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

  app "ClaudeCodeMonitor.app"

  uninstall quit: "com.k9i.claude-code-monitor"

  zap trash: [
    "~/Library/Preferences/com.k9i.claude-code-monitor.plist",
    "~/Library/Application Support/Claude Code Monitor",
  ]
end