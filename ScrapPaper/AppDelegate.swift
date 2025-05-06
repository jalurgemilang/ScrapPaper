//
//  AppDelegate.swift
//  ScrapPaper
//
//  Created by Long Fong Yee on 06/05/2025.
//


import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        HotKeyManager.shared.registerHotKey()

        NotificationCenter.default.addObserver(forName: .triggerShowWindow, object: nil, queue: .main) { _ in
            self.toggleWindow()
        }
        
        // Create menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: "Text Editor")
            button.action = #selector(toggleFromMenu)
            button.target = self
        }
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
            self.window = win
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
