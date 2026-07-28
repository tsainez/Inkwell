//
//  StrokeGrader.swift
//  Inkwell
//
//  Pure, UIKit-free engine that grades a single handwritten stroke against a
//  reference stroke median. It judges position, shape, and — crucially —
//  direction (a stroke drawn end-to-start is reported as `.wrongDirection`).
//
//  All geometry is expressed in the 1024×1024 "glyph box" coordinate space used
//  by the bundled stroke data, so thresholds are independent of the on-screen
//  canvas size. PracticeView converts the user's canvas points and the
//  reference medians into this space (see GlyphMetrics) before calling `judge`.
//
//  The approach mirrors HanziWriter's quiz matching: resample both curves to a
//  fixed number of points, then require (a) a small average point-to-point
//  distance and (b) matching start/end points. Comparing the user stroke
//  forwards vs. reversed is what distinguishes a backwards stroke from a stroke
//  that is simply in the wrong place.
//

import CoreGraphics
import Foundation

/// The result of grading one user stroke against one reference stroke.
enum StrokeJudgment: Equatable {
    /// Right place, right shape, right direction.
    case correct
    /// Shape and place are right, but the stroke was drawn end-to-start.
    case wrongDirection
    /// Doesn't match this stroke (wrong location, shape, or — at the
    /// controller level — the wrong stroke for this point in the order).
    case wrongStroke
    /// Too small to be a real stroke (an accidental tap or dot). Ignored
    /// rather than counted as a mistake.
    case tooShort
}

enum StrokeGrader {

    /// Tunable thresholds. Defaults are deliberately a little forgiving; the
    /// `leniency` multiplier (driven by the in-app Lenient/Strict toggle)
    /// scales the distance tolerances so the values can be tuned against real
    /// human testing. Larger `leniency` == more forgiving.
    struct Config {
        /// Max allowed average distance between corresponding resampled points
        /// (1024-unit glyph space).
        var meanDistance: CGFloat = 145
        /// Max allowed distance between the user's start/end and the model's
        /// start/end (1024-unit glyph space).
        var startEndDistance: CGFloat = 215
        /// Strokes shorter than this (and shorter than half the model) are
        /// treated as accidental taps.
        var minLength: CGFloat = 50
        /// Number of points each curve is resampled to before comparison.
        var resampleCount: Int = 16
        /// 1.0 == strict. The app uses ~1.6 for "lenient".
        var leniency: CGFloat = 1.0
    }

    /// When forward and reverse both fit (a short or near-symmetric stroke), the
    /// stroke is only called "backwards" if the reverse fit is clearly better
    /// than the forward fit. This keeps a noisy-but-correct stroke from being
    /// misreported as wrong-direction.
    static let directionMargin: CGFloat = 0.85

    /// Grade `user` (an ordered list of points in glyph-box space) against the
    /// reference stroke `median` (also in glyph-box space).
    static func judge(user: [CGPoint], median: [CGPoint], config: Config = Config()) -> StrokeJudgment {
        return judge(fitResult: fit(user: user, median: median, config: config), config: config)
    }

    private static func judge(fitResult: FitResult, config: Config) -> StrokeJudgment {
        switch fitResult {
        case .tooShort:
            return .tooShort
        case .degenerate:
            return .wrongStroke
        case .metrics(let f):
            let meanTolerance = config.meanDistance * config.leniency
            let endTolerance = config.startEndDistance * config.leniency

            let forwardMatches = f.forwardMean <= meanTolerance && f.forwardEnds <= endTolerance
            let reverseMatches = f.reverseMean <= meanTolerance && f.reverseEnds <= endTolerance

            if forwardMatches && reverseMatches {
                // Both directions are plausible (a short/symmetric stroke).
                // Decide by which way fits the point order better.
                return f.reverseMean < f.forwardMean * directionMargin ? .wrongDirection : .correct
            }
            if forwardMatches { return .correct }
            if reverseMatches { return .wrongDirection }
            return .wrongStroke
        }
    }

    /// Among `medians`, return the index of the stroke the user's stroke fits
    /// best (smallest average distance) while still grading as `.correct`. Used
    /// by the controller to give "out of order" feedback ("that looks like
    /// stroke N") even when a glyph has several similar strokes.
    static func indexOfBestMatch(user: [CGPoint],
                                 medians: [[CGPoint]],
                                 config: Config = Config()) -> Int? {
        var best: Int?
        var bestScore = CGFloat.greatestFiniteMagnitude
        for (i, median) in medians.enumerated() {
            let fitResult = fit(user: user, median: median, config: config)
            guard judge(fitResult: fitResult, config: config) == .correct else { continue }
            if case .metrics(let f) = fitResult,
               f.forwardMean < bestScore {
                bestScore = f.forwardMean
                best = i
            }
        }
        return best
    }

