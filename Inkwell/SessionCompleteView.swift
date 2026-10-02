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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Drives the staggered entrance: everything animates in against this one
    /// flag, each row with its own delay.
    @State private var appeared = false

    var totalWritten: Int { results.count }
    var flawlessCount: Int { results.filter { $0.mistakes == 0 && !$0.skipped }.count }
    var totalMistakes: Int { results.reduce(0) { $0 + $1.mistakes } }
    var accuracyPct: Int { totalWritten > 0 ? Int(Double(flawlessCount) / Double(totalWritten) * 100) : 0 }

    var body: some View {
        ZStack {
            InkTheme.paper.ignoresSafeArea()

            VStack(spacing: 24) {
                SealView(size: 44)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.4)
                    .rotationEffect(.degrees(appeared || reduceMotion ? 0 : -14))
                    .modifier(EntranceModifier(shown: appeared, delay: 0, reduceMotion: reduceMotion))

                Text("SESSION COMPLETE")
                    .font(.inkSans(size: 12, weight: .bold))
                    .foregroundColor(InkTheme.accent)
                    .tracking(1.4)
                    .modifier(EntranceModifier(shown: appeared, delay: 0.08, reduceMotion: reduceMotion))

                Text(deck.title)
                    .font(.inkSerif(size: 38, weight: .bold))
                    .foregroundColor(InkTheme.ink)
                    .modifier(EntranceModifier(shown: appeared, delay: 0.14, reduceMotion: reduceMotion))

                // Glyph Grid
                GlyphGrid(results: results)
                    .modifier(EntranceModifier(shown: appeared, delay: 0.22, reduceMotion: reduceMotion))

                // Stats Grid
                StatsGrid(totalWritten: totalWritten, flawlessCount: flawlessCount, accuracyPct: accuracyPct, totalMistakes: totalMistakes)
                    .modifier(EntranceModifier(shown: appeared, delay: 0.3, reduceMotion: reduceMotion))

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
                .modifier(EntranceModifier(shown: appeared, delay: 0.38, reduceMotion: reduceMotion))

                ActionButtons(onAgain: onAgain, onHome: onHome)
                    .modifier(EntranceModifier(shown: appeared, delay: 0.46, reduceMotion: reduceMotion))
            }
            .padding(40)
            .frame(width: 560)
            .background(InkTheme.card)
            .cornerRadius(24)
            .shadow(color: InkTheme.shadow, radius: 30, x: 0, y: 12)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(InkTheme.line, lineWidth: 1))
        }
        .onAppear {
            appeared = true
            SoundEffects.shared.play(.sessionComplete)
        }
    }
}

private struct GlyphGrid: View {
    let results: [SessionResultItem]

    var body: some View {
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
    }
}

private struct StatView: View {
    let value: String
    let label: String
    var isPercentage: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            if isPercentage {
                HStack(spacing: 0) {
                    Text(value)
                        .font(.inkSerif(size: 32, weight: .bold))
                    Text("%")
                        .font(.inkSerif(size: 18, weight: .bold))
                }
                .foregroundColor(InkTheme.ink)
            } else {
                Text(value)
                    .font(.inkSerif(size: 32, weight: .bold))
                    .foregroundColor(InkTheme.ink)
            }
            Text(label)
                .font(.inkSans(size: 12))
                .foregroundColor(InkTheme.ink2)
        }
        .frame(width: 90)
    }
}

private struct StatsGrid: View {
    let totalWritten: Int
    let flawlessCount: Int
    let accuracyPct: Int
    let totalMistakes: Int

    var body: some View {
        HStack(spacing: 24) {
            StatView(value: "\(totalWritten)", label: "written")
            StatView(value: "\(flawlessCount)", label: "flawless")
            StatView(value: "\(accuracyPct)", label: "first-try", isPercentage: true)
            StatView(value: "\(totalMistakes)", label: "corrections")
        }
        .padding(.vertical, 12)
    }
}

private struct ActionButtons: View {
    let onAgain: () -> Void
    let onHome: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onAgain) {
                Text("Practice again")
                    .font(.inkSans(size: 16, weight: .bold))
                    .foregroundColor(InkTheme.onInk)
                    .frame(width: 200, height: 50)
                    .background(InkTheme.ink)
                    .cornerRadius(12)
            }
            .buttonStyle(InkPressButtonStyle())
            .accessibilityLabel("Practice again")

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
            .buttonStyle(InkPressButtonStyle())
            .accessibilityLabel("Return to Library")
        }
    }
}

/// Fade-up entrance used to stagger the summary's rows: each element rises
/// ~14 pt while fading in, on a soft spring after its own delay. Under Reduce
/// Motion the offset is dropped and only a quick fade remains.
private struct EntranceModifier: ViewModifier {
    let shown: Bool
    let delay: Double
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 14)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.2).delay(delay)
                    : .spring(response: 0.55, dampingFraction: 0.8).delay(delay),
                value: shown
            )
    }
}
