import Foundation
import NIO
import NIOHTTP1

class HelperService {
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var channel: Channel?
    private let authToken: String
    
    init() {
        // Generate or retrieve auth token
        if let sharedDefaults = UserDefaults(suiteName: "group.com.k9i.claudecodemonitor"),
           let existingToken = sharedDefaults.string(forKey: "helperAuthToken") {
            self.authToken = existingToken
        } else {
            // Generate new token
            self.authToken = UUID().uuidString
            // Save to app group
            if let sharedDefaults = UserDefaults(suiteName: "group.com.k9i.claudecodemonitor") {
                sharedDefaults.set(authToken, forKey: "helperAuthToken")
                sharedDefaults.synchronize()
            }
        }
        print("[Helper] Using auth token: \(authToken)")
    }
    
    func start() throws {
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withPipeliningAssistance: true)
                    .flatMap {
                        channel.pipeline.addHandler(HTTPHandler(authToken: self.authToken))
                    }
            }
        
        // Try preferred port first, then find available port
        let preferredPort = 8456
        var actualPort = preferredPort
        
        do {
            channel = try bootstrap.bind(host: "127.0.0.1", port: preferredPort).wait()
            actualPort = preferredPort
        } catch {
            // Port is in use, find an available port
            print("Port \(preferredPort) is in use, finding available port...")
            for port in 8457...8470 {
                do {
                    channel = try bootstrap.bind(host: "127.0.0.1", port: port).wait()
                    actualPort = port
                    break
                } catch {
                    continue
                }
            }
            
            if channel == nil {
                throw error
            }
        }
        
        // Save the actual port to app group
        if let sharedDefaults = UserDefaults(suiteName: "group.com.k9i.claudecodemonitor") {
            sharedDefaults.set(actualPort, forKey: "helperPort")
            sharedDefaults.synchronize()
        }
        
        print("Helper server started on port \(actualPort)")
        
        // Keep running
        try channel!.closeFuture.wait()
    }
    
    func stop() {
        try? channel?.close().wait()
        try? group.syncShutdownGracefully()
    }
}

