import Foundation

@MainActor
class PracticeFeedbackService {
    static let shared = PracticeFeedbackService()

    func analyzePractice(
        songTitle: String,
        instrument: Instrument,
        skillLevel: SkillLevel,
        notes: [MusicNote],
        keySignature: String,
        timeSignature: String,
        tempo: Int,
        practiceDuration: TimeInterval,
        audioURL: URL?
    ) async throws -> PracticeFeedback {
        let baseURL = Config.EXPO_PUBLIC_TOOLKIT_URL
        guard !baseURL.isEmpty else {
            throw PracticeFeedbackError.configurationMissing
        }

        let endpoint = baseURL.hasSuffix("/") ? "\(baseURL)agent/chat" : "\(baseURL)/agent/chat"
        guard let url = URL(string: endpoint) else {
            throw PracticeFeedbackError.invalidURL
        }

        let notesSummary = buildNotesSummary(notes)
        let durationFormatted = formatDuration(practiceDuration)

        let prompt = buildPrompt(
            songTitle: songTitle,
            instrument: instrument,
            skillLevel: skillLevel,
            notesSummary: notesSummary,
            keySignature: keySignature,
            timeSignature: timeSignature,
            tempo: tempo,
            duration: durationFormatted
        )

        let requestBody: [String: Any] = [
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "response_format": [
                "type": "json_object"
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw PracticeFeedbackError.serverError
        }

        let aiResponse = try parseAIResponse(data)
        return PracticeFeedback(
            overallScore: aiResponse.overallScore,
            summary: aiResponse.summary,
            strengths: aiResponse.strengths,
            improvements: aiResponse.improvements,
            tips: aiResponse.tips,
            encouragement: aiResponse.encouragement,
            focusAreas: aiResponse.focusAreas.map { FocusArea(name: $0.name, score: $0.score, detail: $0.detail) }
        )
    }

    private func parseAIResponse(_ data: Data) throws -> AIFeedbackResponse {
        if let directResponse = try? JSONDecoder().decode(AIFeedbackResponse.self, from: data) {
            return directResponse
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PracticeFeedbackError.parsingError
        }

        if let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String,
           let contentData = content.data(using: .utf8) {
            if let parsed = try? JSONDecoder().decode(AIFeedbackResponse.self, from: contentData) {
                return parsed
            }
        }

        if let content = json["content"] as? String,
           let contentData = content.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(AIFeedbackResponse.self, from: contentData) {
            return parsed
        }

        if let text = json["text"] as? String,
           let textData = text.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(AIFeedbackResponse.self, from: textData) {
            return parsed
        }

        throw PracticeFeedbackError.parsingError
    }

    private func buildNotesSummary(_ notes: [MusicNote]) -> String {
        let totalNotes = notes.filter { !$0.isRest }.count
        let restCount = notes.filter { $0.isRest }.count
        let pitchRange: String = {
            let pitches = notes.filter { !$0.isRest }.map(\.pitch)
            guard let minP = pitches.min(), let maxP = pitches.max() else { return "N/A" }
            return "MIDI \(minP)-\(maxP)"
        }()
        let uniqueNotes = Set(notes.filter { !$0.isRest }.map(\.noteName))
        let totalBeats = notes.last.map { $0.startBeat + $0.duration } ?? 0

        return """
        Total notes: \(totalNotes), Rests: \(restCount), \
        Pitch range: \(pitchRange), \
        Unique pitches: \(uniqueNotes.sorted().joined(separator: ", ")), \
        Total beats: \(Int(totalBeats))
        """
    }

    private func buildPrompt(
        songTitle: String,
        instrument: Instrument,
        skillLevel: SkillLevel,
        notesSummary: String,
        keySignature: String,
        timeSignature: String,
        tempo: Int,
        duration: String
    ) -> String {
        """
        You are an expert music teacher and practice coach. A student just finished a practice session. \
        Analyze their practice and provide detailed, constructive feedback.

        PRACTICE SESSION DETAILS:
        - Song: "\(songTitle)"
        - Instrument: \(instrument.rawValue)
        - Key Signature: \(keySignature)
        - Time Signature: \(timeSignature)
        - Tempo: \(tempo) BPM
        - Practice Duration: \(duration)
        - Skill Level: \(skillLevel.rawValue)
        - Music Content: \(notesSummary)

        SKILL LEVEL GUIDANCE:
        \(skillLevelGuidance(skillLevel))

        Respond with ONLY valid JSON in this exact format:
        {
            "overallScore": <number 1-100>,
            "summary": "<2-3 sentence overall assessment>",
            "strengths": ["<strength 1>", "<strength 2>", "<strength 3>"],
            "improvements": ["<area 1>", "<area 2>"],
            "tips": ["<actionable tip 1>", "<actionable tip 2>", "<actionable tip 3>"],
            "encouragement": "<motivating closing message>",
            "focusAreas": [
                {"name": "Pitch Accuracy", "score": <1-100>, "detail": "<specific feedback>"},
                {"name": "Rhythm & Timing", "score": <1-100>, "detail": "<specific feedback>"},
                {"name": "Dynamics", "score": <1-100>, "detail": "<specific feedback>"},
                {"name": "Expression", "score": <1-100>, "detail": "<specific feedback>"}
            ]
        }
        """
    }

    private func skillLevelGuidance(_ level: SkillLevel) -> String {
        switch level {
        case .beginner:
            return """
            For BEGINNER: Be very encouraging and supportive. Focus on basic concepts like hitting the right notes, \
            maintaining steady tempo, and proper breathing/posture. Use simple language. \
            Celebrate small wins. Score generously (60-90 range). Keep tips simple and actionable.
            """
        case .intermediate:
            return """
            For INTERMEDIATE: Balance encouragement with constructive criticism. Address dynamics (playing too loud/soft), \
            articulation, note transitions, and consistency. Discuss musical phrasing. \
            Score fairly (40-85 range). Provide specific technical tips.
            """
        case .advanced:
            return """
            For ADVANCED: Provide detailed, nuanced critique. Address expression, phrasing, intonation, \
            vibrato, tonal quality, musicality, and interpretation. Be honest but respectful. \
            Score critically (30-80 range). Offer advanced technique suggestions.
            """
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

nonisolated enum PracticeFeedbackError: Error, LocalizedError, Sendable {
    case configurationMissing
    case invalidURL
    case serverError
    case parsingError
    case recordingFailed

    var errorDescription: String? {
        switch self {
        case .configurationMissing: "AI service is not configured"
        case .invalidURL: "Invalid service URL"
        case .serverError: "The AI service is temporarily unavailable"
        case .parsingError: "Could not process the feedback"
        case .recordingFailed: "Microphone recording failed"
        }
    }
}
