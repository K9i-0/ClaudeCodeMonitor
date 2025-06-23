# Claude Usage Monitor App

macOSのメニューバーに常駐し、Claude Codeの利用額をリアルタイムで表示するアプリケーション。

## 機能

- 💰 メニューバーに今日の利用額を常時表示
- 📊 ポップオーバーで詳細情報を確認
  - 今日/今月の利用額
  - トークン数
  - モデル別内訳
- 🔄 5分ごとの自動更新
- 🔄 手動更新ボタン

## ビルド方法

```bash
swift build
```

## アプリケーションバンドルの作成

```bash
# ビルド
swift build

# アプリケーションバンドルの作成
mkdir -p ClaudeUsageMonitor.app/Contents/MacOS
mkdir -p ClaudeUsageMonitor.app/Contents/Resources
cp .build/arm64-apple-macosx/debug/ClaudeUsageMonitor ClaudeUsageMonitor.app/Contents/MacOS/
cp Info.plist ClaudeUsageMonitor.app/Contents/
```

## 実行

```bash
open ClaudeUsageMonitor.app
```

## 必要な環境

- macOS 13.0以上
- Swift 5.9以上
- Node.js（ccusage CLIツールの実行に必要）

## 注意事項

- `npx ccusage@latest` コマンドが実行可能である必要があります
- 初回実行時はデータ取得に時間がかかる場合があります