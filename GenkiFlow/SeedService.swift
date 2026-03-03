import Foundation
import SwiftData

@Observable
final class SeedService {
    var isSeeding = false
    var seedProgress: Double = 0
    var seedComplete = false

    func seedIfNeeded(modelContainer: ModelContainer) async {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<StudyItem>()
        let count = (try? context.fetchCount(descriptor)) ?? 0

        guard count == 0 else {
            seedComplete = true
            return
        }

        isSeeding = true
        await performSeed(modelContainer: modelContainer)
        isSeeding = false
        seedComplete = true
    }

    private func performSeed(modelContainer: ModelContainer) async {
        guard let url = Bundle.main.url(forResource: "study_items", withExtension: "json") else {
            print("[SeedService] study_items.json not found in bundle")
            seedComplete = true
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let dtos = try JSONDecoder().decode([StudyItemDTO].self, from: data)
            let totalCount = dtos.count

            // Insert in batches to keep memory bounded.
            // Each batch gets a fresh context so we don't accumulate
            // 187K pending objects in memory.
            let batchSize = 10_000
            var insertedCount = 0

            for batchStart in stride(from: 0, to: totalCount, by: batchSize) {
                let batchEnd = min(batchStart + batchSize, totalCount)
                let context = ModelContext(modelContainer)
                context.autosaveEnabled = false

                for i in batchStart..<batchEnd {
                    let dto = dtos[i]
                    guard !dto.meanings.isEmpty else { continue }

                    let readingObjects = dto.toReadingObjects()
                    let item = StudyItem(
                        id: dto.id,
                        type: dto.type,
                        subject: dto.subject,
                        furigana: dto.furigana,
                        meanings: dto.meanings,
                        readings: readingObjects,
                        searchableText: StudyItem.buildSearchableText(
                            subject: dto.subject,
                            furigana: dto.furigana,
                            meanings: dto.meanings,
                            readings: readingObjects
                        )
                    )
                    context.insert(item)
                    insertedCount += 1
                }

                try context.save()
                await MainActor.run {
                    self.seedProgress = Double(batchEnd) / Double(totalCount)
                }
                await Task.yield()
            }

            await MainActor.run {
                self.seedProgress = 1.0
            }
            print("[SeedService] Seeded \(insertedCount) items (of \(totalCount) total)")
        } catch {
            print("[SeedService] Seed error: \(error)")
        }
    }
}
