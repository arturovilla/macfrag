# macfrag — User Guide

macfrag is a native macOS playground for writing Metal Shading Language (MSL) fragment shaders and seeing them render live.

## Requirements

- macOS with Metal support
- Xcode (to build from source)

## Launching

Open `macfrag.xcodeproj` in Xcode and run the `macfrag` scheme. The window opens with two panes:

- **Left** — the MSL source editor, pre-loaded with a starter shader (a palette-driven FBM noise pattern).
- **Right** — the live Metal preview, rendered at 60 FPS.

If the shader compiles, the preview animates immediately. If it fails, a build-log panel appears under the editor with the error.

## The editor

- Syntax highlighting uses a VS Code Dark+ style palette and adapts to Light/Dark mode.
- Line numbers, current-line highlight, and a 28pt tab stop are on by default.
- Smart quotes, text replacement, and autocomplete are disabled — what you type is what the compiler sees.

> Caveat (0.0.1): highlighting only paints characters as you type them. Pasting or reopening a file shows the text unstyled until you edit it.

## Writing a shader

Your source must define both entry points the renderer looks for:

```metal
vertex   Varyings  vertex_main(uint vid [[vertex_id]]) { ... }
fragment float4    fragment_main(Varyings in [[stage_in]],
                                 constant Uniforms& u [[buffer(0)]]) { ... }
```

The renderer draws a fullscreen triangle (3 vertices, no vertex buffer), so `vertex_main` should derive its position from `[[vertex_id]]`. The fragment shader receives a `Uniforms` struct in buffer 0:

```metal
struct Uniforms {
    float2 resolution; // drawable size in pixels
    float  time;       // seconds since the renderer started
    float  pad;        // padding to 16 bytes — keep it
};
```

The starter shader in `ContentView.swift` is a complete working example.

## The preview

- Continuous 60 FPS redraw — `time` advances monotonically from when the view was created.
- Clear color is a near-black `(0.08, 0.08, 0.09, 1.0)`; visible only if your fragment shader doesn't cover the whole frame.
- The drawable's pixel format is `bgra8Unorm`.

## Recompilation

Edits trigger a recompile after a 250 ms debounce. Identical source is skipped, so cosmetic UI updates won't kick off a rebuild.

- On success: the build-log panel disappears.
- On failure: the panel shows the Metal compiler's message, the failure reason if present, and a `(domain code)` suffix. If `vertex_main` or `fragment_main` isn't defined, you'll get an explicit "Missing required shader entry point" message instead.

## Saving

File save is supported in this build. (The save UX is minimal in 0.0.1 — see CHANGELOG.)

## Troubleshooting

- **"Metal is not supported on this Mac."** — your hardware/OS doesn't expose a Metal device. macfrag won't render here.
- **Black preview, no errors** — your fragment shader probably returns `float4(0,0,0,1)` for all pixels, or doesn't write to the color attachment. Try `return float4(in.uv, 0.0, 1.0);` to verify the pipeline.
- **"Missing required shader entry point: …"** — rename your entry function to `vertex_main` or `fragment_main`. The renderer looks them up by name.
- **Highlighting looks wrong on a freshly opened file** — known issue in 0.0.1. Type a character to repaint.

## Project layout

- `macfrag/macfragApp.swift` — app entry point
- `macfrag/ContentView.swift` — split-pane root view, ships the default MSL shader
- `macfrag/MSLCodeEditor.swift` — MSL source editor
- `macfrag/MetalShaderPreview.swift` — live Metal compile + render
- `macfrag/MacfragNeonTheme.swift` — neon syntax highlighting theme
- `macfrag/MacfragAppearancePlugin.swift`, `MacfragTextDefaultsPlugin.swift` — editor plugins
- `macfrag/MacfragTextView.swift` — underlying text view
- `macfragTests/`, `macfragUITests/` — test targets
