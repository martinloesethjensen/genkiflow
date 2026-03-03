import Foundation

struct SRSEngine {
    // Intervals in seconds: [4h, 8h, 23h, 47h, 1w, 2w, 1m, 4m]
    static let intervals: [TimeInterval] = [
        4 * 3600,       // Stage 1: 4 hours
        8 * 3600,       // Stage 2: 8 hours
        23 * 3600,      // Stage 3: 23 hours
        47 * 3600,      // Stage 4: 47 hours
        7 * 86400,      // Stage 5: 1 week
        14 * 86400,     // Stage 6: 2 weeks
        30 * 86400,     // Stage 7: 1 month
        120 * 86400     // Stage 8: 4 months
    ]

    static let stageNames = [
        "Lesson",       // 0
        "Apprentice I", // 1
        "Apprentice II",// 2
        "Apprentice III",// 3
        "Apprentice IV",// 4
        "Guru I",       // 5
        "Guru II",      // 6
        "Master",       // 7
        "Enlightened"   // 8
    ]

    static func processCorrect(item: StudyItem) {
        let newStage = min(item.srsStage + 1, intervals.count)
        item.srsStage = newStage
        if newStage <= intervals.count {
            item.nextReview = Date.now.addingTimeInterval(intervals[newStage - 1])
        }
    }

    static func processIncorrect(item: StudyItem) {
        let newStage = max(item.srsStage - 1, 1)
        item.srsStage = newStage
        item.lastIncorrectDate = .now
        item.nextReview = Date.now.addingTimeInterval(intervals[newStage - 1])
    }

    static func stageName(for stage: Int) -> String {
        guard stage >= 0, stage < stageNames.count else { return "Burned" }
        return stageNames[stage]
    }
}
