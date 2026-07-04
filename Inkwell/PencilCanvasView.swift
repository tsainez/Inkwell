//
//  PencilCanvasView.swift
//  Inkwell
//

import SwiftUI
import PencilKit

struct PencilCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    var inkColor: UIColor = InkTheme.inkUI
    var strokeWidth: CGFloat = 16.0

    /// Called once each time the user finishes a stroke (lifts the pen), with
    /// the stroke's sampled points in the canvas's own coordinate space.
    var onStrokeFinished: (([CGPoint]) -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    /// `inkColor` resolved for the app's *actual* appearance. PencilKit must be
    /// given a plain (non-dynamic) color: it resolves dynamic colors against its
    /// own trait collection and additionally remaps stroke colors when the
    /// canvas is in Dark Mode, which left the pen at the light-mode near-black
    /// ink on the dark pad (black on black).
    private var resolvedInk: UIColor {
        let traits = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        return inkColor.resolvedColor(with: traits)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        // Pin the canvas to light so PencilKit never applies its own dark-mode
        // color inversion — appearance is handled entirely by `resolvedInk`.
        canvasView.overrideUserInterfaceStyle = .light
        canvasView.tool = PKInkingTool(.pen, color: resolvedInk, width: strokeWidth)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput // Supports Apple Pencil & finger touch
        canvasView.delegate = context.coordinator
        context.coordinator.lastResolvedInk = resolvedInk
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        context.coordinator.parent = self

        let resolved = resolvedInk
        uiView.tool = PKInkingTool(.pen, color: resolved, width: strokeWidth)

        // If the appearance flipped mid-character, re-ink the strokes already
        // on the canvas so earlier ink doesn't stay invisible on the new pad.
        guard context.coordinator.lastResolvedInk != resolved else { return }
        context.coordinator.lastResolvedInk = resolved
        guard !uiView.drawing.strokes.isEmpty else { return }
        var drawing = uiView.drawing
        for index in drawing.strokes.indices {
            drawing.strokes[index].ink = PKInk(.pen, color: resolved)
        }
        uiView.drawing = drawing
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvasView
        /// Last pen color handed to PencilKit, used to detect appearance flips.
        var lastResolvedInk: UIColor?
        /// Number of strokes present at the last change, so we only react when a
        /// new stroke is *added* (not when one is removed during a rejection or
        /// when the canvas is cleared).
        private var lastStrokeCount = 0

        init(_ parent: PencilCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let strokes = canvasView.drawing.strokes
            let count = strokes.count
            defer { lastStrokeCount = count }

            guard count > lastStrokeCount, let last = strokes.last else { return }
            parent.onStrokeFinished?(Coordinator.points(from: last))
        }

        /// Sample a finished PencilKit stroke into canvas-space points.
        static func points(from stroke: PKStroke) -> [CGPoint] {
            let transform = stroke.transform
            return stroke.path.map { $0.location.applying(transform) }
        }
    }
}
