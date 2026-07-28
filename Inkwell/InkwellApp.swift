//
//  InkwellApp.swift
//  Inkwell
//
//  Created by Tony Sainez on 6/28/26.
//

import SwiftUI
import SwiftData

@main
struct InkwellApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            CharacterProgress.self,
        ])
        let isInMemory = ProcessInfo.processInfo.arguments.contains("-inMemoryStore")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isInMemory)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // SECURITY: Do not leak internal container paths or schema errors to crash reports
            fatalError("Could not create ModelContainer. The application cannot continue.")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
