import AVFoundation
import AudioToolbox

@Observable
@MainActor
class AudioEngineService {
    var isPlaying: Bool = false
    var currentBeat: Double = 0
    var totalBeats: Double = 0
    var progress: Double = 0

    private var engine: AVAudioEngine?
    private var sampler: AVAudioUnitSampler?
    private var playbackTask: Task<Void, Never>?
    private var notes: [MusicNote] = []
    private var tempo: Double = 120
    private var currentInstrument: Instrument = .trumpet
    private var isLooping: Bool = false
    private var soundFontURL: URL?

    func setup() {
        let engine = AVAudioEngine()
        let sampler = AVAudioUnitSampler()

        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            engine.prepare()
            try engine.start()
        } catch {
            print("Audio engine setup failed: \(error)")
        }

        self.engine = engine
        self.sampler = sampler
        self.soundFontURL = Bundle.main.url(forResource: "TimGM6mb", withExtension: "sf2")

        loadInstrumentFromSoundFont(currentInstrument)
    }

    func setInstrument(_ instrument: Instrument) {
        currentInstrument = instrument
        loadInstrumentFromSoundFont(instrument)
    }

    private func loadInstrumentFromSoundFont(_ instrument: Instrument) {
        guard let sampler, let soundFontURL else { return }

        let bankMSB: UInt8 = instrument.isPercussion
            ? UInt8(kAUSampler_DefaultPercussionBankMSB)
            : UInt8(kAUSampler_DefaultMelodicBankMSB)

        do {
            try sampler.loadSoundBankInstrument(
                at: soundFontURL,
                program: instrument.midiProgram,
                bankMSB: bankMSB,
                bankLSB: 0
            )
        } catch {
            print("Failed to load instrument \(instrument.rawValue): \(error)")
        }
    }

    func loadNotes(_ notes: [MusicNote], tempo: Double) {
        self.notes = notes
        self.tempo = tempo
        self.totalBeats = notes.last.map { $0.startBeat + $0.duration } ?? 0
        self.currentBeat = 0
        self.progress = 0
    }

    func play() {
        guard !notes.isEmpty else { return }
        if engine == nil { setup() }
        setInstrument(currentInstrument)

        isPlaying = true
        playbackTask?.cancel()

        playbackTask = Task {
            await performPlayback()
        }
    }

    func pause() {
        isPlaying = false
        playbackTask?.cancel()
        sampler?.stopNote(0, onChannel: currentInstrument.midiChannel)
    }

    func stop() {
        isPlaying = false
        playbackTask?.cancel()
        currentBeat = 0
        progress = 0
        sampler?.stopNote(0, onChannel: currentInstrument.midiChannel)
    }

    func setTempo(_ newTempo: Double) {
        tempo = newTempo
    }

    func setLooping(_ looping: Bool) {
        isLooping = looping
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    private func performPlayback() async {
        guard let sampler else { return }
        let channel = currentInstrument.midiChannel

        repeat {
            let startBeatOffset = currentBeat

            for note in notes {
                guard isPlaying, !Task.isCancelled else { return }

                if note.startBeat < startBeatOffset { continue }

                let waitBeats = note.startBeat - currentBeat
                if waitBeats > 0 {
                    let waitSeconds = (waitBeats / tempo) * 60.0
                    try? await Task.sleep(for: .milliseconds(Int(waitSeconds * 1000)))
                }

                guard isPlaying, !Task.isCancelled else { return }

                currentBeat = note.startBeat
                progress = totalBeats > 0 ? currentBeat / totalBeats : 0

                if !note.isRest {
                    sampler.startNote(note.midiNote, withVelocity: 80, onChannel: channel)

                    let noteDurationSeconds = (note.duration / tempo) * 60.0
                    try? await Task.sleep(for: .milliseconds(Int(noteDurationSeconds * 1000)))

                    guard !Task.isCancelled else { return }
                    sampler.stopNote(note.midiNote, onChannel: channel)
                } else {
                    let restDurationSeconds = (note.duration / tempo) * 60.0
                    try? await Task.sleep(for: .milliseconds(Int(restDurationSeconds * 1000)))
                }
            }

            currentBeat = totalBeats
            progress = 1.0

            if !isLooping {
                isPlaying = false
                currentBeat = 0
                progress = 0
            } else {
                currentBeat = 0
                progress = 0
            }
        } while isLooping && isPlaying && !Task.isCancelled
    }

    func cleanup() {
        stop()
        engine?.stop()
        if let sampler {
            engine?.detach(sampler)
        }
        engine = nil
        sampler = nil
    }
}