class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    private var accumulated = Data()
    private let authToken: String
    
    init(authToken: String) {
        self.authToken = authToken
    }
    
    private func getSharedEnvironment() -> [String: String] {
        // リクエストごとに最新の環境変数を読み込む
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.k9i.claudecodemonitor") else {
            print("[Helper] Failed to access app group")
            return [:]
        }
        
        // 強制的に同期
        sharedDefaults.synchronize()
        
        if let env = sharedDefaults.dictionary(forKey: "sharedEnvironment") as? [String: String] {
            print("[Helper] Loaded shared environment with PATH: \(env["PATH"]?.prefix(100) ?? "not set")...")
            return env
        } else {
            print("[Helper] No shared environment found")
            return [:]
        }
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = unwrapInboundIn(data)
        
        switch reqPart {
        case .head(let header):
            accumulated = Data()
            
            // Check authorization header
            let authHeader = header.headers["Authorization"].first
            if authHeader != "Bearer \(authToken)" {
                sendResponse(context: context, status: .unauthorized, body: "{\"error\":\"Unauthorized\"}")
                return
            }
            
            if header.uri == "/blocks/active" {
                handleBlocksRequest(context: context)
            } else if header.uri == "/usage" {
                handleUsageRequest(context: context)
            } else if header.uri == "/health" {
                sendResponse(context: context, status: .ok, body: "{\"status\":\"ok\"}")
            } else {
                sendResponse(context: context, status: .notFound, body: "{\"error\":\"Not found\"}")
            }
            
        case .body:
            break
            
        case .end:
            accumulated = Data()
        }
    }
    
    private func handleBlocksRequest(context: ChannelHandlerContext) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-l", "-c", "npx ccusage@latest blocks --active --json"]
        
        // 共有された環境変数を使用
        var environment = ProcessInfo.processInfo.environment
        
        // App Groupから読み込んだ環境変数をマージ
        let sharedEnv = getSharedEnvironment()
        for (key, value) in sharedEnv {
            environment[key] = value
        }
        
        // CLAUDE_CONFIG_DIRの設定
        if let homeDir = environment["HOME"] ?? ProcessInfo.processInfo.environment["HOME"] {
            environment["CLAUDE_CONFIG_DIR"] = "\(homeDir)/.claude"
        }
        
        task.environment = environment
        
        print("[Helper] Executing ccusage via bash -l -c with PATH: \(environment["PATH"] ?? "not set")")
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            if task.terminationStatus != 0 {
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("ccusage blocks error: \(errorString)")
                sendResponse(context: context, status: .internalServerError, 
                           body: "{\"error\":\"ccusage failed: \(errorString)\"}")
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                sendResponse(context: context, status: .ok, body: jsonString)
            } else {
                sendResponse(context: context, status: .internalServerError, 
                           body: "{\"error\":\"Failed to decode response\"}")
            }
        } catch {
            print("Failed to run ccusage blocks: \(error)")
            sendResponse(context: context, status: .internalServerError, 
                       body: "{\"error\":\"\(error.localizedDescription)\"}")
        }
    }
    
    private func handleUsageRequest(context: ChannelHandlerContext) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-l", "-c", "npx ccusage@latest --json"]
        
        // 共有された環境変数を使用
        var environment = ProcessInfo.processInfo.environment
        
        // App Groupから読み込んだ環境変数をマージ
        let sharedEnv = getSharedEnvironment()
        for (key, value) in sharedEnv {
            environment[key] = value
        }
        
        // CLAUDE_CONFIG_DIRの設定
        if let homeDir = environment["HOME"] ?? ProcessInfo.processInfo.environment["HOME"] {
            environment["CLAUDE_CONFIG_DIR"] = "\(homeDir)/.claude"
        }
        
        task.environment = environment
        
        print("[Helper] Executing ccusage via bash -l -c with PATH: \(environment["PATH"] ?? "not set")")
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            if task.terminationStatus != 0 {
                let errorString = String(data: errorData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "\"", with: "\\\"") ?? "Unknown error"
                print("ccusage error: \(errorString)")
                sendResponse(context: context, status: .internalServerError, 
                           body: "{\"error\":\"ccusage failed: \(errorString)\"}")
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                sendResponse(context: context, status: .ok, body: jsonString)
            } else {
                sendResponse(context: context, status: .internalServerError, 
                           body: "{\"error\":\"Failed to decode response\"}")
            }
        } catch {
            print("Failed to run ccusage: \(error)")
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

// Signal handling for graceful shutdown
class SignalHandler {
    private let service: HelperService
    
    init(service: HelperService) {
        self.service = service
    }
    
    func setupHandlers() {
        signal(SIGINT) { _ in
            print("\nReceived SIGINT, shutting down...")
            exit(0)
        }
        
        signal(SIGTERM) { _ in
            print("\nReceived SIGTERM, shutting down...")
            exit(0)
        }
    }
}

// エントリポイント
print("Starting ClaudeMonitorHelper...")

// デバッグ：App Groupのデータを確認
if let sharedDefaults = UserDefaults(suiteName: "group.com.k9i.claudecodemonitor") {
    sharedDefaults.synchronize()
    if let env = sharedDefaults.dictionary(forKey: "sharedEnvironment") as? [String: String] {
        print("[Helper] App Group data found with keys: \(env.keys.joined(separator: ", "))")
        if let path = env["PATH"] {
            print("[Helper] PATH from App Group: \(path.prefix(200))...")
        }
    } else {
        print("[Helper] No sharedEnvironment in App Group")
    }
} else {
    print("[Helper] Cannot access App Group")
}

let service = HelperService()
let signalHandler = SignalHandler(service: service)
signalHandler.setupHandlers()

do {
    try service.start()
} catch {
    print("Failed to start helper service: \(error)")
    exit(1)
}