import Foundation
import SwiftData

@Model
class PracticeSession {
    var id: UUID = UUID()
    var songTitle: String = ""
    var instrument: String = ""
    var skillLevel: String = "Beginner"
    var duration: TimeInterval = 0
    var date: Date = Date()
    var overallScore: Int = 0
    var feedbackJSON: Data?

    init(songTitle: String, instrument: String, skillLevel: String, duration: TimeInterval, overallScore: Int = 0) {
        self.id = UUID()
        self.songTitle = songTitle
        self.instrument = instrument
        self.skillLevel = skillLevel
        self.duration = duration
        self.date = Date()
        self.overallScore = overallScore
    }

    var feedback: PracticeFeedback? {
        guard let data = feedbackJSON else { return nil }
        return try? JSONDecoder().decode(PracticeFeedback.self, from: data)
    }

    func setFeedback(_ feedback: PracticeFeedback) {
        feedbackJSON = try? JSONEncoder().encode(feedback)
        overallScore = feedback.overallScore
    }
}
