import SwiftUI
import AppKit

struct TextView: NSViewRepresentable {
    @Binding var text: String
    var textStorage: NSTextStorage
    var onEvaluateExpression: () -> Void
    var fontSize: CGFloat = NSFont.systemFontSize  // Add font size parameter with default value
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, textStorage: textStorage, onEvaluateExpression: onEvaluateExpression)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        // Create text container and layout manager for attributed text
        let textContainer = NSTextContainer()
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Create NSTextView inside NSScrollView with our text system
        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true  // Enable rich text to support colors
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: fontSize)  // Use the provided font size
        textView.delegate = context.coordinator
        textView.backgroundColor = .textBackgroundColor
        textView.autoresizingMask = [.width]
        
        // Monitor key events
        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 36 && event.modifierFlags.contains(.shift) { // Enter with Shift (==)
                context.coordinator.processEqualsPressed()
                return nil
            }
            return event
        }
        context.coordinator.eventMonitor = monitor
        
        // Wrap in scroll view
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .bezelBorder
        scrollView.autoresizingMask = [.width, .height]
        scrollView.contentView.postsBoundsChangedNotifications = true
        
        context.coordinator.textView = textView
        
        // Make it focused to accept typing
        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // Update font size if it has changed
        if textView.font?.pointSize != fontSize {
            textView.font = NSFont.systemFont(ofSize: fontSize)
        }
        
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            
            // Only update if the text actually changed to avoid losing formatting
            if textView.string != text {
                // Preserve attributed text where possible
                if context.coordinator.isUpdatingFromTextView == false && !context.coordinator.isAddingAttributedResult {
                    // Only replace content if we're not in the middle of adding a result
                    textStorage.beginEditing()
                    textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: text)
                    textStorage.endEditing()
                }
                
                // If this update was triggered by our equals evaluation, move cursor to end
                if context.coordinator.shouldMoveCursorToEnd {
                    textView.setSelectedRange(NSRange(location: text.count, length: 0))
                    context.coordinator.shouldMoveCursorToEnd = false
                } else if selectedRange.location <= text.count {
                    textView.setSelectedRange(selectedRange)
                }
                
                context.coordinator.isAddingAttributedResult = false
            }
        }
    }
    
    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        if let monitor = coordinator.eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        var textStorage: NSTextStorage
        let onEvaluateExpression: () -> Void
        weak var textView: NSTextView?
        var eventMonitor: Any?
        var shouldMoveCursorToEnd = false
        var isUpdatingFromTextView = false
        var isAddingAttributedResult = false
        
        init(text: Binding<String>, textStorage: NSTextStorage, onEvaluateExpression: @escaping () -> Void) {
            _text = text
            self.textStorage = textStorage
            self.onEvaluateExpression = onEvaluateExpression
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Set flag to prevent circular updates
            isUpdatingFromTextView = true
            text = textView.string
            isUpdatingFromTextView = false
            
            // Check if the user just typed "=="
            if let selectedRange = textView.selectedRanges.first as? NSRange,
               selectedRange.location >= 2,
               textView.string.count >= 2 {
                let location = selectedRange.location
                let startIndex = textView.string.index(textView.string.startIndex, offsetBy: location - 2)
                let endIndex = textView.string.index(textView.string.startIndex, offsetBy: location)
                let lastTwoChars = String(textView.string[startIndex..<endIndex])
                
                if lastTwoChars == "==" {
                    processEqualsPressed()
                }
            }
        }
        
        func processEqualsPressed() {
            let originalLength = text.count
            onEvaluateExpression()
            
            // If text length changed, we inserted a result and should move cursor to end
            if text.count > originalLength {
                shouldMoveCursorToEnd = true
            }
        }
    }
}
