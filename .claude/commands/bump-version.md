@scripts/update-version.sh を使ってバージョンを更新する

## 使用方法

### 増分指定でバージョンを更新
- `patch` - パッチバージョンを増やす (0.7.0 → 0.7.1)
- `minor` - マイナーバージョンを増やす (0.7.0 → 0.8.0)  
- `major` - メジャーバージョンを増やす (0.7.0 → 1.0.0)

### 特定のバージョンを指定
- 例: `0.8.0`

## 実行例

```bash
# パッチバージョンを上げる
./scripts/update-version.sh patch

# マイナーバージョンを上げる  
./scripts/update-version.sh minor

# 特定のバージョンに設定
./scripts/update-version.sh 0.8.0
```

## 実行後の処理

1. 変更内容を確認
2. CHANGELOG.mdを更新（必要に応じて）
3. コミット: `git add Info.plist CHANGELOG.md && git commit -m "chore: bump version to <version>"`
