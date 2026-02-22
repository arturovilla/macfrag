//
//  MacfragTextView.swift
//  macfrag
//
//  Created by Arturo  Villalobos on 2/22/26.
//

import SwiftUI
import STTextView
import STTextViewSwiftUICommon

struct MacfragTextView: NSViewRepresentable {
    @Binding var text: AttributedString

    let options: TextViewOptions
    let plugins: [any STPlugin]

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = STTextView.scrollableTextView()
        let tv = scrollView.documentView as! STTextView

        tv.textDelegate = context.coordinator
        applyOptions(options, to: tv)

        // Set initial content ONCE
        context.coordinator.isUpdating = true
        tv.attributedText = NSAttributedString(text)
        context.coordinator.isUpdating = false

        // Add plugins ONCE
        for plugin in plugins {
            tv.addPlugin(plugin)
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let tv = nsView.documentView as! STTextView
        applyOptions(options, to: tv)

        // Only push SwiftUI -> AppKit updates if the actual string differs.
        let newString = String(text.characters)
        let currentString = tv.attributedText?.string ?? ""

        if !context.coordinator.isUpdating && currentString != newString {
            context.coordinator.isUpdating = true
            tv.attributedText = NSAttributedString(text)
            context.coordinator.isUpdating = false
        }
    }

    private func applyOptions(_ options: TextViewOptions, to tv: STTextView) {
        tv.highlightSelectedLine = options.contains(.highlightSelectedLine)
        tv.showsLineNumbers = options.contains(.showLineNumbers)
        tv.isHorizontallyResizable = !options.contains(.wrapLines)

        if options.contains(.disableSmartQuotes) {
            tv.isAutomaticQuoteSubstitutionEnabled = false
        }
        if options.contains(.disableTextReplacement) {
            tv.isAutomaticTextReplacementEnabled = false
        }
        if options.contains(.disableTextCompletion) {
            tv.isAutomaticTextCompletionEnabled = false
        }
    }

    final class Coordinator: NSObject, STTextViewDelegate {
        @Binding var text: AttributedString
        var isUpdating = false

        init(text: Binding<AttributedString>) {
            _text = text
        }

        func textViewDidChangeText(_ notification: Notification) {
            guard !isUpdating, let tv = notification.object as? STTextView else { return }
            // Pull the document text back into SwiftUI state
            text = AttributedString(tv.attributedText ?? NSAttributedString())
        }
    }
}
