import Foundation

struct StreakManager {
    /// Compute the updated streak after completing a review session.
    /// - Parameters:
    ///   - currentStreak: The current streak count.
    ///   - longestStreak: The all-time longest streak.
    ///   - lastReviewDate: The date of the last completed review (nil if never reviewed).
    ///   - now: The current date (injectable for testing).
    ///   - calendar: The calendar to use (injectable for testing).
    /// - Returns: Updated (currentStreak, longestStreak, lastReviewDate).
    static func recordSession(
        currentStreak: Int,
        longestStreak: Int,
        lastReviewDate: Date?,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> (currentStreak: Int, longestStreak: Int, lastReviewDate: Date) {
        guard let lastDate = lastReviewDate else {
            // First ever review
            return (1, max(longestStreak, 1), now)
        }

        if calendar.isDate(lastDate, inSameDayAs: now) {
            // Already reviewed today — no change
            return (currentStreak, longestStreak, now)
        }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
        if calendar.isDate(lastDate, inSameDayAs: yesterday) {
            // Reviewed yesterday — extend streak
            let newStreak = currentStreak + 1
            return (newStreak, max(longestStreak, newStreak), now)
        }

        // Missed a full calendar day — reset to 1
        return (1, max(longestStreak, 1), now)
    }
}
