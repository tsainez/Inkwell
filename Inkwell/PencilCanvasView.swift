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

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: inkColor, width: strokeWidth)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput // Supports Apple Pencil & finger touch
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.tool = PKInkingTool(.pen, color: inkColor, width: strokeWidth)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvasView
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
