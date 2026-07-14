//
//  InkwellTests.swift
//  InkwellTests
//
//  Created by Tony Sainez on 6/28/26.
//

import Testing
import CoreGraphics
import Foundation
import SwiftUI
import UIKit
@testable import Inkwell

// MARK: - StrokeGrader

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

    @Test func emptyUserStrokeIsTooShort() async throws {
        #expect(StrokeGrader.judge(user: [], median: renStroke1) == .tooShort)
    }

    @Test func singlePointUserStrokeIsTooShort() async throws {
        let singlePoint = [CGPoint(x: 480, y: 160)]
        #expect(StrokeGrader.judge(user: singlePoint, median: renStroke1) == .tooShort)
    }

    @Test func degenerateMedianIsWrongStroke() async throws {
        let user = jitter(renStroke1, amount: 10)
        let degenerateMedian = [CGPoint(x: 480, y: 160)]
        #expect(StrokeGrader.judge(user: user, median: degenerateMedian) == .wrongStroke)
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

    // MARK: - SQLite Character Lookups

    @Test func testXieStrokeDataLookup() async throws {
        let data = StrokeReference.shared.data(for: "謝")
        #expect(data != nil)
        #expect(data?.strokes.count ?? 0 > 0)
    }

    @Test func testSakuraStrokeDataLookup() async throws {
        let data = StrokeReference.shared.data(for: "桜")
        #expect(data != nil)
        #expect(data?.strokes.count ?? 0 > 0)
    }
}

// MARK: - StrokeGrader Internal Utilities

struct StrokeGraderUtilityTests {

    // MARK: dedupe

    @Test func dedupeRemovesConsecutiveDuplicates() {
        let pts = [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0)]
        #expect(StrokeGrader.dedupe(pts).count == 2)
    }

    @Test func dedupePreservesDistinctPoints() {
        let pts = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 2, y: 0)]
        #expect(StrokeGrader.dedupe(pts).count == 3)
    }

    @Test func dedupeEmptyArrayReturnsEmpty() {
        #expect(StrokeGrader.dedupe([]).isEmpty)
    }

    @Test func dedupeSinglePointReturnsSinglePoint() {
        #expect(StrokeGrader.dedupe([CGPoint(x: 5, y: 10)]).count == 1)
    }

    @Test func dedupeAllSamePointCollapsesToOne() {
        let pts = Array(repeating: CGPoint(x: 3, y: 7), count: 10)
        #expect(StrokeGrader.dedupe(pts).count == 1)
    }

    @Test func dedupeKeepsNonConsecutiveDuplicates() {
        // A→B→A: the second A is not consecutive with the first, so all 3 kept.
        let pts = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 0, y: 0)]
        #expect(StrokeGrader.dedupe(pts).count == 3)
    }

    // MARK: meanDistance

    @Test func meanDistanceIdenticalArraysIsZero() {
        let pts = [CGPoint(x: 10, y: 20), CGPoint(x: 30, y: 40)]
        #expect(StrokeGrader.meanDistance(pts, pts) < 0.0001)
    }

    @Test func meanDistanceKnownValue() {
        // Both points in b are exactly 5 units from the origin.
        let a = [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 0)]
        let b = [CGPoint(x: 3, y: 4), CGPoint(x: 3, y: 4)]
        #expect(abs(StrokeGrader.meanDistance(a, b) - 5.0) < 0.0001)
    }

    @Test func meanDistanceEmptyArraysReturnsGreatestMagnitude() {
        #expect(StrokeGrader.meanDistance([], []) == .greatestFiniteMagnitude)
    }

    // MARK: resample edge cases

    @Test func resampleSingleInputPointFillsRequestedCount() {
        let single = [CGPoint(x: 50, y: 50)]
        let result = StrokeGrader.resample(single, count: 8)
        #expect(result.count == 8)
        #expect(result.allSatisfy { $0 == CGPoint(x: 50, y: 50) })
    }

    @Test func resampleAllSamePointDoesNotCrash() {
        // Zero-length path: all points identical.
        let pts = Array(repeating: CGPoint(x: 200, y: 300), count: 5)
        let result = StrokeGrader.resample(pts, count: 10)
        #expect(result.count == 10)
    }

    @Test func resampleCountBelowTwoReturnsCleanedInput() {
        // guard count >= 2 else { return cleaned } — count=1 returns the deduped input.
        let pts = [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 100)]
        let result = StrokeGrader.resample(pts, count: 1)
        #expect(!result.isEmpty)
    }

    @Test func resamplePreservesEndpoints() {
        let start = CGPoint(x: 10, y: 20)
        let end = CGPoint(x: 300, y: 500)
        let pts = [start, CGPoint(x: 100, y: 200), end]
        let result = StrokeGrader.resample(pts, count: 12)
        #expect(StrokeGrader.distance(result.first!, start) < 0.01)
        #expect(StrokeGrader.distance(result.last!, end) < 0.01)
    }

    // MARK: indexOfBestMatch edge cases

    @Test func indexOfBestMatchNoMatchReturnsNil() {
        // User stroke is nowhere near any median.
        let farAway = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0)]
        let medians = [[CGPoint(x: 800, y: 800), CGPoint(x: 900, y: 800)]]
        #expect(StrokeGrader.indexOfBestMatch(user: farAway, medians: medians) == nil)
    }

    @Test func indexOfBestMatchEmptyMediansReturnsNil() {
        let user = [CGPoint(x: 100, y: 100), CGPoint(x: 200, y: 200)]
        #expect(StrokeGrader.indexOfBestMatch(user: user, medians: []) == nil)
    }
}

