import Foundation

// Define mock data
struct CharacterProgress: Identifiable, Equatable {
    var id = UUID()
    var glyph: String
    var timesPracticed: Int
    var accuracyPercentage: Double
    var lastPracticed: Date
    func isMastered(threshold: Int) -> Bool { timesPracticed >= threshold }
}

struct DisplayCharacter: Identifiable, Equatable {
    var id: String { glyph }
    let glyph: String
    let meaning: String
    let reading: String
    let script: String
    let level: String
}

enum FilterOption {
    case all, japanese, chinese, numbers, mastered
}

enum SortOption {
    case mostPracticed, accuracy, lastPracticed
}

let numCharacters = 2000
var progressList = (0..<numCharacters).map { i in
    CharacterProgress(glyph: "char\(i)", timesPracticed: Int.random(in: 0...20), accuracyPercentage: Double.random(in: 0...100), lastPracticed: Date())
}

var allCharacters = (0..<numCharacters).map { i in
    DisplayCharacter(glyph: "char\(i)", meaning: "meaning\(i)", reading: "reading\(i)", script: "Japanese", level: "N5")
}

let masteryTarget = 10
let selectedFilter: FilterOption = .mastered
let selectedSort: SortOption = .mostPracticed
let searchText = ""

var progressMap: [String: CharacterProgress] {
    Dictionary(uniqueKeysWithValues: progressList.map { ($0.glyph, $0) })
}

func testSlow() {
    let _ = allCharacters.filter { item in
        let matchesSearch = true
        guard matchesSearch else { return false }
        switch selectedFilter {
        case .all: return true
        case .japanese: return item.script.contains("Japanese") || item.level.contains("N5")
        case .chinese: return item.script.contains("Chinese") || item.level.contains("HSK")
        case .numbers: return false
        case .mastered:
            let prog = progressMap[item.glyph]
            return prog?.isMastered(threshold: masteryTarget) ?? false
        }
    }.sorted { a, b in
        let progA = progressMap[a.glyph]
        let progB = progressMap[b.glyph]

        switch selectedSort {
        case .mostPracticed:
            return (progA?.timesPracticed ?? 0) > (progB?.timesPracticed ?? 0)
        case .accuracy:
            return (progA?.accuracyPercentage ?? 0) > (progB?.accuracyPercentage ?? 0)
        case .lastPracticed:
            let dateA = progA?.lastPracticed ?? Date.distantPast
            let dateB = progB?.lastPracticed ?? Date.distantPast
            return dateA > dateB
        }
    }
}

func testFast() {
    let currentMap = progressMap
    let _ = allCharacters.filter { item in
        let matchesSearch = true
        guard matchesSearch else { return false }
        switch selectedFilter {
        case .all: return true
        case .japanese: return item.script.contains("Japanese") || item.level.contains("N5")
        case .chinese: return item.script.contains("Chinese") || item.level.contains("HSK")
        case .numbers: return false
        case .mastered:
            let prog = currentMap[item.glyph]
            return prog?.isMastered(threshold: masteryTarget) ?? false
        }
    }.sorted { a, b in
        let progA = currentMap[a.glyph]
        let progB = currentMap[b.glyph]

        switch selectedSort {
        case .mostPracticed:
            return (progA?.timesPracticed ?? 0) > (progB?.timesPracticed ?? 0)
        case .accuracy:
            return (progA?.accuracyPercentage ?? 0) > (progB?.accuracyPercentage ?? 0)
        case .lastPracticed:
            let dateA = progA?.lastPracticed ?? Date.distantPast
            let dateB = progB?.lastPracticed ?? Date.distantPast
            return dateA > dateB
        }
    }
}

let start1 = Date()
testSlow()
let end1 = Date()
print("Slow version took: \(end1.timeIntervalSince(start1)) seconds")

let start2 = Date()
testFast()
let end2 = Date()
print("Fast version took: \(end2.timeIntervalSince(start2)) seconds")
