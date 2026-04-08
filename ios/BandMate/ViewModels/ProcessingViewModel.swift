import SwiftUI
import SwiftData

@Observable
@MainActor
class ProcessingViewModel {
    let recognitionService = MusicRecognitionService()
    var parsedMusic: ParsedMusic?
    var isComplete: Bool = false
    var hasError: Bool = false

    func processImage(_ image: UIImage) async {
        let result = await recognitionService.analyzeSheetMusic(image: image)
        if let music = result {
            parsedMusic = music
            isComplete = true
        } else {
            hasError = true
        }
    }

    func saveSong(music: ParsedMusic, image: UIImage?, modelContext: ModelContext) -> Song {
        let song = Song(
            title: music.title ?? "Untitled",
            keySignature: music.keySignature,
            timeSignature: music.timeSignatureDisplay,
            tempo: music.tempo,
            noteCount: music.noteCount,
            imageData: image?.jpegData(compressionQuality: 0.7)
        )
        song.setNotes(music.notes)
        modelContext.insert(song)
        GamificationManager.shared.recordSongScanned()
        return song
    }
}
