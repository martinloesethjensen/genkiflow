import Foundation
import SwiftData
import SwiftUI

@Observable
final class ReviewSessionViewModel {
    enum SessionState {
        case answering
        case revealed
        case complete
    }

    enum QuestionType: String {
        case readingOn = "Reading (On'yomi)"
        case readingKun = "Reading (Kun'yomi)"
        case readingVocab = "Reading"
    }

    var state: SessionState = .answering
    var currentIndex = 0
    var userAnswer = ""
    var isCorrect = false
    var questionType: QuestionType = .readingVocab
    var correctCount = 0
    var incorrectCount = 0

    private(set) var items: [StudyItem] = []
    private var modelContext: ModelContext?

    // MARK: - Streak (UserDefaults)

    private let defaults = UserDefaults.standard

    private var currentStreak: Int {
        get { defaults.integer(forKey: "currentStreak") }
        set { defaults.set(newValue, forKey: "currentStreak") }
    }
    private var longestStreak: Int {
        get { defaults.integer(forKey: "longestStreak") }
        set { defaults.set(newValue, forKey: "longestStreak") }
    }
    private var lastReviewDate: Date? {
        get {
            let raw = defaults.double(forKey: "lastReviewDate")
            return raw == 0 ? nil : Date(timeIntervalSince1970: raw)
        }
        set {
            defaults.set(newValue?.timeIntervalSince1970 ?? 0, forKey: "lastReviewDate")
        }
    }

    var currentItem: StudyItem? {
        guard currentIndex < items.count else { return nil }
        return items[currentIndex]
    }

    var totalCount: Int { items.count }
    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(currentIndex) / Double(items.count)
    }

    var isSessionComplete: Bool { state == .complete }

    func loadItems(modelContext: ModelContext, limit: Int = 20) {
        self.modelContext = modelContext
        let now = Date.now
        var descriptor = FetchDescriptor<StudyItem>(
            predicate: #Predicate<StudyItem> { item in
                item.nextReview <= now
            },
            sortBy: [SortDescriptor(\.nextReview)]
        )
        descriptor.fetchLimit = limit

        do {
            items = try modelContext.fetch(descriptor)
        } catch {
            print("[ReviewSession] Fetch error: \(error)")
        }

        if !items.isEmpty {
            pickQuestionType()
        } else {
            state = .complete
        }
    }

    func submitAnswer() {
        guard let item = currentItem else { return }
        let trimmed = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Determine accepted answers based on question type
        let accepted: [String]
        switch questionType {
        case .readingOn:
            accepted = item.readings.filter { $0.type == "on" }.map { $0.value.lowercased() }
        case .readingKun:
            accepted = item.readings.filter { $0.type == "kun" }.map { $0.value.lowercased() }
        case .readingVocab:
            accepted = item.readings.map { $0.value.lowercased() }
        }

        // Accept direct kana match, romaji→kana, or romaji-to-romaji comparison
        let hiraganaInput = RomajiConverter.toHiragana(trimmed)
        let katakanaInput = RomajiConverter.toKatakana(trimmed)
        let acceptedRomaji = accepted.map { RomajiConverter.kanaToRomaji($0).lowercased() }
        isCorrect = accepted.contains(trimmed)
            || accepted.contains(hiraganaInput)
            || accepted.contains(katakanaInput)
            || acceptedRomaji.contains(trimmed)

        if isCorrect {
            SRSEngine.processCorrect(item: item)
            correctCount += 1
            triggerHaptic(success: true)
        } else {
            SRSEngine.processIncorrect(item: item)
            incorrectCount += 1
            triggerHaptic(success: false)
        }

        state = .revealed
    }

    func forgotAnswer() {
        guard let item = currentItem else { return }
        isCorrect = false
        SRSEngine.processIncorrect(item: item)
        incorrectCount += 1
        triggerHaptic(success: false)
        state = .revealed
    }

    func undoAnswer() {
        guard let item = currentItem else { return }
        // Reverse the SRS change
        if isCorrect {
            item.srsStage = max(item.srsStage - 1, 0)
            correctCount -= 1
        } else {
            item.srsStage = min(item.srsStage + 1, SRSEngine.intervals.count)
            item.lastIncorrectDate = nil
            incorrectCount -= 1
        }
        // Reset review time to now so it comes back
        item.nextReview = .now
        state = .answering
        userAnswer = ""
    }

    func nextCard() {
        currentIndex += 1
        userAnswer = ""
        if currentIndex >= items.count {
            state = .complete
            try? modelContext?.save()
            updateStreak()
        } else {
            state = .answering
            pickQuestionType()
        }
    }

    private func updateStreak() {
        let result = StreakManager.recordSession(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastReviewDate: lastReviewDate
        )
        currentStreak = result.currentStreak
        longestStreak = result.longestStreak
        lastReviewDate = result.lastReviewDate
    }

    private func pickQuestionType() {
        guard let item = currentItem else { return }
        if item.type == "kanji" {
            let hasOn = item.readings.contains { $0.type == "on" }
            let hasKun = item.readings.contains { $0.type == "kun" }
            if hasOn && hasKun {
                questionType = Bool.random() ? .readingOn : .readingKun
            } else if hasOn {
                questionType = .readingOn
            } else {
                questionType = .readingKun
            }
        } else {
            questionType = .readingVocab
        }
    }

    private func triggerHaptic(success: Bool) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(success ? .success : .error)
        #endif
    }
}
