import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: EventMonitor?
    private var usageMonitor: UsageMonitor!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        usageMonitor = UsageMonitor()
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "dollarsign.circle.fill", accessibilityDescription: "Claude Usage Monitor")
            button.title = "Loading..."
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 380)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView().environmentObject(usageMonitor))
        
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
    
    private var cancellables = Set<AnyCancellable>()
    
    @MainActor
    private func updateStatusBarTitle() {
        if let button = statusItem.button {
            if usageMonitor.isLoading && usageMonitor.usageData.activeSession == nil {
                button.title = "Loading..."
            } else if let session = usageMonitor.usageData.activeSession {
                // Show session-based info
                let percentage = usageMonitor.usageData.sessionTokenPercentage
                let percentageStr = usageMonitor.usageData.formattedSessionPercentage
                let tokensK = session.totalTokens / 1000  // Show in K
                
                // Show tokens and percentage with appropriate indicator
                if percentage > 100 {
                    button.title = "\(tokensK)K 🚨 \(percentageStr)"
                } else if percentage > 90 {
                    button.title = "\(tokensK)K ⚠️ \(percentageStr)"
                } else if percentage > 70 {
                    button.title = "\(tokensK)K ⚡ \(percentageStr)"
                } else {
                    button.title = "\(tokensK)K • \(percentageStr)"
                }
            } else {
                // Fallback to daily cost if no session data
                button.title = usageMonitor.usageData.formattedDailyCost
            }
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
    private func showPopover() {
        if let button = statusItem.button {
            // Refresh data when opening popover
            usageMonitor.fetchUsageData()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor?.start()
        }
    }
    
    private func closePopover() {
        popover.performClose(nil)
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