    // MARK: - Fit

    /// The raw forward/reverse comparison metrics for one stroke pair.
    private struct Fit {
        let forwardMean: CGFloat
        let forwardEnds: CGFloat
        let reverseMean: CGFloat
        let reverseEnds: CGFloat
    }

    private enum FitResult {
        case tooShort
        case degenerate
        case metrics(Fit)
    }

    /// Resample both curves and measure how well the user stroke matches the
    /// model both forwards and reversed.
    private static func fit(user: [CGPoint], median: [CGPoint], config: Config) -> FitResult {
        let u = dedupe(user)
        let m = dedupe(median)
        guard m.count >= 2 else { return .degenerate }
        guard u.count >= 2 else { return .tooShort }

        let userLength = pathLength(u)
        let modelLength = pathLength(m)
        // Ignore microscopic marks, but never reject a stroke just for being
        // short when the model stroke itself is short (e.g. a dot).
        if userLength < min(config.minLength, modelLength * 0.5) {
            return .tooShort
        }

        let n = config.resampleCount
        let ru = resample(u, count: n)
        let rm = resample(m, count: n)
        let reversed = Array(ru.reversed())

        return .metrics(Fit(
            forwardMean: meanDistance(ru, rm),
            forwardEnds: max(distance(ru.first!, rm.first!), distance(ru.last!, rm.last!)),
            reverseMean: meanDistance(reversed, rm),
            reverseEnds: max(distance(reversed.first!, rm.first!), distance(reversed.last!, rm.last!))
        ))
    }

    // MARK: - Geometry helpers (internal for testing)

    static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }

    /// Remove consecutive duplicate / near-duplicate points.
    static func dedupe(_ pts: [CGPoint], epsilon: CGFloat = 0.0001) -> [CGPoint] {
        var out: [CGPoint] = []
        out.reserveCapacity(pts.count)
        for p in pts {
            if let last = out.last, distance(last, p) <= epsilon { continue }
            out.append(p)
        }
        return out
    }

    static func pathLength(_ pts: [CGPoint]) -> CGFloat {
        guard pts.count >= 2 else { return 0 }
        var total: CGFloat = 0
        for i in 1..<pts.count { total += distance(pts[i - 1], pts[i]) }
        return total
    }

    /// Resample a polyline to exactly `count` points spaced evenly along its
    /// arc length. This normalizes for differences in drawing speed and the
    /// irregular sampling of raw input. (Standard arc-length resampling, per
    /// Wobbrock et al.'s $1 recognizer.)
    static func resample(_ pts: [CGPoint], count: Int) -> [CGPoint] {
        let cleaned = dedupe(pts)
        guard count >= 2 else { return cleaned }
        guard cleaned.count >= 2 else {
            return Array(repeating: cleaned.first ?? .zero, count: count)
        }
        let total = pathLength(cleaned)
        guard total > 0 else { return Array(repeating: cleaned[0], count: count) }

        let interval = total / CGFloat(count - 1)
        var result: [CGPoint] = [cleaned[0]]
        var accumulated: CGFloat = 0
        var i = 1

        var prev = cleaned[0]

        while i < cleaned.count {
            let curr = cleaned[i]
            let segment = distance(prev, curr)

            if accumulated + segment >= interval {
                let t = (interval - accumulated) / segment
                let q = CGPoint(x: prev.x + t * (curr.x - prev.x),
                                y: prev.y + t * (curr.y - prev.y))
                result.append(q)
                // We don't advance `i` yet, but update `prev` to our new inserted point `q`
                // ⚡ Bolt: Removed O(N^2) array insertion here, keeping iteration purely O(N)
                prev = q
                accumulated = 0
            } else {
                accumulated += segment
                prev = curr
                i += 1
            }
        }

        // Guarantee exactly `count` points, with the true endpoint preserved.
        if result.count > count { result = Array(result.prefix(count)) }
        while result.count < count { result.append(cleaned.last!) }
        result[count - 1] = cleaned.last!
        return result
    }

    /// Average distance between corresponding points of two equal-length,
    /// resampled polylines.
    static func meanDistance(_ a: [CGPoint], _ b: [CGPoint]) -> CGFloat {
        let n = min(a.count, b.count)
        guard n > 0 else { return .greatestFiniteMagnitude }
        var total: CGFloat = 0
        for i in 0..<n { total += distance(a[i], b[i]) }
        return total / CGFloat(n)
    }
}
