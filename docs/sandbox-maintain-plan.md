# App Sandbox維持修正プラン

## 概要
App Sandboxを維持しながら、XPC Service アーキテクチャを導入することで、現在の問題を解決する。

## 現在直面している具体的な課題

### 1. アクティブセッションが表示されない
**症状**：
- 使用状況サマリー（今日/今月）は表示される
- 「現在」タブのアクティブセッション情報が取得できない

**原因**：
- Node.jsサーバー（`server/server.js`）が起動できない
- フォールバック処理（`npx ccusage blocks --active --json`）も実行できない
- App SandboxがProcess()でのサブプロセス起動を制限

**関連コード**：
```swift
// UsageMonitor.swift - 現在の失敗箇所
private func fetchSessionData() async {
    // サーバー接続試行 → 失敗
    if let url = URL(string: "http://127.0.0.1:3456/blocks/active") {
        // エラー: Could not connect to the server
    }
}

// ServerManager.swift - Node.js起動試行
func startServer() async -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: bundledNodePath)
    // App Sandboxにより起動失敗
}
```

### 2. 複雑な実装による保守性の低下
**現在の実装**：
- Node.jsバイナリをアプリにバンドル（187MB）
- 複雑なエンタイトルメント設定
- GitHub Actionsでの特殊な署名プロセス
- セキュリティスコープブックマークの管理

**問題のあるファイル**：
- `ClaudeCodeMonitor.entitlements`
- `node.entitlements`
- `scripts/build-release.sh`
- `scripts/test-local-with-node.sh`
- `.github/workflows/release.yml`

### 3. Developer ID署名でも解決しない
**試みた対策**：
- Node.jsバイナリへのDeveloper ID署名
- JIT実行エンタイトルメント（`com.apple.security.cs.allow-unsigned-executable-memory`）
- 結果：それでもApp Sandbox内では動作しない

### 4. XPC Serviceも解決策にならない
**重要な発見**：
- macOS 10.14以降、XPC Serviceも親アプリのSandbox制限を継承
- つまり、XPC Service内でもNode.jsやnpxの実行は不可能
- この事実により、以下の「XPC Service アーキテクチャ」案は**実現不可能**

## 現状分析

### 根本的な問題
- App Sandboxは、セキュリティ上の理由から、アプリが他の実行可能ファイルを起動することを制限
- Node.jsのようなJITコンパイルを使用するランタイムは、動的なコード実行が必要
- これらの制限により、バンドルしたNode.jsが起動できない

### なぜ今の方法が失敗するのか
1. **エンタイトルメントの限界**: `com.apple.security.cs.allow-unsigned-executable-memory`を付与してもSandbox内では不十分
2. **プロセス起動の制限**: Sandbox内からの`Process()`によるサブプロセス起動は厳しく制限
3. **ネットワークサーバーの制限**: Sandbox内でのサーバー起動も制約が多い

## ~~解決策: XPC Service アーキテクチャ~~ （実現不可能）

**注意**: 以下のXPC Service案は、macOS 10.14以降では機能しません。XPC ServiceもApp Sandboxの制限を継承するため、Node.jsやnpxの実行は不可能です。参考のために残しています。

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
  ```swift
  func fetchActiveSession(reply: @escaping (Data?, Error?) -> Void) {
      let task = Process()
      task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
      task.arguments = ["npx", "ccusage", "blocks", "--active", "--json"]
      
      if let claudePath = self.claudePath {
          task.environment = ProcessInfo.processInfo.environment
          task.environment?["CLAUDE_CONFIG_DIR"] = claudePath
      }
      
      let outputPipe = Pipe()
      task.standardOutput = outputPipe
      
      do {
          try task.run()
          task.waitUntilExit()
          
          let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
          reply(data, nil)
      } catch {
          reply(nil, error)
      }
  }
  ```
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
  ```swift
  // UsageMonitor.swift の修正例
  private func fetchSessionData() async {
      guard let service = xpcServiceManager.remoteObjectProxy else { return }
      
      return await withCheckedContinuation { continuation in
          service.fetchActiveSession { data, error in
              if let data = data,
                 let blocksResponse = try? JSONDecoder().decode(BlocksResponse.self, from: data) {
                  // アクティブセッションを処理
                  if let activeBlock = blocksResponse.blocks.first(where: { $0.isActive }) {
                      self.usageData.activeSession = activeBlock
                  }
              }
              continuation.resume()
          }
      }
  }
  ```
