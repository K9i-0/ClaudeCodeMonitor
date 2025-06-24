# Homebrew Cask 正式PR提出ガイド

## 手順

### 1. homebrew-caskリポジトリをフォーク
https://github.com/Homebrew/homebrew-cask でForkボタンをクリック

### 2. フォークしたリポジトリをクローン
```bash
# あなたのGitHubユーザー名に置き換えてください
git clone https://github.com/YOUR_USERNAME/homebrew-cask.git
cd homebrew-cask
```

### 3. ブランチ作成
```bash
git checkout -b add-ccmonitor
```

### 4. Cask formulaをコピー
```bash
cp /Users/kotahayashi/Workspace/ClaudeCodeMonitor/homebrew/ccmonitor.rb Casks/c/
```

### 5. formulaの検証
```bash
# 構文チェック
brew audit --cask ccmonitor

# スタイルチェック
brew style --cask ccmonitor

# インストールテスト（オプション）
brew install --cask ./Casks/c/ccmonitor.rb
brew uninstall --cask ccmonitor
```

### 6. コミット
```bash
git add Casks/c/ccmonitor.rb
git commit -m "Add Claude Code Monitor 0.1.5

Real-time monitoring for Claude Code API usage in your menubar.
Short name: ccmonitor"
```

### 7. プッシュ
```bash
git push origin add-ccmonitor
```

### 8. PR作成
GitHub上で自動的に表示される "Compare & pull request" ボタンをクリック、または：
```bash
gh pr create --repo Homebrew/homebrew-cask --title "Add Claude Code Monitor 0.1.5" --body "- **Name**: Claude Code Monitor
- **Short name**: ccmonitor
- **Homepage**: https://github.com/K9i-0/ClaudeCodeMonitor
- **Description**: Real-time monitoring for Claude Code API usage
- **Version**: 0.1.5

This app provides real-time monitoring of Claude Code API usage directly in your macOS menubar. It tracks current session usage, costs, and provides notifications when approaching limits.

## Pre-merge checklist
- [x] The cask is named correctly
- [x] The cask has been audited with \`brew audit --cask <cask>\`
- [x] The cask has been styled with \`brew style --cask <cask>\`
- [x] The cask works with \`brew install --cask <cask>\`"
```

## 注意事項

1. **署名について**: 現在はad-hoc署名のため、初回起動時にGatekeeper警告が表示されます。READMEに手順を記載済み。

2. **バージョン更新時**: 新しいリリースごとにSHA256の更新が必要です。

3. **レビュープロセス**: Homebrew maintainerからのフィードバックに迅速に対応してください。

## よくあるフィードバックと対応

- **"Please use a more specific description"**: descフィールドをより具体的に
- **"Please squash commits"**: `git rebase -i` でコミットを1つにまとめる
- **"CI is failing"**: CIログを確認して問題を修正

## 参考リンク
- [Homebrew Cask Cookbook](https://docs.brew.sh/Cask-Cookbook)
- [Acceptable Casks](https://docs.brew.sh/Acceptable-Casks)