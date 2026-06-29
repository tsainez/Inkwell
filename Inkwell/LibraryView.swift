//
//  LibraryView.swift
//  Inkwell
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query private var progressList: [CharacterProgress]
    let decks: [CharacterDeck]
    let progress: [String: Int] // Deck ID to count completed
    let onSelectDeck: (CharacterDeck) -> Void
    let onOpenTable: () -> Void
    let onOpenSettings: () -> Void
    
    @State private var customInput: String = ""
    private let suggestions = ["愛", "夢", "桜", "山川", "一期一会", "謝謝"]
    
    private var totalPracticedCount: Int {
        let countFromSwiftData = progressList.reduce(0) { $0 + $1.timesPracticed }
        let countFromLegacy = progress.values.reduce(0, +)
        return max(countFromSwiftData, countFromLegacy)
    }
    
    private var avgAccuracyPct: Int {
        guard !progressList.isEmpty else { return 92 }
        let total = progressList.reduce(0) { $0 + $1.accuracyPercentage }
        return total / progressList.count
    }

    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "GOOD MORNING"
        case 12..<17: return "GOOD AFTERNOON"
        case 17..<21: return "GOOD EVENING"
        default:      return "GOOD NIGHT"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        SealView(size: 38)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Inkwell")
                                .font(.inkSerif(size: 26, weight: .bold))
                                .foregroundColor(InkTheme.ink)
                            Text("stroke order, by hand")
                                .font(.inkSans(size: 13))
                                .foregroundColor(InkTheme.ink3)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: onOpenTable) {
                            HStack(spacing: 6) {
                                Image(systemName: "tablecells.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(InkTheme.accent)
                                Text("Mastery Table")
                                    .font(.inkSans(size: 14, weight: .semibold))
                                    .foregroundColor(InkTheme.ink)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(InkTheme.card)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(InkTheme.line, lineWidth: 1.5))
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(InkTheme.accent)
                            Text("4 day streak")
                                .font(.inkSans(size: 14, weight: .semibold))
                                .foregroundColor(InkTheme.ink)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().stroke(InkTheme.line, lineWidth: 1.5))

                        Button(action: onOpenSettings) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16))
                                .foregroundColor(InkTheme.ink)
                                .frame(width: 38, height: 38)
                                .background(InkTheme.card)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(InkTheme.line, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Settings")
                    }
                }
                
                // Hero Grid (2-column layout for iPad)
                HStack(alignment: .top, spacing: 40) {
                    // Left Hero Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text(timeBasedGreeting)
                            .font(.inkSans(size: 13, weight: .bold))
                            .foregroundColor(InkTheme.accent)
                            .tracking(1.5)
                        
                        Text("What will you write today?")
                            .font(.inkSerif(size: 42, weight: .regular))
                            .foregroundColor(InkTheme.ink)
                            .lineSpacing(4)
                        
                        Spacer().frame(height: 12)
                        
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(totalPracticedCount)")
                                    .font(.inkSerif(size: 34, weight: .bold))
                                    .foregroundColor(InkTheme.ink)
                                Text("characters practiced")
                                    .font(.inkSans(size: 13))
                                    .foregroundColor(InkTheme.ink2)
                            }
                            
                            Rectangle()
                                .fill(InkTheme.line)
                                .frame(width: 1, height: 38)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(decks.count)")
                                    .font(.inkSerif(size: 34, weight: .bold))
                                    .foregroundColor(InkTheme.ink)
                                Text("decks available")
                                    .font(.inkSans(size: 13))
                                    .foregroundColor(InkTheme.ink2)
                            }
                            
                            Rectangle()
                                .fill(InkTheme.line)
                                .frame(width: 1, height: 38)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                (Text("\(avgAccuracyPct)")
                                    .font(.inkSerif(size: 34, weight: .bold))
                                + Text("%")
                                    .font(.inkSerif(size: 20, weight: .bold)))
                                .foregroundColor(InkTheme.ink)
                                .lineLimit(1)

                                Text("avg. accuracy")
                                    .font(.inkSans(size: 13))
                                    .foregroundColor(InkTheme.ink2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Right Custom Practice Panel
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 14))
                                .foregroundColor(InkTheme.accent)
                            Text("PRACTICE ANYTHING")
                                .font(.inkSans(size: 12, weight: .bold))
                                .foregroundColor(InkTheme.accent)
                                .tracking(1.2)
                        }
                        
                        Text("Search a single character, or paste a word or sentence to write it out — one character at a time.")
                            .font(.inkSans(size: 13))
                            .foregroundColor(InkTheme.ink2)
                            .lineSpacing(2)
                        
                        HStack(spacing: 8) {
                            TextField("Type or paste 漢字…", text: $customInput)
                                .font(.inkSerif(size: 18))
                                .padding(.horizontal, 14)
                                .frame(height: 46)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(InkTheme.line, lineWidth: 1))
                            
                            Button(action: startCustomPractice) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 46, height: 46)
                                    .background(InkTheme.ink)
                                    .cornerRadius(10)
                            }
                            .disabled(buildCustomDeck() == nil)
                            .opacity(buildCustomDeck() == nil ? 0.4 : 1.0)
                        }
                        
                        HStack(spacing: 8) {
                            if let deck = buildCustomDeck() {
                                Text("\(deck.chars.count) character\(deck.chars.count == 1 ? "" : "s")")
                                    .font(.inkSans(size: 12, weight: .medium))
                                    .foregroundColor(InkTheme.accent)
                            } else {
                                Text("Tries:")
                                    .font(.inkSans(size: 12))
                                    .foregroundColor(InkTheme.ink3)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(suggestions, id: \.self) { item in
                                        Button(action: { customInput = item }) {
                                            Text(item)
                                                .font(.inkSerif(size: 14))
                                                .foregroundColor(InkTheme.ink)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(InkTheme.line2)
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(22)
                    .frame(width: 380)
                    .background(InkTheme.card)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(InkTheme.line, lineWidth: 1))
                }
                .padding(.bottom, 16)
                
                Divider()
                    .background(InkTheme.line)

                // Character of the Day
                CharacterOfTheDayWidget(decks: decks, onPractice: onSelectDeck)

                // Deck Grid
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 22), GridItem(.flexible(), spacing: 22), GridItem(.flexible(), spacing: 22)], spacing: 22) {
                    ForEach(decks) { deck in
                        DeckCardView(deck: deck, completedCount: progress[deck.id] ?? 0) {
                            onSelectDeck(deck)
                        }
                    }
                }
            }
            .padding(44)
        }
        .background(InkTheme.paper.ignoresSafeArea())
    }
    
    private func buildCustomDeck() -> CharacterDeck? {
        let cjk = customInput.filter { ch in
            guard let scalar = ch.unicodeScalars.first else { return false }
            return (0x3400...0x9FFF).contains(scalar.value) || (0xF900...0xFAFF).contains(scalar.value)
        }
        guard !cjk.isEmpty else { return nil }
        return CharacterDeck(
            id: "custom",
            lang: .both,
            script: "Custom",
            level: "Your input",
            title: cjk.count > 1 ? "Phrase practice" : "Custom character",
            blurb: "Ad-hoc practice session for typed characters.",
            accentName: "vermilion",
            chars: cjk.map { CharacterItem(glyph: String($0), meaning: "Custom", reading: "") }
        )
    }
    
    private func startCustomPractice() {
        if let deck = buildCustomDeck() {
            onSelectDeck(deck)
        }
    }
}

