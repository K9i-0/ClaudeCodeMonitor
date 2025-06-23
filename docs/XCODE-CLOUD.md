# Xcode Cloud Setup for TestFlight Distribution

This document describes how to set up Xcode Cloud for automatic TestFlight distribution.

## ⚠️ 人間がやる必要があること

### 1. Apple Developer Program
- [ ] Apple Developer Programに登録（年額$99）
- [ ] Apple IDで[developer.apple.com](https://developer.apple.com)にサインイン

### 2. App IDの作成
1. [ ] [Apple Developer Portal](https://developer.apple.com)にアクセス
2. [ ] Certificates, Identifiers & Profilesに移動
3. [ ] Identifiers → + ボタン → App IDs → Continue
4. [ ] 以下を設定:
   - **Description**: Claude Usage Monitor
   - **Bundle ID**: Explicit → `com.k9i.claude-usage-monitor`
   - **Capabilities**:
     - ✅ App Sandbox
     - ✅ Hardened Runtime

### 3. App Store Connectでアプリ作成
1. [ ] [App Store Connect](https://appstoreconnect.apple.com)にサインイン
2. [ ] My Apps → + → New App
3. [ ] 以下を入力:
   - **Platform**: macOS
   - **Name**: Claude Usage Monitor
   - **Primary Language**: Japanese (or English)
   - **Bundle ID**: 先ほど作成したものを選択
   - **SKU**: claude-usage-monitor

### 4. Xcodeでの設定
1. [ ] プロジェクトを開く
2. [ ] Signing & Capabilities:
   - **Team**: あなたのDeveloper Team
   - **Bundle Identifier**: `com.k9i.claude-usage-monitor`
   - **Signing**: Automatically manage signing
3. [ ] Product → Xcode Cloud → Create Workflow
4. [ ] GitHubと連携（初回のみ）
5. [ ] ワークフローを設定:

#### ワークフロー設定
**基本設定:**
- **Name**: TestFlight Release
- **Description**: Automatic TestFlight distribution on version tags

**Start Conditions:**
- **Source Control Changes**
  - **Branch Changes**: OFF
  - **Tag Changes**: ON
    - **Tags Beginning With**: `v`
    - **Source Branch**: main

**Environment:**
- **Platform**: macOS
- **Xcode Version**: Latest Release
- **macOS Version**: Latest

**Actions:**
- **Archive - macOS**
  - **Platform**: macOS
  - **Scheme**: ClaudeUsageMonitor
  - **Configuration**: Release

**Post-Actions:**
- **TestFlight Internal Testing**: External Groups
- **Notify**: ON

### 5. TestFlightの設定
1. [ ] App Store Connect → TestFlight
2. [ ] Test Information を入力
3. [ ] Internal Groupを作成（任意の名前）
4. [ ] テスターを追加

## Xcode Cloudのカスタムスクリプト（オプション）

もしビルド時にカスタム処理が必要な場合は、リポジトリに`ci_scripts`ディレクトリを作成して以下のスクリプトを配置できます：

- `ci_post_clone.sh`: クローン後に実行
- `ci_pre_xcodebuild.sh`: ビルド前に実行  
- `ci_post_xcodebuild.sh`: ビルド後に実行

現時点では不要なので、リポジトリには含めていません。

## Workflow

### Automatic TestFlight Distribution

1. Create and push a version tag:
   ```bash
   git tag -a v1.0.0 -m "Version 1.0.0"
   git push origin v1.0.0
   ```

2. Xcode Cloud automatically:
   - Builds the app
   - Archives with proper signing
   - Uploads to TestFlight
   - Notifies internal testers

### Manual Builds

You can also trigger builds manually from Xcode or App Store Connect.

## Testing Groups

Configure testing groups in App Store Connect:

1. **Internal Testing**
   - Automatic distribution
   - Up to 100 testers
   - No review required

2. **External Testing** (optional)
   - Manual submission
   - Up to 10,000 testers
   - Requires TestFlight review

## Troubleshooting

### Build Failures

1. Check Xcode Cloud logs in App Store Connect
2. Verify signing certificates are valid
3. Ensure provisioning profiles include all capabilities

### Distribution Issues

1. Verify app metadata in App Store Connect
2. Check export compliance settings
3. Ensure TestFlight agreements are signed

## Best Practices

1. **Version Management**
   - Use semantic versioning (e.g., 1.0.0)
   - Tag format: `v1.0.0`
   - Build numbers auto-increment via CI_BUILD_NUMBER

2. **Testing**
   - Test each build internally before external distribution
   - Include release notes for testers
   - Monitor crash reports and feedback

3. **Security**
   - Never commit signing certificates to repository
   - Use Xcode Cloud's managed signing when possible
   - Enable App Sandbox and Hardened Runtime

## Integration with GitHub Actions

While Xcode Cloud handles TestFlight distribution, GitHub Actions continues to handle:
- Pull request checks
- Code quality (SwiftLint, tests)
- GitHub Releases with DMG files
- Homebrew distribution

This provides a comprehensive CI/CD pipeline:
- **GitHub Actions**: Open source distribution
- **Xcode Cloud**: App Store/TestFlight distribution