//
//  ToolbarView.swift
//  ScrapPaper
//
//  Created by Long Fong Yee on 07/05/2025.
//


import SwiftUI

struct ToolbarView: View {
    let increaseFontSize: () -> Void
    let decreaseFontSize: () -> Void
    let shareText: () -> Void
    
    var body: some View {
        HStack {
            Button(action: decreaseFontSize) {
                Image(systemName: "textformat.size.smaller")
            }
            
            Button(action: increaseFontSize) {
                Image(systemName: "textformat.size.larger")
            }
            
            Spacer()
            
            Button(action: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .help("Share and Clear Text")
            }
        }
    }
}