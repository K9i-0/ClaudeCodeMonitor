---
description: 作業環境をセットアップしてClaude Codeを起動
allowed-tools: Bash(git *), Bash(tmux *), Read, Write
---

作業を開始するための環境を自動セットアップしてClaude Codeを起動します。

## 現在の環境確認

### Git状態
!`git status --porcelain | head -5 || echo "✅ 作業ツリーはクリーンです"`

### 現在のブランチ
!`git branch --show-current`

### Tmuxインストール確認
!`which tmux >/dev/null && echo "✅ tmux is installed" || echo "❌ tmux not found - please install tmux first"`

### 既存のworktrees
!`git worktree list | tail -n +2 || echo "No worktrees found"`

## 作業開始の準備

作業概要: **{{ARGUMENTS}}**

この作業概要から以下を実行します：

1. **ブランチタイプの判定**
   - 「実装」「追加」「機能」→ `feature/`
   - 「修正」「バグ」「エラー」→ `fix/`
   - 「更新」「ドキュメント」「README」→ `docs/`
   - 「リファクタ」「改善」→ `refactor/`
   - その他 → `chore/`

2. **ブランチ名の生成**
   - 日本語を英語に変換
   - スペースをハイフンに変換
   - 小文字に統一

3. **環境セットアップ**
   - developブランチの最新を取得
   - worktreeを作成
   - tmuxセッションを開始
   - Claude Codeを起動

## 実行

まず、未コミットの変更がないか確認します。変更がある場合は、先にコミットまたはstashしてください。

次に、以下の処理を実行します：

### 1. developブランチの更新
!`git fetch origin develop:develop`

### 2. ブランチ名の決定
作業概要に基づいて適切なブランチ名を生成します。

### 3. worktreeとセッションの作成

実際の作業は以下のステップで行います：

1. ブランチタイプとブランチ名を決定
2. worktreeを作成
3. tmuxセッションでClaude Codeを起動

**注意**: 
- worktreeは `../worktrees/` ディレクトリに作成されます
- tmuxセッション名は `claude-{branch-name}` となります
- 作業が完了したら `git worktree remove` でworktreeを削除してください