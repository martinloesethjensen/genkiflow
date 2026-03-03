import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("sessionSize") private var sessionSize = 20
    @AppStorage("currentStreak") private var currentStreak = 0
    @AppStorage("longestStreak") private var longestStreak = 0
    @State private var showResetAlert = false
    @State private var showResetProgress = false
    @State private var totalItems = 0
    @State private var studiedItems = 0
    @State private var guruItems = 0
    @State private var showStreakSheet = false
    @State private var tempStreak = 0
    
    var body: some View {
        NavigationStack {
            List {
                Section("Statistics") {
                    LabeledContent("Total Items", value: "\(totalItems)")
                    LabeledContent("Studied", value: "\(studiedItems)")
                    LabeledContent("Guru+", value: "\(guruItems)")
                }
                
                Section("Session Settings") {
                    Picker("Session Size", selection: $sessionSize) {
                        ForEach([5, 10, 15, 20, 25], id: \.self) { count in
                            Text("\(count) items").tag(count)
                        }
                    }
                    
                }
                
                Section("Streak") {
                    LabeledContent("Current Streak", value: "\(currentStreak)")
                    LabeledContent("LongestStreak", value: "\(longestStreak)")
                    Button("Change Current Streak") {
                        tempStreak = currentStreak
                        showStreakSheet = true
                    }
                }
                
                Section("SRS Settings") {
                    ForEach(Array(SRSEngine.intervals.enumerated()), id: \.offset) { index, interval in
                        LabeledContent(
                            "Stage \(index + 1)",
                            value: formatInterval(interval)
                        )
                    }
                }
                
                Section("About") {
                    LabeledContent("App", value: "GenkiFlow")
                    LabeledContent("Developer", value: "Martin Jensen (https://github.com/martinloesethjensen)")
                    LabeledContent("Website", value: "https://github.com/martinloesethjensen/genkiflow")
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                }
                
                Section {
                    Button("Reset All Progress", role: .destructive) {
                        showResetAlert = true
                    }
                    .disabled(showResetProgress)
                }
            }
            .navigationTitle("Settings")
            .onAppear { refreshCounts() }
            .overlay {
                if showResetProgress {
                    ProgressView("Resetting...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Reset All Progress?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetProgress()
                }
            } message: {
                Text("This will reset SRS progress for all items. The items themselves will not be deleted.")
            }
            .sheet(isPresented: $showStreakSheet) {
                editStreakSheet
            }
        }
    }
    
    private var editStreakSheet: some View {
        NavigationStack {
            Form {
                Section("Enter New Streak") {
                    // Ensure there is no whitespace or strange wrapping between the TextField and its modifier
                    TextField("Streak", value: $tempStreak, format: .number)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
            }
            .navigationTitle("Edit Streak")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showStreakSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        currentStreak = tempStreak
                        if currentStreak > longestStreak {
                            longestStreak = currentStreak
                        }
                        showStreakSheet = false
                    }
                }
            }
        }
    }
    
    private func refreshCounts() {
        totalItems = (try? modelContext.fetchCount(FetchDescriptor<StudyItem>())) ?? 0
        studiedItems = (try? modelContext.fetchCount(FetchDescriptor<StudyItem>(
            predicate: #Predicate { $0.srsStage > 0 }
        ))) ?? 0
        guruItems = (try? modelContext.fetchCount(FetchDescriptor<StudyItem>(
            predicate: #Predicate { $0.srsStage > 4 }
        ))) ?? 0
    }
    
    private func resetProgress() {
        showResetProgress = true
        let container = modelContext.container
        
        Task.detached {
            let context = ModelContext(container)
            context.autosaveEnabled = false
            var descriptor = FetchDescriptor<StudyItem>(
                predicate: #Predicate { $0.srsStage > 0 }
            )
            descriptor.propertiesToFetch = [\.srsStage, \.nextReview, \.lastIncorrectDate]
            
            if let items = try? context.fetch(descriptor) {
                for item in items {
                    item.srsStage = 0
                    item.nextReview = .now
                    item.lastIncorrectDate = nil
                }
                try? context.save()
            }
            await MainActor.run {
                sessionSize = 20
                currentStreak = 0
                longestStreak = 0
                showResetProgress = false
                refreshCounts()
            }
        }
    }
    
    private func formatInterval(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        if hours < 24 {
            return "\(hours)h"
        }
        let days = hours / 24
        if days < 7 {
            return "\(days)d"
        }
        let weeks = days / 7
        if weeks <= 2 {
            return "\(weeks)w"
        }
        let months = days / 30
        return "\(months)mo"
    }
}
