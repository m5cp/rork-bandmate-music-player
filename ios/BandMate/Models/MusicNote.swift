import Foundation

nonisolated struct MusicNote: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let pitch: Int
    let duration: Double
    let startBeat: Double
    let noteName: String
    let octave: Int
    let isRest: Bool

    init(id: UUID = UUID(), pitch: Int, duration: Double, startBeat: Double, noteName: String, octave: Int, isRest: Bool = false) {
        self.id = id
        self.pitch = pitch
        self.duration = duration
        self.startBeat = startBeat
        self.noteName = noteName
        self.octave = octave
        self.isRest = isRest
    }

    var displayName: String {
        isRest ? "Rest" : "\(noteName)\(octave)"
    }

    var midiNote: UInt8 {
        UInt8(clamping: pitch)
    }

    var durationInSeconds: Double {
        duration
    }
}
