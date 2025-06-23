# Xcodeデバッグガイド

## Xcodeから実行してデータが取得できない問題の調査方法

### 1. Xcodeでプロジェクトを開く
```bash
open Package.swift
```

### 2. ビルドと実行
- Product > Run (⌘R) でアプリを実行

### 3. コンソール出力を確認

Xcodeの下部のコンソールに以下のようなデバッグ出力が表示されます：

```
[DEBUG] Running from Xcode: true
[DEBUG] PATH: /usr/bin:/bin:/usr/sbin:/sbin
[DEBUG] Attempting server connection to http://127.0.0.1:3456/blocks/active
[DEBUG] Server connection failed: The request timed out.
[DEBUG] Falling back to direct ccusage execution
[DEBUG] Found npx at: /Users/username/.local/share/mise/shims/npx
```

### 4. 問題の特定と解決

#### ケース1: サーバーに接続できない
```
[DEBUG] Server connection failed: The request timed out.
```
**解決策**: ターミナルでサーバーを起動
```bash
cd server
npm start
```

#### ケース2: npxが見つからない
```
[DEBUG] which command failed: ...
[DEBUG] Using shell with extended PATH
[DEBUG] ccusage stderr: zsh:1: command not found: npx
```
**解決策**: 
1. 実際のnpxの場所を確認: `which npx`
2. その場所をUsageMonitor.swiftのnpxSearchPathsに追加

#### ケース3: ccusageの実行エラー
```
[DEBUG] ccusage stderr: Error: ...
```
**解決策**: エラーメッセージに基づいて対処

### 5. 追加のデバッグ情報

環境変数を確認するには、AppDelegate.swiftに以下を追加：

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    print("=== Environment ===")
    for (key, value) in ProcessInfo.processInfo.environment {
        if key.contains("PATH") || key.contains("NODE") || key.contains("NPM") {
            print("\(key): \(value)")
        }
    }
    print("==================")
    // 既存のコード...
}
```

## よくある問題と解決策

### 1. mise/asdfを使用している場合
mise/asdfのshimディレクトリがPATHに含まれていない可能性があります。
```bash
# ~/.zshrcに追加
export PATH="$HOME/.local/share/mise/shims:$PATH"
```

### 2. Homebrewを使用している場合
M1 Macでは`/opt/homebrew/bin`、Intel Macでは`/usr/local/bin`にインストールされます。

### 3. nvm/voltaを使用している場合
これらのツールは通常、シェルの初期化ファイルで設定されるため、
Xcodeから実行時には利用できない可能性があります。