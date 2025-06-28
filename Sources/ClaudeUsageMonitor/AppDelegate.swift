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
    private var dataAccessManager: ClaudeDataAccessManager!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register Helper Item first
        registerHelperItem()
        
        // Initialize data access manager
        dataAccessManager = ClaudeDataAccessManager()
        
        // Helper Item will provide the server, so we don't need ServerManager anymore
        // Just wait a bit for the helper to start
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.usageMonitor.fetchUsageData()
        }
        
        usageMonitor = UsageMonitor()
        
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
                .environmentObject(dataAccessManager)
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
        
        // Observe data access changes
        dataAccessManager.$hasAccess
            .receive(on: DispatchQueue.main)
            .dropFirst() // Skip initial value
            .sink { [weak self] hasAccess in
                if hasAccess {
                    // Helper Item is already running, just fetch data
                    self?.usageMonitor.fetchUsageData()
                }
            }
            .store(in: &cancellables)
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