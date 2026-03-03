import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currentStreak") private var currentStreak = 0
    @AppStorage("longestStreak") private var longestStreak = 0
    @State private var showReviewSession = false
    @State private var stats = DashboardStats()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Streak
                    StreakCard(currentStreak: currentStreak, longestStreak: longestStreak)

                    // MARK: - Stats Cards
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Reviews Due",
                            count: stats.reviewsDue,
                            color: .orange
                        )
                        StatCard(
                            title: "New Lessons",
                            count: stats.newLessons,
                            color: .blue
                        )
                    }

                    // MARK: - Progress
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Guru+ Progress")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(stats.guruProgress * 100))%")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: stats.guruProgress)
                            .tint(.purple)
                            .scaleEffect(y: 2)

                        HStack {
                            Text("\(stats.guruPlus) of \(stats.total) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // MARK: - SRS Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SRS Stages")
                            .font(.headline)

                        ForEach(0..<9, id: \.self) { stage in
                            let count = stats.stageCounts[stage, default: 0]
                            HStack {
                                Text(SRSEngine.stageName(for: stage))
                                    .font(.subheadline)
                                    .frame(width: 110, alignment: .leading)
                                ProgressView(value: stats.total == 0 ? 0 : Double(count) / Double(stats.total))
                                    .tint(stageColor(stage))
                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // MARK: - Start Button
                    Button {
                        showReviewSession = true
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Session")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(stats.hasItemsDue ? Color.accentColor : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!stats.hasItemsDue)
                }
                .padding()
            }
            .navigationTitle("GenkiFlow")
            .onAppear { refreshStats() }
            .sheet(isPresented: $showReviewSession) {
                ReviewSessionView()
                #if os(macOS)
                    .frame(minWidth: 500, minHeight: 600)
                #endif
            }
            .onChange(of: showReviewSession) {
                if !showReviewSession { refreshStats() }
            }
        }
    }

    private func refreshStats() {
        stats = DashboardStats.load(from: modelContext)
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

// MARK: - Dashboard Stats (computed via fetchCount, never loads full objects)

struct DashboardStats {
    var total = 0
    var reviewsDue = 0
    var newLessons = 0
    var guruPlus = 0
    var stageCounts: [Int: Int] = [:]

    var guruProgress: Double {
        guard total > 0 else { return 0 }
        return Double(guruPlus) / Double(total)
    }

    var hasItemsDue: Bool {
        reviewsDue > 0 || newLessons > 0
    }

    static func load(from context: ModelContext) -> DashboardStats {
        var s = DashboardStats()
        let now = Date.now

        s.total = (try? context.fetchCount(FetchDescriptor<StudyItem>())) ?? 0

        s.reviewsDue = (try? context.fetchCount(FetchDescriptor<StudyItem>(
            predicate: #Predicate { $0.nextReview <= now && $0.srsStage > 0 }
        ))) ?? 0

        s.newLessons = (try? context.fetchCount(FetchDescriptor<StudyItem>(
            predicate: #Predicate { $0.srsStage == 0 }
        ))) ?? 0

        s.guruPlus = (try? context.fetchCount(FetchDescriptor<StudyItem>(
            predicate: #Predicate { $0.srsStage > 4 }
        ))) ?? 0

        for stage in 0..<9 {
            s.stageCounts[stage] = (try? context.fetchCount(FetchDescriptor<StudyItem>(
                predicate: #Predicate { $0.srsStage == stage }
            ))) ?? 0
        }

        return s
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(currentStreak > 0 ? .orange : .gray)
                    .font(.title2)
                Text("\(currentStreak)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(currentStreak > 0 ? .orange : .gray)
                Text("Day Streak")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(longestStreak)")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("Best")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
