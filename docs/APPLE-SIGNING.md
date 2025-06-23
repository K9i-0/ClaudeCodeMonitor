# Apple Code Signing and Notarization Guide

## 概要

macOSアプリの配布方法による署名・公証の必要性：

| 配布方法 | コード署名 | 公証 | 備考 |
|---------|-----------|------|------|
| GitHub Releases (DMG) | 推奨 | 推奨 | なくても動くが警告が出る |
| Homebrew Cask | 推奨 | 推奨 | 多くのユーザーが期待 |
| TestFlight/App Store | 必須 | 自動 | Xcode Cloudが処理 |
| 直接配布（開発者間） | 不要 | 不要 | 自己責任で使用 |

## なぜ必要か？

### 署名なし・公証なしの場合
1. **初回起動時**: 「開発元を確認できません」警告
2. **回避方法**: 右クリック → 開く（面倒）
3. **企業環境**: 実行不可の場合あり
4. **ユーザー体験**: 信頼性に欠ける印象

### 署名あり・公証ありの場合
1. **初回起動時**: スムーズに起動
2. **信頼性**: Appleの安全性確認済み
3. **企業環境**: 問題なく実行可能
4. **ユーザー体験**: プロフェッショナル

## 設定方法

### オプション1: 署名・公証なしで配布（簡単）
何もしない。release.ymlはそのまま動作します。

### オプション2: 署名・公証ありで配布（推奨）

#### 1. Developer ID証明書の取得
1. Apple Developer Program登録（年額$99）
2. [developer.apple.com](https://developer.apple.com)で証明書作成
3. 証明書タイプ: "Developer ID Application"
4. .p12形式でエクスポート

#### 2. GitHub Secretsの設定
```bash
# 証明書をBase64エンコード
base64 -i certificate.p12 | pbcopy

# GitHubリポジトリ → Settings → Secrets → New repository secret
```

設定するSecrets:
- `MACOS_CERTIFICATE`: Base64エンコードした証明書
- `MACOS_CERTIFICATE_PWD`: 証明書のパスワード  
- `MACOS_CERTIFICATE_NAME`: "Developer ID Application: Your Name (TEAMID)"
- `APPLE_ID`: your-email@example.com
- `APPLE_ID_PASSWORD`: アプリ固有パスワード（Apple IDの2要素認証ページで生成）
- `APPLE_TEAM_ID`: 10文字のチームID

### オプション3: Xcode Cloud使用（TestFlight/App Store向け）
Xcode Cloudが自動で署名・公証を行うため、追加設定不要。

## よくある質問

**Q: 個人開発者でも署名は必要？**
A: 必須ではないが、ユーザー体験向上のため推奨。

**Q: 無料で署名する方法は？**
A: Apple Developer Programへの登録が必要（年額$99）。

**Q: TestFlightだけ使いたい場合は？**
A: Xcode Cloudを使えばGitHub Actionsでの署名設定は不要。

**Q: Homebrewで配布する場合は？**
A: 署名・公証を強く推奨。多くのユーザーが期待している。

## 判断フローチャート

```
オープンソースで配布したい？
├─ Yes → 少数の技術者向け？
│        ├─ Yes → 署名なしでOK（警告は出る）
│        └─ No → 署名・公証を推奨
└─ No → App Store配布？
         ├─ Yes → Xcode Cloud（自動処理）
         └─ No → 直接配布なら署名不要
```