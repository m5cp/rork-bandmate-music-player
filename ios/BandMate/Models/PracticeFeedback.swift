import Foundation

nonisolated struct PracticeFeedback: Codable, Sendable, Identifiable {
    let id: UUID
    let overallScore: Int
    let summary: String
    let strengths: [String]
    let improvements: [String]
    let tips: [String]
    let encouragement: String
    let focusAreas: [FocusArea]
    let date: Date

    init(id: UUID = UUID(), overallScore: Int, summary: String, strengths: [String], improvements: [String], tips: [String], encouragement: String, focusAreas: [FocusArea], date: Date = Date()) {
        self.id = id
        self.overallScore = overallScore
        self.summary = summary
        self.strengths = strengths
        self.improvements = improvements
        self.tips = tips
        self.encouragement = encouragement
        self.focusAreas = focusAreas
        self.date = date
    }
}

nonisolated struct FocusArea: Codable, Sendable, Identifiable {
    let id: UUID
    let name: String
    let score: Int
    let detail: String

    init(id: UUID = UUID(), name: String, score: Int, detail: String) {
        self.id = id
        self.name = name
        self.score = score
        self.detail = detail
    }
}

nonisolated struct AIFeedbackResponse: Codable, Sendable {
    let overallScore: Int
    let summary: String
    let strengths: [String]
    let improvements: [String]
    let tips: [String]
    let encouragement: String
    let focusAreas: [AIFocusArea]
}

nonisolated struct AIFocusArea: Codable, Sendable {
    let name: String
    let score: Int
    let detail: String
}
