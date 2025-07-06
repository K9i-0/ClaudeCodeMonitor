---
description: 作業環境をセットアップしてClaude Codeを起動
allowed-tools: Bash(git *), Bash(tmux *), Bash(osascript *), Read, Write
---

## 環境確認
- Git status: !`git status --porcelain | head -5 || echo "✅ 作業ツリーはクリーンです"`
- Tmux: !`which tmux >/dev/null && echo "✅ tmux is installed" || echo "❌ tmux not found"`
- 現在のブランチ: !`git branch --show-current`
- 既存のworktrees: !`git worktree list | tail -n +2 || echo "No worktrees found"`

## タスク
作業内容: **{{ARGUMENTS}}**

以下の手順で作業環境をセットアップしてください：

1. まず、作業内容から適切なブランチタイプとブランチ名を決定してください：
   - 「実装」「追加」「機能」→ `feature/`
   - 「修正」「バグ」「エラー」「失敗」→ `fix/`
   - 「更新」「ドキュメント」「README」→ `docs/`
   - 「リファクタ」「改善」→ `refactor/`
   - その他 → `chore/`

2. ブランチ名は以下のルールで生成してください：
   - 日本語を英語に変換（例：リリース→release、失敗→failure、調査→investigate）
   - スペースをハイフンに変換
   - 小文字に統一

3. 以下のコマンドを実行してください：

```bash
# developブランチを更新
git fetch origin develop:develop

# worktreeを作成（ブランチ名を適切に置き換えてください）
git worktree add -b [ブランチタイプ]/[ブランチ名] ../worktrees/[ブランチ名] develop

# tmuxセッションを作成してClaude Codeを起動
tmux new-session -d -s claude-[ブランチ名] -c ../worktrees/[ブランチ名] "claude code"

# iTermで新しい垂直ペインを開いてtmuxセッションに接続
osascript -e '
tell application "iTerm"
    tell current window
        tell current session
            split vertically with default profile
        end tell
        tell current session
            write text "tmux attach -t claude-[ブランチ名]"
        end tell
    end tell
end tell
'
```

4. セッション作成後、以下の情報を表示してください：
   - 新しいペインでtmuxセッションに自動接続されました
   - 手動で接続する場合: `tmux attach -t claude-[ブランチ名]`
   - 片付け方法:
     - `tmux kill-session -t claude-[ブランチ名]`
     - `git worktree remove ../worktrees/[ブランチ名]`