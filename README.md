# macfrag

A native macOS Metal Shading Language (MSL) playground/editor, written in Swift/SwiftUI.

It's a split-pane app: an MSL code editor on the left (with neon syntax highlighting via the `MacfragNeonTheme`/`MacfragTextDefaultsPlugin`/`MacfragAppearancePlugin` plugins on `MSLCodeEditor.swift`) and a live Metal shader preview on the right (`MetalShaderPreview.swift`) that compiles the source and renders the fragment shader, with a build log panel underneath the editor.

## Status

Early/work-in-progress:

- Editor is rough.
- Debug/build-log pane is rough.
- File save works.
- Syntax highlighting only paints characters as you type (and only the affected characters).

## Requirements

- macOS with Metal support
- Xcode

## Build & run

Open `macfrag.xcodeproj` in Xcode and run the `macfrag` scheme.

## Project layout

- `macfrag/macfragApp.swift` — app entry point
- `macfrag/ContentView.swift` — split-pane root view, ships a default MSL fragment shader
- `macfrag/MSLCodeEditor.swift` — MSL source editor
- `macfrag/MetalShaderPreview.swift` — live Metal compile + render preview
- `macfrag/MacfragNeonTheme.swift` — neon syntax highlighting theme
- `macfrag/MacfragAppearancePlugin.swift`, `MacfragTextDefaultsPlugin.swift` — editor plugins
- `macfrag/MacfragTextView.swift` — underlying text view
- `macfragTests/`, `macfragUITests/` — test targets
