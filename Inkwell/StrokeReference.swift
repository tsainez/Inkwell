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

import CoreGraphics
import Foundation
import SwiftUI
import SQLite3

/// On-demand store of reference stroke data, querying the offline SQLite database on demand.
final class StrokeReference {
    static let shared = StrokeReference()

    private var cache: [String: CharacterStrokeData] = [:]
    private var db: OpaquePointer?

    private init() {
        openDatabase()
    }

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    func data(for glyph: String) -> CharacterStrokeData? {
        if let cached = cache[glyph] {
            return cached
        }
        // 1. Try the reference database first.
        if let loaded = fetchFromDatabase(glyph: glyph) {
            cache[glyph] = loaded
            return loaded
        }
        // 2. Fall back to IDS decomposition synthesis.
        //    The lookup closure passes only reference data to avoid recursion:
        //    components must already be in the DB, not themselves synthesized.
        if let synthesized = IDSDecomposer.synthesize(
            glyph: glyph,
            lookup: { [weak self] g in self?.fetchFromDatabase(glyph: g) }
        ) {
            cache[glyph] = synthesized
            return synthesized
        }
        return nil
    }

    private func openDatabase() {
        if let url = Bundle.main.url(forResource: "StrokeData", withExtension: "sqlite") {
            if sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
                print("StrokeReference: Successfully opened StrokeData.sqlite")
                return
            } else {
                print("StrokeReference: Failed to open StrokeData.sqlite at \(url.path)")
            }
        } else {
            print("StrokeReference: StrokeData.sqlite not found in Bundle.main")
        }
        loadFallbackJSON()
    }

    private func fetchFromDatabase(glyph: String) -> CharacterStrokeData? {
        guard let db = db else { return nil }
        let query = "SELECT strokes_json, medians_json FROM character_strokes WHERE glyph = ? LIMIT 1;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, 1, glyph, -1, SQLITE_TRANSIENT)

        if sqlite3_step(statement) == SQLITE_ROW {
            guard let strokesCStr = sqlite3_column_text(statement, 0),
                  let mediansCStr = sqlite3_column_text(statement, 1) else { return nil }
            
            let strokesJson = String(cString: strokesCStr)
            let mediansJson = String(cString: mediansCStr)
            
            guard let strokesData = strokesJson.data(using: .utf8),
                  let mediansData = mediansJson.data(using: .utf8),
                  let strokes = try? JSONDecoder().decode([String].self, from: strokesData),
                  let medians = try? JSONDecoder().decode([[StrokePoint]].self, from: mediansData) else {
                return nil
            }
            return CharacterStrokeData(glyph: glyph, strokes: strokes, medians: medians)
        }
        return nil
    }

    private func loadFallbackJSON() {
        guard let url = Bundle.main.url(forResource: "StrokeData", withExtension: "json") else { return }
        do {
            let raw = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([CharacterStrokeData].self, from: raw)
            cache = Dictionary(uniqueKeysWithValues: items.map { ($0.glyph, $0) })
        } catch {
            print("Failed to decode fallback StrokeData.json: \(error)")
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
    private static var cache: [String: Path] = [:]
    private static let lock = NSLock()

    static func path(from d: String) -> Path {
        lock.lock()
        if let cached = cache[d] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        var path = Path()
        let tokens = tokenize(d)
        var index = 0
        var start = CGPoint.zero

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
                let p = CGPoint(x: number(), y: number())
                path.move(to: p); start = p
                // Extra coordinate pairs after an M are implicit line-tos.
                while peekIsNumber() {
                    let q = CGPoint(x: number(), y: number())
                    path.addLine(to: q)
                }
            case "L":
                while peekIsNumber() {
                    let q = CGPoint(x: number(), y: number())
                    path.addLine(to: q)
                }
            case "Q":
                while peekIsNumber() {
                    let c = CGPoint(x: number(), y: number())
                    let end = CGPoint(x: number(), y: number())
                    path.addQuadCurve(to: end, control: c)
                }
            case "C":
                while peekIsNumber() {
                    let c1 = CGPoint(x: number(), y: number())
                    let c2 = CGPoint(x: number(), y: number())
                    let end = CGPoint(x: number(), y: number())
                    path.addCurve(to: end, control1: c1, control2: c2)
                }
            case "Z", "z":
                path.closeSubpath()
            default:
                break
            }
        }

        lock.lock()
        cache[d] = path
        lock.unlock()

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
