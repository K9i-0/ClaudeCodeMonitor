# Changelog

All notable changes to this project will be documented in this file.















## [0.7.12] - 2025-07-06

### Fixed
- CI/CDパイプラインのビルドエラーを修正
  - GitHub ActionsのmacOS-latestランナーでXcode 15.xが利用不可になったため、Xcode 16.0に更新
  - Sparkleフレームワークとツールを最新の2.7.1に統一

## [0.7.11] - 2025-07-06

### Added
- バージョン検証成功時に古い警告コメントを自動削除する機能

## [0.7.10] - 2025-07-06

### Fixed
- CI環境でのSparkle appcast生成エラーを修正
- プライベートキーの改行問題を解決（echo -nを使用）
- generate-appcast.shスクリプトを削除してワークフローに直接記述
- Sparkleを最新版（2.6.4）に更新

## [0.7.9] - 2025-07-06

### Fixed
- CI環境でSparkleの`sign_update`ツールが見つからない問題を修正
- setup-sparkle GitHub Actionを導入してSparkleツールのセットアップを自動化
- Sparkleを最新のセキュリティバージョン(2.6.2)に更新

## [0.7.8] - 2025-07-06

### Fixed
- Sparkle署名生成の非推奨フラグを修正 (generate-appcast.sh, sign-update.sh)

## [0.7.7] - 2025-07-06

### Fixed
- Update /start-work slash command to properly execute bash commands instead of pre-execution format

## [0.7.6] - 2025-07-06

### Fixed
- Add DMG_PATH environment variable for Sparkle appcast generation

### Changed
- Update /bump-version command documentation to clarify default behavior

## [0.7.5] - 2025-07-06

### Fixed
- Remove GITHUB_TOKEN from workflow_call secrets (reserved name conflict)

## [0.7.4] - 2025-07-06

### Fixed
- CI/CD workflow syntax errors in release-common.yml (heredoc issue)
- YAML indentation issues in all workflow files
- Security warnings for github.head_ref usage in pr-validation.yml and version-helper.yml
- ShellCheck warnings for unquoted GITHUB_OUTPUT variables

## [0.7.3] - 2025-07-06

### Added
- Common reusable workflow for unified release processes

### Changed
- Simplified download instructions in README (removed unnecessary developer verification warnings)
- Unified release workflows - dev and stable now use the same workflow with parameters
- Both dev and stable releases now support Sparkle auto-update

### Fixed
- Fixed EOF delimiter error in development release workflow changelog generation
- Simplified release-dev workflow by removing unnecessary job separation
- Fixed command injection vulnerability in certificate name extraction
- Added secure cleanup for certificate files using trap

## [0.7.2] - 2025-07-06

### Added
- 

### Changed
- 

### Fixed
- Fixed code signing issue in release-dev workflow by adding proper keychain configuration
- Unified release workflows with reusable build-and-sign workflow
- Improved certificate handling and error logging in signing process

## [0.7.1] - 2025-07-06

### Added
- 

### Changed
- 

### Fixed
- 

## [0.7.0] - 2025-07-06

### Added
- Sparkle framework integration for automatic updates
- Update settings UI in Settings tab
- EdDSA signature verification for secure updates
- Automatic appcast.xml generation in release workflow

### Changed
- Refactored GitHub Actions workflows to remove duplicates
- Updated release workflows to support Sparkle appcast generation

### Fixed
- SessionBlock.usagePercentage compatibility issue with latest codebase


## [Unreleased]

## [1.0.0] - TBD
### Added
- Initial release of ClaudeCodeMonitor

## [0.1.8] - TBD
### Fixed
- Semantic versioning workflow implementation
- Package.swift version comment handling
