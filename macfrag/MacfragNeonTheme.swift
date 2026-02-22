//
//  MacfragNeonTheme.swift
//  macfrag
//
//  Created by Arturo  Villalobos on 2/22/26.
//

import AppKit
import STPluginNeon

// MARK: - Helpers

extension NSColor {
    static func hex(_ hex: UInt32, alpha: CGFloat = 1.0) -> NSColor {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        return NSColor(srgbRed: r, green: g, blue: b, alpha: alpha)
    }

    /// A dynamic color that adapts automatically when the user switches Light/Dark mode.
    static func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            let best = appearance.bestMatch(from: [.darkAqua, .aqua])
            return (best == .darkAqua) ? dark : light
        }
    }
}

// MARK: - Editor palette (UI + syntax)

enum MacfragPalette {
    // Editor UI colors
    static let editorBackground = NSColor.dynamic(
        light: .hex(0xFFFFFF),
        dark:  .hex(0x1E1E1E)
    )

    static let currentLine = NSColor.dynamic(
        light: .hex(0xF2F2F2),
        dark:  .hex(0x2A2D2E)
    )

    static let caret = NSColor.dynamic(
        light: .hex(0x111111),
        dark:  .hex(0xD4D4D4)
    )

    static let gutterText = NSColor.dynamic(
        light: .hex(0x6B7280),
        dark:  .hex(0x858585)
    )

    static let gutterSeparator = NSColor.dynamic(
        light: .hex(0xE5E7EB),
        dark:  .hex(0x3C3C3C)
    )

    // Syntax colors (VS Code Dark+ inspired)
    static let plain   = NSColor.dynamic(light: .hex(0x111111), dark: .hex(0xD4D4D4))
    static let comment = NSColor.dynamic(light: .hex(0x6A737D), dark: .hex(0x6A9955))
    static let keyword = NSColor.dynamic(light: .hex(0xAF00DB), dark: .hex(0x569CD6))
    static let type    = NSColor.dynamic(light: .hex(0x267F99), dark: .hex(0x4EC9B0))
    static let fnCall  = NSColor.dynamic(light: .hex(0x795E26), dark: .hex(0xDCDCAA))
    static let string  = NSColor.dynamic(light: .hex(0xA31515), dark: .hex(0xCE9178))
    static let number  = NSColor.dynamic(light: .hex(0x098658), dark: .hex(0xB5CEA8))
    static let variable = NSColor.dynamic(light: .hex(0x001080), dark: .hex(0x9CDCFE))
    static let builtin  = NSColor.dynamic(light: .hex(0x0070C1), dark: .hex(0x4FC1FF))
}

// MARK: - Neon Theme

extension Theme {
    /// Your custom theme. Pass this into `NeonPlugin(theme:language:)`.
    ///
    /// Note: we provide NO per-token fonts here to avoid font-size mismatches;
    /// everything will use whatever `.textViewFont(...)` you set in SwiftUI.
    static let macfrag = Theme(
        colors: .init(colors: [
            "plain": MacfragPalette.plain,
            "boolean": MacfragPalette.keyword,
            "comment": MacfragPalette.comment,
            "constructor": MacfragPalette.type,
            "function.call": MacfragPalette.fnCall,
            "include": MacfragPalette.keyword,
            "keyword": MacfragPalette.keyword,
            "keyword.function": MacfragPalette.keyword,
            "keyword.return": MacfragPalette.keyword,
            "method": MacfragPalette.fnCall,
            "number": MacfragPalette.number,
            "operator": MacfragPalette.plain,
            "parameter": MacfragPalette.variable,
            "punctuation.special": MacfragPalette.plain,
            "string": MacfragPalette.string,
            "text.literal": MacfragPalette.string,
            "text.title": MacfragPalette.fnCall,
            "type": MacfragPalette.type,
            "variable.builtin": MacfragPalette.builtin,
            "variable": MacfragPalette.variable
        ]),
        fonts: .init(fonts: [:]) // <-- IMPORTANT: avoid 12pt overrides from the plugin default fonts
    )
}
