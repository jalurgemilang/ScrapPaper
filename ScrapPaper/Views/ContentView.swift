import SwiftUI
import SoulverCore
import AppKit

struct ContentView: View {
    @State private var text = ""
    @State private var textStorage = NSTextStorage()
    
    @AppStorage("fontSize") private var fontSize: Double = 14.0
    @AppStorage("selectedFontName") var selectedFontName: String = NSFont.systemFont(ofSize: 14).fontName
    
    @State private var showSaveSuccess = false
    
    var body: some View {
        ZStack{
            Color(NSColor.windowBackgroundColor).ignoresSafeArea() //background color, span whole window
            VStack {
                Text("9").font(.system(size: 6)).hidden()
                ToolbarView(
                    saveToNotes     : saveToNotes,
                    increaseFontSize: increaseFontSize,
                    decreaseFontSize: decreaseFontSize,
                    clearText       : clearText,
                    shareText       : shareText
                )
                .padding(.horizontal)
                TextView(text: $text,
                         fontName: selectedFontName,
                         textStorage: textStorage,
                         onEvaluateExpression: useSoulverCore,
                         fontSize: CGFloat(fontSize),
                         margins: NSSize(width: 14, height: 14))
                .frame(minWidth: 300, minHeight: 300)
                Text("9").font(.system(size: 6)).hidden()
            } //VStack
            
            // Success notification
            if showSaveSuccess {
                VStack {
                    Text("Saved to Notes!")
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            showSaveSuccess = false
                        }
                    }
                }
            }
        }
    }
    
    private func saveToNotes() {
        guard !text.isEmpty else { return }
        
        ShortcutManager.shared.runShortcut(name: "ScrapPaperToNotes", text: text) { success in
            if success {
                DispatchQueue.main.async {
                    withAnimation {
                        showSaveSuccess = true
                    }
                }
            }
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

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
