# Claude Usage Monitor

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

macOSのメニューバーに常駐し、Claude Codeの使用状況をリアルタイムでモニタリングするアプリケーション。

このアプリは [ccusage](https://github.com/ryoppippi/ccusage) CLIツールをラップし、Claude Codeの使用状況を視覚的に分かりやすく表示します。

## ✨ 主な機能

### セッションベースモニタリング
- **リアルタイム表示**: メニューバーに現在のセッション使用率を表示
- **セッション管理**: Claude Codeの5時間セッションに基づいた正確な追跡
- **プラン対応**: Pro/Max5/Max20プランの自動検出と手動設定
- **使用率通知**: 90%到達時に通知

### 詳細な使用状況分析
- 📊 **現在のセッション情報**
  - 残りトークン数とパーセンテージ
  - セッションコスト（参考値）
  - バーンレート（トークン/分）
  - 残り時間予測
- 📈 **履歴データ**
  - 日別の使用量とコスト
  - モデル別の内訳
  - 過去のセッション一覧

### その他の機能
- 🔄 5分ごとの自動更新
- 🔄 手動更新ボタン
- ⚙️ プラン設定（Pro/Max5/Max20）
- 🌐 ローカルサーバーモードでの安定動作

## 🚀 インストール

### 今後の予定
- **Homebrew Cask**: `brew install --cask claude-usage-monitor` (準備中)
- **App Store**: Mac App Storeから直接インストール (準備中)

### 現在の方法（ソースからビルド）

## 📋 必要な環境

- macOS 13.0以上
- Swift 5.9以上
- Node.js 18以上（ccusage CLIツールの実行に必要）
- Xcode 15以上（開発時）

## 🛠️ セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/yourusername/ClaudeUsageMonitor.git
cd ClaudeUsageMonitor
```

### 2. Node.jsサーバーのセットアップ（推奨）

ローカルサーバーを使用することで、より安定した動作を実現できます：

```bash
cd server
npm install
npm start
```

サーバーは`http://127.0.0.1:3456`で起動します。

### 3. ビルド方法

#### 方法1: Xcodeを使用（推奨）

```bash
open Package.swift
```

Xcodeで:
- **ビルド**: Product > Build（⌘B）
- **実行**: Product > Run（⌘R）

#### 方法2: コマンドラインでビルド

```bash
# リリースビルド
swift build -c release

# アプリバンドルの作成
mkdir -p ClaudeUsageMonitor.app/Contents/MacOS
mkdir -p ClaudeUsageMonitor.app/Contents/Resources
cp .build/arm64-apple-macosx/release/ClaudeUsageMonitor ClaudeUsageMonitor.app/Contents/MacOS/
cp Info.plist ClaudeUsageMonitor.app/Contents/

# アプリを起動
open ClaudeUsageMonitor.app
```

## 🖼️ スクリーンショット

<p align="center">
  <i>スクリーンショットは準備中です</i>
</p>

## 🤝 コントリビューション

コントリビューションを歓迎します！詳細は[CONTRIBUTING.md](CONTRIBUTING.md)をご覧ください。

### 開発に参加する

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add some amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## 📝 ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。

## 🙏 謝辞

- [ccusage](https://github.com/ryoppippi/ccusage) - Claude使用状況を取得するCLIツール
- [Anthropic](https://www.anthropic.com/) - Claude AIの開発元

## 💬 サポート

- **Issues**: [GitHub Issues](https://github.com/yourusername/ClaudeUsageMonitor/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/ClaudeUsageMonitor/discussions)

## 🔗 関連リンク

- [Claude Code](https://claude.ai/code) - Anthropic公式のClaude Code
- [ccusage CLI](https://github.com/ryoppippi/ccusage) - ベースとなっているCLIツール