//
//  IDSDecomposer.swift
//  Inkwell
//
//  Synthesizes stroke data for CJK characters that are absent from the reference
//  database by decomposing them into two spatial components using IDS
//  (Ideographic Description Sequence) data.
//
//  The bundled IDS_fallback.json maps each missing basic-CJK glyph to an
//  operator ("lr" = left-right, "tb" = top-bottom) and two component glyphs
//  whose stroke data *is* available in StrokeData.sqlite.
//
//  Coordinate space note
//  ─────────────────────
//  All medians live in the 1024 × 900 glyph-box:
//      x: 0 (left) … 1024 (right)
//      y: 0 (baseline) … 900 (cap-height / top)
//
//  Left-right split (operator "lr"):
//      left  component: x_out = x_in × 0.5               (maps 0-1024 → 0-512)
//      right component: x_out = 512 + x_in × 0.5         (maps 0-1024 → 512-1024)
//
//  Top-bottom split (operator "tb"):
//      top    component: y_out = 450 + y_in × 0.5        (maps 0-900 → 450-900)
//      bottom component: y_out =         y_in × 0.5      (maps 0-900 → 0-450)
//
//  The generated strokes are open-path SVG "M x,y L x,y …" strings (not filled
//  brush-stroke outlines). GlyphOutlineView detects source == .synthesized and
//  renders them with context.stroke instead of context.fill.
//
//  Coverage: ~8,764 of the ~9,306 basic-CJK glyphs absent from the DB can be
//  synthesized this way (≈ 94 %). The remaining ~542 have no spatial decomposition
//  whose components are both in the DB; they fall through to free-practice mode.
//

import Foundation
import OSLog

// MARK: - JSON model

private struct IDSEntry: Codable {
    /// "lr" = left-right, "tb" = top-bottom.
    let op: String
    /// Exactly two component glyph strings.
    let parts: [String]
}

// MARK: - Decomposer

enum IDSDecomposer {

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Inkwell", category: "IDSDecomposer")

    // MARK: Public API

    /// Attempt to synthesize stroke data for `glyph` by decomposing it into
    /// spatial components and assembling their (transformed) medians.
    ///
    /// Returns `nil` when:
    ///   - `glyph` has no entry in IDS_fallback.json
    ///   - either component's stroke data cannot be fetched (shouldn't happen
    ///     for the bundled data, but guards against DB inconsistency)
    static func synthesize(glyph: String,
                           lookup: (String) -> CharacterStrokeData?) -> CharacterStrokeData? {
        guard let entry = fallbackMap[glyph],
              entry.parts.count == 2 else { return nil }

        let partA = entry.parts[0]
        let partB = entry.parts[1]

        // We deliberately call lookup without going through the synthesizer again
        // (components must already be reference data) to avoid infinite recursion.
        guard let dataA = lookup(partA),
              let dataB = lookup(partB) else { return nil }

        let isLR = (entry.op == "lr")
        var medians: [[StrokePoint]] = []
        var strokes: [String]        = []

        for (data, isSecond) in [(dataA, false), (dataB, true)] {
            for median in data.medians {
                let transformed = median.map { transform($0, isLR: isLR, isSecond: isSecond) }
                medians.append(transformed)
                strokes.append(openPath(from: transformed))
            }
        }

        return CharacterStrokeData(
            glyph:   glyph,
            strokes: strokes,
            medians: medians,
            source:  .synthesized
        )
    }

    // MARK: - Spatial transform

    /// Map a single glyph-box point into the sub-region occupied by one half
    /// of the synthesized character.
    private static func transform(_ p: StrokePoint, isLR: Bool, isSecond: Bool) -> StrokePoint {
        if isLR {
            // left half: 0-512; right half: 512-1024
            let xOff = isSecond ? 512.0 : 0.0
            return StrokePoint(x: xOff + p.x * 0.5, y: p.y)
        } else {
            // top half: 450-900; bottom half: 0-450
            let yOff = isSecond ? 0.0 : 450.0
            return StrokePoint(x: p.x, y: yOff + p.y * 0.5)
        }
    }

    // MARK: - SVG path generation

    /// Build a simple open-path SVG string "M x,y L x,y …" from a median.
    /// GlyphOutlineView strokes (rather than fills) these for .synthesized data.
    private static func openPath(from median: [StrokePoint]) -> String {
        guard !median.isEmpty else { return "" }
        var tokens: [String] = []
        tokens.reserveCapacity(median.count * 3)
        for (i, pt) in median.enumerated() {
            let cmd = i == 0 ? "M" : "L"
            tokens.append("\(cmd) \(fmt(pt.x)),\(fmt(pt.y))")
        }
        return tokens.joined(separator: " ")
    }

    private static func fmt(_ v: Double) -> String {
        // One decimal place is enough precision for the grader.
        String(format: "%.1f", v)
    }

    // MARK: - Data loading

    /// Lazy-loaded, parse-once table from IDS_fallback.json.
    private static let fallbackMap: [String: IDSEntry] = {
        guard let url  = Bundle.main.url(forResource: "IDS_fallback", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            logger.error("IDS_fallback.json not found in bundle")
            return [:]
        }
        do {
            let map = try JSONDecoder().decode([String: IDSEntry].self, from: data)
            logger.debug("loaded \(map.count) IDS entries")
            return map
        } catch {
            logger.error("failed to decode IDS_fallback.json — \(String(describing: error))")
            return [:]
        }
    }()
}