// MARK: - GlyphMetrics

struct GlyphMetricsTests {

    /// Unit-scale metrics: size = em = 1024, inset = 0, so scale = 1.0.
    /// Makes manual arithmetic straightforward.
    private let unit = GlyphMetrics(size: GlyphMetrics.em, inset: 0)

    @Test func scaleComputedCorrectly() {
        let m = GlyphMetrics(size: 512, inset: 0)
        #expect(abs(m.scale - 0.5) < 0.0001)
    }

    @Test func scaleWithInsetComputedCorrectly() {
        // size=1044, inset=10 → (1044 - 20) / 1024 = 1.0
        let m = GlyphMetrics(size: 1044, inset: 10)
        #expect(abs(m.scale - 1.0) < 0.0001)
    }

    @Test func canvasPointYAxisIsFlipped() {
        // Raw y=0 (bottom of glyph space) maps to a larger canvas y than raw y=900 (top),
        // because screen y grows downward.
        let low = unit.canvasPoint(rawX: 512, rawY: 0)
        let high = unit.canvasPoint(rawX: 512, rawY: 900)
        #expect(low.y > high.y)
    }

    @Test func canvasPointKnownValue() {
        // unit scale (size=1024, inset=0): canvasX = x, canvasY = baseline - y = 900 - y
        let p = unit.canvasPoint(rawX: 200, rawY: 300)
        #expect(abs(p.x - 200) < 0.001)
        #expect(abs(p.y - 600) < 0.001) // 900 - 300
    }

    @Test func canvasPointOriginMapsToBaseline() {
        // Raw (0, 0) is the bottom-left of glyph space → canvas y should equal baseline.
        let p = unit.canvasPoint(rawX: 0, rawY: 0)
        #expect(abs(p.y - GlyphMetrics.baseline) < 0.001)
    }

    @Test func canvasPointWithInsetApplied() {
        // size = em + 2*inset so scale stays 1.0; inset shifts both axes.
        let inset: CGFloat = 10
        let m = GlyphMetrics(size: GlyphMetrics.em + 2 * inset, inset: inset)
        let p = m.canvasPoint(rawX: 100, rawY: 200)
        #expect(abs(p.x - (inset + 100)) < 0.001)
        #expect(abs(p.y - (inset + 700)) < 0.001) // inset + (900-200)
    }

