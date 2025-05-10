//
//  ExpressionEvaluator.swift
//  ScrapPaper
//
//  Created by Long Fong Yee on 07/05/2025.
//
//  This is to run SoulverCore
//

import Foundation
import AppKit
import SoulverCore

struct ExpressionEvaluator {
    
    static func evaluate(
        text: String,
        textStorage: NSTextStorage,
        fontName: String,
        fontSize: Double,
        moveCursorToEnd: Bool,
        completion: @escaping (String) -> Void
    ) {
        let baseFont = NSFont(name: fontName, size: CGFloat(fontSize)) ?? NSFont.systemFont(ofSize: CGFloat(fontSize))
        let lines = text.components(separatedBy: .newlines)
        
        let newStorage = NSTextStorage()
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let attributedLine = NSMutableAttributedString(
                string: line,
                attributes: [
                    .foregroundColor: NSColor.labelColor,
                    .font: baseFont
                ]
            )
            
            let hiddenMarker = "\u{2063}"                   // Invisible Separator
            let customColor  = NSColor(named: "CustomResultColor")
            //define SoulverCore class and Calculator object
            let calculator = Calculator(customization: {
                var c = EngineCustomization.standard        //default SoulverCore Engine Customization
                c.featureFlags.variableDeclarations = true  //enable variable declaration, usage: meal=$2
                return c
            }())
            
            //this is where SoulverCore starts to work its magic
            if trimmed.contains("==") && !trimmed.contains("\(hiddenMarker)") {
                let result = calculator.calculate(trimmed)
                if !result.isEmptyResult {
                    let resultText = "\(hiddenMarker)\(result.stringValue)"
                    let attributedResult = NSAttributedString(
                        string: resultText,
                        attributes: [
                            .font: baseFont,
                            .foregroundColor: customColor!
                        ]
                    )
                    attributedLine.append(attributedResult)
                }
            //just change the color to blue if result exist, no need to reevaluate
            } else if let range = trimmed.range(of: "\(hiddenMarker).*?$", options: .regularExpression) {
                let beforeResult = String(trimmed[..<range.lowerBound])
                let resultPart = String(trimmed[range.lowerBound...])
                
                let attributed = NSMutableAttributedString()
                attributed.append(NSAttributedString(string: beforeResult, attributes: [
                    .font: baseFont,
                    .foregroundColor: NSColor.labelColor
                ]))
                attributed.append(NSAttributedString(string: resultPart, attributes: [
                    .font: baseFont,
                    .foregroundColor: customColor!
                ]))
                
                attributedLine.setAttributedString(attributed) // Replace, not append
            }
            
            
            if !line.isEmpty {
                attributedLine.append(NSAttributedString(string: "\n"))
            }
            
            newStorage.append(attributedLine)
            
        }
        
        textStorage.beginEditing()
        textStorage.setAttributedString(newStorage)
        textStorage.endEditing()
        
        completion(textStorage.string)
        
        if moveCursorToEnd,
           let coordinator = textStorage.layoutManagers.first?.textContainers.first?.textView?.delegate as? TextView.Coordinator {
            coordinator.shouldMoveCursorToEnd = true
        }
    }
}
