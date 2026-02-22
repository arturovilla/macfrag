//
//  MSLCodeEditor.swift
//  macfrag
//
//  Created by Arturo  Villalobos on 2/22/26.
//

import SwiftUI
import AppKit

import STTextViewSwiftUI
import STTextViewSwiftUICommon

import STPluginNeon
import TreeSitterResource

struct MSLCodeEditor: View {
    @Binding var text: AttributedString

    private static let editorFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    private let opts: TextViewOptions = [
        .highlightSelectedLine,
        .showLineNumbers,
        .disableSmartQuotes,
        .disableTextReplacement,
        .disableTextCompletion
    ]

    var body: some View {
            MacfragTextView(
                text: $text,
                options: opts,
                plugins: [
                    MacfragTextDefaultsPlugin(font: Self.editorFont, lineHeightMultiple: 1.15, tabWidth: 28),
                    MacfragAppearancePlugin(),
                    NeonPlugin(theme: .macfrag, language: .cpp)
                ]
            )
        }
}
