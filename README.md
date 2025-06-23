# Claude Usage Monitor App

macOSのメニューバーに常駐し、Claude Codeの利用額をリアルタイムで表示するアプリケーション。

このアプリは [ccusage](https://github.com/ryoppippi/ccusage) CLIツールをラップしており、メニューバーから簡単に利用状況を確認できるようにしたものです。

## 機能

- 💰 メニューバーに今日の利用額を常時表示
- 📊 ポップオーバーで詳細情報を確認
  - 今日/今月の利用額
  - トークン数
  - モデル別内訳
- 🔄 5分ごとの自動更新
- 🔄 手動更新ボタン

## セットアップ

### 1. Node.jsサーバーのセットアップ（推奨）

ローカルサーバーを使用することで、npxのパス問題を回避できます：

```bash
cd server
npm install
npm start
```

サーバーは`http://127.0.0.1:3456`で起動します。

### 2. ビルド方法

#### 方法1: Xcodeを使用（推奨）

1. Xcodeでプロジェクトを開く
```bash
open Package.swift
```

2. Xcodeでビルド
- Product > Build（⌘B）でビルド
- Product > Run（⌘R）で実行

#### 方法2: コマンドラインでビルド

デバッグビルド:
```bash
swift build
```

リリースビルド:
```bash
swift build -c release
```

アプリケーションバンドルの作成:
```bash
# デバッグビルドの場合
swift build
mkdir -p ClaudeUsageMonitor.app/Contents/MacOS
mkdir -p ClaudeUsageMonitor.app/Contents/Resources
cp .build/arm64-apple-macosx/debug/ClaudeUsageMonitor ClaudeUsageMonitor.app/Contents/MacOS/
cp Info.plist ClaudeUsageMonitor.app/Contents/

# リリースビルドの場合
swift build -c release
mkdir -p ClaudeUsageMonitor.app/Contents/MacOS
mkdir -p ClaudeUsageMonitor.app/Contents/Resources
cp .build/arm64-apple-macosx/release/ClaudeUsageMonitor ClaudeUsageMonitor.app/Contents/MacOS/
cp Info.plist ClaudeUsageMonitor.app/Contents/

# 実行
open ClaudeUsageMonitor.app
```

ワンライナービルド（リリース版）:
```bash
swift build -c release && mkdir -p ClaudeUsageMonitor.app/Contents/MacOS && mkdir -p ClaudeUsageMonitor.app/Contents/Resources && cp .build/arm64-apple-macosx/release/ClaudeUsageMonitor ClaudeUsageMonitor.app/Contents/MacOS/ && cp Info.plist ClaudeUsageMonitor.app/Contents/ && open ClaudeUsageMonitor.app
```

## 必要な環境

- macOS 13.0以上
- Swift 5.9以上
- Node.js（ccusage CLIツールの実行に必要）

## 注意事項

- `npx ccusage@latest` コマンドが実行可能である必要があります
- 初回実行時はデータ取得に時間がかかる場合があります