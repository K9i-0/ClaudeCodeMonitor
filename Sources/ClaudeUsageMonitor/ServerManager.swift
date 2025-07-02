import Foundation

@MainActor
class ServerManager: ObservableObject {
    static let shared = ServerManager()

    private var serverProcess: Process?
    private let serverPort: Int
    @Published var isServerRunning = false
    var claudePath: String?
    private var serverMonitorTask: Task<Void, Never>?

    private init() {
        // 環境変数CLAUDE_MONITOR_PORTからポート番号を取得、デフォルトは3456
        if let portString = ProcessInfo.processInfo.environment["CLAUDE_MONITOR_PORT"],
           let port = Int(portString) {
            self.serverPort = port
        } else {
            self.serverPort = 3_456
        }
        print("[ServerManager] Using port: \(serverPort)")
    }

    func checkAndStartServer() async -> Bool {
        // Check if server is already running
        if await isServerResponding() {
            print("[ServerManager] Server already running")
            isServerRunning = true
            return true
        }

        // Try to start the server
        return await startServer()
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

    private func findServerPath() -> String? {
        // First, try to find server in the app bundle (production)
        print("[ServerManager] Bundle.main.bundlePath: \(Bundle.main.bundlePath)")
        print("[ServerManager] Bundle.main.resourcePath: \(Bundle.main.resourcePath ?? "nil")")

        // Check for server directory in Resources
        if let resourcePath = Bundle.main.resourcePath {
            let bundledServerPath = (resourcePath as NSString).appendingPathComponent("server")
            if FileManager.default.fileExists(atPath: bundledServerPath) {
                print("[ServerManager] Using bundled server at: \(bundledServerPath)")

                // Verify server.js exists
                let serverJsPath = (bundledServerPath as NSString).appendingPathComponent("server.js")
                if FileManager.default.fileExists(atPath: serverJsPath) {
                    print("[ServerManager] server.js found at: \(serverJsPath)")
                } else {
                    print("[ServerManager] ERROR: server.js not found at: \(serverJsPath)")
                }
                return bundledServerPath
            }
        }

        // Fallback to development location if not found in bundle
        let possiblePaths = [
            // Development location (when running from Xcode)
            (Bundle.main.bundlePath as NSString).deletingLastPathComponent.appending("/server"),
            // Project root location
            "/Users/kotahayashi/Workspace/ClaudeCodeMonitor/server",
            // Alternative development location
            ((Bundle.main.bundlePath as NSString).deletingLastPathComponent as NSString)
                .deletingLastPathComponent
                .replacingOccurrences(of: "/Build/Products/Debug", with: "")
                .appending("/server")
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                print("[ServerManager] Using development server at: \(path)")
                return path
            }
        }
        
        return nil
    }
    
    private func findNodePath() -> String? {
        let systemNodePaths = [
            "/Users/\(NSUserName())/.local/share/mise/shims/node",
            "/Users/\(NSUserName())/.local/share/mise/installs/node/22.16.0/bin/node",
            "/opt/homebrew/bin/node",
            "/usr/local/bin/node",
            "/usr/bin/node"
        ]

        for path in systemNodePaths {
            let expandedPath = (path as NSString).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expandedPath) {
                print("[ServerManager] Using system Node.js at: \(expandedPath)")
                return expandedPath
            }
        }
        
        return nil
    }
    
    private func configureServerProcess(node: String, serverPath: String) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: node)
        process.arguments = ["server.js"]
        process.currentDirectoryURL = URL(fileURLWithPath: serverPath)
        
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
            if !data.isEmpty {
                if let output = String(data: data, encoding: .utf8) {
                    print("[Server] \(output)", terminator: "")
                }
            }
        }
        
        // Monitor process termination
        process.terminationHandler = { proc in
            print("[ServerManager] Process terminated with status: \(proc.terminationStatus)")
            print("[ServerManager] Termination reason: \(proc.terminationReason)")
        }
        
        return process
    }

    private func startServer() async -> Bool {
        print("[ServerManager] Attempting to start server")
        NSLog("[ServerManager] Attempting to start server")

        // Find server path
        guard let serverPath = findServerPath() else {
            print("[ServerManager] Server directory not found - server will not start")
            print("[ServerManager] This is expected in development mode. npx will be used directly.")
            NSLog("[ServerManager] Server directory not found")
            return false
        }

        // Find Node.js
        guard let node = findNodePath() else {
            print("[ServerManager] Node.js not found")
            return false
        }

        // Configure and run process
        let process = configureServerProcess(node: node, serverPath: serverPath)

        do {
            print("[ServerManager] About to run process with:")
            print("[ServerManager]   Executable: \(node)")
            print("[ServerManager]   Arguments: \(process.arguments ?? [])")
            print("[ServerManager]   Directory: \(serverPath)")
            print("[ServerManager]   Environment CLAUDE_CONFIG_DIR: \(process.environment?["CLAUDE_CONFIG_DIR"] ?? "not set")")

            try process.run()
            serverProcess = process
            print("[ServerManager] Process started with PID: \(process.processIdentifier)")

            // Wait for server to start with multiple retry attempts
            var retryCount = 0
            let maxRetries = Constants.Server.serverStartupRetryCount
            let retryDelay = UInt64(Constants.Timing.serverStartupRetryDelay * 1_000_000_000)

            while retryCount < maxRetries {
                try? await Task.sleep(nanoseconds: retryDelay)

                if await isServerResponding() {
                    print("[ServerManager] Server started successfully after \(retryCount + 1) attempt(s)")
                    isServerRunning = true
                    startServerMonitoring()
                    return true
                }

                retryCount += 1
                print("[ServerManager] Server not responding yet, retry \(retryCount)/\(maxRetries)")
            }

            print("[ServerManager] Server failed to start after \(maxRetries) attempts")
            stopServer() // Clean up the process
            return false
        } catch {
            print("[ServerManager] Failed to start server: \(error)")
            return false
        }
    }

    func stopServer() {
        serverMonitorTask?.cancel()
        serverMonitorTask = nil
        serverProcess?.terminate()
        serverProcess = nil
        isServerRunning = false
    }

    private func startServerMonitoring() {
        serverMonitorTask?.cancel()

        serverMonitorTask = Task {
            print("[ServerManager] Starting server health monitoring")

            while !Task.isCancelled {
                // Check at configured interval
                let checkInterval = UInt64(Constants.Timing.serverHealthCheckInterval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: checkInterval)

                if Task.isCancelled { break }

                // Check if server is still responding
                let isResponding = await isServerResponding()
                if !isResponding {
                    print("[ServerManager] Server is not responding, attempting restart...")
                    isServerRunning = false

                    // Try to restart the server
                    let restarted = await startServer()
                    if restarted {
                        print("[ServerManager] Server restarted successfully")
                    } else {
                        print("[ServerManager] Failed to restart server")
                        // Could emit a notification here in the future
                    }
                }
            }

            print("[ServerManager] Server monitoring stopped")
        }
    }
}