    @Test func boxPointFromStrokePointFlipsY() {
        // boxPoint(StrokePoint) maps raw y → baseline - y (no canvas scaling).
        let sp = StrokePoint(x: 300, y: 400)
        let bp = unit.boxPoint(sp)
        #expect(abs(bp.x - 300) < 0.001)
        #expect(abs(bp.y - 500) < 0.001) // 900 - 400
    }

    @Test func boxPointCanvasRoundTrip() {
        // Converting a StrokePoint to canvas then back to box space should yield
        // the same box point as boxPoint(StrokePoint) directly.
        let sp = StrokePoint(x: 450, y: 600)
        let canvas = unit.canvasPoint(sp)
        let boxViaCanvas = unit.boxPoint(canvas: canvas)
        let boxDirect = unit.boxPoint(sp)
        #expect(abs(boxViaCanvas.x - boxDirect.x) < 0.01)
        #expect(abs(boxViaCanvas.y - boxDirect.y) < 0.01)
    }

    @Test func boxPointCanvasIdentityAtUnitScale() {
        // At unit scale with no inset, boxPoint(canvas:) is the identity transform.
        let canvas = CGPoint(x: 200, y: 700)
        let box = unit.boxPoint(canvas: canvas)
        #expect(abs(box.x - 200) < 0.001)
        #expect(abs(box.y - 700) < 0.001)
    }
}

// MARK: - SVGPath

struct SVGPathTests {

    private func identity(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    @Test func emptyStringProducesEmptyPath() {
        #expect(SVGPath.path(from: "", transform: identity).isEmpty)
    }

    @Test func moveAndLineProducesNonEmptyPath() {
        #expect(!SVGPath.path(from: "M 0 0 L 100 100", transform: identity).isEmpty)
    }

    @Test func moveCommandPositionsStartCorrectly() {
        let path = SVGPath.path(from: "M 50 80 L 150 80", transform: identity)
        let bounds = path.boundingRect
        #expect(bounds.minX <= 50 + 0.5)
        #expect(bounds.maxX >= 150 - 0.5)
    }

    @Test func implicitLineTosAfterMMatchExplicitL() {
        // "M x1 y1 x2 y2" — the second coordinate pair is an implicit line-to.
        let explicit = SVGPath.path(from: "M 0 0 L 100 0", transform: identity)
        let implicit = SVGPath.path(from: "M 0 0 100 0", transform: identity)
        let diff = abs(explicit.boundingRect.maxX - implicit.boundingRect.maxX)
        #expect(diff < 0.5)
    }

    @Test func quadraticCurveProducesCorrectBounds() {
        let path = SVGPath.path(from: "M 0 0 Q 50 100 100 0", transform: identity)
        #expect(!path.isEmpty)
        #expect(path.boundingRect.maxX >= 100 - 0.5)
    }

    @Test func cubicCurveProducesNonEmptyPath() {
        #expect(!SVGPath.path(from: "M 0 0 C 0 50 100 50 100 0", transform: identity).isEmpty)
    }

    @Test func closeSubpathZProducesNonEmptyPath() {
        let path = SVGPath.path(from: "M 0 0 L 100 0 L 100 100 Z", transform: identity)
        #expect(!path.isEmpty)
    }

    @Test func negativeCoordsTokenizedCorrectly() {
        // "100-50" must be split into 100 and -50 by the tokenizer.
        let path = SVGPath.path(from: "M 100-50 L 200-50", transform: identity)
        let bounds = path.boundingRect
        #expect(abs(bounds.midY - (-50)) < 1)
        #expect(abs(bounds.minX - 100) < 1)
        #expect(abs(bounds.maxX - 200) < 1)
    }

    @Test func commaSeparatorsEquivalentToSpaces() {
        let withSpaces = SVGPath.path(from: "M 10 20 L 30 40", transform: identity)
        let withCommas = SVGPath.path(from: "M 10,20 L 30,40", transform: identity)
        #expect(abs(withSpaces.boundingRect.minX - withCommas.boundingRect.minX) < 0.5)
        #expect(abs(withSpaces.boundingRect.minY - withCommas.boundingRect.minY) < 0.5)
    }

    @Test func chainedQuadraticCurvesAllRendered() {
        // Q with multiple control+end pairs — both curves should extend the path.
        let path = SVGPath.path(from: "M 0 0 Q 25 50 50 0 75 -50 100 0", transform: identity)
        #expect(!path.isEmpty)
        #expect(path.boundingRect.maxX >= 100 - 0.5)
    }

    @Test func transformIsApplied() {
        // A transform that doubles all coordinates should double the bounding rect.
        let scale: (CGFloat, CGFloat) -> CGPoint = { CGPoint(x: $0 * 2, y: $1 * 2) }
        let normal = SVGPath.path(from: "M 0 0 L 100 0", transform: identity)
        let scaled = SVGPath.path(from: "M 0 0 L 100 0", transform: scale)
        #expect(abs(scaled.boundingRect.maxX - normal.boundingRect.maxX * 2) < 0.5)
    }
}

// MARK: - StrokeReference Robustness

struct StrokeReferenceRobustnessTests {

