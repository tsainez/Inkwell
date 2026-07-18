//
//  GlyphOutlineView.swift
//  Inkwell
//
//  Draws the reference glyph from the bundled stroke outlines, registered to
//  the exact coordinate space used for grading. Strokes already written are
//  inked solid, the rest are shown as a faint ghost, and a single stroke can be
//  highlighted as a hint (after repeated misses or via "Show stroke order").
//
//  When a stroke is newly completed it doesn't just fade in: an overlay sweeps
//  solid ink along the stroke's median (trim on the median polyline, masked to
//  the brush outline), so a correct stroke reads as ink flowing onto the paper.
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
        ZStack {
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

            // Ink-flow reveal for the stroke that just landed. `.id` restarts
            // the sweep for each newly completed stroke; once finished it sits
            // pixel-identical on top of the solid stroke underneath.
            if let index = inkFlowIndex {
                inkFlowOverlay(for: index)
                    .id(completedCount)
                    // No fade on insertion — the trim starting at 0 already hides
                    // it, and fading would dilute the sweep. Removal is instant
                    // and seamless: the solid stroke below is identical.
                    .transition(.identity)
            }
        }
        .frame(width: metrics.size, height: metrics.size)
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.3), value: completedCount)
        .animation(.easeInOut(duration: 0.2), value: highlightIndex)
    }

    /// The most recently completed stroke, if it should get the ink-flow
    /// reveal. Suppressed while that same stroke is being highlighted (the
    /// stroke-order demo would otherwise be hidden under the solid overlay).
    private var inkFlowIndex: Int? {
        let index = completedCount - 1
        guard index >= 0,
              index < strokeData.strokes.count,
              index < strokeData.medians.count,
              highlightIndex != index else { return nil }
        return index
    }

    private func inkFlowOverlay(for index: Int) -> some View {
        let median = strokeData.medians[index].map { metrics.canvasPoint($0) }
        let isSynthesized = strokeData.source == .synthesized
        let mask = SVGPath.path(from: strokeData.strokes[index]) { x, y in
            metrics.canvasPoint(rawX: x, rawY: y)
        }
        return StrokeInkFlow(
            median: median,
            mask: mask,
            // Wide enough to cover the fattest brush stroke; the mask keeps it
            // from ever bleeding outside the outline.
            sweepWidth: metrics.scale * 170,
            maskLineWidth: isSynthesized ? metrics.scale * 38 : nil,
            color: completedColor
        )
    }
}

/// Sweeps solid ink along a stroke: the median polyline is trimmed from 0 → 1
/// with a fat round-capped stroke, masked to the brush outline so only the
/// real stroke shape is revealed.
private struct StrokeInkFlow: View {
    let median: [CGPoint]
    let mask: Path
    let sweepWidth: CGFloat
    /// Non-nil for synthesized strokes, whose "outline" is the centerline
    /// stroked at this width (matching how the base canvas draws them).
    let maskLineWidth: CGFloat?
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    var body: some View {
        PolylineShape(points: median)
            .trim(from: 0, to: progress)
            .stroke(color, style: StrokeStyle(lineWidth: sweepWidth, lineCap: .round, lineJoin: .round))
            .mask { maskShape }
            .onAppear {
                if reduceMotion {
                    progress = 1
                } else {
                    withAnimation(.easeOut(duration: 0.3)) { progress = 1 }
                }
            }
    }

    @ViewBuilder
    private var maskShape: some View {
        if let maskLineWidth {
            FixedPath(path: mask)
                .stroke(style: StrokeStyle(lineWidth: maskLineWidth, lineCap: .round, lineJoin: .round))
        } else {
            FixedPath(path: mask)
        }
    }
}

/// A `Shape` wrapper around an already-transformed `Path` (our stroke paths
/// are pre-mapped into canvas space, so the rect is ignored).
private struct FixedPath: Shape {
    let path: Path
    func path(in rect: CGRect) -> Path { path }
}

/// Straight-segment polyline through the given (canvas-space) points.
private struct PolylineShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard let first = points.first else { return p }
        p.move(to: first)
        for point in points.dropFirst() {
            p.addLine(to: point)
        }
        return p
    }
}
