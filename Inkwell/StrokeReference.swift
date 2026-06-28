//
//  StrokeReference.swift
//  Inkwell
//
//  Loads the bundled offline stroke data (StrokeData.json) and provides the
//  coordinate mapping between the 1024×1024 glyph-box space of that data and
//  the on-screen practice canvas, plus an SVG path parser used to draw the
//  reference glyph outline.
//
//  Stroke data is derived from the Make Me a Hanzi / hanzi-writer-data project
//  (graphics under the Arphic Public License). See StrokeData-ATTRIBUTION.txt.
//

import CoreGraphics
import Foundation
import SwiftUI

/// In-memory store of reference stroke data, keyed by glyph.
final class StrokeReference {
    static let shared = StrokeReference()

    private(set) var byGlyph: [String: CharacterStrokeData] = [:]

    private init() {
        load()
    }

    func data(for glyph: String) -> CharacterStrokeData? {
        byGlyph[glyph]
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "StrokeData", withExtension: "json") else {
            assertionFailure("StrokeData.json missing from app bundle")
            return
        }
        do {
            let raw = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([CharacterStrokeData].self, from: raw)
            byGlyph = Dictionary(uniqueKeysWithValues: items.map { ($0.glyph, $0) })
        } catch {
            assertionFailure("Failed to decode StrokeData.json: \(error)")
        }
    }
}

/// Maps the raw Make Me a Hanzi coordinate system to an on-screen square canvas
/// of side `size`, and back. The source data uses a 1024-unit em with the
/// y-axis pointing up from a baseline at y = 900, so the vertical axis is
/// flipped when converting to screen space.
struct GlyphMetrics: Equatable {
    /// Side length of the (square) drawing canvas, in points.
    let size: CGFloat
    /// Margin between the glyph and the canvas edge, in points.
    let inset: CGFloat

    /// Em size of the source coordinate system.
    static let em: CGFloat = 1024
    /// Baseline offset applied by the source data's `scale(1,-1) translate(0,-900)`.
    static let baseline: CGFloat = 900

    var scale: CGFloat { (size - inset * 2) / GlyphMetrics.em }

    /// Raw stroke-data coordinate → on-screen canvas point.
    func canvasPoint(rawX x: CGFloat, rawY y: CGFloat) -> CGPoint {
        CGPoint(x: inset + x * scale,
                y: inset + (GlyphMetrics.baseline - y) * scale)
    }

    func canvasPoint(_ p: StrokePoint) -> CGPoint {
        canvasPoint(rawX: CGFloat(p.x), rawY: CGFloat(p.y))
    }

    /// Reference median point → grading "box" space (y flipped, no canvas scale).
    func boxPoint(_ p: StrokePoint) -> CGPoint {
        CGPoint(x: CGFloat(p.x), y: GlyphMetrics.baseline - CGFloat(p.y))
    }

    /// On-screen canvas point (a user's pen sample) → grading "box" space.
    func boxPoint(canvas p: CGPoint) -> CGPoint {
        CGPoint(x: (p.x - inset) / scale,
                y: (p.y - inset) / scale)
    }
}

/// Minimal parser for the absolute-coordinate SVG path strings used by the
/// stroke data (commands M, L, Q, C, Z). Each coordinate is mapped through
/// `transform` so the resulting `Path` is already in canvas space.
enum SVGPath {
    static func path(from d: String, transform: (CGFloat, CGFloat) -> CGPoint) -> Path {
        var path = Path()
        let tokens = tokenize(d)
        var index = 0
        var start = CGPoint.zero
        var current = CGPoint.zero

        func peekIsNumber() -> Bool {
            guard index < tokens.count else { return false }
            return Double(tokens[index]) != nil
        }
        func number() -> CGFloat {
            defer { index += 1 }
            guard index < tokens.count else { return 0 }
            return CGFloat(Double(tokens[index]) ?? 0)
        }

        while index < tokens.count {
            let token = tokens[index]
            guard let command = token.first, token.count == 1, command.isLetter else {
                index += 1 // stray number — skip
                continue
            }
            index += 1

            switch command {
            case "M":
                let p = transform(number(), number())
                path.move(to: p); current = p; start = p
                // Extra coordinate pairs after an M are implicit line-tos.
                while peekIsNumber() {
                    let q = transform(number(), number())
                    path.addLine(to: q); current = q
                }
            case "L":
                while peekIsNumber() {
                    let q = transform(number(), number())
                    path.addLine(to: q); current = q
                }
            case "Q":
                while peekIsNumber() {
                    let c = transform(number(), number())
                    let end = transform(number(), number())
                    path.addQuadCurve(to: end, control: c); current = end
                }
            case "C":
                while peekIsNumber() {
                    let c1 = transform(number(), number())
                    let c2 = transform(number(), number())
                    let end = transform(number(), number())
                    path.addCurve(to: end, control1: c1, control2: c2); current = end
                }
            case "Z", "z":
                path.closeSubpath(); current = start
            default:
                break
            }
        }
        return path
    }

    private static func tokenize(_ d: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        for ch in d {
            if ch.isLetter {
                if !current.isEmpty { tokens.append(current); current = "" }
                tokens.append(String(ch))
            } else if ch == " " || ch == "," || ch == "\n" || ch == "\t" || ch == "\r" {
                if !current.isEmpty { tokens.append(current); current = "" }
            } else {
                // A '-' that isn't the first character starts a new number.
                if ch == "-" && !current.isEmpty {
                    tokens.append(current); current = ""
                }
                current.append(ch)
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }
}
