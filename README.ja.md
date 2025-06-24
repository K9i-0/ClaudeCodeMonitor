# Claude Code Monitor

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

<p align="center">
  <a href="README.md">English</a> | <strong>日本語</strong>
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

### Homebrew Cask（準備中）
```bash
brew install --cask ccmonitor
```

**注意**: 初回起動時に「開発元を検証できません」と表示される場合：
1. 警告ダイアログで「キャンセル」をクリック
2. システム設定 → プライバシーとセキュリティを開く
3. Claude Code Monitorの「このまま開く」をクリック
4. またはアプリを右クリックして「開く」を選択

### 現在の方法（ソースからビルド）

## 📋 必要な環境

- macOS 13.0以上
- Swift 5.9以上
- Node.js 18以上（ccusage CLIツールの実行に必要）
- Xcode 15以上（開発時）

## 🛠️ セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/K9i-0/ClaudeCodeMonitor.git
cd ClaudeCodeMonitor
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
mkdir -p ClaudeCodeMonitor.app/Contents/MacOS
mkdir -p ClaudeCodeMonitor.app/Contents/Resources
cp .build/arm64-apple-macosx/release/ClaudeCodeMonitor ClaudeCodeMonitor.app/Contents/MacOS/
cp Info.plist ClaudeCodeMonitor.app/Contents/

# アプリを起動
open ClaudeCodeMonitor.app
```

## 🖼️ スクリーンショット

### メニューバーアイコン
現在のセッション使用率をメニューバーに直接表示：
- 🔵 青（0-50%）：安全な使用範囲
- 🟠 オレンジ（50-75%）：中程度の使用
- 🔴 赤（75%+）：高使用率警告

![メニューバーアイコン](docs/images/menubar-icon.png)

### 現在のセッション表示
5時間セッションの詳細表示：
- 大きくて読みやすい残りトークン数表示
- 色分けされたプログレスバー
- バーンレート計算（トークン/分）
- 残り時間の推定

![現在のセッション](docs/images/current-session.png)

### 履歴表示
時間経過による使用パターンの追跡：
- セッション別の内訳
- 日別使用量サマリ
- モデル別の使用統計
- コスト追跡（参考値）

![履歴表示](docs/images/history-view.png)

### 設定
アプリをカスタマイズ：
- プラン選択（Pro/Max5/Max20）
- 自動更新間隔
- 言語設定（英語/日本語）

![設定タブ](docs/images/settings-tab.png)

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

- **Issues**: [GitHub Issues](https://github.com/K9i-0/ClaudeCodeMonitor/issues)
- **Discussions**: [GitHub Discussions](https://github.com/K9i-0/ClaudeCodeMonitor/discussions)

## 🔗 関連リンク

- [Claude Code](https://claude.ai/code) - Anthropic公式のClaude Code
- [ccusage CLI](https://github.com/ryoppippi/ccusage) - ベースとなっているCLIツール