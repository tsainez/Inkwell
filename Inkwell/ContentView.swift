//
//  ContentView.swift
//  Inkwell
//

import SwiftUI

enum ActiveScreen {
    case library
    case practice(CharacterDeck)
    case complete(CharacterDeck, [SessionResultItem])
}

struct ContentView: View {
    @State private var activeScreen: ActiveScreen = .library
    @State private var deckProgress: [String: Int] = [
        "jp-n5": 3,
        "zh-hsk1": 5,
        "numbers": 10
    ]
    
    var body: some View {
        ZStack {
            switch activeScreen {
            case .library:
                LibraryView(
                    decks: SeedData.decks,
                    progress: deckProgress
                ) { selectedDeck in
                    activeScreen = .practice(selectedDeck)
                }
                
            case .practice(let deck):
                PracticeView(
                    deck: deck,
                    onExit: { activeScreen = .library },
                    onFinish: { results in
                        let flawless = results.filter { !$0.skipped && $0.mistakes == 0 }.count
                        deckProgress[deck.id] = max(deckProgress[deck.id] ?? 0, flawless)
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
    }
}

#Preview {
    ContentView()
}
