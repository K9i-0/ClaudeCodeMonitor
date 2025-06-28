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
                channel.pipeline.configureHTTPServerPipeline(withPipeliningAssistance: true)
                    .flatMap {
                        channel.pipeline.addHandler(HTTPHandler())
                    }
            }
        
        channel = try bootstrap.bind(host: "127.0.0.1", port: 3456).wait()
        print("Helper server started on port 3456")
        
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
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = unwrapInboundIn(data)
        
        switch reqPart {
        case .head(let header):
            accumulated = Data()
            
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
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["npx", "ccusage@latest", "blocks", "--active", "--json"]
        
        // CLAUDE_CONFIG_DIRの設定
        task.environment = ProcessInfo.processInfo.environment
        if let homeDir = ProcessInfo.processInfo.environment["HOME"] {
            task.environment?["CLAUDE_CONFIG_DIR"] = "\(homeDir)/.claude"
        }
        
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
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["npx", "ccusage@latest", "--json"]
        
        // CLAUDE_CONFIG_DIRの設定
        task.environment = ProcessInfo.processInfo.environment
        if let homeDir = ProcessInfo.processInfo.environment["HOME"] {
            task.environment?["CLAUDE_CONFIG_DIR"] = "\(homeDir)/.claude"
        }
        
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

let service = HelperService()
let signalHandler = SignalHandler(service: service)
signalHandler.setupHandlers()

do {
    try service.start()
} catch {
    print("Failed to start helper service: \(error)")
    exit(1)
}