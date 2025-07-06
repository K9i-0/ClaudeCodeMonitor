import Cocoa
import SwiftUI
import Sparkle
import Combine
import UserNotifications

extension Notification.Name {
    static let usageDataUpdated = Notification.Name("ClaudeMonitor.usageDataUpdated")
}

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
    #if DEBUG
    // Allow testing Sparkle in debug builds with TEST_SPARKLE environment variable
    private let updaterController: SPUStandardUpdaterController? = {
        if ProcessInfo.processInfo.environment["TEST_SPARKLE"] != nil {
            print("⚠️ Sparkle enabled in DEBUG mode for testing")
            return SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        }
        return nil
    }()
    #else
    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
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
        
        let data = usageMonitor.usageData
        guard let activeSession = data.activeSession else {
            updateStatusItemTitle("bolt.fill", percentage: 0)
            return
        }
        
        // Calculate percentage based on the detected plan limit
        let limit = data.sessionTokenLimit
        let percentage = (Double(activeSession.totalTokens) / Double(limit)) * 100.0
        updateStatusItemTitle("bolt.fill", percentage: Int(percentage))
    }
    
    private func updateStatusItemTitle(_ iconName: String, percentage: Int) {
        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
                button.image = image.withSymbolConfiguration(config)
            }
            
            #if DEBUG
            button.title = " [D] \(percentage)%"
            #else
            button.title = " \(percentage)%"
            #endif
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

extension Notification.Name {
    static let usageDataUpdated = Notification.Name("usageDataUpdated")
}