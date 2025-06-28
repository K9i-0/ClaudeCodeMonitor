import Foundation
import AppKit

@MainActor
class FolderAccessHelper {
    static func requestFolderAccess(completion: @escaping (URL?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.title = L10n.selectClaudeDataFolder
        openPanel.message = L10n.claudeDataFolderMessage
        openPanel.prompt = L10n.select
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.showsHiddenFiles = true
        
        // Navigate directly to ~/.claude if it exists
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let claudeURL = homeURL.appendingPathComponent(".claude")
        
        // Check if .claude exists and has projects subdirectory
        let projectsURL = claudeURL.appendingPathComponent("projects")
        var isDirectory: ObjCBool = false
        
        if FileManager.default.fileExists(atPath: claudeURL.path, isDirectory: &isDirectory),
           isDirectory.boolValue,
           FileManager.default.fileExists(atPath: projectsURL.path) {
            openPanel.directoryURL = claudeURL
            // Also pre-select it
            openPanel.nameFieldStringValue = ".claude"
        } else {
            // If .claude doesn't exist, try .config/claude
            let configClaudeURL = homeURL.appendingPathComponent(".config/claude")
            if FileManager.default.fileExists(atPath: configClaudeURL.path) {
                openPanel.directoryURL = configClaudeURL
            } else {
                openPanel.directoryURL = homeURL
            }
        }
        
        // Make sure panel is key and front
        openPanel.makeKeyAndOrderFront(nil)
        openPanel.level = .modalPanel
        
        // Use async begin to avoid blocking the UI
        openPanel.begin { response in
            Task { @MainActor in
                if response == .OK, let selectedURL = openPanel.url {
                    print("[FolderAccessHelper] User selected: \(selectedURL.path)")
                    
                    // Double-check that user selected the correct folder
                    if selectedURL.lastPathComponent == ".claude" {
                        completion(selectedURL)
                    } else {
                        // If user selected a parent directory, try to find .claude within it
                        let claudeInSelected = selectedURL.appendingPathComponent(".claude")
                        if FileManager.default.fileExists(atPath: claudeInSelected.path) {
                            print("[FolderAccessHelper] Adjusting selection to: \(claudeInSelected.path)")
                            completion(claudeInSelected)
                        } else {
                            completion(selectedURL)
                        }
                    }
                } else {
                    print("[FolderAccessHelper] User cancelled")
                    completion(nil)
                }
            }
        }
    }
}