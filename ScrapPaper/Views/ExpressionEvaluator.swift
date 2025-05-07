//
//  ExpressionEvaluator.swift
//  ScrapPaper
//
//  Created by Long Fong Yee on 07/05/2025.
//


import Foundation
import AppKit
import SoulverCore

struct ExpressionEvaluator {
    static func evaluate(
        text: String,
        textStorage: NSTextStorage,
        fontSize: Double,
        completion: @escaping (String) -> Void
    ) {
        // Find the current line the cursor is on
        let lines = text.components(separatedBy: .newlines)
        guard let lastLine = lines.last else { return }
        
        // Check if the line contains "==" and needs evaluation
        if lastLine.contains("==") {
            let calculator = Calculator(customization: {
                var c = EngineCustomization.standard
                c.featureFlags.variableDeclarations = true
                return c
            }())
            
            let result = calculator.calculate(lastLine)
            if !result.isEmptyResult {
                // Get the result text
                let resultText = " → \(result.stringValue)"
                
                // Create attributed string with blue color and current font size
                let attributedResult = NSAttributedString(
                    string: resultText,
                    attributes: [
                        .foregroundColor: NSColor.systemBlue,
                        .font: NSFont.systemFont(ofSize: CGFloat(fontSize))
                    ]
                )
                
                // Tell the coordinator we're adding an attributed result
                if let coordinator = textStorage.layoutManagers.first?.textContainers.first?.textView?.delegate as? TextView.Coordinator {
                    coordinator.isAddingAttributedResult = true
                }
                
                // Add to the text storage directly
                textStorage.beginEditing()
                textStorage.append(attributedResult)
                textStorage.endEditing()
                
                // Update the bound text property
                completion(textStorage.string)
                
                // Set flag to move cursor to end
                if let coordinator = textStorage.layoutManagers.first?.textContainers.first?.textView?.delegate as? TextView.Coordinator {
                    coordinator.shouldMoveCursorToEnd = true
                }
            }
        }
    }
}