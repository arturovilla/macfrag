//
//  MacfragAppearancePlugin.swift
//  macfrag
//
//  Created by Arturo  Villalobos on 2/22/26.
//

import AppKit
import STTextView

struct MacfragAppearancePlugin: STPlugin {

    func setUp(context: any Context) {
        let tv = context.textView

        // UI chrome (safe)
        tv.backgroundColor = MacfragPalette.editorBackground
        tv.insertionPointColor = MacfragPalette.caret
        tv.selectedLineHighlightColor = MacfragPalette.currentLine

        // IMPORTANT:
        // Do NOT set tv.textColor here.
        // In STTextView, setting textColor applies a foregroundColor attribute
        // to the entire document, which will wipe syntax highlighting.  [oai_citation:3‡GitHub](https://raw.githubusercontent.com/krzyzanowskim/STTextView/2.3.5/Sources/STTextViewAppKit/STTextView.swift)

        if let gutter = tv.gutterView {
            gutter.textColor = MacfragPalette.gutterText
            gutter.separatorColor = MacfragPalette.gutterSeparator
            gutter.selectedLineHighlightColor = MacfragPalette.currentLine
            gutter.selectedLineTextColor = MacfragPalette.gutterText
//            gutter.backgroundColor = MacfragPalette.editorBackground
        }

        if let scroll = tv.enclosingScrollView {
            scroll.drawsBackground = true
            scroll.backgroundColor = MacfragPalette.editorBackground
        }

        tv.needsDisplay = true
    }

    func makeCoordinator(context: CoordinatorContext) -> Coordinator { Coordinator() }
    final class Coordinator {}
}
