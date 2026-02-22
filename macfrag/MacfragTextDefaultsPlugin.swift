//
//  MacfragTextDefaultsPlugin.swift
//  macfrag
//
//  Created by Arturo  Villalobos on 2/22/26.
//

import AppKit
import STTextView

struct MacfragTextDefaultsPlugin: STPlugin {
    let font: NSFont
    let lineHeightMultiple: CGFloat
    let tabWidth: CGFloat

    init(
        font: NSFont = .monospacedSystemFont(ofSize: 13, weight: .regular),
        lineHeightMultiple: CGFloat = 1.15,
        tabWidth: CGFloat = 28
    ) {
        self.font = font
        self.lineHeightMultiple = lineHeightMultiple
        self.tabWidth = tabWidth
    }

    func setUp(context: any Context) {
        let tv = context.textView

        // ✅ Public API (this also applies the font to the document)
        tv.font = font

        // Keep gutter matching (if line numbers are enabled)
        tv.gutterView?.font = font

        // ✅ Public API: default paragraph style used for missing attrs / new typing
        let paragraph = (NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle)
        paragraph.lineHeightMultiple = lineHeightMultiple
        paragraph.defaultTabInterval = tabWidth
        tv.defaultParagraphStyle = paragraph

        // Important: clear derived typing attrs so the new defaults take effect
        tv.resetTypingAttributes()
    }
}
