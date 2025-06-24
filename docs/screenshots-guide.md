# スクリーンショット撮影ガイド

## 準備

1. **サーバーの起動**
```bash
cd server
npm install  # 初回のみ
npm start
```

2. **Xcodeでビルド**
```bash
open Package.swift
```
- Xcodeが開いたら、⌘B でビルド
- ⌘R で実行

## 撮影するスクリーンショット

### 1. メニューバーアイコン
- 通常状態（使用率表示）
- クリック時のポップオーバー

### 2. Current Session タブ
- 残りトークン表示
- プログレスバー
- バーンレート
- セッション情報

### 3. History タブ
- 過去のセッション一覧
- 日別使用状況

### 4. Settings タブ
- プラン選択
- 更新間隔設定

### 5. 通知
- 90%使用時の通知

## 撮影方法

1. ⌘ + Shift + 5 でスクリーンショットツールを起動
2. 「選択部分を取り込む」を選択
3. 必要な部分を選択して撮影

## ファイル名規則

- `menubar-icon.png` - メニューバーアイコン
- `current-session.png` - Current Sessionタブ
- `history-view.png` - Historyタブ
- `settings-tab.png` - Settingsタブ
- `notification.png` - 通知

## 保存場所

`docs/images/` ディレクトリに保存