import Cocoa
import SwiftUI
import Combine
import UserNotifications
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: EventMonitor?
    private var usageMonitor: UsageMonitor!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Save environment variables and npx path to App Group before starting Helper Item
        saveEnvironmentVariables()
        findAndSaveHelperPaths()
        
        // Register Helper Item first
        registerHelperItem()
        
        // Initialize usage monitor
        usageMonitor = UsageMonitor()
        
        // Helper Item will provide the server, so we don't need ServerManager anymore
        // Check if helper is running, if not in development, start it manually
        checkAndStartHelper()
        
        // 通知機能は初回リリースでは無効化
        /*
        // Setup notification center delegate
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().delegate = NotificationManager.shared
        }
        */
        
        // Hide all windows for menubar-only app
        NSApp.windows.forEach { window in
            window.close()
        }
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // SF Symbolsを使用した初期アイコン
            if let image = NSImage(systemSymbolName: "hourglass", accessibilityDescription: "Claude Code Monitor") {
                let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                button.image = image.withSymbolConfiguration(config)
                button.imagePosition = .imageLeading
            } else {
                button.title = "⏳"
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 480)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(usageMonitor)
        )
        
        // Monitor for clicks outside the popover
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let self = self, self.popover.isShown {
                self.closePopover()
            }
        }
        
        // Update status bar title when usage data changes
        updateStatusBarTitle()
        
        // Observe usage data changes
        usageMonitor.$usageData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusBarTitle()
            }
            .store(in: &cancellables)
    }
    
    private func saveEnvironmentVariables() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.k9i.claudecodemonitor") else {
            print("[AppDelegate] Failed to access app group")
            return
        }
        
        let environment = ProcessInfo.processInfo.environment
        
        // 保存する環境変数を選択（必要なものだけ）
        var envToSave: [String: String] = [:]
        
        // 必須の環境変数
        if let path = environment["PATH"] {
            envToSave["PATH"] = path
        }
        if let home = environment["HOME"] {
            envToSave["HOME"] = home
        }
        
        // Node.js関連の環境変数
        let nodeRelatedKeys = ["MISE_HOME", "MISE_BIN_DIR", "MISE_DATA_DIR", 
                              "ASDF_DIR", "ASDF_DATA_DIR", 
                              "NVM_DIR", "NVM_BIN", 
                              "VOLTA_HOME", 
                              "NODE_PATH", "NPM_CONFIG_PREFIX"]
        
        for key in nodeRelatedKeys {
            if let value = environment[key] {
                envToSave[key] = value
            }
        }
        
        // UserDefaultsに保存
        sharedDefaults.set(envToSave, forKey: "sharedEnvironment")
        sharedDefaults.synchronize()
        
        print("[AppDelegate] Saved environment variables to app group: \(envToSave.keys.joined(separator: ", "))")
    }
    
    private func findAndSaveHelperPaths() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.k9i.claudecodemonitor") else {
            print("[AppDelegate] Failed to access app group for helper paths")
            return
        }
        
        var pathsToSave: [String: String] = [:]
        var npxPath: String? = nil
        var nodePath: String? = nil
        var npmPath: String? = nil
        
        // Find npx path
        let npxTask = Process()
        npxTask.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        npxTask.arguments = ["bash", "-l", "-c", "which npx"]
        let npxPipe = Pipe()
        npxTask.standardOutput = npxPipe
        npxTask.standardError = npxPipe
        do {
            try npxTask.run()
            npxTask.waitUntilExit()
            let data = npxPipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                npxPath = path
                pathsToSave["npxPath"] = path
                print("[AppDelegate] Found npx path: \(path)")
            } else {
                let errorString = String(data: npxPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown error"
                print("[AppDelegate] Failed to find npx path. Error: \(errorString)")
            }
        } catch { print("[AppDelegate] Error finding npx path: \(error)") }
        
        // Find node path
        let nodeTask = Process()
        nodeTask.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        nodeTask.arguments = ["bash", "-l", "-c", "which node"]
        let nodePipe = Pipe()
        nodeTask.standardOutput = nodePipe
        nodeTask.standardError = nodePipe
        do {
            try nodeTask.run()
            nodeTask.waitUntilExit()
            let data = nodePipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                nodePath = path
                pathsToSave["nodePath"] = path
                print("[AppDelegate] Found node path: \(path)")
            } else {
                let errorString = String(data: nodePipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown error"
                print("[AppDelegate] Failed to find node path. Error: \(errorString)")
            }
        } catch { print("[AppDelegate] Error finding node path: \(error)") }
        
        // Find npm path
        let npmTask = Process()
        npmTask.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        npmTask.arguments = ["bash", "-l", "-c", "which npm"]
        let npmPipe = Pipe()
        npmTask.standardOutput = npmPipe
        npmTask.standardError = npmPipe
        do {
            try npmTask.run()
            npmTask.waitUntilExit()
            let data = npmPipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                npmPath = path
                pathsToSave["npmPath"] = path
                print("[AppDelegate] Found npm path: \(path)")
            } else {
                let errorString = String(data: npmPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown error"
                print("[AppDelegate] Failed to find npm path. Error: \(errorString)")
            }
        } catch { print("[AppDelegate] Error finding npm path: \(error)") }
        
        // Construct a robust PATH for the helper
        var helperPathComponents: Set<String> = []
        if let npxDir = npxPath.map({ URL(fileURLWithPath: $0).deletingLastPathComponent().path }) { helperPathComponents.insert(npxDir) }
        if let nodeDir = nodePath.map({ URL(fileURLWithPath: $0).deletingLastPathComponent().path }) { helperPathComponents.insert(nodeDir) }
        if let npmDir = npmPath.map({ URL(fileURLWithPath: $0).deletingLastPathComponent().path }) { helperPathComponents.insert(npmDir) }
        
        // Add standard paths that might be missing in launchd environment
        helperPathComponents.insert("/usr/local/bin")
        helperPathComponents.insert("/usr/bin")
        helperPathComponents.insert("/bin")
        helperPathComponents.insert("/usr/sbin")
        helperPathComponents.insert("/sbin")
        
        let constructedPath = helperPathComponents.joined(separator: ":")
        pathsToSave["HELPER_PATH"] = constructedPath
        print("[AppDelegate] Constructed HELPER_PATH: \(constructedPath)")
        
        sharedDefaults.set(pathsToSave, forKey: "helperPaths")
        sharedDefaults.synchronize()
        
        print("[AppDelegate] Saved helper paths to app group: \(pathsToSave.keys.joined(separator: ", "))")
    }
    
    private func registerHelperItem() {
        let helperBundleIdentifier = "com.k9i.ClaudeMonitorHelper"
        
        if #available(macOS 13.0, *) {
            // Use SMAppService for macOS 13+
            let service = SMAppService.loginItem(identifier: helperBundleIdentifier)
            
            do {
                if service.status == .enabled {
                    print("[AppDelegate] Helper item is already enabled")
                } else {
                    try service.register()
                    print("[AppDelegate] Helper item registered successfully")
                }
            } catch {
                print("[AppDelegate] Failed to register helper item: \(error)")
                // Try legacy method as fallback
                SMLoginItemSetEnabled(helperBundleIdentifier as CFString, true)
            }
        } else {
            // Use legacy SMLoginItemSetEnabled for macOS 12 and earlier
            let success = SMLoginItemSetEnabled(helperBundleIdentifier as CFString, true)
            print("[AppDelegate] Helper item registration (legacy): \(success ? "success" : "failed")")
        }
    }
    
    private func checkAndStartHelper() {
        // Wait a bit for the helper to start
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            // Get the actual port from app group
            let port = UserDefaults(suiteName: "group.com.k9i.claudecodemonitor")?.integer(forKey: "helperPort") ?? 8456
            
            // Check if helper is running by testing the health endpoint
            let url = URL(string: "http://127.0.0.1:\(port)/health")!
            var request = URLRequest(url: url, timeoutInterval: 1.0)
            
            // Add authentication header
            if let sharedDefaults = UserDefaults(suiteName: "group.com.k9i.claudecodemonitor"),
               let authToken = sharedDefaults.string(forKey: "helperAuthToken") {
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if error != nil || (response as? HTTPURLResponse)?.statusCode != 200 {
                        // Helper is not running, start it manually in development
                        #if DEBUG
                        print("[AppDelegate] Helper not running, starting manually in development")
                        self?.startHelperManually()
                        #else
                        print("[AppDelegate] Helper not running in production - user may need to grant permission")
                        #endif
                    } else {
                        print("[AppDelegate] Helper is running, fetching data")
                        self?.usageMonitor.fetchUsageData()
                    }
                }
            }.resume()
        }
    }
    
    private func startHelperManually() {
        // In development, start the helper directly
        let helperPath = Bundle.main.path(forResource: "ClaudeMonitorHelper", ofType: nil, inDirectory: "Library/LaunchServices")
        
        if let helperPath = helperPath {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: helperPath)
            
            do {
                try task.run()
                print("[AppDelegate] Helper started manually at: \(helperPath)")
                
                // Wait for helper to start and then fetch data
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.usageMonitor.fetchUsageData()
                }
            } catch {
                print("[AppDelegate] Failed to start helper manually: \(error)")
            }
        } else {
            print("[AppDelegate] Helper executable not found in bundle")
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    @MainActor
    private func updateStatusBarTitle() {
        guard let button = statusItem.button else { return }
        
        if usageMonitor.isLoading && usageMonitor.usageData.activeSession == nil {
            // ローディング中
            if let image = NSImage(systemSymbolName: "hourglass", accessibilityDescription: "Loading") {
                let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                button.image = image.withSymbolConfiguration(config)
                button.title = ""
                button.toolTip = L10n.Status.loading
            }
        } else if let session = usageMonitor.usageData.activeSession {
            // アクティブセッション
            let percentage = usageMonitor.usageData.sessionUsagePercentage
            let cost = session.costUSD
            
            // SF Symbolを使用したアイコン表示
            let symbolName = getStatusSymbol(percentage: percentage)
            let tintColor = getStatusColor(percentage: percentage)
            
            if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Usage Status") {
                let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                    .applying(.init(paletteColors: [tintColor]))
                button.image = image.withSymbolConfiguration(config)
            }
            
            // パーセンテージのみ表示（HIGに準拠した簡潔な表示）
            button.title = String(format: "%.0f%%", percentage)
            button.attributedTitle = NSAttributedString(
                string: button.title,
                attributes: [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
                    .foregroundColor: tintColor
                ]
            )
            
            // 詳細情報はツールチップで表示
            let burnRateString = usageMonitor.usageData.sessionBurnRate
            let burnRate = Double(burnRateString) ?? 0.0
            let remaining = usageMonitor.usageData.sessionRemainingTime
            button.toolTip = L10n.Status.usageFormat(usage: percentage, cost: cost, burnRate: burnRate, timeRemaining: remaining)
        } else {
            // 非アクティブ
            if let image = NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: "Inactive") {
                let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                button.image = image.withSymbolConfiguration(config)
                button.title = ""
                button.toolTip = L10n.Status.noActiveSession
            }
        }
    }
    
    @MainActor
    private func getStatusSymbol(percentage: Double) -> String {
        switch percentage {
        case 90...:
            return "exclamationmark.triangle.fill"  // 危険
        case 70..<90:
            return "bolt.fill"  // 注意
        case 50..<70:
            return "flame.fill"  // 高使用率
        case 30..<50:
            return "speedometer"  // 中使用率
        case 10..<30:
            return "circle.lefthalf.filled"  // 低使用率
        default:
            return "circle.fill"  // 最小使用率
        }
    }
    
    @MainActor
    private func getStatusColor(percentage: Double) -> NSColor {
        switch percentage {
        case 90...:
            return NSColor.systemRed  // 危険
        case 70..<90:
            return NSColor.systemOrange  // 警告
        case 50..<70:
            return NSColor.systemYellow  // 注意
        case 30..<50:
            return NSColor.systemBlue  // 標準
        default:
            return NSColor.systemGreen  // 良好
        }
    }
    
    
    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            Task { @MainActor in
                showPopover()
            }
        }
    }
    
    @MainActor
    func showPopover() {
        if let button = statusItem.button {
            // Refresh data when opening popover
            usageMonitor.fetchUsageData()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor?.start()
        }
    }
    
    func closePopover() {
        popover.performClose(nil)
        eventMonitor?.stop()
    }
    
    func pauseEventMonitor() {
        eventMonitor?.stop()
    }
    
    func resumeEventMonitor() {
        if popover.isShown {
            eventMonitor?.start()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        usageMonitor.stopMonitoring()
    }
}

class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void
    
    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }
    
    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}