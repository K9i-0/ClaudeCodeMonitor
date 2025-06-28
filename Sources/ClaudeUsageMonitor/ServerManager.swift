import Foundation

@MainActor
class ServerManager: ObservableObject {
    static let shared = ServerManager()
    
    private var serverProcess: Process?
    private let serverPort = 3456
    @Published var isServerRunning = false
    var claudePath: String?
    
    private init() {}
    
    func checkAndStartServer() {
        // Check if server is already running
        Task {
            if await isServerResponding() {
                print("[ServerManager] Server already running")
                isServerRunning = true
                return
            }
            
            // Try to start the server
            startServer()
        }
    }
    
    private func isServerResponding() async -> Bool {
        guard let url = URL(string: "http://127.0.0.1:\(serverPort)/health") else { return false }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 1.0
            
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            // Server not responding
        }
        
        return false
    }
    
    private func startServer() {
        print("[ServerManager] Attempting to start server")
        
        // First, try to find server in the app bundle (production)
        var serverPath: String?
        if let bundledServerPath = Bundle.main.path(forResource: "server", ofType: nil) {
            serverPath = bundledServerPath
            print("[ServerManager] Using bundled server at: \(bundledServerPath)")
        } else {
            // Fallback to development location
            let appPath = Bundle.main.bundlePath
            let devServerPath = (appPath as NSString).deletingLastPathComponent
                .appending("/server")
            if FileManager.default.fileExists(atPath: devServerPath) {
                serverPath = devServerPath
                print("[ServerManager] Using development server at: \(devServerPath)")
            }
        }
        
        // Check if server directory exists
        guard let validServerPath = serverPath else {
            print("[ServerManager] Server directory not found")
            return
        }
        
        // Create process to start server
        let process = Process()
        
        // Find Node.js
        var nodePath: String?
        
        // First, try to use bundled Node.js (production)
        if let bundledNodePath = Bundle.main.path(forResource: "node/node", ofType: nil) {
            nodePath = bundledNodePath
            print("[ServerManager] Using bundled Node.js at: \(bundledNodePath)")
        } else {
            // Fallback to system Node.js (development)
            let systemNodePaths = [
                "/Users/\(NSUserName())/.local/share/mise/shims/node",
                "/opt/homebrew/bin/node",
                "/usr/local/bin/node"
            ]
            
            for path in systemNodePaths {
                let expandedPath = (path as NSString).expandingTildeInPath
                if FileManager.default.fileExists(atPath: expandedPath) {
                    nodePath = expandedPath
                    print("[ServerManager] Using system Node.js at: \(expandedPath)")
                    break
                }
            }
        }
        
        guard let node = nodePath else {
            print("[ServerManager] Node.js not found")
            return
        }
        
        process.executableURL = URL(fileURLWithPath: node)
        // Add --max-old-space-size to prevent memory issues in sandboxed environment
        process.arguments = ["--max-old-space-size=128", "server.js"]
        process.currentDirectoryURL = URL(fileURLWithPath: validServerPath)
        
        // Set up environment
        var environment = ProcessInfo.processInfo.environment
        environment["PORT"] = "\(serverPort)"
        
        // Set CLAUDE_CONFIG_DIR if we have access to Claude data
        if let claudePath = claudePath {
            environment["CLAUDE_CONFIG_DIR"] = claudePath
            print("[ServerManager] Setting CLAUDE_CONFIG_DIR to: \(claudePath)")
        } else {
            print("[ServerManager] WARNING: No claudePath set, server may not find data")
        }
        
        process.environment = environment
        
        // Redirect output
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8) {
                print("[Server] \(output)", terminator: "")
            }
        }
        
        do {
            try process.run()
            serverProcess = process
            
            // Wait a bit for server to start
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                Task {
                    if await self.isServerResponding() {
                        print("[ServerManager] Server started successfully")
                        self.isServerRunning = true
                    } else {
                        print("[ServerManager] Server failed to start")
                    }
                }
            }
        } catch {
            print("[ServerManager] Failed to start server: \(error)")
        }
    }
    
    func stopServer() {
        serverProcess?.terminate()
        serverProcess = nil
        isServerRunning = false
    }
}