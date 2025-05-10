import SwiftUI
import AppKit

struct TextView: NSViewRepresentable {
    @Binding var text: String
    var fontName: String
    var textStorage: NSTextStorage
    var onEvaluateExpression: () -> Void
    var fontSize: CGFloat = NSFont.systemFontSize       // Add font size parameter with default value
    var margins: NSSize = NSSize(width: 10, height: 10) // Add margin
    
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
        //textView.translatesAutoresizingMaskIntoConstraints = false //remove this to mouse click, drag & highlight
        textView.isEditable                 = true
        textView.isSelectable               = true
        textView.isRichText                 = false
        textView.allowsUndo                 = true
        textView.font                       = NSFont(name: fontName, size: fontSize) ?? .systemFont(ofSize: fontSize)
        textView.textColor                  = .labelColor
        textView.backgroundColor            = .textBackgroundColor
        textView.drawsBackground            = false     //set false if using image as background
        textView.isVerticallyResizable      = true      //true  = this enable wordwrap?
        textView.isHorizontallyResizable    = false     //false = this enable wordwrap; also needed for mouse click, drag & highlight
        textView.autoresizingMask           = [.width]  //needed for mouse click, drag & highlight
        textView.importsGraphics            = false     //prevents NSTextView from expecting drag and drop images in rich text mode
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude) //allows scrolling beyond bottom window
        textView.delegate = context.coordinator
        
        // Apply text margins
        textView.textContainerInset = margins
                
        textView.becomeFirstResponder()
        
        // Embed in scroll view
        let scrollView                      = NSScrollView()
        scrollView.backgroundColor          = NSColor(named: "CustomWindowBackground")!
        scrollView.drawsBackground          = true      //set false if using image as background
        scrollView.hasVerticalScroller      = true
        scrollView.hasHorizontalScroller    = false
        scrollView.autohidesScrollers       = true
        scrollView.borderType               = .noBorder
        scrollView.autoresizingMask         = [.width, .height]
        scrollView.contentView.postsBoundsChangedNotifications = true
        
        // Configures how NSTextView handles word wrap and resizing
        if let container = textView.textContainer {
            container.widthTracksTextView = true
            container.lineBreakMode = .byWordWrapping
            container.containerSize = NSSize(width: scrollView.contentSize.width,
                                             height: CGFloat.greatestFiniteMagnitude) //allows scrolling beyond bottom window
        }
        
        context.coordinator.textView = textView
        
        // Make it focused to accept typing
        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }
        

        
        // FINALE:
        scrollView.documentView = textView
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // Prevent updates if the user is actively editing
        if context.coordinator.isUpdatingFromTextView {
            return
        }
        
        // I am using attributed strings so, I have to set the color to the attributed string
        // to adapt to Light or Dark Appearance. It will not work if I set it in makeNSView
        let font = NSFont(name: fontName, size: fontSize) ?? .systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ]
       
        // Update typing attributes (used for new text the user types)
        textView.typingAttributes[.font] = font
        textView.typingAttributes[.foregroundColor] = NSColor.labelColor
        
        // Update font on the existing attributed text without touching colors
        if let storage = textView.textStorage {
            storage.beginEditing()
            
            storage.enumerateAttributes(in: NSRange(location: 0, length: storage.length)) { attrs, range, _ in
                // Only update the font if it exists (to avoid affecting SoulverCore's attributed results)
                if let _ = attrs[.font] {
                    var updated = attrs
                    updated[.font] = font
                    storage.setAttributes(updated, range: range)
                }
            }            
            storage.endEditing()
        }
        
        // Update inset if needed
        if textView.textContainerInset != margins {
            textView.textContainerInset = margins
        }
        
        // Update plain text only if needed (e.g. external edit)
        if textView.string != text {
            context.coordinator.isUpdatingFromTextView = true
            textView.string = text
            context.coordinator.isUpdatingFromTextView = false
        }
        
        if textView.textContainerInset != margins {
            textView.textContainerInset = margins
        }
        
        // Only replace text if it changed (preserves cursor, user edits)
        if textView.string != text {
            context.coordinator.isUpdatingFromTextView = true
            textView.string = text
            context.coordinator.isUpdatingFromTextView = false
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
            
            // Delay the reset of the flag to ensure any SwiftUI updates complete
            DispatchQueue.main.async {
                self.isUpdatingFromTextView = false
            }
            
            // ✅ Scroll to caret if needed
            textView.scrollRangeToVisible(textView.selectedRange())
            
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
