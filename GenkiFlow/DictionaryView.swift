import SwiftUI
import SwiftData

struct DictionaryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var filterType = "all"
    @State private var results: [StudyItem] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var canLoadMore = false
    private let pageSize = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter picker
                Picker("Type", selection: $filterType) {
                    Text("All").tag("all")
                    Text("Kanji").tag("kanji")
                    Text("Vocab").tag("vocabulary")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                List {
                    ForEach(results) { item in
                        NavigationLink {
                            ItemDetailView(item: item)
                        } label: {
                            DictionaryRowView(item: item)
                        }
                    }

                    if canLoadMore {
                        Color.clear
                            .frame(height: 1)
                            .onAppear { loadMore() }
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if results.isEmpty && searchText.isEmpty {
                        ContentUnavailableView(
                            "Dictionary",
                            systemImage: "book.fill",
                            description: Text("Loading items...")
                        )
                    } else if results.isEmpty {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "magnifyingglass",
                            description: Text("No items match your search")
                        )
                    }
                }
            }
            .navigationTitle("Dictionary")
            .searchable(text: $searchText, prompt: "Search kanji or vocab...")
            .onAppear { performSearch() }
            .onChange(of: searchText) { debouncedSearch() }
            .onChange(of: filterType) { performSearch() }
        }
    }

    private func debouncedSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            performSearch()
        }
    }

    private func performSearch() {
        let type = filterType
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()

        var descriptor: FetchDescriptor<StudyItem>

        if query.isEmpty {
            // Browse mode — paginated list of all items
            if type == "all" {
                descriptor = FetchDescriptor<StudyItem>(
                    sortBy: [SortDescriptor(\.subject)]
                )
            } else {
                descriptor = FetchDescriptor<StudyItem>(
                    predicate: #Predicate { $0.type == type },
                    sortBy: [SortDescriptor(\.subject)]
                )
            }
            descriptor.fetchLimit = pageSize
        } else {
            // Search mode — match against the precomputed searchableText field
            // which includes subject, furigana, meanings, readings, and romaji
            if type == "all" {
                descriptor = FetchDescriptor<StudyItem>(
                    predicate: #Predicate {
                        $0.searchableText.localizedStandardContains(query)
                    },
                    sortBy: [SortDescriptor(\.srsStage, order: .reverse)]
                )
            } else {
                descriptor = FetchDescriptor<StudyItem>(
                    predicate: #Predicate {
                        $0.type == type &&
                        $0.searchableText.localizedStandardContains(query)
                    },
                    sortBy: [SortDescriptor(\.srsStage, order: .reverse)]
                )
            }
            descriptor.fetchLimit = 100
        }

        do {
            results = try modelContext.fetch(descriptor)
            canLoadMore = results.count == (query.isEmpty ? pageSize : 100)
        } catch {
            print("[Dictionary] Search error: \(error)")
        }
    }

    private func loadMore() {
        let type = filterType
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let currentCount = results.count

        var descriptor: FetchDescriptor<StudyItem>

        if query.isEmpty {
            if type == "all" {
                descriptor = FetchDescriptor<StudyItem>(
                    sortBy: [SortDescriptor(\.subject)]
                )
            } else {
                descriptor = FetchDescriptor<StudyItem>(
                    predicate: #Predicate { $0.type == type },
                    sortBy: [SortDescriptor(\.subject)]
                )
            }
        } else {
            if type == "all" {
                descriptor = FetchDescriptor<StudyItem>(
                    predicate: #Predicate {
                        $0.searchableText.localizedStandardContains(query)
                    },
                    sortBy: [SortDescriptor(\.srsStage, order: .reverse)]
                )
            } else {
                descriptor = FetchDescriptor<StudyItem>(
                    predicate: #Predicate {
                        $0.type == type &&
                        $0.searchableText.localizedStandardContains(query)
                    },
                    sortBy: [SortDescriptor(\.srsStage, order: .reverse)]
                )
            }
        }

        descriptor.fetchOffset = currentCount
        descriptor.fetchLimit = pageSize

        do {
            let moreItems = try modelContext.fetch(descriptor)
            results.append(contentsOf: moreItems)
            canLoadMore = moreItems.count == pageSize
        } catch {
            print("[Dictionary] Load more error: \(error)")
        }
    }

    private func stageColor(_ stage: Int) -> Color {
        switch stage {
        case 0: return .gray
        case 1...4: return .pink
        case 5...6: return .purple
        case 7: return .blue
        case 8: return .yellow
        default: return .green
        }
    }
}

// MARK: - Dictionary Row View

private struct DictionaryRowView: View {
    let item: StudyItem

    var body: some View {
        HStack(spacing: 12) {
            Text(item.subject)
                .font(.title2.weight(.bold))
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.meanings.prefix(3).joined(separator: ", "))
                    .font(.subheadline)
                    .lineLimit(1)

                if !item.furigana.isEmpty {
                    Text(item.furigana)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
            
            Text(item.type)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(typeColor(item.type).opacity(0.2))
                .foregroundStyle(typeColor(item.type))
                .clipShape(Capsule())

            Text(SRSEngine.stageName(for: item.srsStage))
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(stageColor(item.srsStage).opacity(0.2))
                .foregroundStyle(stageColor(item.srsStage))
                .clipShape(Capsule())
        }
    }
    
    private func typeColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "kanji":
            return .blue
        default:
            return .green
        }
    }

    private func stageColor(_ stage: Int) -> Color {
        switch stage {
        case 0: return .gray
        case 1...4: return .pink
        case 5...6: return .purple
        case 7: return .blue
        case 8: return .yellow
        default: return .green
        }
    }
}

// MARK: - Item Detail View

struct ItemDetailView: View {
    let item: StudyItem

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    if !item.furigana.isEmpty {
                        Text(item.furigana)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    Text(item.subject)
                        .font(.system(size: 72, weight: .bold))
                }
                .padding(.top)

                // Type + SRS
                HStack {
                    Label(item.type.capitalized, systemImage: item.type == "kanji" ? "character.ja" : "text.book.closed")
                        .font(.subheadline)
                    Spacer()
                    Text(SRSEngine.stageName(for: item.srsStage))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.purple)
                }
                .padding(.horizontal)

                Divider()

                // Meanings
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meanings")
                        .font(.headline)
                    ForEach(item.meanings, id: \.self) { meaning in
                        Text("• \(meaning)")
                            .font(.body)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Readings
                if !item.readings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Readings")
                            .font(.headline)
                        ForEach(item.readings, id: \.self) { reading in
                            HStack {
                                Text(reading.value)
                                    .font(.body)
                                Text(reading.type)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                // SRS Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("SRS Info")
                        .font(.headline)
                    LabeledContent("Stage", value: SRSEngine.stageName(for: item.srsStage))
                    LabeledContent("Next Review", value: item.nextReview.formatted(date: .abbreviated, time: .shortened))
                    if let lastIncorrect = item.lastIncorrectDate {
                        LabeledContent("Last Incorrect", value: lastIncorrect.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                Spacer()
            }
        }
        .navigationTitle(item.subject)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
