import Foundation

nonisolated struct ParsedMusic: Codable, Sendable {
    let notes: [MusicNote]
    let timeSignatureTop: Int
    let timeSignatureBottom: Int
    let keySignature: String
    let tempo: Int
    let title: String?

    var noteCount: Int { notes.count }

    var totalDuration: Double {
        guard let lastNote = notes.last else { return 0 }
        return lastNote.startBeat + lastNote.duration
    }

    var timeSignatureDisplay: String {
        "\(timeSignatureTop)/\(timeSignatureBottom)"
    }
}