    @Test func unknownGlyphReturnsNil() {
        #expect(StrokeReference.shared.data(for: "🐸") == nil)
    }

    @Test func emptyStringReturnsNil() {
        #expect(StrokeReference.shared.data(for: "") == nil)
    }

    @Test func lookupIsCached() {
        // Calling twice for the same glyph should return identical data.
        let first = StrokeReference.shared.data(for: "桜")
        let second = StrokeReference.shared.data(for: "桜")
        #expect(first?.glyph == second?.glyph)
        #expect(first?.strokes.count == second?.strokes.count)
        #expect(first?.medians.count == second?.medians.count)
    }

    @Test func strokeAndMedianCountsMatch() {
        // Every character must have the same number of SVG stroke paths and median arrays.
        guard let data = StrokeReference.shared.data(for: "人") else { return }
        #expect(data.strokes.count == data.medians.count)
    }

    @Test func strokePathsAreNonEmpty() {
        guard let data = StrokeReference.shared.data(for: "日") else { return }
        for stroke in data.strokes {
            #expect(!stroke.isEmpty, "Found an empty SVG path string for 日")
        }
    }

    @Test func mediansHaveAtLeastTwoPoints() {
        guard let data = StrokeReference.shared.data(for: "月") else { return }
        for (i, median) in data.medians.enumerated() {
            #expect(median.count >= 2, "Stroke \(i) of 月 has fewer than 2 median points")
        }
    }
}

// MARK: - StrokePoint Codable

struct StrokePointCodableTests {

    @Test func decodesFromArrayFormat() throws {
        let json = "[300.0, 450.5]".data(using: .utf8)!
        let point = try JSONDecoder().decode(StrokePoint.self, from: json)
        #expect(point.x == 300.0)
        #expect(point.y == 450.5)
    }

    @Test func encodesToArrayFormat() throws {
        let point = StrokePoint(x: 100, y: 200)
        let data = try JSONEncoder().encode(point)
        let decoded = try JSONDecoder().decode([Double].self, from: data)
        #expect(decoded.count == 2)
        #expect(decoded[0] == 100)
        #expect(decoded[1] == 200)
    }

    @Test func roundTripPreservesValues() throws {
        let original = StrokePoint(x: 512.5, y: 123.75)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StrokePoint.self, from: data)
        #expect(original.x == decoded.x)
        #expect(original.y == decoded.y)
    }

    @Test func decodeArrayOfStrokePoints() throws {
        // Medians are stored as [[StrokePoint]], so nested array decoding must work.
        let json = "[[10.0, 20.0], [30.0, 40.0]]".data(using: .utf8)!
        let points = try JSONDecoder().decode([StrokePoint].self, from: json)
        #expect(points.count == 2)
        #expect(points[0].x == 10)
        #expect(points[1].y == 40)
    }
}

// MARK: - CharacterModels

struct CharacterModelsTests {

