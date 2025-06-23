# Xcodeプロジェクトセットアップ手順

## 新規Xcodeプロジェクトを作成する場合

1. **Xcodeで新規プロジェクト作成**
   - File > New > Project
   - macOS > App を選択
   - Product Name: ClaudeUsageMonitor
   - Interface: SwiftUI
   - Language: Swift
   - Bundle Identifier: com.example.claudeusagemonitor

2. **既存のSPMコードを統合**
   - 生成されたプロジェクトのデフォルトファイルを削除
   - Sources/ClaudeUsageMonitor/ 内のファイルをプロジェクトに追加
   - Info.plistの内容を統合

3. **ビルド設定**
   - Deployment Target: macOS 13.0
   - LSUIElement を Info.plist に追加（メニューバーアプリとして設定）

## Package.swiftを直接使用する場合

1. **Xcodeで開く**
   ```bash
   open Package.swift
   ```

2. **実行可能ターゲットの設定**
   - Scheme > Edit Scheme
   - Run > Info > Executable で "ClaudeUsageMonitor" を選択

3. **Info.plist埋め込み設定**
   Package.swiftに以下を追加：
   ```swift
   .executableTarget(
       name: "ClaudeUsageMonitor",
       dependencies: [],
       resources: [.process("Info.plist")],
       linkerSettings: [
           .unsafeFlags([
               "-Xlinker", "-sectcreate",
               "-Xlinker", "__TEXT",
               "-Xlinker", "__info_plist",
               "-Xlinker", "Info.plist"
           ])
       ]
   )
   ```

## 推奨される構成

現在のプロジェクトの場合、最小限の変更で済む「Package.swiftを直接使用」する方法をお勧めします。