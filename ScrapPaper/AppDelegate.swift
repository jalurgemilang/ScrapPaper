//
//  AppDelegate.swift
//  ScrapPaper
//
//  Created by Long Fong Yee on 06/05/2025.
//


import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSToolbarDelegate {
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
        
        // Create Edit menu with your shortcuts
        let editMenuItem = NSMenuItem()
        editMenuItem.title = "Editor"           //visible to user
        menu.addItem(editMenuItem)
        
        let editMenu = NSMenu(title: "Editor")  //internal, can replace with NSMenu() also
        editMenuItem.submenu = editMenu
        
        editMenu.addItem(NSMenuItem(title: "Save to Notes", action: #selector(saveToNotes), keyEquivalent: "s"))
        editMenu.addItem(NSMenuItem(title: "Clear Text", action: #selector(clearText), keyEquivalent: "d"))
        editMenu.addItem(NSMenuItem(title: "Decrease Font Size", action: #selector(decreaseFontSize), keyEquivalent: "-"))
        editMenu.addItem(NSMenuItem(title: "Increase Font Size", action: #selector(increaseFontSize), keyEquivalent: "=")) // Shift + = is +
        
        NSApp.mainMenu = menu
        
    }
    
    
    // MARK: - WINDOW
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
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false)
            
            // Add toolbar (I didn't put in applicationDidFinishLaunching because in there windows is still nil
            // windows is only initialize here in showWindow
            let toolbar = NSToolbar(identifier: NSToolbar.Identifier("MainToolbar"))
            toolbar.delegate = self
            toolbar.allowsUserCustomization = true
            toolbar.autosavesConfiguration = true
            
            win.toolbar = toolbar
            win.titleVisibility = .visible
            //win.toolbarStyle = .unified
            win.toolbarStyle = .expanded //classic macOS, left aligned toolbar
            
            //Hotkey Control+Space
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
    
    // MARK: - Menu Bar
    @objc func toggleFromMenu() {
        toggleWindow()
    }
    
    @objc func quitApp() {
        let text = UserDefaults.standard.string(forKey: "scrapText") ?? ""
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let alert = NSAlert()
            alert.messageText = "You have typed some words..."
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
    
    // MARK: - NSToolbarDelegate

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .saveToNotes, .decreaseFontSize, .increaseFontSize,
            .fontPicker, .clearText, .shareText,
            .flexibleSpace
        ]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        // Default order of the toolbar buttons (left to right)
        return [
            .saveToNotes, .clearText, .shareText,
            .decreaseFontSize, .increaseFontSize, .fontPicker,
            .flexibleSpace
        ]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)

        switch itemIdentifier {
        case .saveToNotes:
            item.label = "Save"
            item.image = NSImage(systemSymbolName: "paperplane", accessibilityDescription: nil)
            item.action = #selector(saveToNotes)
            
        case .increaseFontSize:
            item.label = "Larger"
            item.image = NSImage(systemSymbolName: "textformat.size.larger", accessibilityDescription: nil)
            item.action = #selector(increaseFontSize)

        case .decreaseFontSize:
            item.label = "Smaller"
            item.image = NSImage(systemSymbolName: "textformat.size.smaller", accessibilityDescription: nil)
            item.action = #selector(decreaseFontSize)

        case .clearText:
            item.label = "Clear"
            item.image = NSImage(systemSymbolName: "eraser.line.dashed", accessibilityDescription: nil)
            item.action = #selector(clearText)

        case .shareText:
            item.label = "Share"
            item.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: nil)
            item.action = #selector(shareText)

        case .fontPicker:
            let fontPopup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 160, height: 24), pullsDown: false)
            let fonts = NSFontManager.shared.availableFontFamilies.sorted()
            
            for fontName in fonts {
                let menuItem = NSMenuItem(title: fontName, action: nil, keyEquivalent: "")
                menuItem.representedObject = fontName
                fontPopup.menu?.addItem(menuItem)
            }
                
            fontPopup.target = self
            fontPopup.action = #selector(fontChanged(_:))
            item.view = fontPopup
            item.label = "Font"
            
            let savedFont = UserDefaults.standard.string(forKey: "selectedFontName")
            if let match = fontPopup.itemArray.first(where: { ($0.representedObject as? String) == savedFont }) {
                fontPopup.select(match)
            }
                
        default:
            return nil
        }

        item.target = self
        return item
    }

    //Call these buttons in AppDelegate
    @objc func saveToNotes() {
        ActionDispatcher.shared.saveToNotes?()
    }

    @objc func increaseFontSize() {
        ActionDispatcher.shared.increaseFontSize?()
    }

    @objc func decreaseFontSize() {
        ActionDispatcher.shared.decreaseFontSize?()
    }

    @objc func clearText() {
        ActionDispatcher.shared.clearText?()
    }

    @objc func shareText() {
        ActionDispatcher.shared.shareText?()
    }

    @objc func fontChanged(_ sender: NSPopUpButton) {
        if let fontName = sender.selectedItem?.representedObject as? String {
            UserDefaults.standard.set(fontName, forKey: "selectedFontName")
        }
    }
}
