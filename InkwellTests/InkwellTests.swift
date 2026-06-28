//
//  InkwellTests.swift
//  InkwellTests
//
//  Created by Tony Sainez on 6/28/26.
//

import Testing
import CoreGraphics
import Foundation
@testable import Inkwell

struct InkwellTests {

    // MARK: - Helpers

    /// Evenly spaced points along a straight segment.
    private func line(from a: CGPoint, to b: CGPoint, count: Int = 24) -> [CGPoint] {
        (0..<count).map { i in
            let t = CGFloat(i) / CGFloat(count - 1)
            return CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
    }

    /// Add a small, deterministic wobble so the input isn't a perfect copy.
    private func jitter(_ points: [CGPoint], amount: CGFloat = 8) -> [CGPoint] {
        points.enumerated().map { i, p in
            let dx = (i % 2 == 0 ? amount : -amount)
            let dy = (i % 3 == 0 ? amount : -amount) * 0.5
            return CGPoint(x: p.x + dx, y: p.y + dy)
        }
    }

    private func offset(_ points: [CGPoint], by delta: CGPoint) -> [CGPoint] {
        points.map { CGPoint(x: $0.x + delta.x, y: $0.y + delta.y) }
    }

    /// A realistic reference stroke: the first stroke of 人 (丿), converted to
    /// grading "box" space (y flipped about the 900 baseline).
    private let renStroke1: [CGPoint] = [
        CGPoint(x: 483, y: 164), CGPoint(x: 508, y: 198), CGPoint(x: 511, y: 222),
        CGPoint(x: 473, y: 348), CGPoint(x: 408, y: 484), CGPoint(x: 328, y: 597),
        CGPoint(x: 271, y: 656), CGPoint(x: 144, y: 761), CGPoint(x: 72, y: 805)
    ]

    // MARK: - Core judgments

    @Test func correctStrokePasses() async throws {
        let user = jitter(renStroke1, amount: 10)
        #expect(StrokeGrader.judge(user: user, median: renStroke1) == .correct)
    }

    @Test func reversedStrokeIsWrongDirection() async throws {
        // Drawing the right shape, in the right place, but end-to-start.
        let user = Array(renStroke1.reversed())
        #expect(StrokeGrader.judge(user: user, median: renStroke1) == .wrongDirection)
    }

    @Test func displacedStrokeIsWrong() async throws {
        // Same shape and direction, but far from where it belongs.
        let user = offset(renStroke1, by: CGPoint(x: 480, y: 0))
        var lenient = StrokeGrader.Config()
        lenient.leniency = 1.6
        // Wrong even with the most forgiving setting.
        #expect(StrokeGrader.judge(user: user, median: renStroke1, config: lenient) == .wrongStroke)
    }

    @Test func wrongShapeWithMatchingEndsIsWrong() async throws {
        // Same start and end as a horizontal stroke, but a wildly different
        // path (a tall tent). Endpoints match, so this proves shape matters.
        let median = line(from: CGPoint(x: 120, y: 400), to: CGPoint(x: 920, y: 400))
        let tent = line(from: CGPoint(x: 120, y: 400), to: CGPoint(x: 520, y: -150))
            + line(from: CGPoint(x: 520, y: -150), to: CGPoint(x: 920, y: 400))
        #expect(StrokeGrader.judge(user: tent, median: median) == .wrongStroke)
    }

    @Test func tinyTapIsTooShort() async throws {
        let tap = [CGPoint(x: 480, y: 160), CGPoint(x: 483, y: 162)]
        #expect(StrokeGrader.judge(user: tap, median: renStroke1) == .tooShort)
    }

    // MARK: - Direction on a symmetric (horizontal) stroke

    @Test func backwardsHorizontalStrokeIsWrongDirection() async throws {
        // The hard case: a straight horizontal stroke occupies the same points
        // whether drawn L→R or R→L, so direction must be caught via endpoints.
        let median = line(from: CGPoint(x: 120, y: 400), to: CGPoint(x: 920, y: 400))
        let forward = jitter(median, amount: 6)
        let backward = Array(median.reversed())
        #expect(StrokeGrader.judge(user: forward, median: median) == .correct)
        #expect(StrokeGrader.judge(user: backward, median: median) == .wrongDirection)
    }

    // MARK: - Leniency

    @Test func strictRejectsWhatLenientAccepts() async throws {
        // A recognizable trace shifted ~190 units sideways: too far for strict,
        // within tolerance for lenient.
        let user = offset(jitter(renStroke1, amount: 10), by: CGPoint(x: 190, y: 0))

        var strict = StrokeGrader.Config(); strict.leniency = 1.0
        var lenient = StrokeGrader.Config(); lenient.leniency = 1.8

        #expect(StrokeGrader.judge(user: user, median: renStroke1, config: strict) != .correct)
        #expect(StrokeGrader.judge(user: user, median: renStroke1, config: lenient) == .correct)
    }

    // MARK: - Order disambiguation

    @Test func bestMatchFindsTheIntendedStroke() async throws {
        // Two strokes of 二 (box space): a shorter upper bar and a longer lower bar.
        let upperBar = line(from: CGPoint(x: 300, y: 313), to: CGPoint(x: 720, y: 290))
        let lowerBar = line(from: CGPoint(x: 130, y: 680), to: CGPoint(x: 900, y: 660))
        let medians = [upperBar, lowerBar]

        // The user draws the lower bar first; we should identify it as stroke 2.
        let userDrawsLower = jitter(lowerBar, amount: 8)
        #expect(StrokeGrader.indexOfBestMatch(user: userDrawsLower, medians: medians) == 1)
    }

    // MARK: - Geometry utilities

    @Test func resampleReturnsRequestedCount() async throws {
        let pts = line(from: .zero, to: CGPoint(x: 100, y: 0), count: 5)
        let resampled = StrokeGrader.resample(pts, count: 16)
        #expect(resampled.count == 16)
        // Endpoints are preserved.
        #expect(StrokeGrader.distance(resampled.first!, CGPoint(x: 0, y: 0)) < 0.001)
        #expect(StrokeGrader.distance(resampled.last!, CGPoint(x: 100, y: 0)) < 0.001)
    }

    @Test func pathLengthIsArcLength() async throws {
        let pts = [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 30), CGPoint(x: 40, y: 30)]
        #expect(abs(StrokeGrader.pathLength(pts) - 70) < 0.001)
    }
}
