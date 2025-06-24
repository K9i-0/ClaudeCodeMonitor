# Changelog

All notable changes to Claude Code Monitor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-06-24

### Added
- Initial release of Claude Code Monitor
- Real-time session monitoring in macOS menubar
- Support for Claude Code Pro/Max5/Max20 plans
- Session-based usage tracking (5-hour sessions)
- Visual progress indicators with color coding
- Burn rate calculation (tokens/minute)
- Time remaining predictions
- Historical usage data viewing
- Daily usage summaries
- Model-specific usage breakdown
- Cost tracking (reference values)
- 90% usage threshold notifications
- Multi-language support (English/Japanese)
- Auto-refresh every 5 minutes
- Manual refresh option
- Local server mode for stable operation
- App Sandbox enabled for security

### Technical Details
- Built with Swift 5.9 and SwiftUI
- Requires macOS 13.0 or later
- Uses ccusage CLI tool for data fetching
- Implements MVVM architecture
- Protocol-oriented design for testability

### Known Issues
- Requires Node.js 18+ for ccusage CLI
- Initial release is not code-signed with Developer ID
- Users may need to allow the app in Security & Privacy settings

[1.0.0]: https://github.com/K9i-0/ClaudeCodeMonitor/releases/tag/v1.0.0