    @Test func accentColorSun() {
        let deck = CharacterDeck(id: "t", lang: .japanese, script: "Japanese",
                                 level: "N5", title: "T", blurb: "", accentName: "sun", chars: [])
        #expect(deck.accentColor == "#9a6a2f")
    }

    @Test func accentColorJade() {
        let deck = CharacterDeck(id: "t", lang: .chinese, script: "Chinese",
                                 level: "HSK1", title: "T", blurb: "", accentName: "jade", chars: [])
        #expect(deck.accentColor == "#1f6f6b")
    }

    @Test func accentColorInkIsVermilion() {
        let deck = CharacterDeck(id: "t", lang: .both, script: "Both",
                                 level: "Foundations", title: "T", blurb: "", accentName: "ink", chars: [])
        #expect(deck.accentColor == "#c8492f")
    }

    @Test func accentColorUnknownNameFallsToDefault() {
        let deck = CharacterDeck(id: "t", lang: .japanese, script: "Japanese",
                                 level: "N5", title: "T", blurb: "", accentName: "purple", chars: [])
        #expect(deck.accentColor == "#c8492f")
    }

    @Test func characterItemIDMatchesGlyph() {
        let item = CharacterItem(glyph: "日", meaning: "sun", reading: "ニチ")
        #expect(item.id == "日")
    }

    @Test func seedDataDecksAreNonEmpty() {
        #expect(!SeedData.decks.isEmpty)
    }

    @Test func seedDataAllDecksHaveCharacters() {
        for deck in SeedData.decks {
            #expect(!deck.chars.isEmpty, "Deck '\(deck.id)' has no characters")
        }
    }

    @Test func seedDataDeckIDsAreUnique() {
        let ids = SeedData.decks.map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}

// MARK: - CharacterProgress

struct CharacterProgressTests {

    @Test func accuracyWithNoPracticeIsZero() {
        let progress = CharacterProgress(glyph: "日")
        #expect(progress.accuracyPercentage == 0)
    }

    @Test func accuracyFullyFlawlessIs100() {
        let progress = CharacterProgress(glyph: "月", timesPracticed: 10, timesFlawless: 10)
        #expect(progress.accuracyPercentage == 100)
    }

    @Test func accuracyPartialCalculation() {
        // 2 flawless out of 5 = 40%.
        let progress = CharacterProgress(glyph: "火", timesPracticed: 5, timesFlawless: 2)
        #expect(progress.accuracyPercentage == 40)
    }

    @Test func accuracyNeverExceeds100() {
        // Defensive: timesFlawless somehow > timesPracticed at the model layer.
        let progress = CharacterProgress(glyph: "水", timesPracticed: 5, timesFlawless: 10)
        #expect(progress.accuracyPercentage <= 100)
    }

    @Test func recordFlawlessAttemptIncrementsAllCounters() {
        let progress = CharacterProgress(glyph: "木")
        progress.recordAttempt(mistakes: 0)
        #expect(progress.timesPracticed == 1)
        #expect(progress.timesFlawless == 1)
        #expect(progress.totalMistakes == 0)
    }

    @Test func recordAttemptWithMistakesDoesNotIncrementFlawless() {
        let progress = CharacterProgress(glyph: "金")
        progress.recordAttempt(mistakes: 3)
        #expect(progress.timesPracticed == 1)
        #expect(progress.timesFlawless == 0)
        #expect(progress.totalMistakes == 3)
    }

    @Test func recordAttemptAccumulatesAcrossMultipleSessions() {
        let progress = CharacterProgress(glyph: "土")
        progress.recordAttempt(mistakes: 0)
        progress.recordAttempt(mistakes: 2)
        progress.recordAttempt(mistakes: 0)
        #expect(progress.timesPracticed == 3)
        #expect(progress.timesFlawless == 2)
        #expect(progress.totalMistakes == 2)
    }

    @Test func masteryLevelUnpracticedWhenZeroPractice() {
        #expect(CharacterProgress(glyph: "山").masteryLevel() == .unpracticed)
    }

