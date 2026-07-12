//
//  GlyphOutlineView.swift
//  Inkwell
//
//  Draws the reference glyph from the bundled stroke outlines, registered to
//  the exact coordinate space used for grading. Strokes already written are
//  inked solid, the rest are shown as a faint ghost, and a single stroke can be
//  highlighted as a hint (after repeated misses or via "Show stroke order").
//

import SwiftUI

struct GlyphOutlineView: View {
    let strokeData: CharacterStrokeData
    let metrics: GlyphMetrics

    /// Number of leading strokes already completed (drawn solid).
    var completedCount: Int = 0
    /// A stroke to emphasize as a hint, if any.
    var highlightIndex: Int? = nil

    var ghostColor: Color = InkTheme.glyphGhost
    var completedColor: Color = InkTheme.ink.opacity(0.85)
    var highlightColor: Color = InkTheme.accent

    var body: some View {
        Canvas { context, _ in
            let isSynthesized = strokeData.source == .synthesized
            // Synthesized strokes are open-path centerlines; use a thick stroke
            // so they read clearly even though they lack filled brush outlines.
            let strokeWidth: CGFloat = isSynthesized ? metrics.scale * 38 : 0

            for (i, definition) in strokeData.strokes.enumerated() {
                let path = SVGPath.path(from: definition) { x, y in
                    metrics.canvasPoint(rawX: x, rawY: y)
                }

                let color: Color
                if highlightIndex == i {
                    color = highlightColor
                } else if i < completedCount {
                    color = completedColor
                } else {
                    color = ghostColor
                }

                if isSynthesized {
                    context.stroke(path,
                                   with: .color(color),
                                   style: StrokeStyle(lineWidth: strokeWidth,
                                                      lineCap: .round,
                                                      lineJoin: .round))
                } else {
                    context.fill(path, with: .color(color))
                }
            }
        }
        .frame(width: metrics.size, height: metrics.size)
        .allowsHitTesting(false)
        // TODO(animation): instead of fading completed strokes in, animate each one
        // filling along its median path (trim(from:to:) on the median, masked to the
        // outline) so correct strokes feel like brush ink flowing.
        .animation(.easeInOut(duration: 0.2), value: completedCount)
        .animation(.easeInOut(duration: 0.2), value: highlightIndex)
    }
}
