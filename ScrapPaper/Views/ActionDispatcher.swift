//
//  ActionDispatcher.swift
//  ScrapPaper
//
//  Created by Long Fong Yee on 09/05/2025.
//


import Foundation

// Toolbar Action Dispatcher
final class ActionDispatcher {
    static let shared = ActionDispatcher()
    
    var saveToNotes: (() -> Void)?
    var increaseFontSize: (() -> Void)?
    var decreaseFontSize: (() -> Void)?
    var clearText: (() -> Void)?
    var shareText: (() -> Void)?
}
