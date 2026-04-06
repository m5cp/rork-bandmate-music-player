import Foundation
import SwiftData

@Model
class Song {
    var id: UUID = UUID()
    var title: String = ""
    var keySignature: String = "C Major"
    var timeSignature: String = "4/4"
    var tempo: Int = 120
    var noteCount: Int = 0
    var createdAt: Date = Date()
    var lastPlayedAt: Date?
    var imageData: Data?
    var notesJSON: Data?
    var preferredInstrument: String = "Trumpet"

    init(title: String, keySignature: String, timeSignature: String, tempo: Int, noteCount: Int, imageData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.keySignature = keySignature
        self.timeSignature = timeSignature
        self.tempo = tempo
        self.noteCount = noteCount
        self.createdAt = Date()
        self.imageData = imageData
    }

    var parsedNotes: [MusicNote]? {
        guard let data = notesJSON else { return nil }
        return try? JSONDecoder().decode([MusicNote].self, from: data)
    }

    func setNotes(_ notes: [MusicNote]) {
        notesJSON = try? JSONEncoder().encode(notes)
    }
}
