# App Sandbox 無効化修正プラン

## 概要
App Sandboxを無効化することで、Node.jsサーバーの起動問題を解決し、シンプルな実装に移行する。

## 現在の課題
- Node.jsサーバーが起動できない（JIT実行の制限）
- npxコマンドが実行できない
- アクティブセッションが表示されない
- 実装とデバッグの複雑化

## 修正タスク

### Phase 1: エンタイトルメント修正
- [ ] `ClaudeCodeMonitor.entitlements`
  - `com.apple.security.app-sandbox` を `false` に変更
  - 不要なサンドボックス関連エンタイトルメントを削除
- [ ] `node.entitlements` を削除

### Phase 2: データアクセス層の簡素化
- [ ] `ClaudeDataAccessManager.swift`
  - セキュリティスコープブックマーク関連のコードを削除
  - `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()` を削除
  - シンプルなパス保存・読み込みに変更
- [ ] `FolderAccessHelper.swift`
  - セキュリティチェックを削除
  - NSOpenPanelの処理を簡素化

### Phase 3: サーバー管理の簡素化
- [ ] `ServerManager.swift`
  - バンドルされたNode.js使用コードを削除
  - システムNode.jsを直接使用するように変更
  - プロセス起動の簡素化
- [ ] `UsageMonitor.swift`
  - サーバー接続失敗時のフォールバックを`npx ccusage`直接実行に変更

### Phase 4: ビルドプロセスの簡素化
- [ ] `scripts/build-release.sh`
  - Node.jsバンドル処理を削除
  - シンプルなアプリバンドル作成に変更
- [ ] `scripts/test-local-with-node.sh` を削除
- [ ] `.github/workflows/release.yml`
  - Node.jsダウンロード・署名ステップを削除
  - ビルドプロセスを簡素化

### Phase 5: サーバー依存の見直し
- [ ] サーバー経由でのデータ取得を検討
  - Option A: サーバーを完全に削除し、直接ccusageを実行
  - Option B: サーバーを残すが、シンプルな起動方法に変更

### Phase 6: UI/UXの調整
- [ ] `DataAccessView.swift`
  - エラーメッセージの更新
  - セキュリティ関連の警告を削除

### Phase 7: ドキュメント更新
- [ ] README.md
  - インストール要件を更新（Node.js必須）
  - App Store配布不可の明記
- [ ] CLAUDE.md
  - ビルド手順の更新

## 実装順序
1. エンタイトルメント修正（Phase 1）
2. データアクセス層の簡素化（Phase 2）
3. サーバー管理の簡素化（Phase 3）
4. 動作確認
5. ビルドプロセスの簡素化（Phase 4）
6. サーバー依存の見直し（Phase 5）
7. UI/UX調整とドキュメント更新（Phase 6-7）

## 予想される影響
### メリット
- Node.jsサーバーの起動問題が解決
- 実装がシンプルになる
- デバッグが容易になる
- メンテナンスコストの削減

### デメリット
- App Store配布が不可能
- セキュリティレベルの低下
- ユーザーの信頼が必要

## 配布方法の変更
- App Store: ❌ 不可
- Homebrew Cask: ✅ 推奨
- GitHub Releases: ✅ 可能
- TestFlight: ✅ 可能（Developer ID署名は必要）

## 注意事項
- Developer ID署名は引き続き必要（Gatekeeper対応）
- 最小限の権限で動作するよう設計
- ユーザーデータへのアクセスは明示的な許可を維持