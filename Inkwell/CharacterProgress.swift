//
//  CharacterProgress.swift
//  Inkwell
//

import Foundation
import SwiftData

enum MasteryLevel: String, CaseIterable {
    case unpracticed = "Unpracticed"
    case learning = "Learning"
    case proficient = "Proficient"
    case mastered = "Mastered"
}

@Model
final class CharacterProgress {
    @Attribute(.unique) var glyph: String
    var timesPracticed: Int
    var timesFlawless: Int
    var totalMistakes: Int
    var firstPracticed: Date
    var lastPracticed: Date
    
    init(
        glyph: String,
        timesPracticed: Int = 0,
        timesFlawless: Int = 0,
        totalMistakes: Int = 0,
        firstPracticed: Date = Date(),
        lastPracticed: Date = Date()
    ) {
        self.glyph = glyph
        self.timesPracticed = timesPracticed
        self.timesFlawless = timesFlawless
        self.totalMistakes = totalMistakes
        self.firstPracticed = firstPracticed
        self.lastPracticed = lastPracticed
    }
    
    var accuracyPercentage: Int {
        guard timesPracticed > 0 else { return 0 }
        let ratio = Double(timesFlawless) / Double(timesPracticed)
        return min(100, max(0, Int(ratio * 100)))
    }
    
    func isMastered(threshold: Int = 10) -> Bool {
        return timesPracticed >= threshold
    }
    
    func masteryLevel(threshold: Int = 10) -> MasteryLevel {
        if timesPracticed <= 0 {
            return .unpracticed
        } else if timesPracticed >= threshold {
            return .mastered
        } else if timesPracticed >= max(1, threshold / 2) {
            return .proficient
        } else {
            return .learning
        }
    }
    
    func recordAttempt(mistakes: Int) {
        timesPracticed += 1
        if mistakes == 0 {
            timesFlawless += 1
        }
        totalMistakes += mistakes
        lastPracticed = Date()
    }
}