// MARK: - Character of the Day

struct CharacterOfTheDayWidget: View {
    let decks: [CharacterDeck]
    let onPractice: (CharacterDeck) -> Void

    private var todaysPick: (item: CharacterItem, deck: CharacterDeck)? {
        let allPairs = decks.flatMap { deck in deck.chars.map { (item: $0, deck: deck) } }
        guard !allPairs.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let idx = (dayOfYear - 1) % allPairs.count
        return allPairs[idx]
    }

    var body: some View {
        guard let pick = todaysPick else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 20) {
                // Section label
                HStack(spacing: 6) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(InkTheme.accent)
                    Text("CHARACTER OF THE DAY")
                        .font(.inkSans(size: 12, weight: .bold))
                        .foregroundColor(InkTheme.accent)
                        .tracking(1.4)
                }

                HStack(alignment: .center, spacing: 40) {
                    // Large character display
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(InkTheme.paper)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(InkTheme.line, lineWidth: 1.5))
                        Text(pick.item.glyph)
                            .font(.inkSerif(size: 96, weight: .regular))
                            .foregroundColor(InkTheme.ink)
                    }
                    .frame(width: 160, height: 160)

                    // Details
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(pick.item.meaning.uppercased())
                                .font(.inkSans(size: 11, weight: .bold))
                                .foregroundColor(InkTheme.ink3)
                                .tracking(1.2)
                            Text(pick.item.meaning)
                                .font(.inkSerif(size: 28, weight: .regular))
                                .foregroundColor(InkTheme.ink)
                            Text(pick.item.reading)
                                .font(.inkSans(size: 16))
                                .foregroundColor(InkTheme.ink2)
                        }

                        HStack(spacing: 8) {
                            Text("\(pick.deck.script.uppercased())  ·  \(pick.deck.level.uppercased())")
                                .font(.inkSans(size: 11, weight: .semibold))
                                .foregroundColor(InkTheme.ink3)
                                .tracking(1.0)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(InkTheme.line2)
                                .cornerRadius(6)
                        }

                        Button(action: {
                            let singleCharDeck = CharacterDeck(
                                id: "cotd-\(pick.item.glyph)",
                                lang: pick.deck.lang,
                                script: pick.deck.script,
                                level: pick.deck.level,
                                title: pick.item.glyph,
                                blurb: pick.item.meaning,
                                accentName: pick.deck.accentName,
                                chars: [pick.item]
                            )
                            onPractice(singleCharDeck)
                        }) {
                            HStack(spacing: 8) {
                                Text("Practice this character")
                                    .font(.inkSans(size: 14, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(InkTheme.ink)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Spacer()

                    // Decorative oversized character
                    Text(pick.item.glyph)
                        .font(.inkSerif(size: 220, weight: .regular))
                        .foregroundColor(InkTheme.line2)
                        .allowsHitTesting(false)
                        .clipped()
                }
            }
            .padding(32)
            .background(InkTheme.card)
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(InkTheme.line, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 4)
            .clipped()
        )
    }
}

