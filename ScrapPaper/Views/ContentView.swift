//
//  ContentView.swift
//  ScrapPaper
//
//  Created by Long Fong Yee on 06/05/2025.
//

import SwiftUI
import SoulverCore

struct ContentView: View {
    @State private var text = ""
    
    var body: some View {
        
        TextView(text: $text, onEvaluateExpression: evaluateExpression)
            .frame(minWidth: 300, minHeight: 300)
       
    }
    
    private func evaluateExpression() {
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
                // Append the result after "=="
                text += " → \(result.stringValue)"
                
                // The cursor position will be updated in the Coordinator
            }
        }
    }
}


#Preview {
    ContentView()
}
