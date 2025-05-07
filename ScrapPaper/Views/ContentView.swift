import SwiftUI
import SoulverCore
import AppKit

struct ContentView: View {
    @State private var text = ""
    @State private var textStorage = NSTextStorage()
    @AppStorage("fontSize") private var fontSize: Double = 14.0
    
    var body: some View {
        VStack {
            ToolbarView(
                increaseFontSize: increaseFontSize,
                decreaseFontSize: decreaseFontSize,
                shareText: shareText
            )
            .padding(.horizontal)
            
            TextView(text: $text,
                    textStorage: textStorage,
                    onEvaluateExpression: useSoulverCore,
                    fontSize: CGFloat(fontSize))
                .frame(minWidth: 300, minHeight: 300)
        }
    }
    
    private func increaseFontSize() {
        fontSize = min(fontSize + 2, 36)
    }
    
    private func decreaseFontSize() {
        fontSize = max(fontSize - 2, 10)
    }
    
    private func shareText() {
        SharingManager.shared.shareText(
            from: textStorage,
            withFontSize: fontSize,
            onSuccess: clearText
        )
    }
    
    private func clearText() {
        // Clear the text and text storage
        text = ""
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: "")
        textStorage.endEditing()
    }
    
    private func useSoulverCore() {
        ExpressionEvaluator.evaluate(
            text: text,
            textStorage: textStorage,
            fontSize: fontSize
        ) { newText in
            self.text = newText
        }
    }
}
