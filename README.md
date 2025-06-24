# Claude Code Usage Monitor

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

<p align="center">
  <strong>English</strong> | <a href="README.ja.md">日本語</a>
</p>

A macOS menubar application that monitors Claude Code API usage and costs in real-time.

This app wraps the [ccusage](https://github.com/ryoppippi/ccusage) CLI tool to provide visual, easy-to-understand usage tracking for Claude Code.

## ✨ Key Features

### Session-Based Monitoring
- **Real-time Display**: Shows current session usage percentage in the menubar
- **Session Management**: Accurate tracking based on Claude Code's 5-hour sessions
- **Plan Support**: Auto-detection and manual setting for Pro/Max5/Max20 plans
- **Usage Notifications**: Alerts when reaching 90% usage

### Detailed Usage Analytics
- 📊 **Current Session Information**
  - Remaining tokens and percentage
  - Session cost (reference value)
  - Burn rate (tokens/minute)
  - Time remaining prediction
- 📈 **Historical Data**
  - Daily usage and costs
  - Model-specific breakdown
  - Past session history

### Additional Features
- 🔄 Auto-refresh every 5 minutes
- 🔄 Manual refresh button
- ⚙️ Plan settings (Pro/Max5/Max20)
- 🌐 Stable operation with local server mode

## 🚀 Installation

### Coming Soon
- **Homebrew Cask**: `brew install --cask claude-usage-monitor` (in preparation)
- **App Store**: Direct installation from Mac App Store (in preparation)

### Current Method (Build from Source)

## 📋 Requirements

- macOS 13.0 or later
- Swift 5.9 or later
- Node.js 18 or later (required for ccusage CLI tool)
- Xcode 15 or later (for development)

## 🛠️ Setup

### 1. Clone the Repository

```bash
git clone https://github.com/K9i-0/ClaudeUsageMonitor.git
cd ClaudeUsageMonitor
```

### 2. Node.js Server Setup (Recommended)

Using a local server provides more stable operation:

```bash
cd server
npm install
npm start
```

The server will start at `http://127.0.0.1:3456`.

### 3. Build Instructions

#### Method 1: Using Xcode (Recommended)

```bash
open Package.swift
```

In Xcode:
- **Build**: Product > Build (⌘B)
- **Run**: Product > Run (⌘R)

#### Method 2: Command Line Build

```bash
# Release build
swift build -c release

# Create app bundle
mkdir -p ClaudeUsageMonitor.app/Contents/MacOS
mkdir -p ClaudeUsageMonitor.app/Contents/Resources
cp .build/arm64-apple-macosx/release/ClaudeUsageMonitor ClaudeUsageMonitor.app/Contents/MacOS/
cp Info.plist ClaudeUsageMonitor.app/Contents/

# Launch the app
open ClaudeUsageMonitor.app
```

## 🖼️ Screenshots

<p align="center">
  <i>Screenshots coming soon</i>
</p>

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

## 📝 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [ccusage](https://github.com/ryoppippi/ccusage) - CLI tool for fetching Claude usage
- [Anthropic](https://www.anthropic.com/) - The creators of Claude AI

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/K9i-0/ClaudeUsageMonitor/issues)
- **Discussions**: [GitHub Discussions](https://github.com/K9i-0/ClaudeUsageMonitor/discussions)

## 🔗 Related Links

- [Claude Code](https://claude.ai/code) - Official Claude Code by Anthropic
- [ccusage CLI](https://github.com/ryoppippi/ccusage) - The underlying CLI tool