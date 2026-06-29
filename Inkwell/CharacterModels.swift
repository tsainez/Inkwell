//
//  CharacterModels.swift
//  Inkwell
//

import Foundation

struct CharacterItem: Identifiable, Codable, Hashable {
    var id: String { glyph }
    let glyph: String
    let meaning: String
    let reading: String
}

enum ScriptLanguage: String, Codable {
    case japanese = "ja"
    case chinese = "zh"
    case both = "both"
}

struct CharacterDeck: Identifiable, Codable, Hashable {
    let id: String
    let lang: ScriptLanguage
    let script: String
    let level: String
    let title: String
    let blurb: String
    let accentName: String
    let chars: [CharacterItem]
    
    var accentColor: String {
        switch accentName {
        case "sun": return "#9a6a2f"
        case "jade": return "#1f6f6b"
        default: return "#c8492f" // vermilion / ink
        }
    }
}

// MARK: - Stroke data source

/// Indicates whether stroke data came directly from the reference database or was
/// synthesized by IDSDecomposer from component glyphs. Synthesized data uses
/// approximate medians, so the grader applies wider tolerances for it.
enum StrokeDataSource: String, Codable {
    case reference
    case synthesized
}

// MARK: - Stroke geometry

struct StrokePoint: Codable, Hashable {
    let x: Double
    let y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(), let arr = try? container.decode([Double].self), arr.count >= 2 {
            self.x = arr[0]
            self.y = arr[1]
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.x = try container.decode(Double.self, forKey: .x)
            self.y = try container.decode(Double.self, forKey: .y)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }

    private enum CodingKeys: String, CodingKey {
        case x, y
    }
}

struct CharacterStrokeData: Codable {
    let glyph: String
    let strokes: [String]           // SVG path strings (or median-derived paths for synthesized data)
    let medians: [[StrokePoint]]    // Centerline points per stroke, in 1024 × 900 glyph-box space
    let source: StrokeDataSource    // .reference (DB) or .synthesized (IDS decomposition)

    // Memberwise init with a default source so existing call sites stay unchanged.
    init(glyph: String, strokes: [String], medians: [[StrokePoint]],
         source: StrokeDataSource = .reference) {
        self.glyph   = glyph
        self.strokes = strokes
        self.medians = medians
        self.source  = source
    }

    // Custom decoder so old JSON without a "source" field decodes as .reference.
    init(from decoder: Decoder) throws {
        let c      = try decoder.container(keyedBy: CodingKeys.self)
        glyph      = try c.decode(String.self, forKey: .glyph)
        strokes    = try c.decode([String].self, forKey: .strokes)
        medians    = try c.decode([[StrokePoint]].self, forKey: .medians)
        source     = try c.decodeIfPresent(StrokeDataSource.self, forKey: .source) ?? .reference
    }

    private enum CodingKeys: String, CodingKey { case glyph, strokes, medians, source }
}

struct SeedData {
    static let decks: [CharacterDeck] = [
        CharacterDeck(
            id: "jp-n5",
            lang: .japanese,
            script: "Japanese",
            level: "JLPT N5",
            title: "First Kanji",
            blurb: "The everyday kanji behind days of the week, nature, and people.",
            accentName: "sun",
            chars: [
                CharacterItem(glyph: "日", meaning: "sun · day", reading: "ニチ / ひ"),
                CharacterItem(glyph: "月", meaning: "moon · month", reading: "ゲツ / つき"),
                CharacterItem(glyph: "火", meaning: "fire", reading: "カ / ひ"),
                CharacterItem(glyph: "水", meaning: "water", reading: "スイ / みず"),
                CharacterItem(glyph: "木", meaning: "tree · wood", reading: "モク / き"),
                CharacterItem(glyph: "金", meaning: "gold · money", reading: "キン / かね"),
                CharacterItem(glyph: "土", meaning: "earth · soil", reading: "ド / つち"),
                CharacterItem(glyph: "山", meaning: "mountain", reading: "サン / やま"),
                CharacterItem(glyph: "川", meaning: "river", reading: "セン / かわ"),
                CharacterItem(glyph: "人", meaning: "person", reading: "ジン / ひと")
            ]
        ),
        CharacterDeck(
            id: "zh-hsk1",
            lang: .chinese,
            script: "Chinese",
            level: "HSK 1",
            title: "Essentials",
            blurb: "Your first ten characters — enough to greet someone and introduce yourself.",
            accentName: "ink",
            chars: [
                CharacterItem(glyph: "你", meaning: "you", reading: "nǐ"),
                CharacterItem(glyph: "好", meaning: "good · well", reading: "hǎo"),
                CharacterItem(glyph: "我", meaning: "I · me", reading: "wǒ"),
                CharacterItem(glyph: "是", meaning: "to be", reading: "shì"),
                CharacterItem(glyph: "不", meaning: "not · no", reading: "bù"),
                CharacterItem(glyph: "中", meaning: "middle · center", reading: "zhōng"),
                CharacterItem(glyph: "国", meaning: "country", reading: "guó"),
                CharacterItem(glyph: "学", meaning: "to study", reading: "xué"),
                CharacterItem(glyph: "人", meaning: "person", reading: "rén"),
                CharacterItem(glyph: "大", meaning: "big · large", reading: "dà")
            ]
        ),
        CharacterDeck(
            id: "numbers",
            lang: .both,
            script: "Chinese · Japanese",
            level: "Foundations",
            title: "Numbers 一–十",
            blurb: "One through ten — shared across both scripts, the perfect warm-up.",
            accentName: "jade",
            chars: [
                CharacterItem(glyph: "一", meaning: "one", reading: "yī / いち"),
                CharacterItem(glyph: "二", meaning: "two", reading: "èr / に"),
                CharacterItem(glyph: "三", meaning: "three", reading: "sān / さん"),
                CharacterItem(glyph: "四", meaning: "four", reading: "sì / よん"),
                CharacterItem(glyph: "五", meaning: "five", reading: "wǔ / ご"),
                CharacterItem(glyph: "六", meaning: "six", reading: "liù / ろく"),
                CharacterItem(glyph: "七", meaning: "seven", reading: "qī / なな"),
                CharacterItem(glyph: "八", meaning: "eight", reading: "bā / はち"),
                CharacterItem(glyph: "九", meaning: "nine", reading: "jiǔ / きゅう"),
                CharacterItem(glyph: "十", meaning: "ten", reading: "shí / じゅう")
            ]
        )
    ]
}
