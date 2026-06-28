//
//  SessionCompleteView.swift
//  Inkwell
//

import SwiftUI

struct SessionCompleteView: View {
    let deck: CharacterDeck
    let results: [SessionResultItem]
    let onHome: () -> Void
    let onAgain: () -> Void
    
    var totalWritten: Int { results.count }
    var flawlessCount: Int { results.filter { $0.mistakes == 0 && !$0.skipped }.count }
    var totalMistakes: Int { results.reduce(0) { $0 + $1.mistakes } }
    var accuracyPct: Int { totalWritten > 0 ? Int(Double(flawlessCount) / Double(totalWritten) * 100) : 0 }
    
    var body: some View {
        ZStack {
            InkTheme.paper.ignoresSafeArea()
            
            VStack(spacing: 24) {
                SealView(size: 44)
                
                Text("SESSION COMPLETE")
                    .font(.inkSans(size: 12, weight: .bold))
                    .foregroundColor(InkTheme.accent)
                    .tracking(1.4)
                
                Text(deck.title)
                    .font(.inkSerif(size: 38, weight: .bold))
                    .foregroundColor(InkTheme.ink)
                
                // Glyph Grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(results.enumerated()), id: \.offset) { _, item in
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(item.skipped ? InkTheme.line2 : (item.mistakes == 0 ? InkTheme.accent.opacity(0.08) : InkTheme.card))
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(item.mistakes == 0 && !item.skipped ? InkTheme.accent : InkTheme.line, lineWidth: item.mistakes == 0 && !item.skipped ? 2 : 1)
                                    )
                                
                                Text(item.glyph)
                                    .font(.inkSerif(size: 30))
                                    .foregroundColor(item.skipped ? InkTheme.ink3 : InkTheme.ink)
                                    .frame(width: 64, height: 64)
                                
                                if item.mistakes == 0 && !item.skipped {
                                    Circle()
                                        .fill(InkTheme.accent)
                                        .frame(width: 18, height: 18)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                        .offset(x: 4, y: -4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 80)
                
                // Stats Grid
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(totalWritten)")
                            .font(.inkSerif(size: 32, weight: .bold))
                            .foregroundColor(InkTheme.ink)
                        Text("written")
                            .font(.inkSans(size: 12))
                            .foregroundColor(InkTheme.ink2)
                    }
                    .frame(width: 90)
                    
                    VStack(spacing: 4) {
                        Text("\(flawlessCount)")
                            .font(.inkSerif(size: 32, weight: .bold))
                            .foregroundColor(InkTheme.ink)
                        Text("flawless")
                            .font(.inkSans(size: 12))
                            .foregroundColor(InkTheme.ink2)
                    }
                    .frame(width: 90)
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 0) {
                            Text("\(accuracyPct)")
                                .font(.inkSerif(size: 32, weight: .bold))
                            Text("%")
                                .font(.inkSerif(size: 18, weight: .bold))
                        }
                        .foregroundColor(InkTheme.ink)
                        Text("first-try")
                            .font(.inkSans(size: 12))
                            .foregroundColor(InkTheme.ink2)
                    }
                    .frame(width: 90)
                    
                    VStack(spacing: 4) {
                        Text("\(totalMistakes)")
                            .font(.inkSerif(size: 32, weight: .bold))
                            .foregroundColor(InkTheme.ink)
                        Text("corrections")
                            .font(.inkSans(size: 12))
                            .foregroundColor(InkTheme.ink2)
                    }
                    .frame(width: 90)
                }
                .padding(.vertical, 12)
                
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(InkTheme.accent)
                    Text("Streak extended to ")
                        .foregroundColor(InkTheme.ink2) +
                    Text("5 days")
                        .bold()
                        .foregroundColor(InkTheme.ink)
                }
                .font(.inkSans(size: 14))
                
                HStack(spacing: 16) {
                    Button(action: onAgain) {
                        Text("Practice again")
                            .font(.inkSans(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(InkTheme.ink)
                            .cornerRadius(12)
                    }
                    
                    Button(action: onHome) {
                        HStack(spacing: 6) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 14))
                            Text("Library")
                                .font(.inkSans(size: 16, weight: .semibold))
                        }
                        .foregroundColor(InkTheme.ink)
                        .frame(width: 140, height: 50)
                        .background(InkTheme.line2)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(40)
            .frame(width: 560)
            .background(InkTheme.card)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.06), radius: 30, x: 0, y: 12)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(InkTheme.line, lineWidth: 1))
        }
    }
}
