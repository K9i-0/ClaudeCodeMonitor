import Cocoa
import SwiftUI
import Combine
import UserNotifications
#if canImport(Sparkle)
import Sparkle
#endif

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!
    
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: EventMonitor?
    private var usageMonitor: UsageMonitor!
    private var environmentCheckResult = EnvironmentCheckResult()
    private var isEnvironmentValid = false
    private var cancellables = Set<AnyCancellable>()
    
    // Sparkle configuration based on build type
    #if canImport(Sparkle)
        #if DEBUG
        // Allow testing Sparkle in debug builds with TEST_SPARKLE environment variable
        private lazy var updaterController: SPUStandardUpdaterController? = {
            if ProcessInfo.processInfo.environment["TEST_SPARKLE"] != nil {
                print("⚠️ Sparkle enabled in DEBUG mode for testing")
                return SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
            }
            return nil
        }()
        #else
        private lazy var updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
        #endif
    #else
    private let updaterController: AnyObject? = nil
    #endif

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Debug builds use different settings to avoid conflicts with release version
        #if DEBUG
        // This will be reflected in menu bar and other UI elements
        print("Running in DEBUG mode")
        if ProcessInfo.processInfo.environment["TEST_SPARKLE"] != nil {
            print("Sparkle testing mode enabled")
        }
        #endif
        
        // Configure Sparkle update channel
        configureUpdateChannel()

        // Perform synchronous environment check first
        environmentCheckResult = CommandExecutor.shared.checkEnvironmentSync()
        isEnvironmentValid = environmentCheckResult.hasClaudeCode &&
                             (environmentCheckResult.hasBun || environmentCheckResult.hasNode)
        
        // Always create UsageMonitor (it handles invalid environments internally)
        usageMonitor = UsageMonitor()
        
        // Set up the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
        }
        
        // Set initial status bar title
        updateStatusBarTitle()
        
        // Configure popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 480, height: 300)
        popover.behavior = .transient
        popover.animates = false
        
        updatePopoverContent()
        
        // Set up event monitor for clicks outside popover
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let self = self, self.popover.isShown {
                self.closePopover(event)
            }
        }
        
        // Subscribe to usage updates only if environment is valid
        if isEnvironmentValid {
            // Subscribe to usage data changes
            usageMonitor.$usageData
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.updateStatusBarTitle()
                }
                .store(in: &cancellables)
            
            // Start monitoring
            usageMonitor.startMonitoring()
            
            // Fetch exchange rates
            Task {
                await CurrencySettings.shared.fetchExchangeRates()
            }
        }
    }
    
    private func updatePopoverContent() {
        if isEnvironmentValid {
            let contentView = ContentView()
                .environmentObject(usageMonitor)
            popover.contentViewController = NSHostingController(rootView: contentView)
        } else {
            let setupView = EnvironmentSetupView()
            popover.contentViewController = NSHostingController(rootView: setupView)
        }
    }
    
    private func updateStatusBarTitle() {
        guard let button = statusItem.button else { return }
        guard let usageMonitor = usageMonitor else {
            // Environment setup mode
            if let image = NSImage(systemSymbolName: "exclamationmark.circle", accessibilityDescription: "Setup Required") {
                let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                button.image = image.withSymbolConfiguration(config)
                button.title = ""
                button.toolTip = L10n.Environment.setupRequired
            }
            return
        }

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
            #if DEBUG
            button.title = String(format: "%.0f%% [D]", percentage)
            #else
            button.title = String(format: "%.0f%%", percentage)
            #endif
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
            let formattedCost = CurrencyConverter.formatCostWithFallback(cost, using: CurrencySettings.shared)
            button.toolTip = L10n.Status.usageFormat(usage: percentage, cost: formattedCost, burnRate: burnRate, timeRemaining: remaining)
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
    
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func showPopover(_ sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            eventMonitor?.start()
        }
    }
    
    func closePopover(_ sender: Any?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        usageMonitor.stopMonitoring()
    }
    
    private func configureUpdateChannel() {
        #if canImport(Sparkle)
        let channel = UserDefaults.standard.updateChannel
        print("Sparkle configured for \(channel.rawValue) channel: \(channel.appcastURL)")
        #endif
    }
    
    func updateChannelChanged(to newChannel: UpdateChannel) {
        #if canImport(Sparkle)
        guard let updater = updaterController?.updater else { return }
        
        print("Sparkle channel changed to \(newChannel.rawValue): \(newChannel.appcastURL)")
        
        // Check for updates with new channel
        updater.checkForUpdates()
        #endif
    }
}

// MARK: - SPUUpdaterDelegate
#if canImport(Sparkle)
extension AppDelegate: SPUUpdaterDelegate {
    nonisolated func feedURLString(for updater: SPUUpdater) -> String? {
        let channel = UserDefaults.standard.updateChannel
        return channel.appcastURL
    }
}
#endif

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