//
//  ContentView.swift
//  Inkwell
//

import SwiftUI
import SwiftData

enum ActiveScreen {
    case library
    case characterTable
    case settings
    case practice(CharacterDeck)
    case complete(CharacterDeck, [SessionResultItem])
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedProgress: [CharacterProgress]
    
    @State private var activeScreen: ActiveScreen = .library
    @State private var deckProgress: [String: Int] = [
        "jp-n5": 3,
        "zh-hsk1": 5,
        "numbers": 10
    ]

    // Drives the app-wide light/dark preference. Edited in Settings; `nil`
    // (the "System" option) lets the device setting win.
    @AppStorage(AppSettings.Key.appearance) private var appearanceRaw: String = AppSettings.defaultAppearance.rawValue
    
    private func saveResults(_ results: [SessionResultItem], for deck: CharacterDeck) {
        let flawless = results.filter { !$0.skipped && $0.mistakes == 0 }.count
        deckProgress[deck.id] = max(deckProgress[deck.id] ?? 0, flawless)
        for item in results where !item.skipped {
            if let existing = savedProgress.first(where: { $0.glyph == item.glyph }) {
                existing.recordAttempt(mistakes: item.mistakes)
            } else {
                let newProg = CharacterProgress(glyph: item.glyph)
                newProg.recordAttempt(mistakes: item.mistakes)
                modelContext.insert(newProg)
            }
        }
        try? modelContext.save()
    }

    var body: some View {
        ZStack {
            switch activeScreen {
            case .library:
                LibraryView(
                    decks: SeedData.decks,
                    progress: deckProgress,
                    onSelectDeck: { selectedDeck in
                        activeScreen = .practice(selectedDeck)
                    },
                    onOpenTable: {
                        activeScreen = .characterTable
                    },
                    onOpenSettings: {
                        activeScreen = .settings
                    }
                )

            case .characterTable:
                CharacterTableView(
                    decks: SeedData.decks,
                    onBack: {
                        activeScreen = .library
                    },
                    onStartPractice: { selectedDeck in
                        activeScreen = .practice(selectedDeck)
                    }
                )

            case .settings:
                SettingsView(
                    onBack: {
                        activeScreen = .library
                    }
                )
                
            case .practice(let deck):
                PracticeView(
                    deck: deck,
                    onExit: { results in
                        saveResults(results, for: deck)
                        activeScreen = .library
                    },
                    onFinish: { results in
                        saveResults(results, for: deck)
                        activeScreen = .complete(deck, results)
                    }
                )
                
            case .complete(let deck, let results):
                SessionCompleteView(
                    deck: deck,
                    results: results,
                    onHome: { activeScreen = .library },
                    onAgain: { activeScreen = .practice(deck) }
                )
            }
        }
        .background(InkTheme.paper.ignoresSafeArea())
        .tint(InkTheme.accent)
        .preferredColorScheme(AppAppearance(storedRawValue: appearanceRaw).colorScheme)
    }
}

#Preview {
    ContentView()
}
