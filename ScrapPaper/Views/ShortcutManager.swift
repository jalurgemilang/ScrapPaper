//
//  ShortcutManager.swift
//  ScrapPaper
//
//  Created by Long Fong Yee on 08/05/2025.
//


import Foundation
import AppKit

class ShortcutManager {
    static let shared = ShortcutManager()
    
    private init() {}
    
    /// Run a shortcut with a specified name and text input
    /// - Parameters:
    ///   - name: The name of the shortcut as it appears in the Shortcuts app
    ///   - text: The text to pass to the shortcut
    ///   - completion: Optional completion handler called when the shortcut is launched
    func runShortcut(name: String, text: String, completion: ((Bool) -> Void)? = nil) {
        // First try URL scheme method
        if !runShortcutWithURLScheme(name: name, text: text, completion: completion) {
            // If URL scheme fails, attempt direct NSAppleScript method
            runShortcutWithAppleScript(name: name, text: text, completion: completion)
        }
    }
    
    /// Run a shortcut using URL scheme (best method for sandboxed apps)
    /// - Returns: Boolean indicating if the URL could be constructed and opened
    private func runShortcutWithURLScheme(name: String, text: String, completion: ((Bool) -> Void)? = nil) -> Bool {
        guard let shortcutName = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            print("^ Error encoding shortcut name")
            completion?(false)
            return false
        }
                
        let encodedInput = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "shortcuts://run-shortcut?name=\(shortcutName)&input=text&text=\(encodedInput)"
        
        guard let shortcutURL = URL(string: urlString) else {
            print("^ Invalid URL")
            completion?(false)
            return false
        }
        
        let success = NSWorkspace.shared.open(shortcutURL)
        print(success ? "^ Successfully opened Shortcuts URL" : "^ Failed to open Shortcuts URL")
        completion?(success)
        
        return true
    }
    
    /// Run a shortcut using AppleScript (fallback method)
    private func runShortcutWithAppleScript(name: String, text: String, completion: ((Bool) -> Void)? = nil) {
        // First, ensure Shortcuts app is running
        let launchScript = """
        tell application "Shortcuts" to activate
        delay 0.5
        """
        
        let escapedText = text.replacingOccurrences(of: "\\", with: "\\\\")
                              .replacingOccurrences(of: "\"", with: "\\\"")
                              .replacingOccurrences(of: "\n", with: "\\n")
                              .replacingOccurrences(of: "\r", with: "\\r")
                              .replacingOccurrences(of: "\t", with: "\\t")
        
        let runShortcutScript = """
        tell application "Shortcuts"
            run shortcut "\(name)" with input "\(escapedText)"
        end tell
        """
        
        // First launch Shortcuts if needed
        if let launchScriptObj = NSAppleScript(source: launchScript) {
            var launchError: NSDictionary?
            launchScriptObj.executeAndReturnError(&launchError)
            
            if let error = launchError {
                print("^ Error launching Shortcuts app: \(error)")
                completion?(false)
                return
            }
            
            // Then run the shortcut
            if let scriptObj = NSAppleScript(source: runShortcutScript) {
                var error: NSDictionary?
                scriptObj.executeAndReturnError(&error)
                
                if let error = error {
                    print("^ Error running shortcut: \(error)")
                    completion?(false)
                } else {
                    print("^ Shortcut executed successfully")
                    completion?(true)
                }
            } else {
                completion?(false)
            }
        } else {
            completion?(false)
        }
    }
}
