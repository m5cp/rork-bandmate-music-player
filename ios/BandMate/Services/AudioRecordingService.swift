import AVFoundation

@Observable
@MainActor
class AudioRecordingService {
    var isRecording: Bool = false
    var recordingDuration: TimeInterval = 0
    var audioLevel: Float = 0

    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var timer: Timer?
    private var levelTimer: Timer?
    private var startTime: Date?

    var currentRecordingURL: URL? { recordingURL }

    func startRecording() async -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            return false
        }

        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else { return false }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("practice_\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord()
            recorder.record()

            audioRecorder = recorder
            recordingURL = url
            isRecording = true
            startTime = Date()
            recordingDuration = 0

            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self, let start = self.startTime else { return }
                    self.recordingDuration = Date().timeIntervalSince(start)
                }
            }

            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.audioRecorder?.updateMeters()
                    let level = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
                    let normalizedLevel = max(0, (level + 50) / 50)
                    self.audioLevel = normalizedLevel
                }
            }

            return true
        } catch {
            return false
        }
    }

    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        timer?.invalidate()
        timer = nil
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        return recordingURL
    }

    func cleanup() {
        stopRecording()
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        recordingDuration = 0
    }
}
