# Developer ID 署名セットアップガイド

## 1. 証明書の確認

```bash
# インストール済みの証明書を確認
security find-identity -v -p codesigning

# Developer ID Application証明書を探す
security find-identity -v -p codesigning | grep "Developer ID Application"
```

## 2. build-release.sh の更新

証明書が見つかったら、スクリプトの以下の部分を更新：

```bash
# 現在の設定（13行目）
DEVELOPER_ID="Developer ID Application: Your Name (XXXXXXXXXX)"

# あなたの証明書情報に置き換える
# 例: DEVELOPER_ID="Developer ID Application: Kotaro Hayashi (ABC123DEF4)"
```

## 3. 署名付きビルドの実行

```bash
# 署名付きでビルド
./scripts/build-release.sh

# 署名を確認
codesign -dv --verbose=4 "ClaudeCodeMonitor.app"
spctl -a -vvv -t install "ClaudeCodeMonitor.app"
```

## 4. 公証（Notarization）- オプション

macOS 10.15以降では公証も推奨：

```bash
# App Store Connect API キーが必要
xcrun notarytool submit ClaudeCodeMonitor-1.0.0.dmg \
    --key-id YOUR_KEY_ID \
    --key YOUR_API_KEY_FILE \
    --issuer YOUR_ISSUER_ID \
    --wait

# 公証後、DMGにステープル
xcrun stapler staple ClaudeCodeMonitor-1.0.0.dmg
```

## トラブルシューティング

### 証明書が見つからない場合
1. Xcodeで再度ダウンロード
2. ダウンロードした.cerファイルをダブルクリックしてキーチェーンに追加

### 署名エラーが出る場合
```bash
# キーチェーンのロックを解除
security unlock-keychain -p "パスワード" ~/Library/Keychains/login.keychain-db
```