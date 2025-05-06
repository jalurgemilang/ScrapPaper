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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
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
            textView.string = text
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        weak var textView: NSTextView?
        
        init(text: Binding<String>) {
            _text = text
        }
        
        func textDidChange(_ notification: Notification) {
            guard let updated = textView?.string else { return }
            text = updated
        }
    }
}
