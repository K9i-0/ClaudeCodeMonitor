import Foundation
import AppKit

@MainActor
class ClaudeDataAccessManager: ObservableObject {
    @Published var hasAccess = false
    @Published var claudePath: String?
    
    init() {
        print("[ClaudeDataAccess] Initializing...")
        checkExistingAccess()
        print("[ClaudeDataAccess] Initial hasAccess: \(hasAccess), claudePath: \(claudePath ?? "nil")")
    }
    
    /// Check if we have existing access via saved path or auto-detect
    func checkExistingAccess() {
        // First try to load saved path
        if let savedPath = UserDefaults.standard.string(forKey: "claudeDataPath") {
            print("[ClaudeDataAccess] Found saved path: \(savedPath)")
            // Verify the path still exists and has projects subdirectory
            let url = URL(fileURLWithPath: savedPath)
            let projectsURL = url.appendingPathComponent("projects")
            
            if FileManager.default.fileExists(atPath: projectsURL.path) {
                claudePath = savedPath
                hasAccess = true
                print("[ClaudeDataAccess] Path is valid, access restored")
                return
            } else {
                print("[ClaudeDataAccess] Saved path no longer valid")
                // Clear invalid path
                UserDefaults.standard.removeObject(forKey: "claudeDataPath")
            }
        }
        
        // Auto-detect ~/.claude path
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let defaultClaudePath = homeDirectory.appendingPathComponent(".claude")
        let projectsURL = defaultClaudePath.appendingPathComponent("projects")
        
        if FileManager.default.fileExists(atPath: projectsURL.path) {
            claudePath = defaultClaudePath.path
            hasAccess = true
            // Save the auto-detected path
            UserDefaults.standard.set(defaultClaudePath.path, forKey: "claudeDataPath")
            print("[ClaudeDataAccess] Auto-detected Claude data at: \(defaultClaudePath.path)")
        } else {
            print("[ClaudeDataAccess] Claude data not found at default location: \(defaultClaudePath.path)")
        }
    }
    
    /// Request access to Claude data folder
    func requestAccess() async -> Bool {
        print("[ClaudeDataAccess] Requesting folder access...")
        
        // Pause event monitor to prevent popover from closing
        await MainActor.run {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.pauseEventMonitor()
            }
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false
                panel.message = L10n.selectClaudeDataFolder
                panel.prompt = L10n.select
                
                // Default to home directory
                panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
                
                panel.begin { [weak self] response in
                    // Resume event monitor after dialog is closed
                    Task { @MainActor in
                        if let appDelegate = NSApp.delegate as? AppDelegate {
                            appDelegate.resumeEventMonitor()
                        }
                    }
                    
                    guard response == .OK, let url = panel.url else {
                        print("[ClaudeDataAccess] User cancelled folder selection")
                        continuation.resume(returning: false)
                        return
                    }
                    
                    print("[ClaudeDataAccess] User selected: \(url.path)")
                    
                    Task {
                        let success = await self?.processSelectedFolder(url) ?? false
                        continuation.resume(returning: success)
                    }
                }
            }
        }
    }
    
    private func processSelectedFolder(_ url: URL) async -> Bool {
        // Resolve any symbolic links to get the real path
        let resolvedURL = url.resolvingSymlinksInPath()
        print("[ClaudeDataAccess] Original path: \(url.path)")
        print("[ClaudeDataAccess] Resolved path: \(resolvedURL.path)")
        
        // Verify this is a Claude data folder by checking for projects subdirectory
        let projectsURL = resolvedURL.appendingPathComponent("projects")
        let fileManager = FileManager.default
        
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: projectsURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            print("[ClaudeDataAccess] Selected folder doesn't contain 'projects' subdirectory: \(resolvedURL.path)")
            print("[ClaudeDataAccess] Looking for: \(projectsURL.path)")
            // Show error alert with more detail
            let errorMessage = """
            \(L10n.invalidClaudeFolder)
            
            Selected: \(resolvedURL.path)
            Expected: ~/.claude (with projects subdirectory)
            """
            await showError(message: errorMessage)
            return false
        }
        
        // Save the path
        claudePath = resolvedURL.path
        hasAccess = true
        
        // Save the resolved path to UserDefaults
        UserDefaults.standard.set(resolvedURL.path, forKey: "claudeDataPath")
        UserDefaults.standard.synchronize()
        
        print("[ClaudeDataAccess] Successfully saved path: \(resolvedURL.path)")
        print("[ClaudeDataAccess] hasAccess is now: \(hasAccess)")
        
        return true
    }
    
    /// Show error alert
    private func showError(message: String) async {
        await MainActor.run {
            let alert = NSAlert()
            alert.messageText = L10n.error
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: L10n.ok)
            
            alert.runModal()
        }
    }
    
    /// Reset access (for testing or if user wants to change folder)
    func resetAccess() {
        print("[ClaudeDataAccess] Resetting access...")
        UserDefaults.standard.removeObject(forKey: "claudeDataPath")
        UserDefaults.standard.synchronize()
        
        claudePath = nil
        hasAccess = false
    }
}