- [ ] ServerManagerの削除（不要になる）
- [ ] ClaudeDataAccessManagerの簡素化（セキュリティスコープ処理を削除）

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

## 真の解決策: Login Helper Item アーキテクチャ

### なぜLogin Helper Itemが最適解なのか
1. **Sandboxの外で動作**: システムレベルで動作し、App Sandboxの制限を受けない
2. **Apple公式の方法**: `SMLoginItemSetEnabled`で管理
3. **確実に動作**: XPC Serviceと異なり、Sandbox制限を継承しない
4. **ユーザー体験**: ログイン時に自動起動、バックグラウンドで動作

### 新しいアーキテクチャ概要
```
┌─────────────────────────┐                    ┌─────────────────────────┐
│   ClaudeCodeMonitor     │  HTTP (localhost)  │  ClaudeMonitorHelper    │
│   (Main App)            │ <----------------> │  (Login Helper Item)    │
│   [Sandbox: 有効]       │                    │  [Sandbox: 無効]        │
│                         │                    │                         │
│  - UI表示               │                    │  - HTTPサーバー提供     │
│  - データ表示           │                    │  - ccusage実行          │
│  - 設定管理             │                    │  - Node.js不要          │
└─────────────────────────┘                    └─────────────────────────┘
```

## Login Helper Item 実装計画

### Phase 1: Helper Itemの作成
- [ ] Package.swiftに新しいターゲットを追加
  ```swift
  .executable(
      name: "ClaudeMonitorHelper",
      dependencies: [
          .product(name: "NIO", package: "swift-nio"),
          .product(name: "NIOHTTP1", package: "swift-nio")
      ]
  )
  ```

- [ ] Helper Itemの基本実装（Swift製HTTPサーバー）
  ```swift
  // main.swift
  import Foundation
  import NIO
  import NIOHTTP1
  
  class HelperService {
      private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
      private var channel: Channel?
      
      func start() throws {
          let bootstrap = ServerBootstrap(group: group)
              .serverChannelOption(ChannelOptions.backlog, value: 256)
              .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
              .childChannelInitializer { channel in
                  channel.pipeline.configureHTTPServerPipeline()
                      .flatMap {
                          channel.pipeline.addHandler(HTTPHandler())
                      }
              }
          
          channel = try bootstrap.bind(host: "127.0.0.1", port: 3456).wait()
          print("Helper server started on port 3456")
          
          // Keep running
          try channel!.closeFuture.wait()
      }
  }
  
  class HTTPHandler: ChannelInboundHandler {
      typealias InboundIn = HTTPServerRequestPart
      typealias OutboundOut = HTTPServerResponsePart
      
      func channelRead(context: ChannelHandlerContext, data: NIOAny) {
          let reqPart = unwrapInboundIn(data)
          
          switch reqPart {
          case .head(let header):
              if header.uri == "/blocks/active" {
                  handleBlocksRequest(context: context)
              } else if header.uri == "/usage" {
                  handleUsageRequest(context: context)
              } else if header.uri == "/health" {
                  sendResponse(context: context, status: .ok, body: "{\"status\":\"ok\"}")
              } else {
                  sendResponse(context: context, status: .notFound, body: "{\"error\":\"Not found\"}")
              }
          default:
              break
          }
      }
      
      private func handleBlocksRequest(context: ChannelHandlerContext) {
          let task = Process()
          task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
          task.arguments = ["npx", "ccusage@latest", "blocks", "--active", "--json"]
          
          // CLAUDE_CONFIG_DIRの設定
          task.environment = ProcessInfo.processInfo.environment
          if let homeDir = ProcessInfo.processInfo.environment["HOME"] {
              task.environment?["CLAUDE_CONFIG_DIR"] = "\(homeDir)/.claude"
          }
          
          let pipe = Pipe()
          task.standardOutput = pipe
          task.standardError = pipe
          
          do {
              try task.run()
              task.waitUntilExit()
              
              let data = pipe.fileHandleForReading.readDataToEndOfFile()
              if let jsonString = String(data: data, encoding: .utf8) {
                  sendResponse(context: context, status: .ok, body: jsonString)
              } else {
                  sendResponse(context: context, status: .internalServerError, 
                             body: "{\"error\":\"Failed to decode response\"}")
              }
          } catch {
              sendResponse(context: context, status: .internalServerError, 
                         body: "{\"error\":\"\(error.localizedDescription)\"}")
          }
      }
      
      private func handleUsageRequest(context: ChannelHandlerContext) {
          let task = Process()
          task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
          task.arguments = ["npx", "ccusage@latest", "--json"]
          
          // CLAUDE_CONFIG_DIRの設定
          task.environment = ProcessInfo.processInfo.environment
          if let homeDir = ProcessInfo.processInfo.environment["HOME"] {
              task.environment?["CLAUDE_CONFIG_DIR"] = "\(homeDir)/.claude"
          }
          
          let pipe = Pipe()
          task.standardOutput = pipe
          task.standardError = pipe
          
          do {
              try task.run()
              task.waitUntilExit()
              
              let data = pipe.fileHandleForReading.readDataToEndOfFile()
              if let jsonString = String(data: data, encoding: .utf8) {
                  sendResponse(context: context, status: .ok, body: jsonString)
              } else {
                  sendResponse(context: context, status: .internalServerError, 
                             body: "{\"error\":\"Failed to decode response\"}")
              }
          } catch {
              sendResponse(context: context, status: .internalServerError, 
                         body: "{\"error\":\"\(error.localizedDescription)\"}")
          }
      }
      
      private func sendResponse(context: ChannelHandlerContext, status: HTTPResponseStatus, body: String) {
          var headers = HTTPHeaders()
          headers.add(name: "Content-Type", value: "application/json")
          headers.add(name: "Access-Control-Allow-Origin", value: "*")
          headers.add(name: "Content-Length", value: String(body.utf8.count))
          
          let head = HTTPResponseHead(version: .http1_1, status: status, headers: headers)
          context.write(wrapOutboundOut(.head(head)), promise: nil)
          
          let buffer = context.channel.allocator.buffer(string: body)
          context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
          context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
      }
  }
  
  // エントリポイント
  let service = HelperService()
  do {
      try service.start()
  } catch {
      print("Failed to start helper service: \(error)")
      exit(1)
  }
  ```

