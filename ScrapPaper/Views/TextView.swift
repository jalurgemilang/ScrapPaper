//
//  TextView.swift
//  ScrapPaper
//
//  Created by Long Fong Yee on 06/05/2025.
//


import SwiftUI
import AppKit

struct TextView: NSViewRepresentable {
    @Binding var text: String
    var onEvaluateExpression: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onEvaluateExpression: onEvaluateExpression)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        // Create NSTextView inside NSScrollView
        let textView = NSTextView(frame: .zero)
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.font = .systemFont(ofSize: 14)
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
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            
            // If this update was triggered by our equals evaluation, move cursor to end
            if context.coordinator.shouldMoveCursorToEnd {
                textView.setSelectedRange(NSRange(location: text.count, length: 0))
                context.coordinator.shouldMoveCursorToEnd = false
            } else if selectedRange.location <= text.count {
                textView.setSelectedRange(selectedRange)
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
        let onEvaluateExpression: () -> Void
        weak var textView: NSTextView?
        var eventMonitor: Any?
        var shouldMoveCursorToEnd = false
        
        init(text: Binding<String>, onEvaluateExpression: @escaping () -> Void) {
            _text = text
            self.onEvaluateExpression = onEvaluateExpression
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
            
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
