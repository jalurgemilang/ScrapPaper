import SwiftUI
import SoulverCore

struct ContentView: View {
    @State private var text = ""
    @State private var textStorage = NSTextStorage()
    
    var body: some View {
        TextView(text: $text,
                textStorage: textStorage,
                onEvaluateExpression: useSoulverCore)
            .frame(minWidth: 300, minHeight: 300)
    }
    
    private func useSoulverCore() {
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
                
                // Create attributed string with blue color
                let attributedResult = NSAttributedString(
                    string: resultText,
                    attributes: [.foregroundColor: NSColor.systemBlue]
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
                text = textStorage.string
                
                // Set flag to move cursor to end
                if let coordinator = textStorage.layoutManagers.first?.textContainers.first?.textView?.delegate as? TextView.Coordinator {
                    coordinator.shouldMoveCursorToEnd = true
                }
            }
        }
    }
}