// MARK: - Deck Card

struct DeckCardView: View {
    let deck: CharacterDeck
    let completedCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("\(deck.script.uppercased()) · \(deck.level.uppercased())")
                        .font(.inkSans(size: 11, weight: .bold))
                        .foregroundColor(InkTheme.ink3)
                        .tracking(1.0)
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(Array(deck.chars.prefix(3).enumerated()), id: \.offset) { idx, item in
                            Text(item.glyph)
                                .font(.inkSerif(size: 24))
                                .foregroundColor(InkTheme.ink)
                                .opacity(1.0 - Double(idx) * 0.3)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(deck.title)
                        .font(.inkSerif(size: 24, weight: .bold))
                        .foregroundColor(InkTheme.ink)
                    
                    Text(deck.blurb)
                        .font(.inkSans(size: 14))
                        .foregroundColor(InkTheme.ink2)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(InkTheme.line2)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(hex: deck.accentColor))
                                    .frame(width: geo.size.width * CGFloat(completedCount) / CGFloat(max(deck.chars.count, 1)))
                            }
                        }
                        .frame(height: 6)
                        
                        Text("\(completedCount)/\(deck.chars.count)")
                            .font(.inkSans(size: 12, weight: .semibold))
                            .foregroundColor(InkTheme.ink3)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color(hex: deck.accentColor))
                        .clipShape(Circle())
                }
            }
            .padding(24)
            .frame(height: 230)
            .background(InkTheme.card)
            .cornerRadius(20)
            .overlay(
                HStack {
                    Rectangle()
                        .fill(Color(hex: deck.accentColor))
                        .frame(width: 5)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            )
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(InkTheme.line, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
