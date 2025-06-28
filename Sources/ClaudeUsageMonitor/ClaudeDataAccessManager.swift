import Foundation
import AppKit

@MainActor
class ClaudeDataAccessManager: ObservableObject {
    @Published var hasAccess = false
    @Published var claudePath: String?
    
    private let bookmarkKey = "ClaudeDataFolderBookmark"
    
    init() {
        checkExistingAccess()
    }
    
    /// Check if we have existing access via bookmark
    func checkExistingAccess() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            print("[ClaudeDataAccess] No existing bookmark found")
            return
        }
        
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData,
                            options: .withSecurityScope,
                            relativeTo: nil,
                            bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("[ClaudeDataAccess] Bookmark is stale, need to request access again")
                hasAccess = false
                return
            }
            
            // Start accessing the security-scoped resource
            if url.startAccessingSecurityScopedResource() {
                claudePath = url.path
                hasAccess = true
                print("[ClaudeDataAccess] Successfully accessed Claude data at: \(url.path)")
                
                // We'll stop accessing when the app terminates
                // In a real app, you might want to manage this more carefully
            } else {
                print("[ClaudeDataAccess] Failed to access security-scoped resource")
                hasAccess = false
            }
        } catch {
            print("[ClaudeDataAccess] Error resolving bookmark: \(error)")
            hasAccess = false
        }
    }
    
    /// Request access to Claude data folder
    func requestAccess() async -> Bool {
        let openPanel = NSOpenPanel()
        openPanel.title = L10n.selectClaudeDataFolder
        openPanel.message = L10n.claudeDataFolderMessage
        openPanel.prompt = L10n.select
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.showsHiddenFiles = true
        
        // Set default directory to home
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        
        let response = await openPanel.begin()
        
        guard response == .OK,
              let url = openPanel.url else {
            print("[ClaudeDataAccess] User cancelled folder selection")
            return false
        }
        
        // Verify this is a Claude data folder by checking for projects subdirectory
        let projectsURL = url.appendingPathComponent("projects")
        let fileManager = FileManager.default
        
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: projectsURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            print("[ClaudeDataAccess] Selected folder doesn't contain 'projects' subdirectory")
            // Show error alert
            await showError(message: L10n.invalidClaudeFolder)
            return false
        }
        
        // Create security-scoped bookmark
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope,
                                                   includingResourceValuesForKeys: nil,
                                                   relativeTo: nil)
            
            // Save bookmark to UserDefaults
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            
            // Start accessing the resource
            if url.startAccessingSecurityScopedResource() {
                claudePath = url.path
                hasAccess = true
                print("[ClaudeDataAccess] Successfully saved access to: \(url.path)")
                return true
            } else {
                print("[ClaudeDataAccess] Failed to start accessing security-scoped resource")
                return false
            }
        } catch {
            print("[ClaudeDataAccess] Error creating bookmark: \(error)")
            await showError(message: L10n.failedToSaveAccess)
            return false
        }
    }
    
    /// Show error alert
    private func showError(message: String) async {
        let alert = NSAlert()
        alert.messageText = L10n.error
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.ok)
        
        await alert.beginSheetModal(for: NSApp.keyWindow!)
    }
    
    /// Reset access (for testing or if user wants to change folder)
    func resetAccess() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        if let path = claudePath {
            URL(fileURLWithPath: path).stopAccessingSecurityScopedResource()
        }
        claudePath = nil
        hasAccess = false
    }
}