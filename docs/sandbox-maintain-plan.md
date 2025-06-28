# App Sandbox維持修正プラン

## 概要
App Sandboxを維持しながら、XPC Service アーキテクチャを導入することで、現在の問題を解決する。

## 現状分析

### 根本的な問題
- App Sandboxは、セキュリティ上の理由から、アプリが他の実行可能ファイルを起動することを制限
- Node.jsのようなJITコンパイルを使用するランタイムは、動的なコード実行が必要
- これらの制限により、バンドルしたNode.jsが起動できない

### なぜ今の方法が失敗するのか
1. **エンタイトルメントの限界**: `com.apple.security.cs.allow-unsigned-executable-memory`を付与してもSandbox内では不十分
2. **プロセス起動の制限**: Sandbox内からの`Process()`によるサブプロセス起動は厳しく制限
3. **ネットワークサーバーの制限**: Sandbox内でのサーバー起動も制約が多い

## 解決策: XPC Service アーキテクチャ

### アーキテクチャ概要
```
┌─────────────────────────┐     XPC通信      ┌─────────────────────────┐
│   ClaudeCodeMonitor     │ <--------------> │  ClaudeDataService      │
│   (Main App)            │                   │  (XPC Service)          │
│   [Sandbox: 有効]       │                   │  [Sandbox: 無効/緩和]   │
│                         │                   │                         │
│  - UI表示               │                   │  - Node.js実行          │
│  - データ表示           │                   │  - ccusage実行          │
│  - 設定管理             │                   │  - ファイルアクセス    │
└─────────────────────────┘                   └─────────────────────────┘
```

### XPC Serviceの利点
1. **権限分離**: UIとデータ取得を完全に分離
2. **セキュリティ**: メインアプリはSandbox内で安全に動作
3. **安定性**: サービスがクラッシュしてもメインアプリは継続
4. **Apple推奨**: Appleが推奨するアーキテクチャパターン

## 実装計画

### Phase 1: XPC Service基盤の構築
- [ ] XPC Serviceターゲットの作成
  ```
  File > New > Target > macOS > XPC Service
  名前: ClaudeDataService
  ```
- [ ] XPCプロトコルの定義
  ```swift
  @objc protocol ClaudeDataServiceProtocol {
      func fetchActiveSession(reply: @escaping (Data?, Error?) -> Void)
      func fetchUsageData(reply: @escaping (Data?, Error?) -> Void)
      func startMonitoring(claudePath: String, reply: @escaping (Bool, Error?) -> Void)
      func stopMonitoring(reply: @escaping () -> Void)
  }
  ```

### Phase 2: XPC Service実装
- [ ] Node.js実行ロジックの移植
  ```swift
  class ClaudeDataService: NSObject, ClaudeDataServiceProtocol {
      private var nodeProcess: Process?
      private var serverPort = 3456
      
      func startNodeServer() throws {
          let process = Process()
          // Sandbox外なので自由にNode.jsを実行可能
          process.executableURL = URL(fileURLWithPath: "/usr/local/bin/node")
          process.arguments = ["server.js"]
          try process.run()
      }
  }
  ```
- [ ] ccusage直接実行の実装
- [ ] エラーハンドリングとロギング

### Phase 3: メインアプリの修正
- [ ] XPC接続の確立
  ```swift
  class XPCServiceManager {
      private var connection: NSXPCConnection?
      
      func connect() {
          connection = NSXPCConnection(serviceName: "com.k9i.ClaudeDataService")
          connection?.remoteObjectInterface = NSXPCInterface(with: ClaudeDataServiceProtocol.self)
          connection?.resume()
      }
  }
  ```
- [ ] UsageMonitorをXPC経由に変更
- [ ] ServerManagerの削除（不要になる）

### Phase 4: エンタイトルメントと設定
- [ ] メインアプリのエンタイトルメント
  ```xml
  <key>com.apple.security.app-sandbox</key>
  <true/>
  <key>com.apple.security.application-groups</key>
  <array>
      <string>group.com.k9i.claudecodemonitor</string>
  </array>
  ```
- [ ] XPC Serviceのエンタイトルメント
  ```xml
  <!-- Sandboxなし、または緩和されたSandbox -->
  <key>com.apple.security.app-sandbox</key>
  <false/>
  ```
- [ ] Info.plistの設定
  - メインアプリ: XPCServiceのバンドルIDを記載
  - XPCService: 許可するクライアントを記載

### Phase 5: ビルドとパッケージング
- [ ] Xcodeプロジェクト設定
  - XPC ServiceをEmbed Without Signingで追加
  - Copy Files Phase: Destination = XPC Services
- [ ] 署名設定
  - 両方のターゲットに同じDeveloper IDで署名
- [ ] GitHub Actions更新
  - 2つのターゲットをビルド
  - 適切な場所にXPC Serviceを配置

## 代替案の検討

### 案1: Login Item Helper (推奨度: ★★★★☆)
- ユーザーのログイン時に起動する別アプリ
- システムトレイで常駐し、ローカルサーバーを管理
- メインアプリはHTTP経由で通信

### 案2: WebView + JavaScript実装 (推奨度: ★★☆☆☆)
- ccusageの機能をJavaScriptで再実装
- WebViewで実行（JavaScriptCore使用）
- Node.js不要だが、実装工数が大きい

### 案3: App Extension (推奨度: ★☆☆☆☆)
- 特定の機能に限定される
- この用途には不適切

## 実装の詳細

### XPC通信のデータフロー
```
1. ユーザーがリフレッシュボタンをクリック
2. UsageMonitor.fetchUsageData()が呼ばれる
3. XPCServiceManager経由でClaudeDataServiceにリクエスト
4. ClaudeDataService内で:
   - Node.jsサーバーが起動していなければ起動
   - HTTPリクエストまたはnpx ccusageを実行
   - 結果をData型で返す
5. メインアプリでJSONデコードして表示
```

### エラーハンドリング
- XPC接続の失敗
- サービスのタイムアウト
- Node.js起動失敗
- データ取得失敗

## メリット
1. **App Store配布可能**: Sandboxを維持
2. **安定性向上**: プロセス分離により堅牢
3. **保守性向上**: 責務が明確に分離
4. **将来性**: macOSの方向性に合致

## デメリット
1. **実装の複雑さ**: 初期実装は複雑
2. **デバッグ**: 2つのプロセス間の通信デバッグ
3. **配布サイズ**: わずかに増加

## リスクと対策
- **リスク**: XPC Serviceの署名や設定ミス
- **対策**: Appleのサンプルコード（EvenBetterAuthorizationSample）を参考に

## タイムライン
- Phase 1-2: 2-3日（XPC基盤構築）
- Phase 3-4: 2日（統合とテスト）
- Phase 5: 1日（ビルド設定）
- 合計: 約1週間

## 結論
XPC Serviceアーキテクチャは、実装の初期コストは高いが、長期的には最も安定した解決策。App Sandboxを維持しながら、必要な機能を実現でき、Appleのセキュリティガイドラインにも準拠する。