### Phase 2: メインアプリの修正
- [ ] Login Helper Itemの登録
  ```swift
  // AppDelegate.swift
  import ServiceManagement
  
  func applicationDidFinishLaunching(_ notification: Notification) {
      // Helper Itemを登録
      let helperBundleIdentifier = "com.k9i.ClaudeMonitorHelper"
      SMLoginItemSetEnabled(helperBundleIdentifier as CFString, true)
      
      // 少し待ってからデータ取得開始
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          self.monitor.startMonitoring()
      }
  }
  ```

- [ ] ServerManagerの削除（もはや不要）
- [ ] Node.jsバンドル関連のコードをすべて削除
- [ ] UsageMonitorの修正（既存のHTTP通信をそのまま利用）
  ```swift
  // 変更不要！既存のコードがそのまま動作
  private func fetchSessionData() async {
      if let url = URL(string: "http://127.0.0.1:3456/blocks/active") {
          // Helper Itemが提供するHTTPサーバーと通信
      }
  }
  ```

### Phase 3: Info.plistとビルド設定
- [ ] メインアプリのInfo.plist
  ```xml
  <key>SMPrivilegedExecutables</key>
  <dict>
      <key>com.k9i.ClaudeMonitorHelper</key>
      <string>identifier "com.k9i.ClaudeMonitorHelper" and certificate leaf[subject.CN] = "Developer ID Application: *"</string>
  </dict>
  ```

- [ ] Helper ItemのInfo.plist
  ```xml
  <key>LSBackgroundOnly</key>
  <true/>
  <key>LSUIElement</key>
  <true/>
  ```

- [ ] ビルドスクリプト
  ```bash
  #!/bin/bash
  # build-with-helper.sh
  
  # Helper Itemをビルド
  swift build -c release --product ClaudeMonitorHelper
  
  # メインアプリをビルド
  swift build -c release --product ClaudeCodeMonitor
  
  # Helper Itemを適切な場所にコピー
  mkdir -p ClaudeCodeMonitor.app/Contents/Library/LoginItems/
  cp .build/release/ClaudeMonitorHelper ClaudeCodeMonitor.app/Contents/Library/LoginItems/
  
  # 署名
  codesign --force --sign "Developer ID Application: Your Name" \
           ClaudeCodeMonitor.app/Contents/Library/LoginItems/ClaudeMonitorHelper
  codesign --force --sign "Developer ID Application: Your Name" \
           --deep ClaudeCodeMonitor.app
  ```

