//
//  CharacterTableView.swift
//  Inkwell
//

import SwiftUI
import SwiftData

struct CharacterTableView: View {
    @Query private var progressList: [CharacterProgress]
    let decks: [CharacterDeck]
    let onBack: () -> Void
    let onStartPractice: (CharacterDeck) -> Void
    
    @State private var searchText: String = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedSort: SortOption = .mostPracticed
    @State private var masteryTarget: Int = 10
    
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All Scripts"
        case japanese = "Japanese (N5)"
        case chinese = "Chinese (HSK1)"
        case numbers = "Numbers"
        case mastered = "Mastered Only"
        
        var id: String { rawValue }
    }
    
    enum SortOption: String, CaseIterable, Identifiable {
        case mostPracticed = "Most Practiced"
        case accuracy = "Highest Accuracy"
        case lastPracticed = "Recently Practiced"
        
        var id: String { rawValue }
    }

    private var progressMap: [String: CharacterProgress] {
        Dictionary(uniqueKeysWithValues: progressList.map { ($0.glyph, $0) })
    }
    
    // Combine all standard characters from seed decks + any standalone items
    private var allCharacters: [DisplayCharacter] {
        var items: [DisplayCharacter] = []
        var seen = Set<String>()
        
        for deck in decks {
            for item in deck.chars {
                if !seen.contains(item.glyph) {
                    seen.insert(item.glyph)
                    items.append(DisplayCharacter(
                        glyph: item.glyph,
                        meaning: item.meaning,
                        reading: item.reading,
                        script: deck.script,
                        level: deck.level,
                        deck: deck
                    ))
                }
            }
        }
        
        // Also add any custom practiced characters from SwiftData not in standard decks
        for prog in progressList {
            if !seen.contains(prog.glyph) {
                seen.insert(prog.glyph)
                items.append(DisplayCharacter(
                    glyph: prog.glyph,
                    meaning: "Custom Character",
                    reading: "",
                    script: "Custom",
                    level: "User",
                    deck: nil
                ))
            }
        }
        
        return items
    }
    
    private var filteredCharacters: [DisplayCharacter] {
        let currentMap = progressMap
        return allCharacters.filter { item in
            // Search filter
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                let query = searchText.lowercased()
                matchesSearch = item.glyph.contains(query) ||
                                item.meaning.lowercased().contains(query) ||
                                item.reading.lowercased().contains(query)
            }
            
            guard matchesSearch else { return false }
            
            // Category filter
            switch selectedFilter {
            case .all:
                return true
            case .japanese:
                return item.script.contains("Japanese") || item.level.contains("N5")
            case .chinese:
                return item.script.contains("Chinese") || item.level.contains("HSK")
            case .numbers:
                return item.level.contains("Foundations") || item.meaning.contains("one") || item.meaning.contains("two") || item.meaning.contains("three") || item.meaning.contains("four") || item.meaning.contains("five") || item.meaning.contains("six") || item.meaning.contains("seven") || item.meaning.contains("eight") || item.meaning.contains("nine") || item.meaning.contains("ten")
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
    
    private var totalMasteredCount: Int {
        let currentMap = progressMap
        return allCharacters.filter { item in
            currentMap[item.glyph]?.isMastered(threshold: masteryTarget) ?? false
        }.count
    }
    
    private var totalPracticedAttempts: Int {
        progressList.reduce(0) { $0 + $1.timesPracticed }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    statsAndGoalBanner
                    filterAndSearchControls
                    characterTable
                }
                .padding(40)
            }
        }
        .background(InkTheme.paper.ignoresSafeArea())
    }
    
    // MARK: - Header
    private var headerBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("Decks")
                        .font(.inkSans(size: 15, weight: .medium))
                }
                .foregroundColor(InkTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(InkTheme.card)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(InkTheme.line, lineWidth: 1))
            }
            .accessibilityLabel("Back to Decks")
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("PROGRESS TRACKER")
                    .font(.inkSans(size: 11, weight: .bold))
                    .foregroundColor(InkTheme.accent)
                    .tracking(1.4)
                Text("Character Mastery Table")
                    .font(.inkSerif(size: 22, weight: .bold))
                    .foregroundColor(InkTheme.ink)
            }
            
            Spacer()
            
            // Placeholder spacer to balance layout
            Color.clear.frame(width: 90, height: 36)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 18)
        .background(InkTheme.card)
        .overlay(Rectangle().frame(height: 1).foregroundColor(InkTheme.line), alignment: .bottom)
    }
    
    // MARK: - Stats Banner & Target Goal Selector
    private var statsAndGoalBanner: some View {
        HStack(alignment: .center, spacing: 32) {
            VStack(alignment: .leading, spacing: 6) {
                Text("OVERALL MASTERY")
                    .font(.inkSans(size: 12, weight: .bold))
                    .foregroundColor(InkTheme.accent)
                    .tracking(1.2)
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(totalMasteredCount)")
                        .font(.inkSerif(size: 44, weight: .bold))
                        .foregroundColor(InkTheme.ink)
                    Text("/ \(allCharacters.count) characters mastered")
                        .font(.inkSans(size: 16, weight: .medium))
                        .foregroundColor(InkTheme.ink2)
                }
            }
            
            Spacer()
            
            Rectangle()
                .fill(InkTheme.line)
                .frame(width: 1, height: 50)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("TOTAL PRACTICES")
                    .font(.inkSans(size: 12, weight: .bold))
                    .foregroundColor(InkTheme.ink3)
                    .tracking(1.2)
                
                Text("\(totalPracticedAttempts)")
                    .font(.inkSerif(size: 36, weight: .bold))
                    .foregroundColor(InkTheme.ink)
            }
            
            Spacer()
            
            Rectangle()
                .fill(InkTheme.line)
                .frame(width: 1, height: 50)
            
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .foregroundColor(InkTheme.accent)
                    Text("Mastery Goal Target:")
                        .font(.inkSans(size: 13, weight: .semibold))
                        .foregroundColor(InkTheme.ink)
                }
                
                HStack(spacing: 6) {
                    ForEach([5, 10, 25, 100, 10000], id: \.self) { val in
                        Button(action: { masteryTarget = val }) {
                            Text(val == 10000 ? "10k!" : "\(val)x")
                                .font(.inkSans(size: 12, weight: masteryTarget == val ? .bold : .regular))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(masteryTarget == val ? InkTheme.accent : InkTheme.line2)
                                .foregroundColor(masteryTarget == val ? .white : InkTheme.ink)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(InkTheme.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(InkTheme.line, lineWidth: 1))
    }
    
    // MARK: - Search & Filters
    private var filterAndSearchControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(InkTheme.ink3)
                    TextField("Search glyph, meaning, reading…", text: $searchText)
                        .font(.inkSans(size: 15))
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(InkTheme.ink3)
                        }
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(InkTheme.card)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(InkTheme.line, lineWidth: 1))
                
                Spacer()
                
                // Sort Picker
                HStack(spacing: 8) {
                    Text("Sort:")
                        .font(.inkSans(size: 13, weight: .medium))
                        .foregroundColor(InkTheme.ink2)
                    Picker("Sort", selection: $selectedSort) {
                        ForEach(SortOption.allCases) { opt in
                            Text(opt.rawValue).tag(opt)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(InkTheme.ink)
                    .padding(.horizontal, 8)
                    .frame(height: 44)
                    .background(InkTheme.card)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(InkTheme.line, lineWidth: 1))
                }
            }
            
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FilterOption.allCases) { option in
                        Button(action: { selectedFilter = option }) {
                            Text(option.rawValue)
                                .font(.inkSans(size: 13, weight: selectedFilter == option ? .bold : .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedFilter == option ? InkTheme.ink : InkTheme.card)
                                .foregroundColor(selectedFilter == option ? InkTheme.onInk : InkTheme.ink)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(selectedFilter == option ? Color.clear : InkTheme.line, lineWidth: 1))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Table List
    private var characterTable: some View {
        LazyVStack(spacing: 12) {
            if filteredCharacters.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(InkTheme.ink3)
                    Text("No matching characters found")
                        .font(.inkSerif(size: 18, weight: .bold))
                        .foregroundColor(InkTheme.ink2)
                }
                .frame(maxWidth: .infinity)
                .padding(60)
                .background(InkTheme.card)
                .cornerRadius(16)
            } else {
                ForEach(filteredCharacters) { item in
                    CharacterTableRowView(
                        item: item,
                        progress: progressMap[item.glyph],
                        targetGoal: masteryTarget,
                        onPractice: {
                            if let deck = item.deck {
                                onStartPractice(deck)
                            } else {
                                // Create single character custom deck
                                let customDeck = CharacterDeck(
                                    id: "single-\(item.glyph)",
                                    lang: .both,
                                    script: item.script,
                                    level: item.level,
                                    title: "Practice \(item.glyph)",
                                    blurb: "Targeted single-character session.",
                                    accentName: "vermilion",
                                    chars: [CharacterItem(glyph: item.glyph, meaning: item.meaning, reading: item.reading)]
                                )
                                onStartPractice(customDeck)
                            }
                        }
                    )
                }
            }
        }
    }
}

