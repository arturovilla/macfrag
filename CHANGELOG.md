## 0.0.1 — 2026-04-24

First tagged snapshot of macfrag, the native macOS MSL playground.

### Added
- Split-pane main window: MSL source editor on the left, live Metal shader preview on the right (`ContentView.swift`).
- `MSLCodeEditor` built on `STTextView` with line numbers, current-line highlight, and smart-quotes / text-replacement / completion disabled (`MSLCodeEditor.swift`).
- Neon-based syntax highlighting via a custom `MacfragNeonTheme` (VS Code Dark+ inspired palette) wired through the C++ Tree-sitter grammar (`MacfragNeonTheme.swift`).
- Editor plugins: `MacfragTextDefaultsPlugin` (monospaced 13pt font, 1.15 line height, 28pt tab width) and `MacfragAppearancePlugin` for editor chrome (`MacfragTextDefaultsPlugin.swift`, `MacfragAppearancePlugin.swift`).
- Light/Dark adaptive color palette via `NSColor.dynamic(light:dark:)` (`MacfragNeonTheme.swift`).
- `MetalShaderPreview` Metal renderer: compiles MSL source on a background queue, builds a render pipeline from `vertex_main` + `fragment_main`, and draws a fullscreen triangle at 60 FPS with a `Uniforms { resolution, time }` buffer (`MetalShaderPreview.swift`).
- Debounced recompile (250 ms) on source change, with skip when the source is unchanged (`MetalShaderPreview.swift`).
- Build-log panel under the editor that surfaces Metal compiler errors and a friendly message when `vertex_main` or `fragment_main` is missing (`ContentView.swift`, `MetalShaderPreview.swift`).
- Default starter shader: a palette-driven FBM/noise pattern that exercises the full pipeline on first launch (`ContentView.swift`).
- File save support.

### Known issues
- Editor is rough around the edges.
- Build-log / debug pane is rough.
- Syntax highlighting only paints characters as they are typed, and only the affected characters — opening an existing file shows it unstyled until you edit it.
