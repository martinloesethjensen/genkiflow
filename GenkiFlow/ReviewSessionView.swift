import SwiftUI
import SwiftData

struct ReviewSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("sessionSize") private var sessionSize = 20
    @State private var viewModel = ReviewSessionViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSessionComplete {
                    completionView
                } else if let item = viewModel.currentItem {
                    cardView(item: item)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("End") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    ProgressView(value: viewModel.progress)
                        .frame(width: 120)
                }
                ToolbarItem(placement: .automatic) {
                    Text("\(viewModel.currentIndex + 1)/\(viewModel.totalCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            viewModel.loadItems(modelContext: modelContext, limit: sessionSize)
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Card View

    @ViewBuilder
    private func cardView(item: StudyItem) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Subject display with optional ruby
            if viewModel.state == .revealed {
                rubyText(subject: item.subject, furigana: item.furigana)
                    .padding(.bottom, 8)
            } else {
                Text(item.subject)
                    .font(.system(size: 80, weight: .bold))
                    .padding(.bottom, 8)
            }

            // Type badge + question type
            HStack(spacing: 8) {
                Text(item.type.capitalized)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.type == "kanji" ? Color.pink.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundStyle(item.type == "kanji" ? .pink : .blue)
                    .clipShape(Capsule())

                Text(viewModel.questionType.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)

            // Meanings
            Text(item.meanings.joined(separator: ", "))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Answer area
            if viewModel.state == .answering {
                answerInputView
            } else {
                revealedView(item: item)
            }
        }
        .padding()
    }

    // MARK: - Ruby Text (Furigana above subject)

    @ViewBuilder
    private func rubyText(subject: String, furigana: String) -> some View {
        VStack(spacing: 2) {
            Text(furigana)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
            Text(subject)
                .font(.system(size: 80, weight: .bold))
                .foregroundStyle(viewModel.isCorrect ? .green : .red)
        }
    }

    // MARK: - Answer Input

    private var answerInputView: some View {
        VStack(spacing: 16) {
            TextField("Type reading...", text: $viewModel.userAnswer)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .onSubmit {
                    guard !viewModel.userAnswer.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    viewModel.submitAnswer()
                }

            HStack(spacing: 12) {
                Button {
                    viewModel.forgotAnswer()
                } label: {
                    Text("I Forgot")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    guard !viewModel.userAnswer.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    viewModel.submitAnswer()
                } label: {
                    Text("Submit")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.bottom, 32)
    }

    // MARK: - Revealed State

    @ViewBuilder
    private func revealedView(item: StudyItem) -> some View {
        VStack(spacing: 16) {
            // Correct/Incorrect header
            HStack {
                Image(systemName: viewModel.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(viewModel.isCorrect ? .green : .red)
                    .font(.title2)

                Text(viewModel.isCorrect ? "Correct!" : "Incorrect")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(viewModel.isCorrect ? .green : .red)
            }

            if !viewModel.isCorrect {
                VStack(spacing: 12) {
                    // Show incorrect user input (if they typed something)
                    if !viewModel.userAnswer.trimmingCharacters(in: .whitespaces).isEmpty {
                        VStack(spacing: 2) {
                            Text("Your answer")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(viewModel.userAnswer)
                                .font(.title3)
                                .strikethrough()
                                .foregroundStyle(.red)
                        }
                    }

                    // Show correct answer with furigana if applicable
                    VStack(spacing: 2) {
                        Text("Correct answer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        answerWithFurigana(for: item)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 12) {
                // Undo/Ignore button
                Button {
                    viewModel.undoAnswer()
                } label: {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Undo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Next button
                Button {
                    viewModel.nextCard()
                } label: {
                    HStack {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.bottom, 32)
    }

    /// Renders the accepted reading values, with furigana shown above if the value contains kanji.
    @ViewBuilder
    private func answerWithFurigana(for item: StudyItem) -> some View {
        let readings = acceptedReadings(for: item)
        HStack(spacing: 16) {
            ForEach(readings, id: \.self) { reading in
                if containsKanji(reading) {
                    // Show furigana above the kanji reading
                    VStack(spacing: 0) {
                        Text(item.furigana)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(reading)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.green)
                    }
                } else {
                    Text(reading)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private func containsKanji(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            // CJK Unified Ideographs and extensions
            (scalar.value >= 0x4E00 && scalar.value <= 0x9FFF) ||
            (scalar.value >= 0x3400 && scalar.value <= 0x4DBF) ||
            (scalar.value >= 0x20000 && scalar.value <= 0x2A6DF)
        }
    }

    private func acceptedReadings(for item: StudyItem) -> [String] {
        switch viewModel.questionType {
        case .readingOn:
            return item.readings.filter { $0.type == "on" }.map(\.value)
        case .readingKun:
            return item.readings.filter { $0.type == "kun" }.map(\.value)
        case .readingVocab:
            return item.readings.map(\.value)
        }
    }

    private func acceptedReadingsText(for item: StudyItem) -> String {
        switch viewModel.questionType {
        case .readingOn:
            return item.readings.filter { $0.type == "on" }.map(\.value).joined(separator: ", ")
        case .readingKun:
            return item.readings.filter { $0.type == "kun" }.map(\.value).joined(separator: ", ")
        case .readingVocab:
            return item.readings.map(\.value).joined(separator: ", ")
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Session Complete")
                .font(.largeTitle.weight(.bold))

            HStack(spacing: 32) {
                VStack {
                    Text("\(viewModel.correctCount)")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.green)
                    Text("Correct")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack {
                    Text("\(viewModel.incorrectCount)")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.red)
                    Text("Incorrect")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.bottom, 32)
        }
        .padding()
    }
}
