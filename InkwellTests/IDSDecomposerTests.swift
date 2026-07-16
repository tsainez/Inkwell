import Testing
import CoreGraphics
import Foundation
@testable import Inkwell

struct IDSDecomposerTests {

    private func mockLookup(glyph: String) -> CharacterStrokeData? {
        let dummyMedians = [[StrokePoint(x: 0, y: 0), StrokePoint(x: 1024, y: 900)]]
        return CharacterStrokeData(glyph: glyph, strokes: [], medians: dummyMedians)
    }

    @Test func synthesizeReturnsNilForUnknownGlyph() async throws {
        let result = IDSDecomposer.synthesize(glyph: "XYZ", lookup: mockLookup)
        #expect(result == nil)
    }

    @Test func synthesizeReturnsNilIfLookupFails() async throws {
        // "鵣" requires "束" and "鳥"
        let result = IDSDecomposer.synthesize(glyph: "鵣") { _ in return nil }
        #expect(result == nil)
    }

    @Test func synthesizeLROperator() async throws {
        // "鵣" is "lr" with "束" and "鳥"
        let result = IDSDecomposer.synthesize(glyph: "鵣", lookup: mockLookup)
        #expect(result != nil)

        let medians = result?.medians ?? []
        #expect(medians.count == 2)

        // First part ("束"), left half: x_out = x_in * 0.5 (xOff = 0)
        let partA = medians[0]
        #expect(abs(partA[0].x - 0.0) < 0.001)
        #expect(abs(partA[0].y - 0.0) < 0.001)
        #expect(abs(partA[1].x - 512.0) < 0.001)
        #expect(abs(partA[1].y - 900.0) < 0.001)

        // Second part ("鳥"), right half: x_out = 512 + x_in * 0.5
        let partB = medians[1]
        #expect(abs(partB[0].x - 512.0) < 0.001)
        #expect(abs(partB[0].y - 0.0) < 0.001)
        #expect(abs(partB[1].x - 1024.0) < 0.001)
        #expect(abs(partB[1].y - 900.0) < 0.001)

        let strokes = result?.strokes ?? []
        #expect(strokes.count == 2)
        #expect(strokes[0] == "M 0.0,0.0 L 512.0,900.0")
        #expect(strokes[1] == "M 512.0,0.0 L 1024.0,900.0")

        #expect(result?.source == .synthesized)
    }

    @Test func synthesizeTBOperator() async throws {
        // "鵥" is "tb" with "判" and "鳥"
        let result = IDSDecomposer.synthesize(glyph: "鵥", lookup: mockLookup)
        #expect(result != nil)

        let medians = result?.medians ?? []
        #expect(medians.count == 2)

        // First part ("判"), top half: y_out = 450 + y_in * 0.5
        let partA = medians[0]
        #expect(abs(partA[0].x - 0.0) < 0.001)
        #expect(abs(partA[0].y - 450.0) < 0.001)
        #expect(abs(partA[1].x - 1024.0) < 0.001)
        #expect(abs(partA[1].y - 900.0) < 0.001)

        // Second part ("鳥"), bottom half: y_out = y_in * 0.5
        let partB = medians[1]
        #expect(abs(partB[0].x - 0.0) < 0.001)
        #expect(abs(partB[0].y - 0.0) < 0.001)
        #expect(abs(partB[1].x - 1024.0) < 0.001)
        #expect(abs(partB[1].y - 450.0) < 0.001)

        let strokes = result?.strokes ?? []
        #expect(strokes.count == 2)
        #expect(strokes[0] == "M 0.0,450.0 L 1024.0,900.0")
        #expect(strokes[1] == "M 0.0,0.0 L 1024.0,450.0")
    }

    @Test func synthesizeEmptyMedians() async throws {
        // Test with empty medians from lookup
        let emptyLookup: (String) -> CharacterStrokeData? = { glyph in
            return CharacterStrokeData(glyph: glyph, strokes: [], medians: [[]])
        }
        let result = IDSDecomposer.synthesize(glyph: "鵣", lookup: emptyLookup)
        #expect(result != nil)

        let medians = result?.medians ?? []
        #expect(medians.count == 2)
        #expect(medians[0].isEmpty)
        #expect(medians[1].isEmpty)

        let strokes = result?.strokes ?? []
        #expect(strokes.count == 2)
        #expect(strokes[0] == "")
        #expect(strokes[1] == "")
    }
}