## 実装の優先順位

1. **最小実装で動作確認**（1日）
   - Swift NIOでHTTPサーバーを実装
   - ccusageを直接実行してJSONを返す
   - 既存のメインアプリとの通信確認

2. **エラーハンドリングとロバスト性**（0.5日）
   - タイムアウト処理
   - プロセス終了時の適切なクリーンアップ
   - ヘルスチェックエンドポイント

3. **パフォーマンス最適化**（オプション）
   - レスポンスのキャッシュ（5秒程度）
   - 並行リクエスト処理の改善

## その他の代替案

### 案1: WebView + JavaScript実装 (推奨度: ★★☆☆☆)
- ccusageの機能をJavaScriptで再実装
- WebViewで実行（JavaScriptCore使用）
- Node.js不要だが、実装工数が大きい

### 案2: App Extension (推奨度: ★☆☆☆☆)
- 特定の機能に限定される
- この用途には不適切

## 実装の詳細

### Login Helper Itemのデータフロー
```
1. ユーザーがリフレッシュボタンをクリック
2. UsageMonitor.fetchUsageData()が呼ばれる
3. HTTP経由でHelper Itemにリクエスト（localhost:3456）
4. Helper Item内で:
   - Swift NIOのHTTPハンドラーがリクエストを受信
   - npx ccusageを直接実行
   - 結果をHTTPレスポンスとして返す
5. メインアプリでJSONデコードして表示
```

### エラーハンドリング
- Helper Itemの未起動
- HTTPタイムアウト
- ccusage実行失敗
- JSONパース失敗

## メリット
1. **確実に動作**: Sandboxの制限を完全に回避
2. **シンプル**: XPCより実装が簡単
3. **Node.js不要**: Swiftのみで完結
4. **保守性向上**: 複雑なNode.jsバンドルが不要

## デメリット
1. **ユーザー許可**: 初回起動時にHelper Itemの許可が必要
2. **別プロセス**: プロセス管理の複雑さ

## リスクと対策
- **リスク**: XPC Serviceの署名や設定ミス
- **対策**: Appleのサンプルコード（EvenBetterAuthorizationSample）を参考に

## タイムライン
- Phase 1: 1日（Helper Item実装）
- Phase 2: 0.5日（メインアプリ統合）
- Phase 3: 0.5日（ビルド設定とテスト）
- 合計: 約2日

## 結論
Login Helper Itemアプローチは、XPC Serviceの制限を回避し、確実にApp Sandboxの問題を解決できる唯一の実用的な方法です。Swift NIOを使用した軽量HTTPサーバーにより、Node.js依存も解消でき、全体的にシンプルで保守しやすいアーキテクチャになります。

## 現在のプロジェクト構成

### 主要ファイル
```
ClaudeCodeMonitor/
├── Sources/
│   ├── ClaudeUsageMonitor/        # メインアプリ
│   │   ├── AppDelegate.swift      # メニューバーアプリのエントリポイント
│   │   ├── UsageMonitor.swift     # 使用状況データの取得・管理（HTTP通信のみ）
│   │   ├── ClaudeDataAccessManager.swift # フォルダアクセス管理（簡素化済み）
│   │   ├── Models.swift           # データモデル定義
│   │   └── SessionModels.swift    # セッション関連モデル（BlocksResponse等）
│   └── ClaudeMonitorHelper/       # Helper Item（新規）
│       └── main.swift             # HTTPサーバー実装
├── server/                        # 削除予定（Node.jsサーバーは不要）
├── ClaudeCodeMonitor.entitlements # App Sandboxエンタイトルメント
└── Package.swift                  # SwiftPMパッケージ定義
```

### 重要な型定義
```swift
// SessionModels.swift
struct BlocksResponse: Codable {
    let blocks: [SessionBlock]
}

struct SessionBlock: Codable {
    let id: String
    let startTime: String
    let endTime: String
    let isActive: Bool
    let totalTokens: Int
    // ...
}
```

## デバッグ時の確認コマンド
```bash
# 現在のアクティブセッションを確認
npx ccusage@latest blocks --active --json

# サーバーの状態確認
curl http://127.0.0.1:3456/blocks/active

# プロセス確認
ps aux | grep -E "node.*server|ClaudeCodeMonitor"
```