cask "ccmonitor" do
  version "0.1.6"
  sha256 "4913490738222396f361ad5dd48d0620ff26fad80db8bd75967a1f353b240140"

  url "https://github.com/K9i-0/ClaudeCodeMonitor/releases/download/v#{version}/ClaudeCodeMonitor-#{version}.dmg"
  name "ClaudeCodeMonitor"
  desc "Monitor Claude Code API usage and costs in your menubar"
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
    "~/Library/Application Support/ClaudeCodeMonitor",
  ]
end