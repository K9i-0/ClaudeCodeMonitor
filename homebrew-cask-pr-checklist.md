# Homebrew Cask PR提出チェックリスト

## ✅ 事前確認

- [x] **安定版リリース**: v0.1.5がGitHub Releasesで公開済み
- [x] **DMGファイル**: ClaudeCodeMonitor-0.1.5.dmg
- [x] **SHA256**: f6004ac4931a90506c032e25afbd75ee43334fcf82add57cd429f7ca4d3b6e72
- [x] **署名**: ad-hoc署名（Homebrew Caskで許容）
- [x] **README**: 初回起動時の手順を記載済み

## 📝 すぐに実行する手順

### 1. Homebrew-caskをフォーク
https://github.com/Homebrew/homebrew-cask → "Fork"ボタン

### 2. ローカルにクローン
```bash
# あなたのGitHubユーザー名に置き換え
git clone https://github.com/YOUR_USERNAME/homebrew-cask.git
cd homebrew-cask
git remote add upstream https://github.com/Homebrew/homebrew-cask.git
```

### 3. 最新の状態に更新
```bash
git fetch upstream
git checkout master
git merge upstream/master
git checkout -b add-claude-code-monitor
```

### 4. Caskファイルをコピー
```bash
cp /Users/kotahayashi/Workspace/ClaudeCodeMonitor/homebrew/ccmonitor.rb Casks/c/ccmonitor.rb
```

### 5. 検証（重要！）
```bash
# 新規Caskの監査
brew audit --new-cask ccmonitor

# スタイルチェック
brew style --fix ccmonitor

# インストールテスト
brew install --cask --verbose ./Casks/c/ccmonitor.rb
brew uninstall --cask ccmonitor
```

### 6. コミット
```bash
git add Casks/c/ccmonitor.rb
git commit -m "Add ccmonitor 0.1.5"
```

### 7. プッシュ
```bash
git push origin add-claude-code-monitor
```

### 8. PR作成
GitHubで自動表示される"Compare & pull request"ボタンをクリック

## 📋 PR本文テンプレート

```markdown
#### Pre-merge checklist
- [x] The cask is named [`ccmonitor`](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/c/ccmonitor.rb).
- [x] The cask has been audited with `brew audit --new-cask ccmonitor`.
- [x] The cask has been styled with `brew style --fix ccmonitor`.
- [x] The cask has been tested with `brew install --cask ccmonitor`.
- [x] The submission is for [a stable version](https://github.com/K9i-0/ClaudeCodeMonitor/releases/tag/v0.1.5) of the software.
- [x] I have read the [Acceptable Casks document](https://docs.brew.sh/Acceptable-Casks).

#### App details
- **Name**: Claude Code Monitor
- **Homepage**: https://github.com/K9i-0/ClaudeCodeMonitor
- **Description**: Monitor Claude Code API usage and costs in your menubar
- **Version**: 0.1.5
- **macOS requirement**: 13.0+ (Ventura)

#### Notes
- The app uses ad-hoc signing. First-time users need to allow it in System Settings → Privacy & Security.
- Instructions for this are documented in the [README](https://github.com/K9i-0/ClaudeCodeMonitor#homebrew-cask-coming-soon).
```

## ⚠️ よくある指摘と対応

1. **"Description is too generic"**
   → 現在の説明は具体的なので問題なし

2. **"Please squash commits"**
   ```bash
   git rebase -i upstream/master
   # すべてのコミットを1つにまとめる
   ```

3. **"CI is failing"**
   → ログを確認して修正

4. **"App is not signed"**
   → ad-hoc署名は許容される。READMEに手順記載済みと説明

## 🔍 署名の確認方法

メンテナーから署名について聞かれた場合：
```bash
codesign -dv --verbose=4 /Applications/ClaudeCodeMonitor.app 2>&1 | grep Signature
# 出力: Signature=adhoc
```

これはHomebrew Caskで許容される署名タイプです。

## 📅 タイムライン

1. **今すぐ**: PR提出（5-10分）
2. **1-3日**: 初回レビュー
3. **3-7日**: フィードバック対応
4. **1-2週間**: マージ

## 🚀 次のステップ

PR提出後：
1. CI結果を確認
2. メンテナーのフィードバックに迅速に対応
3. マージされたら、READMEを更新して"Coming Soon"を削除