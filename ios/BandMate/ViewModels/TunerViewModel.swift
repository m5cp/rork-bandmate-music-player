import AVFoundation
import Accelerate
import SwiftUI

@Observable
@MainActor
class TunerViewModel {
    var isListening: Bool = false
    var currentFrequency: Double = 0
    var currentNote: String = "--"
    var currentOctave: Int = 4
    var centsOff: Double = 0
    var referencePitch: Double = 440.0
    var targetFrequency: Double = 440.0

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?

    private let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]

    var tuningColor: Color {
        let absCents = abs(centsOff)
        if absCents < 5 { return .green }
        if absCents < 15 { return .yellow }
        return .red
    }

    var tuningText: String {
        let absCents = abs(centsOff)
        if absCents < 5 { return "In Tune ✓" }
        if centsOff < 0 { return "Flat — \(Int(absCents))¢" }
        return "Sharp + \(Int(absCents))¢"
    }

    func start() {
        Task {
            let granted = await requestMicPermission()
            guard granted else { return }
            startListening()
        }
    }

    func stop() {
        isListening = false
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
    }

    private func requestMicPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func startListening() {
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        let sampleRate = format.sampleRate

        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let frequency = self.detectPitch(buffer: buffer, sampleRate: sampleRate)
            Task { @MainActor in
                if frequency > 60 && frequency < 2000 {
                    self.updatePitch(frequency)
                }
            }
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
            try engine.start()
            self.audioEngine = engine
            isListening = true
        } catch {
            print("Tuner start error: \(error)")
        }
    }

    nonisolated private func detectPitch(buffer: AVAudioPCMBuffer, sampleRate: Double) -> Double {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)

        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(count))
        guard rms > 0.01 else { return 0 }

        let halfCount = count / 2
        var autocorrelation = [Float](repeating: 0, count: halfCount)

        for lag in 0..<halfCount {
            var sum: Float = 0
            vDSP_dotpr(channelData, 1, channelData.advanced(by: lag), 1, &sum, vDSP_Length(count - lag))
            autocorrelation[lag] = sum
        }

        let minLag = Int(sampleRate / 2000)
        let maxLag = min(halfCount - 1, Int(sampleRate / 60))

        guard maxLag > minLag else { return 0 }

        var bestLag = minLag
        var bestValue: Float = -Float.infinity
        for lag in minLag...maxLag {
            if autocorrelation[lag] > bestValue {
                bestValue = autocorrelation[lag]
                bestLag = lag
            }
        }

        guard bestValue > autocorrelation[0] * 0.2 else { return 0 }

        return sampleRate / Double(bestLag)
    }

    private func updatePitch(_ frequency: Double) {
        currentFrequency = frequency

        let semitone = 12.0 * log2(frequency / referencePitch) + 69
        let roundedSemitone = Int(round(semitone))
        let noteIndex = ((roundedSemitone % 12) + 12) % 12
        let octave = (roundedSemitone / 12) - 1

        currentNote = noteNames[noteIndex]
        currentOctave = octave
        centsOff = (semitone - Double(roundedSemitone)) * 100

        let targetSemitone = Double(roundedSemitone)
        targetFrequency = referencePitch * pow(2, (targetSemitone - 69) / 12)
    }
}
