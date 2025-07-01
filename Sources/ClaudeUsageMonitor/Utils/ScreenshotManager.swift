import SwiftUI
import AppKit

@MainActor
class ScreenshotManager {
    static let shared = ScreenshotManager()
    
    private init() {}
    
    func captureViewContent(_ view: AnyView, withText text: String? = nil) async -> Bool {
        // Use ImageRenderer to capture the specific view content
        let renderer = ImageRenderer(content: view)
        
        // Set the scale to match the screen
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        // Create NSImage from the renderer
        guard let nsImage = renderer.nsImage else {
            print("Failed to create screenshot")
            return false
        }
        
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Create pasteboard items
        var items: [NSPasteboardItem] = []
        let item = NSPasteboardItem()
        
        // Add image data
        if let tiffData = nsImage.tiffRepresentation {
            item.setData(tiffData, forType: .tiff)
        }
        
        if let tiffData = nsImage.tiffRepresentation,
           let bitmapRep = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            item.setData(pngData, forType: .png)
        }
        
        // Add text if provided
        if let text = text {
            item.setString(text, forType: .string)
        }
        
        items.append(item)
        
        return pasteboard.writeObjects(items)
    }
    
    func captureAndCopyToClipboard<Content: View>(from view: Content) async -> Bool {
        // Find the current window's content view
        guard let window = NSApp.windows.first(where: { $0.isVisible }),
              let contentView = window.contentView else {
            print("No visible window found")
            return false
        }
        
        // Create bitmap representation of the content view
        guard let bitmapRep = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds) else {
            print("Failed to create bitmap representation")
            return false
        }
        
        // Draw the view into the bitmap
        contentView.cacheDisplay(in: contentView.bounds, to: bitmapRep)
        
        // Create NSImage from bitmap
        let image = NSImage(size: contentView.bounds.size)
        image.addRepresentation(bitmapRep)
        
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Add both PNG and TIFF representations for better compatibility
        var items: [NSPasteboardItem] = []
        let item = NSPasteboardItem()
        
        if let tiffData = image.tiffRepresentation {
            item.setData(tiffData, forType: .tiff)
        }
        
        if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            item.setData(pngData, forType: .png)
        }
        
        items.append(item)
        
        return pasteboard.writeObjects(items)
    }
    
    func captureAndShare<Content: View>(from view: Content) async {
        // Wrap the view with a background to ensure proper rendering
        let wrappedView = ZStack {
            // Add explicit background
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            
            view
        }
        .frame(width: 380, height: 480) // Match ContentView frame

        let renderer = ImageRenderer(content: wrappedView)
        
        // Set the scale to match the screen
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        // Create NSImage from the renderer
        guard let nsImage = renderer.nsImage else {
            print("Failed to create screenshot")
            return
        }
        
        // Create sharing picker
        let picker = NSSharingServicePicker(items: [nsImage])
        
        // Find a suitable view to anchor the picker
        guard let window = NSApp.windows.first(where: { $0.isVisible }),
              let contentView = window.contentView else {
            print("No visible window found")
            return
        }
        
        // Show the picker
        let rect = NSRect(x: contentView.bounds.midX - 1, y: contentView.bounds.midY - 1, width: 2, height: 2)
        picker.show(relativeTo: rect, of: contentView, preferredEdge: .minY)
    }
}