import SwiftUI
import SwiftData

struct PracticeModeView: View {
    let music: ParsedMusic?
    let instrument: Instrument?
    @State private var viewModel = PracticeModeViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var activeInstrument: Instrument {
        instrument ?? viewModel.selectedInstrument
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                switch viewModel.phase {
                case .setup:
                    setupView
                        .frame(maxWidth: horizontalSizeClass == .regular ? 700 : .infinity)
                        .frame(maxWidth: .infinity)
                case .idle:
                    idleView
                        .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
                        .frame(maxWidth: .infinity)
                case .countdown(let count):
                    countdownView(count)
                        .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
                        .frame(maxWidth: .infinity)
                case .recording:
                    recordingView
                        .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
                        .frame(maxWidth: .infinity)
                case .analyzing:
                    analyzingView
                        .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
                        .frame(maxWidth: .infinity)
                case .complete(let feedback):
                    PracticeReportView(
                        feedback: feedback,
                        instrument: activeInstrument,
                        skillLevel: viewModel.skillLevel
                    ) {
                        viewModel.reset()
                    }
                    .onAppear {
                        savePracticeSession(feedback: feedback)
                    }
                case .error(let message):
                    errorView(message)
                }
            }
            .navigationTitle("Practice Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.cancelPractice()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                if let music, let instrument {
                    viewModel.configure(music: music, instrument: instrument)
                } else {
                    viewModel.phase = .setup
                }
            }
            .onDisappear {
                viewModel.reset()
            }
        }
    }

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.red.opacity(0.2), .orange.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 100, height: 100)
                        Image(systemName: "music.mic")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                    .padding(.top, 24)

                    Text("Free Practice")
                        .font(.title2.bold())
                    Text("Record yourself playing and get AI feedback on your performance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Select Your Instrument")
                        .font(.headline.bold())
                        .padding(.horizontal)

                    ForEach(InstrumentCategory.allCases) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: category.iconName)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(category.color)
                                Text(category.rawValue)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(category.color)
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal) {
                                HStack(spacing: 8) {
                                    ForEach(Instrument.instruments(for: category)) { inst in
                                        Button {
                                            withAnimation(.spring(duration: 0.25)) {
                                                viewModel.selectedInstrument = inst
                                            }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: inst.iconName)
                                                    .font(.caption2.weight(.bold))
                                                Text(inst.rawValue)
                                                    .font(.caption.weight(.semibold))
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                viewModel.selectedInstrument == inst
                                                    ? AnyShapeStyle(category.color.gradient)
                                                    : AnyShapeStyle(Color(.tertiarySystemFill)),
                                                in: .capsule
                                            )
                                            .foregroundStyle(viewModel.selectedInstrument == inst ? .white : .primary)
                                        }
                                        .buttonStyle(.plain)
                                        .sensoryFeedback(.selection, trigger: viewModel.selectedInstrument)
                                    }
                                }
                            }
                            .contentMargins(.horizontal, 16)
                            .scrollIndicators(.hidden)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Skill Level")
                        .font(.headline.bold())
                        .padding(.horizontal)

                    HStack(spacing: 8) {
                        ForEach(SkillLevel.allCases) { level in
                            Button {
                                withAnimation(.spring(duration: 0.25)) {
                                    viewModel.skillLevel = level
                                }
                                UserDefaults.standard.set(level.rawValue, forKey: "skillLevel")
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: level.iconName)
                                        .font(.title3)
                                    Text(level.rawValue)
                                        .font(.caption.weight(.bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    viewModel.skillLevel == level
                                        ? AnyShapeStyle(Color.yellow.gradient)
                                        : AnyShapeStyle(Color(.tertiarySystemFill)),
                                    in: .rect(cornerRadius: 12)
                                )
                                .foregroundStyle(viewModel.skillLevel == level ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.skillLevel.reportDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 2)
                }

                Button {
                    viewModel.configureFreePractice()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "record.circle")
                            .font(.title3.weight(.bold))
                        Text("Start Practice")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.selectedInstrument.category.color.gradient, in: .capsule)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            }
        }
    }

    private var idleView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(activeInstrument.category.color.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Circle()
                        .fill(activeInstrument.category.color.opacity(0.08))
                        .frame(width: 160, height: 160)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(activeInstrument.category.color)
                }

                VStack(spacing: 6) {
                    Text("Ready to Practice?")
                        .font(.title2.bold())
                    if let music {
                        Text("Play \"\(music.title ?? "this piece")\" on your \(activeInstrument.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    } else {
                        Text("Free practice on your \(activeInstrument.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
            }

            VStack(spacing: 12) {
                if let music {
                    HStack(spacing: 24) {
                        InfoChip(icon: "music.note", label: music.keySignature, color: .blue)
                        InfoChip(icon: "metronome", label: "\(music.tempo) BPM", color: .orange)
                        InfoChip(icon: "music.quarternote.3", label: music.timeSignatureDisplay, color: .purple)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: viewModel.skillLevel.iconName)
                        .foregroundStyle(.yellow)
                    Text(viewModel.skillLevel.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }

            Spacer()

            Button {
                viewModel.startPractice()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "record.circle")
                        .font(.title3.weight(.bold))
                    Text("Start Practice")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(activeInstrument.category.color.gradient, in: .capsule)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
    }

    private func countdownView(_ count: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(activeInstrument.category.color.opacity(0.1))
                    .frame(width: 200, height: 200)

                Text("\(count)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(activeInstrument.category.color)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.spring(duration: 0.4), value: count)
            }

            Text("Get ready to play...")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                viewModel.cancelPractice()
            } label: {
                Text("Cancel")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 32)
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: count)
    }

    private var recordingView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    ForEach(0..<3, id: \.self) { ring in
                        Circle()
                            .stroke(activeInstrument.category.color.opacity(0.15 + Double(ring) * 0.05), lineWidth: 2)
                            .frame(
                                width: 140 + CGFloat(ring) * 40 * CGFloat(viewModel.recordingService.audioLevel),
                                height: 140 + CGFloat(ring) * 40 * CGFloat(viewModel.recordingService.audioLevel)
                            )
                            .animation(.easeOut(duration: 0.1), value: viewModel.recordingService.audioLevel)
                    }

                    Circle()
                        .fill(activeInstrument.category.color.gradient)
                        .frame(width: 100, height: 100)
                        .overlay {
                            Image(systemName: "waveform")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(.white)
                                .symbolEffect(.variableColor.iterative, isActive: true)
                        }
                }
                .frame(height: 220)

                VStack(spacing: 4) {
                    Text("Listening...")
                        .font(.title3.bold())
                        .foregroundStyle(activeInstrument.category.color)

                    Text(formatRecordingTime(viewModel.recordingService.recordingDuration))
                        .font(.system(.title, design: .rounded).monospacedDigit().weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }

            Text("Play your \(activeInstrument.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                Task {
                    await viewModel.stopPractice()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title3.weight(.bold))
                    Text("Finish & Get Feedback")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red.gradient, in: .capsule)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
    }

    private var analyzingView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(activeInstrument.category.color.opacity(0.1))
                        .frame(width: 140, height: 140)
                    ProgressView()
                        .scaleEffect(2)
                        .tint(activeInstrument.category.color)
                }

                VStack(spacing: 6) {
                    Text("Analyzing Your Practice")
                        .font(.title3.bold())
                    Text("AI is reviewing your performance...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)

                Text("Something Went Wrong")
                    .font(.title3.bold())

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.reset()
                } label: {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(activeInstrument.category.color.gradient, in: .capsule)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Go Back")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
    }

    private func formatRecordingTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func savePracticeSession(feedback: PracticeFeedback) {
        let songTitle = music?.title ?? "Free Practice"
        let session = PracticeSession(
            songTitle: songTitle,
            instrument: activeInstrument.rawValue,
            skillLevel: viewModel.skillLevel.rawValue,
            duration: viewModel.elapsedTime,
            overallScore: feedback.overallScore
        )
        session.setFeedback(feedback)
        modelContext.insert(session)

        GamificationManager.shared.recordPracticeSession(
            instrument: activeInstrument.rawValue,
            durationSeconds: viewModel.elapsedTime
        )
    }
}

struct InfoChip: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1), in: .capsule)
    }
}
