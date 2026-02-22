//
//  MetalShaderPreview.swift
//  macfrag
//
//  Created by Arturo  Villalobos on 2/21/26.
//

import SwiftUI
import MetalKit
import QuartzCore

/// SwiftUI wrapper for a MetalKit MTKView that compiles MSL source from a string.
struct MetalShaderPreview: NSViewRepresentable {
    @Binding var source: String
    @Binding var log: String

    func makeCoordinator() -> Coordinator {
        Coordinator(log: $log)
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()

        guard let device = MTLCreateSystemDefaultDevice() else {
            context.coordinator.setLog("Metal is not supported on this Mac.")
            return view
        }

        view.device = device
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColorMake(0.08, 0.08, 0.09, 1.0)

        // Continuous redraw so u_time animates.
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false

        // Keep renderer alive (MTKView.delegate is weak).
        let renderer = Renderer(
            device: device,
            pixelFormat: view.colorPixelFormat,
            logHandler: { msg in
                DispatchQueue.main.async {
                    context.coordinator.log.wrappedValue = msg
                }
            }
        )

        context.coordinator.renderer = renderer
        view.delegate = renderer

        renderer.compile(source: source)
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.scheduleCompile(source: source)
    }

    final class Coordinator {
        var renderer: Renderer?
        var log: Binding<String>

        private var workItem: DispatchWorkItem?
        private var lastScheduledSource: String = ""

        init(log: Binding<String>) {
            self.log = log
        }

        func setLog(_ text: String) {
            log.wrappedValue = text
        }

        func scheduleCompile(source: String) {
            // Avoid recompiling when only the log/UI updates.
            guard source != lastScheduledSource else { return }
            lastScheduledSource = source

            workItem?.cancel()
            let item = DispatchWorkItem { [weak self] in
                self?.renderer?.compile(source: source)
            }
            workItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: item)
        }
    }
}

// MARK: - Renderer

final class Renderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pixelFormat: MTLPixelFormat
    private let logHandler: (String) -> Void

    private let compileQueue = DispatchQueue(label: "macfrag.msl.compile", qos: .userInitiated)

    private var pipelineState: MTLRenderPipelineState?

    private var startTime: CFTimeInterval = CACurrentMediaTime()

    init(device: MTLDevice, pixelFormat: MTLPixelFormat, logHandler: @escaping (String) -> Void) {
        self.device = device
        self.pixelFormat = pixelFormat
        self.logHandler = logHandler
        self.commandQueue = device.makeCommandQueue()!
        super.init()
    }

    func compile(source: String) {
        let src = source

        compileQueue.async { [weak self] in
            guard let self else { return }

            do {
                let options = MTLCompileOptions()
                let library = try self.device.makeLibrary(source: src, options: options)

                guard let vfn = library.makeFunction(name: "vertex_main") else {
                    throw ShaderError.missingFunction("vertex_main")
                }
                guard let ffn = library.makeFunction(name: "fragment_main") else {
                    throw ShaderError.missingFunction("fragment_main")
                }

                let desc = MTLRenderPipelineDescriptor()
                desc.vertexFunction = vfn
                desc.fragmentFunction = ffn
                desc.colorAttachments[0].pixelFormat = self.pixelFormat

                let pipeline = try self.device.makeRenderPipelineState(descriptor: desc)

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.pipelineState = pipeline
                    self.logHandler("") // clear log on success
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.logHandler(Self.pretty(error))
                }
            }
        }
    }

    // Required by MTKViewDelegate
    @MainActor
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // no-op for now
    }

    // Required by MTKViewDelegate
    @MainActor
    func draw(in view: MTKView) {
        guard let pipelineState else { return }
        guard let rpd = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else { return }

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else { return }

        encoder.setRenderPipelineState(pipelineState)

        var uniforms = Uniforms(
            resolution: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            time: Float(CACurrentMediaTime() - startTime),
            pad: 0
        )
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)

        // Fullscreen triangle (vertex shader uses vertex_id)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private static func pretty(_ error: Error) -> String {
        let ns = error as NSError
        var out = ns.localizedDescription
        if let reason = ns.localizedFailureReason, !reason.isEmpty, reason != out {
            out += "\n\n" + reason
        }
        out += "\n\n(\(ns.domain) \(ns.code))"
        return out
    }
}

enum ShaderError: LocalizedError {
    case missingFunction(String)

    var errorDescription: String? {
        switch self {
        case .missingFunction(let name):
            return """
            Missing required shader entry point: \(name)

            Your source must define BOTH:
              vertex   vertex_main(...)
              fragment fragment_main(...)
            """
        }
    }
}

/// Must match the struct you declare in MSL (including padding).
struct Uniforms {
    var resolution: SIMD2<Float> // float2
    var time: Float              // float
    var pad: Float               // padding to 16 bytes
}
