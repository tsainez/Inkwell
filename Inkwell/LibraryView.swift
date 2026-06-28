//
//  LibraryView.swift
//  Inkwell
//

import SwiftUI

struct LibraryView: View {
    let decks: [CharacterDeck]
    let progress: [String: Int] // Deck ID to count completed
    let onSelectDeck: (CharacterDeck) -> Void
    
    @State private var customInput: String = ""
    private let suggestions = ["愛", "夢", "桜", "山川", "一期一会", "謝謝"]
    
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
                }
                
                // Hero Grid (2-column layout for iPad)
                HStack(alignment: .top, spacing: 40) {
                    // Left Hero Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("GOOD EVENING")
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
                                Text("\(progress.values.reduce(0, +))")
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
                                HStack(spacing: 0) {
                                    Text("92")
                                        .font(.inkSerif(size: 34, weight: .bold))
                                    Text("%")
                                        .font(.inkSerif(size: 20, weight: .bold))
                                }
                                .foregroundColor(InkTheme.ink)
                                
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
