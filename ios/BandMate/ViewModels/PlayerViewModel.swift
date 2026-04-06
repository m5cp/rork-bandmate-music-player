import SwiftUI

@Observable
@MainActor
class PlayerViewModel {
    let audioEngine = AudioEngineService()
    var selectedInstrument: Instrument = .trumpet
    var tempo: Double = 120
    var isLooping: Bool = false
    var parsedMusic: ParsedMusic?
    var sheetImage: UIImage?
    private var hapticTrigger: Int = 0

    func loadMusic(_ music: ParsedMusic, image: UIImage?) {
        parsedMusic = music
        sheetImage = image
        tempo = Double(music.tempo)
        audioEngine.setup()
        audioEngine.loadNotes(music.notes, tempo: tempo)
        audioEngine.setInstrument(selectedInstrument)
    }

    func togglePlayback() {
        audioEngine.togglePlayPause()
        hapticTrigger += 1
    }

    func stopPlayback() {
        audioEngine.stop()
    }

    func updateTempo(_ newTempo: Double) {
        tempo = newTempo
        audioEngine.setTempo(newTempo)
    }

    func updateInstrument(_ instrument: Instrument) {
        selectedInstrument = instrument
        audioEngine.setInstrument(instrument)
    }

    func toggleLoop() {
        isLooping.toggle()
        audioEngine.setLooping(isLooping)
    }

    func cleanup() {
        audioEngine.cleanup()
    }
}
