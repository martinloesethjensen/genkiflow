//
//  ContentView.swift
//  GenkiFlow
//
//  Created by Martin Jensen on 03/03/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(SeedService.self) private var seedService

    var body: some View {
        if seedService.seedComplete {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }

                DictionaryView()
                    .tabItem {
                        Label("Dictionary", systemImage: "book.fill")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
        } else {
            seedingView
        }
    }

    private var seedingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Importing Study Data...")
                .font(.headline)

            ProgressView(value: seedService.seedProgress)
                .frame(width: 200)

            Text("\(Int(seedService.seedProgress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: StudyItem.self, inMemory: true)
        .environment(SeedService())
}
