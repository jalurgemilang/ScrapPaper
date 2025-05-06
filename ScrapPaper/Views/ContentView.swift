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
        ZStack(alignment: .topLeading) {
            TextView(text: $text)
                .frame(minWidth: 500, minHeight: 400)
            
            // Live evaluation overlay
            VStack(alignment: .leading, spacing: 4) {
                ForEach(evaluatedLines(from: text), id: \.self) { result in
                    if let result = result {
                        Text(result)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    } else {
                        Text("") // maintain spacing
                    }
                }
            }
            .padding(8)
            .allowsHitTesting(false)
        }
        .padding()
    }
    
    func evaluatedLines(from input: String) -> [String?] {
        let lines = input.components(separatedBy: .newlines)
        let calculator = Calculator(customization: {
            var c = EngineCustomization.standard
            c.featureFlags.variableDeclarations = true
            return c
        }())
        
        return lines.map { line in
            guard line.contains("==") else { return nil }
            let result = calculator.calculate(line)
            return result.isEmptyResult ? nil : "→ \(result.stringValue)"
        }
    }
}

#Preview {
    ContentView()
}
