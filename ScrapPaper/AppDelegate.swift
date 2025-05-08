//
//  AppDelegate.swift
//  ScrapPaper
//
//  Created by Long Fong Yee on 06/05/2025.
//


import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
//    •    Create the initial app window
//    •    Set up menus, preferences, or status items
//    •    Handle app reopen events (e.g., clicking the dock icon)
    
    var window: NSWindow?
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        HotKeyManager.shared.registerHotKey()

        // Observe Control-Space key stroke
        NotificationCenter.default.addObserver(forName: .triggerShowWindow, object: nil, queue: .main) { _ in
            self.toggleWindow()
        }
        
        // Create menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "Text Editor")
            button.action = #selector(toggleFromMenu)
            button.target = self
        }
        
        // Right click menu bar icon
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show/Hide", action: #selector(toggleFromMenu), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
        
    }
    
    // Menu bar icon
    @objc func toggleFromMenu() {
        toggleWindow()
    }
    
    func toggleWindow() {
        if let window = window, window.isVisible {
            window.orderOut(nil) // Hide window
        } else {
            showWindow()
        }
    }

    func showWindow() {
        if window == nil {
            let contentView = ContentView()
            let win = NSWindow(
                contentRect: NSMakeRect(0, 0, 400, 300),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false)
            win.setFrameAutosaveName("Hotkey Window")               //saves name
            win.setFrameUsingName("Hotkey Window", force: true)     //restore position+size manually
            win.contentView = NSHostingView(rootView: contentView)
            win.delegate = self
            self.window = win
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil) // Hide the window
        return false          // Prevent closing
    }
    
    @objc func quitApp() {
        let text = UserDefaults.standard.string(forKey: "scrapText") ?? ""
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let alert = NSAlert()
            alert.messageText = "You still have text."
            alert.informativeText = "Are you sure you want to quit?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Quit")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSApp.terminate(nil)
            }
            return
        }
        NSApp.terminate(nil)
    }
}
