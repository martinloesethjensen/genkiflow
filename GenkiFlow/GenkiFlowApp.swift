//
//  GenkiFlowApp.swift
//  GenkiFlow
//
//  Created by Martin Jensen on 03/03/2026.
//

import SwiftUI
import SwiftData

@main
struct GenkiFlowApp: App {
    @State private var seedService = SeedService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StudyItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema changed — delete the old store and retry
            let url = modelConfiguration.url
            let related = [
                url,
                url.deletingPathExtension().appendingPathExtension("store-shm"),
                url.deletingPathExtension().appendingPathExtension("store-wal"),
            ]
            for file in related {
                try? FileManager.default.removeItem(at: file)
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(seedService)
                .task {
                    await seedService.seedIfNeeded(modelContainer: sharedModelContainer)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
