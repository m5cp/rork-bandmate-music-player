import Foundation

nonisolated enum SkillLevel: String, CaseIterable, Sendable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .beginner: "Focus on pitch, rhythm basics, and encouragement"
        case .intermediate: "Detailed feedback on dynamics, articulation, consistency"
        case .advanced: "Nuanced critique on expression, phrasing, intonation"
        }
    }

    var iconName: String {
        switch self {
        case .beginner: "star"
        case .intermediate: "star.leadinghalf.filled"
        case .advanced: "star.fill"
        }
    }

    var reportDescription: String {
        switch self {
        case .beginner: "Report covers: pitch accuracy, rhythm basics, tempo steadiness. Encouraging tone with generous scoring."
        case .intermediate: "Report covers: dynamics, articulation, note transitions, phrasing consistency. Balanced critique."
        case .advanced: "Report covers: expression, intonation, vibrato, tonal quality, musical interpretation. Detailed critique."
        }
    }
}