struct DisplayCharacter: Identifiable {
    var id: String { glyph }
    let glyph: String
    let meaning: String
    let reading: String
    let script: String
    let level: String
    let deck: CharacterDeck?
}

struct CharacterTableRowView: View {
    let item: DisplayCharacter
    let progress: CharacterProgress?
    let targetGoal: Int
    let onPractice: () -> Void
    
    private var timesPracticed: Int { progress?.timesPracticed ?? 0 }
    private var timesFlawless: Int { progress?.timesFlawless ?? 0 }
    private var isMastered: Bool { progress?.isMastered(threshold: targetGoal) ?? false }

    private var progressRatio: Double {
        min(1.0, Double(timesPracticed) / Double(max(1, targetGoal)))
    }

    /// Completion toward the mastery goal, as a whole percentage (e.g. 1 of 10 → 10%).
    private var masteryPct: Int { Int((progressRatio * 100).rounded()) }
    
    var body: some View {
        HStack(spacing: 24) {
            // Character Box
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isMastered ? InkTheme.accent.opacity(0.08) : InkTheme.paper)
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isMastered ? InkTheme.accent : InkTheme.line, lineWidth: isMastered ? 2 : 1)
                    )
                
                Text(item.glyph)
                    .font(.inkSerif(size: 38))
                    .foregroundColor(InkTheme.ink)
            }
            
            // Details Column
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.glyph)
                        .font(.inkSerif(size: 20, weight: .bold))
                        .foregroundColor(InkTheme.ink)
                    
                    Text(item.reading)
                        .font(.inkSans(size: 14))
                        .foregroundColor(InkTheme.ink2)
                    
                    Spacer()
                    
                    Text("\(item.script) · \(item.level)")
                        .font(.inkSans(size: 11, weight: .semibold))
                        .foregroundColor(InkTheme.ink3)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(InkTheme.line2)
                        .cornerRadius(6)
                }
                
                Text(item.meaning)
                    .font(.inkSans(size: 13))
                    .foregroundColor(InkTheme.ink2)
            }
            
            Spacer()
            
            // Stats & Progress Bar Column
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 16) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(timesPracticed) / \(targetGoal) written")
                            .font(.inkSans(size: 13, weight: .semibold))
                            .foregroundColor(InkTheme.ink)
                        Text("\(timesFlawless) flawless runs")
                            .font(.inkSans(size: 11))
                            .foregroundColor(InkTheme.ink3)
                    }
                    
                    if timesPracticed > 0 {
                        Text("\(masteryPct)%")
                            .font(.inkSans(size: 13, weight: .bold))
                            .foregroundColor(isMastered ? InkTheme.jade : (masteryPct >= 50 ? InkTheme.sun : InkTheme.ink2))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                (isMastered ? InkTheme.jade : (masteryPct >= 50 ? InkTheme.sun : InkTheme.ink2))
                                    .opacity(0.12)
                            )
                            .cornerRadius(8)
                    }
                }
                
                // Visual Progress Bar towards mastery goal
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(InkTheme.line2)
                            .frame(height: 6)
                        Capsule()
                            .fill(isMastered ? InkTheme.accent : InkTheme.ink)
                            .frame(width: geo.size.width * CGFloat(progressRatio), height: 6)
                    }
                }
                .frame(width: 180, height: 6)
            }
            
            // Mastery Badge & Action Button
            HStack(spacing: 12) {
                if isMastered {
                    VStack(spacing: 2) {
                        Image(systemName: "seal.fill")
                            .font(.system(size: 22))
                            .foregroundColor(InkTheme.accent)
                        Text("MASTERED")
                            .font(.inkSans(size: 9, weight: .bold))
                            .foregroundColor(InkTheme.accent)
                            .tracking(0.8)
                    }
                    .frame(width: 60)
                } else {
                    Color.clear.frame(width: 60)
                }
                
                Button(action: onPractice) {
                    Text("Practice")
                        .font(.inkSans(size: 13, weight: .semibold))
                        .foregroundColor(InkTheme.onInk)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(InkTheme.ink)
                        .cornerRadius(8)
                }
                .accessibilityLabel("Practice \(item.glyph)")
            }
        }
        .padding(18)
        .background(InkTheme.card)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(InkTheme.line, lineWidth: 1))
    }
}