    @Test func masteryLevelLearningBelowHalfThreshold() {
        // With threshold=10, below 5 (threshold/2) is .learning.
        #expect(CharacterProgress(glyph: "川", timesPracticed: 2).masteryLevel() == .learning)
    }

    @Test func masteryLevelProficientAtHalfThreshold() {
        // Exactly at threshold/2 (5) transitions from .learning to .proficient.
        #expect(CharacterProgress(glyph: "人", timesPracticed: 5).masteryLevel() == .proficient)
    }

    @Test func masteryLevelProficientBelowThreshold() {
        #expect(CharacterProgress(glyph: "大", timesPracticed: 7).masteryLevel() == .proficient)
    }

    @Test func masteryLevelMasteredAtThreshold() {
        #expect(CharacterProgress(glyph: "中", timesPracticed: 10).masteryLevel() == .mastered)
    }

    @Test func masteryLevelMasteredAboveThreshold() {
        #expect(CharacterProgress(glyph: "国", timesPracticed: 25).masteryLevel() == .mastered)
    }

    @Test func masteryLevelCustomThreshold() {
        let progress = CharacterProgress(glyph: "学", timesPracticed: 4)
        #expect(progress.masteryLevel(threshold: 5) == .proficient) // 4 >= max(1,2)=2
        #expect(progress.masteryLevel(threshold: 4) == .mastered)   // 4 >= 4
    }

    @Test func isMasteredFalseBeforeThreshold() {
        #expect(CharacterProgress(glyph: "好", timesPracticed: 9).isMastered() == false)
    }

    @Test func isMasteredTrueAtThreshold() {
        #expect(CharacterProgress(glyph: "你", timesPracticed: 10).isMastered() == true)
    }

    @Test func isMasteredCustomThreshold() {
        let progress = CharacterProgress(glyph: "我", timesPracticed: 5)
        #expect(progress.isMastered(threshold: 5) == true)
        #expect(progress.isMastered(threshold: 6) == false)
    }
}

// MARK: - Design tokens (adaptive color)

struct DesignTokenTests {

    /// The primary ink must resolve to genuinely different colors in light vs
    /// dark — this is the load-bearing guarantee of the whole dark-mode system.
    @Test func inkResolvesDifferentlyPerAppearance() {
        let light = InkTheme.inkUI.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark  = InkTheme.inkUI.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        #expect(light != dark)
    }

    /// A flat (non-dynamic) color built from a hex string resolves to the same
    /// value regardless of appearance, proving `inkAdaptive` is what supplies
    /// the per-trait behavior — not some accident of the bridging.
    @Test func staticHexColorIsAppearanceIndependent() {
        let flat = UIColor(Color(hex: "#c8492f"))
        let light = flat.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark  = flat.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        #expect(light == dark)
    }

    @Test func appearanceColorSchemeMapping() {
        #expect(AppAppearance.system.colorScheme == nil)
        #expect(AppAppearance.light.colorScheme == .light)
        #expect(AppAppearance.dark.colorScheme == .dark)
    }

    @Test func appearanceStoredRawValueFallsBackToDefault() {
        #expect(AppAppearance(storedRawValue: "not-a-real-value") == AppSettings.defaultAppearance)
        #expect(AppAppearance(storedRawValue: "dark") == .dark)
        #expect(AppAppearance(storedRawValue: "light") == .light)
    }

    /// The adaptive deck accent maps each `accentName` to the matching
    /// appearance-aware `InkTheme` token (so deck colors brighten in Dark Mode),
    /// while the legacy `accentColor` hex string stays fixed for compatibility.
    @Test func deckAccentMapsToAdaptiveToken() {
        func deck(_ name: String) -> CharacterDeck {
            CharacterDeck(id: "t", lang: .both, script: "", level: "",
                          title: "", blurb: "", accentName: name, chars: [])
        }
        #expect(deck("sun").accent == InkTheme.sun)
        #expect(deck("jade").accent == InkTheme.jade)
        #expect(deck("ink").accent == InkTheme.accent)
        #expect(deck("anything-else").accent == InkTheme.accent)
    }
}
