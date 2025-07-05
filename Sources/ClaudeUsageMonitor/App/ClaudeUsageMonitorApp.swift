import SwiftUI

@main
struct ClaudeUsageMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    var body: some Scene {
        // Use Settings scene with empty content for menubar app
        // All UI is handled by AppDelegate and NSPopover
        Settings {
            EmptyView()
        }
        .commands {
            // Remove default menu commands that aren't needed for menubar app
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .appSettings) { }
        }
    }
}
