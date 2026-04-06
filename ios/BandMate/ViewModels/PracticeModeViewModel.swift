import SwiftUI
import AVFoundation

nonisolated enum PracticePhase: Sendable {
    case setup
    case idle
    case countdown(Int)
    case recording
    case analyzing
    case complete(PracticeFeedback)
    case error(String)
}

@Observable
@MainActor
class PracticeModeViewModel {
    var phase: PracticePhase = .idle
    var recordingService = AudioRecordingService()
    var elapsedTime: TimeInterval = 0

    private let feedbackService = PracticeFeedbackService.shared
    private var countdownTask: Task<Void, Never>?

    var music: ParsedMusic?
    var instrument: Instrument = .trumpet
    var selectedInstrument: Instrument = .trumpet
    var skillLevel: SkillLevel = .beginner

    var isRecording: Bool {
        if case .recording = phase { return true }
        return false
    }

    var isAnalyzing: Bool {
        if case .analyzing = phase { return true }
        return false
    }

    func configure(music: ParsedMusic, instrument: Instrument) {
        self.music = music
        self.instrument = instrument
        self.selectedInstrument = instrument
        let savedLevel = UserDefaults.standard.string(forKey: "skillLevel") ?? SkillLevel.beginner.rawValue
        self.skillLevel = SkillLevel(rawValue: savedLevel) ?? .beginner
        self.phase = .idle
    }

    func configureFreePractice() {
        self.instrument = selectedInstrument
        self.music = nil
        let savedLevel = UserDefaults.standard.string(forKey: "skillLevel") ?? SkillLevel.beginner.rawValue
        self.skillLevel = SkillLevel(rawValue: savedLevel) ?? .beginner
        self.phase = .idle
    }

    func startPractice() {
        phase = .countdown(3)
        countdownTask?.cancel()
        countdownTask = Task {
            for i in stride(from: 3, through: 1, by: -1) {
                guard !Task.isCancelled else { return }
                phase = .countdown(i)
                try? await Task.sleep(for: .seconds(1))
            }
            guard !Task.isCancelled else { return }
            await beginRecording()
        }
    }

    func stopPractice() async {
        countdownTask?.cancel()
        let audioURL = recordingService.stopRecording()
        elapsedTime = recordingService.recordingDuration

        phase = .analyzing

        let songTitle = music?.title ?? "Free Practice"
        let notes = music?.notes ?? []
        let keySignature = music?.keySignature ?? "C Major"
        let timeSignature = music?.timeSignatureDisplay ?? "4/4"
        let tempo = music?.tempo ?? 120

        do {
            let feedback = try await feedbackService.analyzePractice(
                songTitle: songTitle,
                instrument: instrument,
                skillLevel: skillLevel,
                notes: notes,
                keySignature: keySignature,
                timeSignature: timeSignature,
                tempo: tempo,
                practiceDuration: elapsedTime,
                audioURL: audioURL
            )
            phase = .complete(feedback)
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func cancelPractice() {
        countdownTask?.cancel()
        recordingService.cleanup()
        phase = .idle
    }

    func reset() {
        countdownTask?.cancel()
        recordingService.cleanup()
        phase = music != nil ? .idle : .setup
        elapsedTime = 0
    }

    private func beginRecording() async {
        let started = await recordingService.startRecording()
        if started {
            phase = .recording
        } else {
            phase = .error("Microphone access is required for Practice Mode. Please enable it in Settings.")
        }
    }
}
