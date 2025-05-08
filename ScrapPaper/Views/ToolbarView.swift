//
//  ToolbarView.swift
//  ScrapPaper
//
//  Created by Long Fong Yee on 07/05/2025.
//


import SwiftUI

struct ToolbarView: View {
    let saveToNotes: () -> Void
    let increaseFontSize: () -> Void
    let decreaseFontSize: () -> Void
    let clearText: () -> Void
    let shareText: () -> Void
    
    @AppStorage("selectedFontName") private var selectedFontName = NSFont.systemFont(ofSize: 14).fontName
    let availableFonts = NSFontManager.shared.availableFontFamilies.sorted()
    
    var body: some View {
        HStack {
            Button(action: saveToNotes) {
                Image(systemName: "heart.text.clipboard")
            }
            
            Button(action: decreaseFontSize) {
                Image(systemName: "textformat.size.smaller")
            }
            
            Button(action: increaseFontSize) {
                Image(systemName: "textformat.size.larger")
            }
            
            Picker("", selection: $selectedFontName) {
                ForEach(availableFonts, id: \.self) { font in
                    Text(font).font(.custom(font, size: 12)).tag(font)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 160)
            
            Button(action: clearText) {
                Image(systemName: "eraser.line.dashed")
                    .help("Clear Text")
            }
            
            Spacer()
    
            Button(action: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .help("Share")
            }
                
        }
    }
}
